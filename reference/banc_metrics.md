# Per-neuron metrics for BANC v888

Reads the compiled per-neuron metrics feather from the public GCS
bucket: cable length, neuron volume, mitochondria volume, pre/post
synapse counts, segregation index and a handful of other morphology /
connectivity scalars (one row per neuron, keyed by `banc_888_id`).

## Usage

``` r
banc_metrics(rootids = NULL, overwrite = FALSE)
```

## Arguments

- rootids:

  Optional vector of root IDs to filter to. `NULL` (default) returns all
  ~188 k rows.

- overwrite:

  Logical. If `TRUE`, re-download the cached feather even if it already
  exists.

## Value

A data frame of per-neuron metrics.

## Details

Source:
`gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_metrics.feather`
(~7.5 MB; cached under `tools::R_user_dir("bancr", "cache")`). No CAVE
equivalent — this table is compiled offline from the segmentation graph
plus the synapse table. There is consequently no `source` / `fallback`
argument; the only way to refresh is to re-download with
`overwrite = TRUE`.

## Examples

``` r
if (FALSE) { # \dontrun{
m <- banc_metrics()
my_metrics <- banc_metrics(rootids = c("720575941633499884",
                                       "720575941472733451"))
} # }
```
