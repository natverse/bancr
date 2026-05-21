# bancr 0.3.2 (development)

* `banc_edgelist()` now defaults to `source = "gcs"`, reading the
  pre-computed
  `compiled_data/banc_888/banc_888_edgelist_simple_<version>.feather`
  from the public bucket (no auth needed; ~285 MB for v2, ~336 MB for
  v3, cached locally). New `version = c("v2", "v3")` argument selects
  paper-version synapses (`v2`, default) vs the updated `synapses_v3`
  edgelist. `source = "cave"` preserves the previous CAVE materialised
  view query for callers who need live data; the auto-derived view
  name is `synapses_<version>_backbone_proofread_and_peripheral_nerves_counts`,
  overridable via `edgelist_view`.
  Returned schema follows the source: `pre, post, count, norm,
  post_count, pre_count` from GCS; `pre_pt_root_id, post_pt_root_id, n`
  from CAVE.
* `banc_meta_create_cache()` now defaults to `source = "gcs"`,
  reading the public compiled meta feather at
  `gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_meta.feather`.
  This needs no BANC authentication and avoids the slow CAVE union of
  `banc_cell_info()` + `banc_codex_annotations()`.
  - `source = "cave"` keeps the previous CAVE-derived behaviour for
    callers who need labels fresher than the GCS snapshot.
  - `source = "seatable"` reads the draft `banc_meta` SeaTable and is
    restricted to the BANC production team. The dead SQL bug in this
    branch (renaming `super_class` despite never selecting it) is
    fixed.
  - The `use_seatable` argument is kept as a deprecated alias.
* `franken_meta()` likewise defaults to `source = "gcs"`, reading
  per-dataset compiled feathers from
  `compiled_data/<slug>/<slug>_meta.feather`
  (`fafb_783`, `manc_121`, `hemibrain_121`, `malecns_09`).
  `source = "seatable"` (formerly the `"split"` default) and
  `source = "legacy"` remain for production-team callers.
* New internal helper `banc_gcs_meta_feather()` (downloads + caches a
  compiled meta feather under `tools::R_user_dir("bancr", "cache")`).
  Adds a soft dependency on the `arrow` package, already in `Suggests`.
* README: new "Getting BANC meta data" section advertising the GCS
  feather as the main route for almost all users, and clarifying that
  the `banctable_*` family is for the BANC production team only.

# bancr 0.3.1

* Repository moved from `flyconnectome/bancr` to `natverse/bancr`. The
  old URL continues to redirect, but please update local clones with
  `git remote set-url origin git@github.com:natverse/bancr.git` and any
  `Remotes:` lines in downstream packages.
* `banc_all_synapses()` retargeted to
  `gs://lee-lab_brain-and-nerve-cord-fly-connectome/neuron_connectivity/v888/`
  with a new `version` argument (defaults to `"v2"`; `"v1"` is deprecated,
  `"v3"` is in testing). The dead `rawcoords` and `min_size` arguments
  have been dropped and the help page now documents each version's CAVE
  coordinate space.
* New `inst/CITATION` with the BANC paper
  (Bates et al. 2025, bioRxiv 2025.07.31.667571) and the natverse paper.
* `License` field updated to `GPL (>= 3)` via
  `usethis::use_gpl3_license()`.

# bancr 0.3.0

* new `banc_lm_scene()` for overlaying precomputed light-microscopy image
  layers on top of a public BANC Neuroglancer scene, with optional
  shortened-URL POST to `nglstate/api/v1/post`.
* new `banc_influence()` family (`banc_influence_arrow`,
  `banc_influence_duckdb`, `banc_influence_path`) for connectome influence
  scoring against parquet snapshots in GCS.
* read from BANC `synapses_v3`; with `details = TRUE`, `banc_synapses()` now
  returns neurotransmitter prediction scores.
* `bancsee()` gains a `clean_segments` option and surfaces NBLAST scores
  alongside synapse data; assorted scene-building fixes.
* read NBLAST match CAVE tables via `banc_nblast_matches()`.
* fix a Linux PATH_MAX crash in the Neuroglancer URL encoder when the
  scene JSON is long.
* internal: rework CI to use system Python via `actions/setup-python` (the
  reticulate miniconda env no longer ships pip), and clean up
  `R CMD check` Rd cross-reference / `\usage` warnings.

**Full Changelog**: https://github.com/flyconnectome/bancr/compare/v0.2.1...v0.3.0

# bancr 0.2.1

* fixes for `bancr::register_banc_coconat()` so that coconatfly can use new 
  banc dataset.

**Full Changelog**: https://github.com/flyconnectome/bancr/compare/v0.2.0...v0.2.1

# bancr 0.2.0

* first tagged release after BANC preprint

**Full Changelog**: https://github.com/flyconnectome/bancr/commits/v0.2.0
