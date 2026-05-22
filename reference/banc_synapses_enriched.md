# Synapse-level BANC table with neuropil / NT enrichment

Returns a lazy
[`arrow::open_dataset()`](https://arrow.apache.org/docs/r/reference/open_dataset.html)
handle pointing at the per-synapse enriched parquet for BANC v888. The
table carries ~169 M rows with neuropil membership, region, side and
full per-transmitter Eckstein et al. (2024) prediction probabilities for
each synapse. Apply further
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
calls before
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
— predicate pushdown skips parquet row groups that don't match.

## Usage

``` r
banc_synapses_enriched(version = c("v2", "v3"), overwrite = FALSE)
```

## Arguments

- version:

  `"v2"` (default; paper synapses) or `"v3"` (updated synapses, still in
  testing).

- overwrite:

  Logical. If `TRUE`, re-download the cached parquet even if it already
  exists.

## Value

An `arrow_dplyr_query` lazy handle. Chain
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
and
[`dplyr::collect()`](https://dplyr.tidyverse.org/reference/compute.html)
to materialise a data frame.

## Details

Source:
`gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_synapses_<version>_enriched.parquet`.
The file is large (~9.6 GB for v2, ~15 GB for v3); the first call
downloads it under `tools::R_user_dir("bancr", "cache")` and subsequent
calls reuse the cache. Use `overwrite = TRUE` to force a refresh.

There is no CAVE equivalent of this enriched table (CAVE exposes the raw
`synapses_v<version>` table without neuropil / region / NT enrichment),
so there is no `source` / `fallback` argument.

## Examples

``` r
if (FALSE) { # \dontrun{
library(dplyr)

# Lazy handle against the cached parquet
syn <- banc_synapses_enriched()

# Pull synapses in the right mushroom body calyx
mb_ca_r <- syn %>%
  filter(neuropil == "MB_CA_R") %>%
  collect()

# Synapses involving a specific neuron
me <- "720575941633499884"
my_syn <- syn %>%
  filter(pre_root_id == me | post_root_id == me) %>%
  collect()
} # }
```
