#' Per-neuron metrics for BANC v888
#'
#' @description Reads the compiled per-neuron metrics feather from the
#' public GCS bucket: cable length, neuron volume, mitochondria volume,
#' pre/post synapse counts, segregation index and a handful of other
#' morphology / connectivity scalars (one row per neuron, keyed by
#' `banc_888_id`).
#'
#' @details
#' Source:
#' `gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_metrics.feather`
#' (~7.5 MB; cached under `tools::R_user_dir("bancr", "cache")`).
#' No CAVE equivalent — this table is compiled offline from the
#' segmentation graph plus the synapse table. There is consequently no
#' `source` / `fallback` argument; the only way to refresh is to
#' re-download with `overwrite = TRUE`.
#'
#' @param rootids Optional vector of root IDs to filter to. `NULL`
#'   (default) returns all ~188 k rows.
#' @param overwrite Logical. If `TRUE`, re-download the cached
#'   feather even if it already exists.
#'
#' @return A data frame of per-neuron metrics.
#' @export
#'
#' @examples
#' \dontrun{
#' m <- banc_metrics()
#' my_metrics <- banc_metrics(rootids = c("720575941633499884",
#'                                        "720575941472733451"))
#' }
banc_metrics <- function(rootids = NULL, overwrite = FALSE) {
  banc_source_announce("banc_metrics", "gcs", alt = NA)
  res <- banc_gcs_compiled_feather("banc_888/banc_888_metrics.feather",
                                   overwrite = overwrite)
  if (!is.null(rootids)) {
    rootids <- banc_ids(rootids)
    key <- if ("banc_888_id" %in% names(res)) "banc_888_id" else "root_id"
    res <- res[as.character(res[[key]]) %in% as.character(rootids), ,
               drop = FALSE]
  }
  res
}

#' Compartment-resolved BANC edgelist
#'
#' @description Reads the compiled compartment-to-compartment edgelist
#' (axon / dendrite / primary_dendrite / primary_neurite / soma /
#' unknown) for BANC v888 from the public GCS bucket. Sibling of
#' [banc_edgelist()] but with `pre_label` / `post_label` columns and
#' optional pre/post neurotransmitter prediction.
#'
#' @details
#' Source:
#' `gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_edgelist_split_<version>.feather`.
#' `version = "v2"` and `version = "v3"` track the synapse-table
#' generations (see [banc_all_synapses()]). The legacy unversioned
#' `banc_888_edgelist_split.feather` is also available via
#' `version = "legacy"`.
#'
#' Files are ~321-907 MB (v3 is the largest); the first call caches
#' the feather under `tools::R_user_dir("bancr", "cache")`. There is
#' no CAVE equivalent of this compartment-split edgelist (CAVE only
#' exposes per-neuron pre/post root pairs), so there's no
#' `source` / `fallback` argument.
#'
#' @param version `"v2"` (default), `"v3"`, or `"legacy"` (the
#'   unversioned `banc_888_edgelist_split.feather`).
#' @param overwrite Logical. If `TRUE`, re-download the cached
#'   feather even if it already exists.
#'
#' @return A data frame of compartment-pair connections, columns:
#'   `pre, post, pre_label, post_label, count, norm, post_count,
#'   pre_count, connection, pre_conf_nt, pre_conf_nt_p, post_conf_nt,
#'   post_conf_nt_p`.
#' @export
#'
#' @examples
#' \dontrun{
#' # Compartment edgelist for the paper synapses (v2)
#' eds <- banc_edgelist_split()
#'
#' # Axon -> dendrite connections only
#' library(dplyr)
#' a2d <- eds %>% filter(pre_label == "axon", post_label == "dendrite")
#' }
banc_edgelist_split <- function(version = c("v2", "v3", "legacy"),
                                overwrite = FALSE) {
  version <- match.arg(version)
  banc_source_announce("banc_edgelist_split", "gcs", alt = NA)
  rel <- if (version == "legacy")
    "banc_888/banc_888_edgelist_split.feather"
  else
    sprintf("banc_888/banc_888_edgelist_split_%s.feather", version)
  banc_gcs_compiled_feather(rel, overwrite = overwrite)
}

#' Synapse-level BANC table with neuropil / NT enrichment
#'
#' @description Returns a lazy `arrow::open_dataset()` handle pointing
#' at the per-synapse enriched parquet for BANC v888. The table carries
#' ~169 M rows with neuropil membership, region, side and full
#' per-transmitter Eckstein et al. (2024) prediction probabilities for
#' each synapse. Apply further `dplyr::filter()` calls before
#' `dplyr::collect()` — predicate pushdown skips parquet row groups
#' that don't match.
#'
#' @details
#' Source:
#' `gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_synapses_<version>_enriched.parquet`.
#' The file is large (~9.6 GB for v2, ~15 GB for v3); the first call
#' downloads it under `tools::R_user_dir("bancr", "cache")` and
#' subsequent calls reuse the cache. Use `overwrite = TRUE` to force a
#' refresh.
#'
#' There is no CAVE equivalent of this enriched table (CAVE exposes
#' the raw `synapses_v<version>` table without neuropil / region / NT
#' enrichment), so there is no `source` / `fallback` argument.
#'
#' @param version `"v2"` (default; paper synapses) or `"v3"` (updated
#'   synapses, still in testing).
#' @param overwrite Logical. If `TRUE`, re-download the cached
#'   parquet even if it already exists.
#'
#' @return An `arrow_dplyr_query` lazy handle. Chain `dplyr::filter()`
#'   and `dplyr::collect()` to materialise a data frame.
#' @export
#'
#' @examples
#' \dontrun{
#' library(dplyr)
#'
#' # Lazy handle against the cached parquet
#' syn <- banc_synapses_enriched()
#'
#' # Pull synapses in the right mushroom body calyx
#' mb_ca_r <- syn %>%
#'   filter(neuropil == "MB_CA_R") %>%
#'   collect()
#'
#' # Synapses involving a specific neuron
#' me <- "720575941633499884"
#' my_syn <- syn %>%
#'   filter(pre_root_id == me | post_root_id == me) %>%
#'   collect()
#' }
banc_synapses_enriched <- function(version = c("v2", "v3"),
                                   overwrite = FALSE) {
  version <- match.arg(version)
  if (!requireNamespace("arrow", quietly = TRUE)) {
    stop("Package 'arrow' is required to read the enriched synapse parquet. ",
         "Install with: install.packages('arrow')")
  }
  banc_source_announce("banc_synapses_enriched", "gcs", alt = NA)
  rel <- sprintf("banc_888/banc_888_synapses_%s_enriched.parquet", version)
  path <- banc_gcs_compiled_path(rel, overwrite = overwrite)
  arrow::open_dataset(path, format = "parquet")
}
