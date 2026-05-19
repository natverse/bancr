#' Download BANC automatic synapse detections as a .sqlite file
#'
#' @description Downloads a pre-baked Zetta.ai synapse table for the BANC
#' from
#' `gs://lee-lab_brain-and-nerve-cord-fly-connectome/neuron_connectivity/v888/`
#' and caches it as a per-version `banc_data_<version>.sqlite` file. After
#' the one-off download subsequent calls read lazily from the cache so the
#' table is never fully loaded into memory.
#'
#' @details
#' Three versions are exposed, matching the BANC CAVE annotation tables of
#' the same name. The version-specific metadata below is taken directly
#' from each table's CAVE description; check
#' <https://banc.community/Automated-segmentation> for the column-level
#' documentation that ships with the source files.
#'
#' \itemize{
#'   \item \strong{v1} (deprecated). Source
#'     `gs://zetta_lee_fly_cns_001_synapse/240623_run/assignment/final_edgelist.df`,
#'     created 2024-07-25. Coordinates are in nanometers (CAVE
#'     `voxel_resolution = c(1, 1, 1)`). The CAVE table owner notice marks
#'     this version as deprecated in favour of v2.
#'   \item \strong{v2} (default). Source
#'     `gs://zetta_lee_fly_cns_001_synapse/250226_assignment/assignment/final_edgelist.df`,
#'     created 2025-08-14. Coordinates are in nanometers (CAVE
#'     `voxel_resolution = c(1, 1, 1)`). This is the current production
#'     synapse table.
#'   \item \strong{v3} (in testing). Created 2026-04-10. Coordinates are
#'     reported on the synapse-detection grid with CAVE
#'     `voxel_resolution = c(16, 16, 45)` nm/voxel - multiply by these
#'     values to obtain nanometers. Marked "still in testing" by the table
#'     owner.
#' }
#'
#' Note that v1 and v2 coordinates are already in nanometers, which
#' differs from most BANC CAVE tables (those use the EM image grid of
#' `c(4, 4, 45)` nm/voxel).
#'
#' Each version's `synapses_<version>_human_readable.csv.gz` is large
#' (~12 GB gzipped for v2). The 15 columns are, in order:
#' `id`, `pre_x`, `pre_y`, `pre_z`, `post_x`, `post_y`, `post_z`,
#' `centroid_x`, `centroid_y`, `centroid_z`, `size`,
#' `pre_pt_supervoxel_id`, `pre_pt_root_id`,
#' `post_pt_supervoxel_id`, `post_pt_root_id`.
#'
#' @param version Character, which synapse table to download. One of
#'   `"v2"` (default), `"v1"`, or `"v3"`.
#' @param overwrite Logical, whether or not to overwrite an extant
#'   `banc_data_<version>.sqlite` cache.
#' @param n_max Numeric, the maximum number of rows to stream lazily from
#'   the CSV when previewing. Set to `NULL` to trigger a full download
#'   into the SQLite cache.
#' @param details Logical. If `FALSE` (default) only the essential
#'   pre-side columns (`id`, `pre_pt_root_id`, `pre_x`, `pre_y`, `pre_z`,
#'   `size`) are read; if `TRUE` all 15 columns are kept.
#' @param path Optional explicit override of the HTTPS URL. Normally left
#'   `NULL` so the path is built from `version`.
#'
#' @return a data.frame (or a lazy `dplyr::tbl` backed by SQLite when the
#'   full table has been cached).
#'
#' @seealso \code{\link{banc_partner_summary}}, \code{\link{banc_partners}}
#' @export
#'
#' @examples
#' \dontrun{
#' # Default: v2, preview first 2000 rows lazily from the CSV
#' syns <- banc_all_synapses()
#'
#' # Full download of v2 (~12 GB gzipped) into the per-version SQLite cache
#' syns_all <- banc_all_synapses(n_max = NULL)
#'
#' # Switch to the deprecated v1 table or the in-testing v3 table
#' syns_v1 <- banc_all_synapses(version = "v1")
#' syns_v3 <- banc_all_synapses(version = "v3")
#' }
banc_all_synapses <- function(version = c("v2", "v1", "v3"),
                              overwrite = FALSE,
                              n_max = 2000,
                              details = FALSE,
                              path = NULL) {
  version <- match.arg(version)
  if (is.null(path)) {
    path <- sprintf(
      "https://storage.googleapis.com/lee-lab_brain-and-nerve-cord-fly-connectome/neuron_connectivity/v888/synapses_%s_human_readable.csv.gz",
      version
    )
  }

  if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("RSQLite", quietly = TRUE)) {
    stop("Packages 'DBI' and 'RSQLite' are required for this function. Please install them with: install.packages(c('DBI', 'RSQLite'))")
  }
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("Package 'readr' is required for this function. Please install it with: install.packages('readr')")
  }

  # Column layout of the headerless human_readable CSVs. v1/v2 store
  # coordinates in nanometers; v3 stores them on a 16/16/45 grid (see
  # CAVE descriptions in @details).
  col_names_all <- c(
    "id",
    "pre_x", "pre_y", "pre_z",
    "post_x", "post_y", "post_z",
    "centroid_x", "centroid_y", "centroid_z",
    "size",
    "pre_pt_supervoxel_id", "pre_pt_root_id",
    "post_pt_supervoxel_id", "post_pt_root_id"
  )
  col_select_essential <- c("id", "pre_pt_root_id",
                            "pre_x", "pre_y", "pre_z", "size")
  col.types <- readr::cols(
    id                    = readr::col_double(),
    pre_x                 = readr::col_integer(),
    pre_y                 = readr::col_integer(),
    pre_z                 = readr::col_integer(),
    post_x                = readr::col_integer(),
    post_y                = readr::col_integer(),
    post_z                = readr::col_integer(),
    centroid_x            = readr::col_integer(),
    centroid_y            = readr::col_integer(),
    centroid_z            = readr::col_integer(),
    size                  = readr::col_double(),
    pre_pt_supervoxel_id  = readr::col_character(),
    pre_pt_root_id        = readr::col_character(),
    post_pt_supervoxel_id = readr::col_character(),
    post_pt_root_id       = readr::col_character()
  )

  # Per-version SQLite cache. Pre-existing v1 caches keep their legacy
  # path so old installations still work.
  file_path <- file.path(system.file(package = "bancr"), "data",
                         sprintf("banc_data_%s.sqlite", version))
  if (!file.exists(file_path)) {
    con <- DBI::dbConnect(RSQLite::SQLite(), file_path)
    DBI::dbDisconnect(con)
    table_exists <- FALSE
    message("Created: ", file_path)
  } else {
    con <- DBI::dbConnect(RSQLite::SQLite(), file_path)
    table_exists <- "synapses" %in% DBI::dbListTables(con)
    DBI::dbDisconnect(con)
  }

  read_args <- list(
    file      = path,
    col_names = col_names_all,
    col_types = col.types,
    lazy      = TRUE
  )
  if (!details) read_args$col_select <- col_select_essential

  if (!is.null(n_max)) {
    read_args$n_max <- n_max
    return(do.call(readr::read_csv, read_args))
  } else if (!table_exists || overwrite) {
    syns <- do.call(readr::read_csv, read_args)
    con <- DBI::dbConnect(RSQLite::SQLite(), file_path)
    DBI::dbWriteTable(con, "synapses", syns, overwrite = TRUE)
    DBI::dbDisconnect(con)
    message("Added tab synapses, no. rows: ", nrow(syns))
  }

  con <- DBI::dbConnect(RSQLite::SQLite(), file_path)
  dplyr::tbl(src = con, from = "synapses")

}
# Helpful scene: https://spelunker.cave-explorer.org/#!middleauth+https://global.daf-apis.com/nglstate/api/v1/4753860997414912

