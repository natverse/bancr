# Changelog

## bancr 0.3.2

- CAVE-table accessors now default to a public GCS snapshot
  (`neuron_annotations/v888/*.parquet`). Each of
  [`banc_cell_info()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md),
  [`banc_codex_annotations()`](https://natverse.github.io/bancr/reference/banc_codex_annotations.md),
  [`banc_nuclei()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md),
  [`banc_backbone_proofread()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md),
  [`banc_proofreading_notes()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md),
  [`banc_neck_connective_neurons()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md)
  and
  [`banc_peripheral_nerves()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md)
  gains:

  - `source = c("gcs", "cave")` — default `"gcs"`. Reads the v888
    parquet snapshot under
    `gs://lee-lab_brain-and-nerve-cord-fly-connectome/neuron_annotations/v888/`
    (cached locally; no BANC authentication required).
  - `fallback = TRUE` — on primary-source failure, automatically retry
    against the other source with a warning. Pass `fallback = FALSE` to
    surface the original error instead.
  - [`banc_cell_info()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md)
    and
    [`banc_proofreading_notes()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md)
    now actually honour the `rootids` argument (previously declared but
    unused); filter applies in both GCS and CAVE branches.

- On first call with a given source, the function emits a one-shot
  message describing where data is coming from and how to switch.
  Subsequent calls in the same session are silent (rlang’s
  `.frequency = "once"` mechanism).

