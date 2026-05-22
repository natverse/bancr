# Internal helpers shared by the GCS-aware accessors:
#  - banc_source_announce(): one-time message describing which backing
#    store is being used for a given function call.
#  - banc_with_fallback(): dispatcher that tries the requested source
#    and (optionally) falls back to the other on error, emitting a
#    warning when the fallback fires.
#  - banc_gcs_annotation_parquet(): GCS reader for the
#    neuron_annotations/v888/*.parquet snapshots.

# Per-session source-announce throttle. rlang::inform()'s
# .frequency="once" handles this for us, keyed by .frequency_id, so
# each (function, source) pair only prints once.
banc_source_announce <- function(fn, source, alt = NULL) {
  if (is.null(alt)) alt <- if (source == "gcs") "cave" else "gcs"
  alt_line <- if (is.na(alt)) ""
              else switch(source,
                gcs  = sprintf("\n  Pass `source = \"%s\"` for a live materialised query.", alt),
                cave = sprintf("\n  Pass `source = \"%s\"` for the public compiled snapshot.", alt))
  body <- switch(source,
    gcs  = "reading from the public GCS snapshot (no BANC authentication required).",
    cave = "reading from live CAVE materialisation (requires authenticated BANC access).",
    stop("Unknown source: ", source)
  )
  msg <- sprintf("`%s()`: %s%s", fn, body, alt_line)
  rlang::inform(
    msg,
    .frequency = "once",
    .frequency_id = sprintf("bancr.source.%s.%s", fn, source)
  )
}

# Run `gcs_fn` or `cave_fn` per `source`. If it errors and `fallback`
# is TRUE, retry with the other source and warn the user.
banc_with_fallback <- function(fn, source, fallback, gcs_fn, cave_fn) {
  banc_source_announce(fn, source)
  primary_fn <- if (source == "gcs") gcs_fn else cave_fn
  alt <- if (source == "gcs") "cave" else "gcs"
  alt_fn <- if (alt == "gcs") gcs_fn else cave_fn
  res <- tryCatch(primary_fn(), error = function(e) e)
  if (!inherits(res, "error")) return(res)
  if (!isTRUE(fallback)) stop(res)
  warning(
    sprintf(
      paste0(
        "`%s()`: source = \"%s\" failed (%s).\n",
        "  Falling back to source = \"%s\". Pass `fallback = FALSE` ",
        "to disable this behaviour."
      ),
      fn, source, conditionMessage(res), alt
    ),
    call. = FALSE
  )
  banc_source_announce(fn, alt)
  alt_fn()
}

# Read one of the neuron_annotations/v888/*.parquet snapshots. Cached
# under tools::R_user_dir("bancr", "cache"). Same plumbing as
# banc_gcs_compiled_feather() but parquet + a different bucket prefix.
banc_gcs_annotation_parquet <- function(table, overwrite = FALSE) {
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop("Package 'arrow' is required to read .parquet annotation tables. ",
         "Install with: install.packages('arrow')")
  }
  cache_dir <- tools::R_user_dir("bancr", "cache")
  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
  target <- file.path(cache_dir, sprintf("%s.parquet", table))
  if (!file.exists(target) || isTRUE(overwrite)) {
    url <- sprintf(
      "https://storage.googleapis.com/lee-lab_brain-and-nerve-cord-fly-connectome/neuron_annotations/v888/%s.parquet",
      table
    )
    message("Downloading ", basename(target), " from GCS ...")
    old_timeout <- getOption("timeout", default = 60L)
    options(timeout = max(3600L, old_timeout))
    on.exit(options(timeout = old_timeout), add = TRUE)
    utils::download.file(url, target, mode = "wb", quiet = FALSE)
  }
  arrow::read_parquet(target)
}

# Helper used by the GCS branches: filter a CAVE-style annotation
# table to a set of rootids or nucleus ids. Mirrors the
# filter_in_dict behaviour of banc_cave_query().
banc_gcs_filter <- function(df, rootids = NULL, nucleus_ids = NULL) {
  if (!is.null(rootids) && length(rootids) > 0L) {
    rootids <- banc_ids(rootids)
    df <- df[as.character(df$pt_root_id) %in% as.character(rootids), , drop = FALSE]
  }
  if (!is.null(nucleus_ids) && length(nucleus_ids) > 0L) {
    df <- df[as.character(df$id) %in% as.character(nucleus_ids), , drop = FALSE]
  }
  df
}