# # googleCloudStorageR
# banc_gcs_read <- function(path = "gs://zetta_lee_fly_cns_001_synapse/240623_run/assignment/final_edgelist.df"){

  # # Not sure hot to get this working in R, but looks useful
  # googleCloudStorageR::gcs_setup(token="none")
  # googleCloudStorageR::gcs_auth(token=NULL)
  # # OR?
  # scope <-c("https://www.googleapis.com/auth/cloud-platform")
  # token <- gargle::token_fetch(scopes = scope)
  # googleCloudStorageR::gcs_auth(token = token)
  # # Then get data?
  # path <- 'gs://zetta_lee_fly_cns_001_synapse/240529_run/240604_assignment/final_edgelist.df'
  # df <- googleCloudStorageR::gcs_get_object(path, parseFunction = function(x) read.csv(x, nrows = 1000))
# }


#' Add synapses to neuron objects
#'
#' This function family adds synaptic data to neuron objects or neuron lists.
#' It retrieves synaptic connections and attaches them to the neuron object(s).
#'
#' @param x A neuron object, neuronlist, or other object to add synapses to
#' @param id The root ID of the neuron. If `NULL`, it uses the ID from the neuron object
#' @param connectors A dataframe of synaptic connections. If `NULL`, it retrieves the data
#' @param size.threshold Minimum size threshold for synapses to include
#' @param remove.autapses Whether to remove autapses (self-connections)
#' @param update.id Logical, whether or not to use \code{banc_latestid} to update the neuron's `root_id` when fetching synapses.
#' @param ... Additional arguments passed to methods, \code{nat::nlapply}
#'
#' @return An object of the same type as `x`, with synapses added
#' @examples
#' \dontrun{
#' # Get BANC ID for DNA01
#' id <- "720575941572711675"
#' id <- banc_latestid(id)
#'
#' # Get the L2 skeletons
#' n <- banc_read_l2skel(id)
#'
#' # Re-root to soma
#' n.rerooted <- banc_reroot(n)
#'
#' # Add synapse information, stored at n.syn[[1]]$connectors
#' n.syn <- banc_add_synapses(n.rerooted)
#'
#' # Split neuron
#' n.split <- hemibrainr::flow_centrality(n.syn)
#'
#' # Visualise
#' banc_neuron_comparison_plot(n.split)
#' }
#' @export
banc_add_synapses <- function(x,
                              id = NULL,
                              connectors = NULL,
                              size.threshold = 5,
                              remove.autapses = TRUE,
                              update.id = TRUE,
                              ...) {
  UseMethod("banc_add_synapses")
}