- Three new GCS-only accessors:

  - [`banc_metrics()`](https://natverse.github.io/bancr/reference/banc_metrics.md)
    — per-neuron cable / volume / synapse-count metrics from
    `compiled_data/banc_888/banc_888_metrics.feather` (~7.5 MB).
  - `banc_edgelist_split(version = c("v2", "v3", "legacy"))` —
    compartment-resolved edgelist (axon / dendrite / etc.) from
    `compiled_data/banc_888/banc_888_edgelist_split_<version>.feather`.
  - `banc_synapses_enriched(version = c("v2", "v3"))` — lazy
    [`arrow::open_dataset()`](https://arrow.apache.org/docs/r/reference/open_dataset.html)
    handle over the per-synapse enriched parquet (~9.6 GB v2 / ~15 GB
    v3). Apply
    [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
    and
    [`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
    to get a data frame.

- `safe_raw2nm_position()` now accepts either the character form
  returned by CAVE or the arrow `list<integer>` form returned by
  [`arrow::read_parquet()`](https://arrow.apache.org/docs/r/reference/read_parquet.html)
  on the GCS snapshots, so the GCS and CAVE branches share the same
  post-processing path.

- New internal helpers in `R/gcs_sources.R` (`banc_source_announce()`,
  `banc_with_fallback()`, `banc_gcs_annotation_parquet()`) and a
  `banc_gcs_compiled_path()` factored out from
  `banc_gcs_compiled_feather()` so lazy parquet consumers (like
  [`banc_synapses_enriched()`](https://natverse.github.io/bancr/reference/banc_synapses_enriched.md))
  can share the cached download path.

- [`banc_edgelist()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md)
  now defaults to `source = "gcs"`, reading the pre-computed
  `compiled_data/banc_888/banc_888_edgelist_simple_<version>.feather`
  from the public bucket (no auth needed; ~285 MB for v2, ~336 MB for
  v3, cached locally). New `version = c("v2", "v3")` argument selects
  paper-version synapses (`v2`, default) vs the updated `synapses_v3`
  edgelist. `source = "cave"` preserves the previous CAVE materialised
  view query for callers who need live data; the auto-derived view name
  is
  `synapses_<version>_backbone_proofread_and_peripheral_nerves_counts`,
  overridable via `edgelist_view`. Returned schema follows the source:
  `pre, post, count, norm, post_count, pre_count` from GCS;
  `pre_pt_root_id, post_pt_root_id, n` from CAVE.

- [`banc_meta_create_cache()`](https://natverse.github.io/bancr/reference/banc_meta_create_cache.md)
  now defaults to `source = "gcs"`, reading the public compiled meta
  feather at
  `gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_meta.feather`.
  This needs no BANC authentication and avoids the slow CAVE union of
  [`banc_cell_info()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md) +
  [`banc_codex_annotations()`](https://natverse.github.io/bancr/reference/banc_codex_annotations.md).

  - `source = "cave"` keeps the previous CAVE-derived behaviour for
    callers who need labels fresher than the GCS snapshot.
  - `source = "seatable"` reads the draft `banc_meta` SeaTable and is
    restricted to the BANC production team. The dead SQL bug in this
    branch (renaming `super_class` despite never selecting it) is fixed.
  - The `use_seatable` argument is kept as a deprecated alias.

- [`franken_meta()`](https://natverse.github.io/bancr/reference/banctable_query.md)
  likewise defaults to `source = "gcs"`, reading per-dataset compiled
  feathers from `compiled_data/<slug>/<slug>_meta.feather` (`fafb_783`,
  `manc_121`, `hemibrain_121`, `malecns_09`). `source = "seatable"`
  (formerly the `"split"` default) and `source = "legacy"` remain for
  production-team callers.

- New internal helper `banc_gcs_meta_feather()` (downloads + caches a
  compiled meta feather under `tools::R_user_dir("bancr", "cache")`).
  Adds a soft dependency on the `arrow` package, already in `Suggests`.

- README: new “Getting BANC meta data” section advertising the GCS
  feather as the main route for almost all users, and clarifying that
  the `banctable_*` family is for the BANC production team only.

## bancr 0.3.1

- Repository moved from `flyconnectome/bancr` to `natverse/bancr`. The
  old URL continues to redirect, but please update local clones with
  `git remote set-url origin git@github.com:natverse/bancr.git` and any
  `Remotes:` lines in downstream packages.
- [`banc_all_synapses()`](https://natverse.github.io/bancr/reference/banc_all_synapses.md)
  retargeted to
  `gs://lee-lab_brain-and-nerve-cord-fly-connectome/neuron_connectivity/v888/`
  with a new `version` argument (defaults to `"v2"`; `"v1"` is
  deprecated, `"v3"` is in testing). The dead `rawcoords` and `min_size`
  arguments have been dropped and the help page now documents each
  version’s CAVE coordinate space.
- New `inst/CITATION` with the BANC paper (Bates et al. 2025, bioRxiv
  2025.07.31.667571) and the natverse paper.
- `License` field updated to `GPL (>= 3)` via
  [`usethis::use_gpl3_license()`](https://usethis.r-lib.org/reference/licenses.html).

## bancr 0.3.0

- new
  [`banc_lm_scene()`](https://natverse.github.io/bancr/reference/banc_lm_scene.md)
  for overlaying precomputed light-microscopy image layers on top of a
  public BANC Neuroglancer scene, with optional shortened-URL POST to
  `nglstate/api/v1/post`.
- new
  [`banc_influence()`](https://natverse.github.io/bancr/reference/banc_influence.md)
  family (`banc_influence_arrow`, `banc_influence_duckdb`,
  `banc_influence_path`) for connectome influence scoring against
  parquet snapshots in GCS.
- read from BANC `synapses_v3`; with `details = TRUE`, `banc_synapses()`
  now returns neurotransmitter prediction scores.
- [`bancsee()`](https://natverse.github.io/bancr/reference/bancsee.md)
  gains a `clean_segments` option and surfaces NBLAST scores alongside
  synapse data; assorted scene-building fixes.
- read NBLAST match CAVE tables via
  [`banc_nblast_matches()`](https://natverse.github.io/bancr/reference/banc_nblast_matches.md).
- fix a Linux PATH_MAX crash in the Neuroglancer URL encoder when the
  scene JSON is long.
- internal: rework CI to use system Python via `actions/setup-python`
  (the reticulate miniconda env no longer ships pip), and clean up
  `R CMD check` Rd cross-reference / `\usage` warnings.

**Full Changelog**:
<https://github.com/flyconnectome/bancr/compare/v0.2.1>…v0.3.0

## bancr 0.2.1

- fixes for
  [`bancr::register_banc_coconat()`](https://natverse.github.io/bancr/reference/register_banc_coconat.md)
  so that coconatfly can use new banc dataset.

**Full Changelog**:
<https://github.com/flyconnectome/bancr/compare/v0.2.0>…v0.2.1

## bancr 0.2.0

- first tagged release after BANC preprint

**Full Changelog**:
<https://github.com/flyconnectome/bancr/commits/v0.2.0>
