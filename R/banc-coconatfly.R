#' Create or refresh cache of BANC meta information
#'
#' @description
#' `banc_meta_create_cache()` builds or refreshes an in-memory cache of
#' BANC metadata for efficient repeated lookups. The default `source =
#' "gcs"` reads the public compiled meta feather
#' (`gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_meta.feather`)
#' and needs no authentication beyond network access. The main accessor
#' [banc_meta()] always reads from the most recently created cache.
#'
#' @details
#' BANC meta queries can be slow; caching avoids repeated database access.
#' Rerun whenever labels are updated upstream.
#'
#' Three sources are supported:
#' \itemize{
#'   \item `"gcs"` (default): downloads `banc_888_meta.feather` from the
#'     public bucket (cached under `tools::R_user_dir("bancr", "cache")`).
#'     This is the recommended path for almost all users; it does not
#'     require BANC CAVE or SeaTable credentials.
#'   \item `"cave"`: builds the cache live from
#'     [banc_cell_info()] + [banc_codex_annotations()]. Requires
#'     authenticated BANC CAVE access. Use this when you need fresher
#'     annotations than the latest GCS snapshot.
#'   \item `"seatable"`: pulls the in-progress draft `banc_meta` SeaTable.
#'     **Restricted to the BANC production team** (requires a
#'     `BANCTABLE_TOKEN`); the rest of the `banctable_*` family is in the
#'     same category.
#' }
#'
#' @param source Character. Where to read the meta from. One of `"gcs"`
#'   (default), `"cave"`, `"seatable"`. See **Details**.
#' @param overwrite Logical. If `TRUE` and `source = "gcs"`, re-download
#'   the feather even if a cached copy exists.
#' @param use_seatable Deprecated. If supplied, `TRUE` maps to
#'   `source = "seatable"` and `FALSE` (the old default) maps to
#'   `source = "cave"` (the previous default before GCS).
#' @param return Logical; if `TRUE`, return the cache tibble; otherwise
#'   invisible `NULL`.
#' @family coconatfly
#' @return Invisibly returns the cache (data.frame) if `return=TRUE`;
#'   otherwise invisibly `NULL`.
#' @export
#'
#' @examples
#' \dontrun{
#' # Default: download once, cache locally, then look up
#' banc_meta_create_cache()
#' result <- banc_meta()
#'
#' # Live from CAVE (needs BANC CAVE auth)
#' banc_meta_create_cache(source = "cave")
#'
#' # SeaTable (production team only; needs BANCTABLE_TOKEN)
#' banc_meta_create_cache(source = "seatable")
#'
#' # Use the cache to drive a coconatfly plot
#' library(coconatfly)
#' register_banc_coconat()
#' cf_cosine_plot(cf_ids('/type:LAL0(08|09|10|42)',
#'                       datasets = c("banc", "hemibrain")))
#' }
banc_meta_create_cache <- NULL # Placeholder, assigned below

#' Query cached BANC meta data
#'
#' @description
#' Returns results from the in-memory cache, filtered by `ids` if given.
#' Cache must be created first using [banc_meta_create_cache()].
#'
#' @details
#' `banc_meta()` never queries databases directly.
#' If `ids` are given, filters the meta table by root_id.
#'
#' @param ids Vector of neuron/root IDs to select, or `NULL` for all.
#' @return tibble/data.frame, possibly filtered by ids.
#' @export
#' @seealso [banc_meta_create_cache()]
#'
#' @examples
#' \dontrun{
#' banc_meta_create_cache() # build the cache
#' all_meta <- banc_meta()  # retrieve all
#' }
banc_meta <- NULL # Placeholder, assigned below