#' @rdname banc_add_synapses
#' @export
banc_add_synapses.neuron <- function(x,
                              id = NULL,
                              connectors = NULL,
                              size.threshold = 5,
                              remove.autapses = TRUE,
                              update.id = TRUE,
                              ...){
  # Get valid root id
  if(is.null(id)){
    id <- x$id
  }
  if(update.id){
    id <- banc_latestid(id)
  }

  # Get synaptic data
  if(is.null(connectors)){
    connectors.in <- banc_partners(id, partners = "input")
    if(nrow(connectors.in)){
      connectors.in.xyz <- do.call(rbind,connectors.in$post_pt_position)
      connectors.in.xyz <- as.data.frame(connectors.in.xyz)
      colnames(connectors.in.xyz) <- c("X","Y","Z")
      connectors.in <- cbind(connectors.in,connectors.in.xyz)
      connectors.in <- connectors.in %>%
        dplyr::rename(connector_id = .data$id,
                      pre_id = .data$pre_pt_root_id,
                      pre_svid = .data$pre_pt_supervoxel_id,
                      post_id = .data$post_pt_root_id,
                      post_svid = .data$post_pt_supervoxel_id) %>%
        dplyr::filter(.data$size>size.threshold) %>%
        dplyr::mutate(prepost = 1) %>%
        dplyr::select(.data$connector_id,
                      .data$pre_id, .data$post_id, .data$prepost,
                      .data$pre_svid, .data$post_svid, .data$size,
                      .data$X, .data$Y, .data$Z)
    }
    connectors.out <- banc_partners(id, partners = "output")
    if(nrow(connectors.out)){
      connectors.out.xyz <- do.call(rbind,connectors.out$pre_pt_position)
      connectors.out.xyz <- as.data.frame(connectors.out.xyz)
      colnames(connectors.out.xyz) <- c("X","Y","Z")
      connectors.out <- cbind(connectors.out,connectors.out.xyz)
      connectors.out <- connectors.out %>%
        dplyr::rename(connector_id = .data$id,
                      pre_id = .data$pre_pt_root_id,
                      pre_svid = .data$pre_pt_supervoxel_id,
                      post_id = .data$post_pt_root_id,
                      post_svid = .data$post_pt_supervoxel_id) %>%
        dplyr::filter(.data$size>size.threshold) %>%
        dplyr::mutate(prepost = 0) %>%
        dplyr::select(.data$connector_id,
                      .data$pre_id, .data$post_id, .data$prepost,
                      .data$pre_svid, .data$post_svid, .data$size,
                      .data$X, .data$Y, .data$Z)
    }
    connectors <- rbind(connectors.in,connectors.out)
  }else{
    connectors <- connectors %>%
      dplyr::filter(.data$post_id==id|.data$pre_id==id)
  }

  # Attach synapses
  if(nrow(connectors)){
    if(remove.autapses) {
      connectors=connectors[connectors$post_id!=connectors$pre_id,,drop=FALSE]
    }
    near <- nabor::knn(query = nat::xyzmatrix(connectors),
                       data = nat::xyzmatrix(x$d),k=1)
    connectors$treenode_id <- x$d[near$nn.idx,"PointNo"]
    x$connectors = as.data.frame(connectors, stringsAsFactors = FALSE)
  }else{
    connectors <- data.frame()
  }
  x$connectors <- connectors

  # Change class to work with connectivity functions in other packages
  class(x) <- union(c("synapticneuron"), class(x))

  # Return
  x
}

#' @rdname banc_add_synapses
#' @export
banc_add_synapses.neuronlist <- function(x,
                                         id = NULL,
                                         connectors = NULL,
                                         size.threshold = 5,
                                         remove.autapses = TRUE,
                                         update.id = TRUE,
                                         ...) {
  if(is.null(id)){
    x <- add_field_seq(x, entries= names(x), field = "id")
  }
  nat::nlapply(x,
               banc_add_synapses.neuron,
               id=NULL,
               connectors=connectors,
               size.threshold=size.threshold,
               remove.autapses=remove.autapses,
               ...)
}

#' @rdname banc_add_synapses
#' @export
banc_add_synapses.default <- function(x,
                                      id = NULL,
                                      connectors = NULL,
                                      size.threshold = 5,
                                      remove.autapses = TRUE,
                                      update.id = TRUE,
                                      ...) {
  stop("No method for class ", class(x))
}










