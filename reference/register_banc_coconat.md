# Use BANC data with coconat for connectivity similarity

Register the BANC dataset for use with
[coconatfly](https://natverse.org/coconatfly) across dataset connectome
analysis.

## Usage

``` r
register_banc_coconat(showerror = TRUE)
```

## Arguments

- showerror:

  Logical: error-out silently or not.

## Details

`register_banc_coconat()` registers `bancr`-backed functionality for use
with [coconatfly](https://natverse.org/coconatfly),
[natverse](https://natverse.org) R package providing a consistent
interface to core connectome analysis functions across datasets. This
includes within and between dataset connectivity comparisons using
cosine similarity.

## See also

Other coconatfly:
[`banc_meta_create_cache()`](https://natverse.github.io/bancr/reference/banc_meta_create_cache.md)

## Examples

``` r
if (FALSE) { # \dontrun{
library(coconatfly)
# once per session
register_banc_coconat()

# once per session or if you think there have been updates
banc_meta_create_cache()
# source = "seatable" if you are on the BANC production team and want
# the bleeding-edge draft labels (needs BANCTABLE_TOKEN)
banc_meta_create_cache(source = "seatable")

# examples of within dataset analysis
dna02meta <- cf_meta(cf_ids(banc='/DNa02'))
cf_partner_summary(dna02meta, partners = 'out', threshold = 10)
cf_ids(banc='/type:DNa.+')

# an example of across dataset cosine similarity plot
cf_cosine_plot(cf_ids('/type:LAL0(08|09|10|42)', datasets = c("banc", "hemibrain")))
} # }
```