# hidden
banc_meta <- local({
  .banc_meta_cache <- NULL

  .read_gcs <- function(overwrite = FALSE) {
    banc_gcs_meta_feather("banc_888", overwrite = overwrite) %>%
      dplyr::transmute(
        id = as.character(.data$root_id),
        class = .data$super_class,
        type = .data$cell_type,
        side = .data$side,
        subclass = .data$cell_class,
        subsubclass = .data$cell_sub_class
      ) %>%
      dplyr::distinct(.data$id, .keep_all = TRUE)
  }

  .read_seatable <- function() {
    banc.meta <- banctable_query(
      "SELECT root_id, super_class, side, cell_type, cell_class, cell_sub_class from banc_meta"
    )
    banc.meta %>%
      dplyr::transmute(
        id = as.character(.data$root_id),
        class = .data$super_class,
        type = .data$cell_type,
        side = .data$side,
        subclass = .data$cell_class,
        subsubclass = .data$cell_sub_class
      )
  }

  .read_cave <- function() {
    message("Fetching banc_cell_info()")
    bci <- banc_cell_info()
    # latest CAVEclient turns this into a logical value
    bci <- if(is.logical(bci$valid))
      bci %>% dplyr::filter(valid)
    else
      bci %>% dplyr::filter(valid == 't')

    banc.community.meta <- bci %>%
      dplyr::arrange(pt_root_id, tag) %>%
      dplyr::distinct(pt_root_id, tag2, tag, .keep_all = TRUE) %>%
      dplyr::group_by(pt_root_id, tag2) %>%
      dplyr::summarise(
        tag = {
          if (length(tag) > 1 && any(grepl("?", tag, fixed = TRUE))) {
            usx = unique(sub("?", "", tag, fixed = TRUE))
            if (length(usx) < length(tag)) tag = usx
          }
          paste0(tag, collapse = ";")
        },
        .groups = 'drop'
      ) %>%
      tidyr::pivot_wider(
        id_cols = pt_root_id,
        names_from = tag2,
        values_from = tag,
        values_fill = ""
      ) %>%
      dplyr::select(
        id = pt_root_id,
        class = `primary class`,
        type = `neuron identity`,
        side = `soma side`,
        subclass = `anterior-posterior projection pattern`
      ) %>%
      dplyr::mutate(class = gsub(" ","_", class))

    message("Fetching banc_codex_annotations()")
    banc.codex.meta <- banc_codex_annotations() %>%
      dplyr::distinct(pt_root_id, .keep_all = TRUE) %>%
      dplyr::select(
        id = pt_root_id,
        class = super_class,
        type = cell_type,
        side = side,
        subclass = cell_class,
        subsubclass = cell_sub_class
      )

    rbind(
      banc.codex.meta,
      banc.community.meta
    ) %>%
      dplyr::distinct(id, .keep_all = TRUE) %>%
      dplyr::mutate(id = as.character(id))
  }

  .refresh_cache <- function(source = "gcs", overwrite = FALSE) {
    switch(source,
           gcs      = .read_gcs(overwrite = overwrite),
           cave     = .read_cave(),
           seatable = .read_seatable(),
           stop("Unknown banc_meta source: ", source,
                ". Must be one of 'gcs', 'cave', 'seatable'."))
  }

  list(
    create_cache = function(source = c("gcs", "cave", "seatable"),
                            overwrite = FALSE,
                            use_seatable = NULL,
                            return = FALSE) {
      if (!is.null(use_seatable)) {
        warning("`use_seatable` is deprecated; use `source` instead.",
                call. = FALSE)
        source <- if (isTRUE(use_seatable)) "seatable" else "cave"
      } else {
        source <- match.arg(source)
      }
      meta <- .refresh_cache(source = source, overwrite = overwrite)
      .banc_meta_cache <<- meta
      if (return) meta else invisible()
    },
    get_meta = function(ids = NULL) {
      if (is.null(.banc_meta_cache)){
        message("No BANC meta cache loaded. Creating from GCS via banc_meta_create_cache()")
        banc_meta_create_cache()
      }
      meta <- .banc_meta_cache
      if (!is.null(ids)) {
        ids <- extract_ids(unname(unlist(ids)))
        ids <- tryCatch(banc_ids(ids), error = function(e) NULL)
        meta %>% dplyr::filter(.data$id %in% ids)
      } else {
        meta
      }
    }
  )
})

# Exported user-friendly functions
banc_meta_create_cache <- banc_meta$create_cache
banc_meta <- banc_meta$get_meta

# banc_coconat.R
coconat_banc_meta <- function(ids) {
  ids <- extract_ids(ids)
  if(is.character(ids) && length(ids)==1 && !fafbseg:::valid_id(ids))
    ids <- coconat_banc_ids(ids)
  tres=banc_meta(ids)
  tres$side=substr(toupper(tres$side),1,1)
  tres
}

