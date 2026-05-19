# Changelog

## bancr 0.3.1 (development)

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
