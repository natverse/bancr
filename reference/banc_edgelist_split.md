# Compartment-resolved BANC edgelist

Reads the compiled compartment-to-compartment edgelist (axon / dendrite
/ primary_dendrite / primary_neurite / soma / unknown) for BANC v888
from the public GCS bucket. Sibling of
[`banc_edgelist()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md)
but with `pre_label` / `post_label` columns and optional pre/post
neurotransmitter prediction.

## Usage

``` r
banc_edgelist_split(version = c("v2", "v3", "legacy"), overwrite = FALSE)
```

## Arguments

- version:

  `"v2"` (default), `"v3"`, or `"legacy"` (the unversioned
  `banc_888_edgelist_split.feather`).

- overwrite:

  Logical. If `TRUE`, re-download the cached feather even if it already
  exists.

## Value

A data frame of compartment-pair connections, columns:
`pre, post, pre_label, post_label, count, norm, post_count, pre_count, connection, pre_conf_nt, pre_conf_nt_p, post_conf_nt, post_conf_nt_p`.

## Details

Source:
`gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_edgelist_split_<version>.feather`.
`version = "v2"` and `version = "v3"` track the synapse-table
generations (see
[`banc_all_synapses()`](https://natverse.github.io/bancr/reference/banc_all_synapses.md)).
The legacy unversioned `banc_888_edgelist_split.feather` is also
available via `version = "legacy"`.

Files are ~321-907 MB (v3 is the largest); the first call caches the
feather under `tools::R_user_dir("bancr", "cache")`. There is no CAVE
equivalent of this compartment-split edgelist (CAVE only exposes
per-neuron pre/post root pairs), so there's no `source` / `fallback`
argument.

## Examples

``` r
if (FALSE) { # \dontrun{
# Compartment edgelist for the paper synapses (v2)
eds <- banc_edgelist_split()

# Axon -> dendrite connections only
library(dplyr)
a2d <- eds %>% filter(pre_label == "axon", post_label == "dendrite")
} # }
```