# hidden
coconat_banc_ids <- function(ids=NULL) {
  if(is.null(ids)) return(NULL)
  # extract numeric ids if possible
  ids <- extract_ids(ids)
  if(is.character(ids) && length(ids)==1 && !fafbseg:::valid_id(ids)) {
    # query
    metadf=banc_meta()
    if(isTRUE(ids=='all')) return(banc_ids(metadf$id, integer64 = F))
    if(isTRUE(ids=='neurons')) {
      ids <- metadf %>%
        dplyr::filter(is.na(class) | class!='glia') %>%
        dplyr::pull(.data$id)
      return(banc_ids(ids, integer64 = F))
    }
    if(isTRUE(substr(ids, 1, 1)=="/"))
      ids=substr(ids, 2, nchar(ids))
    else warning("All BANC queries are regex queries. ",
                 "Use an initial / to suppress this warning!")
    if(!grepl(":", ids)) ids=paste0("type:", ids)
    qsplit=stringr::str_match(ids, pattern = '[/]{0,1}(.+):(.+)')
    field=qsplit[,2]
    value=qsplit[,3]
    if(!field %in% colnames(metadf)) {
      stop("BANC queries only work with these fields: ",
                paste(colnames(metadf)[-1], collapse = ','))
    }
    ids <- metadf %>%
      dplyr::filter(grepl(value, .data[[field]])) %>%
      dplyr::pull(.data$id)
  } else if(length(ids)>0) {
    # check they are valid for current materialisation
    banc_latestid(ids, version = banc_version())
  }
  return(banc_ids(ids, integer64 = F))
}

# minimal version of this function
coconat_banc_partners <- function(ids,
                                        partners,
                                        threshold,
                                        version=banc_version(),
                                        ...) {
  ids=coconat_banc_ids(ids)
  tres=banc_partner_summary(ids,
                                   partners = partners,
                                   threshold = threshold-1L,
                                   version=version,
                                   ...)
  # nb coconatfly can looks after adding metadata
  tres
}

#' Use BANC data with coconat for connectivity similarity
#'
#' @description Register the BANC dataset for use with
#'   \href{https://natverse.org/coconatfly}{coconatfly} across dataset
#'   connectome analysis.
#'
#' @details `register_banc_coconat()` registers `bancr`-backed functionality for
#'   use with \href{https://natverse.org/coconatfly}{coconatfly},
#'   \href{https://natverse.org}{natverse} R package providing a consistent
#'   interface to core connectome analysis functions across datasets. This
#'   includes within and between dataset connectivity comparisons using cosine
#'   similarity.
#'
#' @param showerror Logical: error-out silently or not.
#' @export
#' @family coconatfly
#'
#' @examples
#' \dontrun{
#' library(coconatfly)
#' # once per session
#' register_banc_coconat()
#'
#' # once per session or if you think there have been updates
#' banc_meta_create_cache()
#' # source = "seatable" if you are on the BANC production team and want
#' # the bleeding-edge draft labels (needs BANCTABLE_TOKEN)
#' banc_meta_create_cache(source = "seatable")
#'
#' # examples of within dataset analysis
#' dna02meta <- cf_meta(cf_ids(banc='/DNa02'))
#' cf_partner_summary(dna02meta, partners = 'out', threshold = 10)
#' cf_ids(banc='/type:DNa.+')
#'
#' # an example of across dataset cosine similarity plot
#' cf_cosine_plot(cf_ids('/type:LAL0(08|09|10|42)', datasets = c("banc", "hemibrain")))
#' }
register_banc_coconat <- function(showerror=TRUE){
  if (!requireNamespace("coconatfly", quietly = showerror)) {
    if(!showerror) return(invisible())
    stop("Package 'coconatfly' is required for this function. Install it with:\n  devtools::install_github('natverse/coconatfly')")
  }
  coconat::register_dataset(
    name = 'banc',
    shortname = 'bc',
    namespace = 'coconatfly',
    sex = "F",
    metafun = coconat_banc_meta,
    idfun = coconat_banc_ids,
    partnerfun = coconat_banc_partners
  )
}
