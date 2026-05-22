# Read BANC CAVE-tables, good sources of metadata

CAVE tables query functions that track neurons across segmentation
changes so that annotations and neuron entities can be stably tracked
together. The Brain And Nerve Cord (BANC) dataset represents the first
complete connectome including both brain and ventral nerve cord of a
limbed animal, comprising approximately 160,000 neurons across the
entire central nervous system.

## Usage

``` r
banc_cave_tables(datastack_name = NULL, select = NULL)

banc_cave_views(datastack_name = NULL, select = NULL)

banc_edgelist(
  version = c("v2", "v3"),
  source = c("gcs", "cave"),
  overwrite = FALSE,
  edgelist_view = NULL,
  ...
)

banc_mitochondria(
  rootids = NULL,
  table = "mitochondria_v1",
  rawcoords = FALSE,
  chunk_size = 200000L,
  ...
)

banc_nuclei(
  rootids = NULL,
  nucleus_ids = NULL,
  table = c("both", "somas_v1a", "somas_v1b"),
  rawcoords = FALSE,
  source = c("gcs", "cave"),
  fallback = TRUE,
  ...
)

banc_cell_info(
  rootids = NULL,
  rawcoords = FALSE,
  source = c("gcs", "cave"),
  fallback = TRUE,
  ...
)

banc_proofreading_notes(
  rootids = NULL,
  rawcoords = FALSE,
  source = c("gcs", "cave"),
  fallback = TRUE,
  ...
)

banc_cell_ids(rootids = NULL, ...)

banc_neck_connective_neurons(
  rootids = NULL,
  table = c("neck_connective_y92500", "neck_connective_y121000"),
  source = c("gcs", "cave"),
  fallback = TRUE,
  ...
)

banc_peripheral_nerves(
  rootids = NULL,
  source = c("gcs", "cave"),
  fallback = TRUE,
  ...
)

banc_backbone_proofread(
  rootids = NULL,
  source = c("gcs", "cave"),
  fallback = TRUE,
  ...
)

banc_nt_prediction(
  rootids = NULL,
  table = "synapses_250226_nt_prediction_5",
  simplify = TRUE,
  rawcoords = TRUE,
  ...
)

banc_version()
```

## Arguments

- datastack_name:

  Defaults to "brain_and_nerve_cord". See
  https://global.daf-apis.com/info/ for other options.

- select:

  A regex term for the name of the table you want

- version:

  Character, `"v2"` (default, paper synapses) or `"v3"` (updated
  synapses, still in testing).

- source:

  `"gcs"` (default; reads the public compiled feather) or `"cave"` (live
  materialised view query).

- overwrite:

  Logical. If `TRUE` and `source = "gcs"`, re-download the cached
  feather.

- edgelist_view:

  Optional CAVE view name override (only honoured when
  `source = "cave"`). Defaults are derived from `version`:
  `synapses_v<version>_backbone_proofread_and_peripheral_nerves_counts`.

- ...:

  Additional arguments passed to
  [`flywire_cave_query`](https://rdrr.io/pkg/fafbseg/man/flywire_cave_query.html)
  or `bancr:::get_cave_table_data`.

- rootids:

  Character vector specifying one or more BANC rootids. As a convenience
  this argument is passed to
  [`banc_ids`](https://natverse.github.io/bancr/reference/banc_ids.md)
  allowing you to pass in data.frames, BANC URLs or simple ids.

- table:

  Character, possible alternative tables for the sort of data frame the
  function returns. One must be chosen.

- rawcoords:

  Logical, whether or not to convert from raw coordinates into
  nanometers. Default is `FALSE`.

- chunk_size:

  Integer page size for full-table pulls (used only when
  `rootids = NULL`). The mitochondria_v1 table has millions of rows and
  a single materialised response trips reticulate's string parser
  (`Error: basic_string`); paginating by `limit`/`offset` keeps each
  response small enough to cross the R/Python boundary. Default 200000.

- nucleus_ids:

  Character vector specifying one or more BANC nucleus ids. The nucleus
  (<https://en.wikipedia.org/wiki/Cell_nucleus>) contains the cell body
  and provides a stable reference point for neuron identification.

- simplify:

  logical, if `TRUE` then the proportion of presynaptic connections for
  each transmitter type is returned, for each query neuron.

## Value

A `data.frame` describing a CAVE-table related to the BANC project. In
the case of `banc_cave_tables`, a vector is returned containing the
names of all query-able cave tables.

## Details

CAVE tables store rich metadata supporting analysis of distributed
neural control across the entire central nervous system. For more
information about CAVE infrastructure, see
<https://www.caveconnecto.me/CAVEclient/>.

`banc_edgelist` returns a data frame of neuron-neuron connections where
the pre (presynaptic) neuron is upstream of the post (postsynaptic)
neuron. This edgelist contains synaptic connectivity data crucial for
understanding distributed neural control and behaviour-centric neural
modules across the brain-VNC boundary.

Two synapse-table versions are exposed via the `version` argument:
`"v2"` (default) is the paper-version edgelist built from CAVE
`synapses_v2`; `"v3"` is the updated/refined synapse table (CAVE
`synapses_v3`, still in testing — see
[`banc_all_synapses()`](https://natverse.github.io/bancr/reference/banc_all_synapses.md)).
The two sources differ slightly in coverage; for most analyses `"v3"` is
the closer-to-current snapshot and `"v2"` matches the published numbers.

Two backing stores are supported via the `source` argument: `"gcs"`
(default) reads the pre-computed compiled feather at
`gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_edgelist_simple_<version>.feather`
from the public bucket — no BANC authentication needed, ~285 MB download
for `v2` / ~336 MB for `v3`, cached locally under
`tools::R_user_dir("bancr", "cache")`. The returned schema is
`pre, post, count, norm, post_count, pre_count`.

`source = "cave"` runs a live materialised CAVE view query (the previous
default). Requires authenticated CAVE access; the returned schema
includes `pre_pt_root_id`, `post_pt_root_id` and `n`. Use this when you
need labels fresher than the latest GCS snapshot or want to override the
materialisation timestamp via `...`.

`banc_cell_info` accesses the cell_info CAVE table containing
non-centralised annotations from the research community for connectome
neurones. These annotations represent diverse contributions from
researchers studying specific neural circuits and cell types in the BANC
dataset.

## See also

[`flywire_cave_query`](https://rdrr.io/pkg/fafbseg/man/flywire_cave_query.html)

## Examples

``` r
if (FALSE) { # \dontrun{
all_banc_soma_positions <- banc_nuclei()
points3d(nat::xyzmatrix(all_banc_soma_positions$pt_position))
} # }
```
