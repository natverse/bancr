#' Download a compiled BANC feather from GCS
#'
#' @description Internal helper. Downloads `compiled_data/<rel_path>`
#' from the public lee-lab BANC bucket, caches a local copy under
#' `tools::R_user_dir("bancr", "cache")`, and returns the
#' `arrow::read_feather()` data frame. Used as the default backing
#' store for [`banc_meta()`] / [`banc_meta_create_cache()`],
#' [`franken_meta()`] and [`banc_edgelist()`].
#'
#' @details The compiled tables live under
#' `gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/`.
#' Dataset slugs follow the `<dataset>_<version>` pattern, e.g.
#' `banc_888`, `fafb_783`, `manc_121`, `hemibrain_121`, `malecns_09`.
#' See the BANC dataset documentation at
#' \url{https://github.com/sjcabs/fly_connectome_data_tutorial/tree/main/data/dataset_documentation}.
#'
#' @param rel_path Character. Path under `compiled_data/`, e.g.
#'   `"banc_888/banc_888_meta.feather"`.
#' @param overwrite Logical. If `TRUE` re-download even if a cached copy
#'   already exists. Default `FALSE`.
#'
#' @return A data frame with all columns of the requested feather.
#' @keywords internal
#' @noRd
banc_gcs_compiled_feather <- function(rel_path, overwrite = FALSE) {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop("Package 'arrow' is required to read .feather tables. ",
         "Install with: install.packages('arrow')")
  }
  cache_dir <- tools::R_user_dir("bancr", "cache")
  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
  target <- file.path(cache_dir, basename(rel_path))
  if (!file.exists(target) || isTRUE(overwrite)) {
    url <- paste0(
      "https://storage.googleapis.com/lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/",
      rel_path
    )
    message("Downloading ", basename(target), " from GCS ...")
    # Some compiled feathers (edgelists, synapse parquets) are several
    # hundred MB; the default 60s download.file() timeout aborts mid-
    # stream on a slow connection. Bump to 1 h while the download runs,
    # then restore on exit.
    old_timeout <- getOption("timeout", default = 60L)
    options(timeout = max(3600L, old_timeout))
    on.exit(options(timeout = old_timeout), add = TRUE)
    utils::download.file(url, target, mode = "wb", quiet = FALSE)
  }
  arrow::read_feather(target)
}

# Thin wrapper for the per-dataset meta feathers used by
# banc_meta / franken_meta.
banc_gcs_meta_feather <- function(slug, overwrite = FALSE) {
  banc_gcs_compiled_feather(
    sprintf("%s/%s_meta.feather", slug, slug),
    overwrite = overwrite
  )
}
