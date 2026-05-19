# Download BANC automatic synapse detections as a .sqlite file

Downloads a pre-baked Zetta.ai synapse table for the BANC from
`gs://lee-lab_brain-and-nerve-cord-fly-connectome/neuron_connectivity/v888/`
and caches it as a per-version `banc_data_<version>.sqlite` file. After
the one-off download subsequent calls read lazily from the cache so the
table is never fully loaded into memory.

## Usage

``` r
banc_all_synapses(
  version = c("v2", "v1", "v3"),
  overwrite = FALSE,
  n_max = 2000,
  details = FALSE,
  path = NULL
)
```

## Arguments

- version:

  Character, which synapse table to download. One of `"v2"` (default),
  `"v1"`, or `"v3"`.

- overwrite:

  Logical, whether or not to overwrite an extant
  `banc_data_<version>.sqlite` cache.

- n_max:

  Numeric, the maximum number of rows to stream lazily from the CSV when
  previewing. Set to `NULL` to trigger a full download into the SQLite
  cache.

- details:

  Logical. If `FALSE` (default) only the essential pre-side columns
  (`id`, `pre_pt_root_id`, `pre_x`, `pre_y`, `pre_z`, `size`) are read;
  if `TRUE` all 15 columns are kept.

- path:

  Optional explicit override of the HTTPS URL. Normally left `NULL` so
  the path is built from `version`.

## Value

a data.frame (or a lazy
[`dplyr::tbl`](https://dplyr.tidyverse.org/reference/tbl.html) backed by
SQLite when the full table has been cached).

## Details

Three versions are exposed, matching the BANC CAVE annotation tables of
the same name. The version-specific metadata below is taken directly
from each table's CAVE description; check
<https://banc.community/Automated-segmentation> for the column-level
documentation that ships with the source files.

- **v1** (deprecated). Source
  `gs://zetta_lee_fly_cns_001_synapse/240623_run/assignment/final_edgelist.df`,
  created 2024-07-25. Coordinates are in nanometers (CAVE
  `voxel_resolution = c(1, 1, 1)`). The CAVE table owner notice marks
  this version as deprecated in favour of v2.

- **v2** (default). Source
  `gs://zetta_lee_fly_cns_001_synapse/250226_assignment/assignment/final_edgelist.df`,
  created 2025-08-14. Coordinates are in nanometers (CAVE
  `voxel_resolution = c(1, 1, 1)`). This is the current production
  synapse table.

- **v3** (in testing). Created 2026-04-10. Coordinates are reported on
  the synapse-detection grid with CAVE
  `voxel_resolution = c(16, 16, 45)` nm/voxel - multiply by these values
  to obtain nanometers. Marked "still in testing" by the table owner.

Note that v1 and v2 coordinates are already in nanometers, which differs
from most BANC CAVE tables (those use the EM image grid of `c(4, 4, 45)`
nm/voxel).

Each version's `synapses_<version>_human_readable.csv.gz` is large (~12
GB gzipped for v2). The 15 columns are, in order: `id`, `pre_x`,
`pre_y`, `pre_z`, `post_x`, `post_y`, `post_z`, `centroid_x`,
`centroid_y`, `centroid_z`, `size`, `pre_pt_supervoxel_id`,
`pre_pt_root_id`, `post_pt_supervoxel_id`, `post_pt_root_id`.

## See also

[`banc_partner_summary`](https://flyconnectome.github.io/bancr/reference/banc_partner_summary.md),
[`banc_partners`](https://flyconnectome.github.io/bancr/reference/banc_partner_summary.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Default: v2, preview first 2000 rows lazily from the CSV
syns <- banc_all_synapses()

# Full download of v2 (~12 GB gzipped) into the per-version SQLite cache
syns_all <- banc_all_synapses(n_max = NULL)

# Switch to the deprecated v1 table or the in-testing v3 table
syns_v1 <- banc_all_synapses(version = "v1")
syns_v3 <- banc_all_synapses(version = "v3")
} # }
```
