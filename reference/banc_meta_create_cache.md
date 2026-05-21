# Create or refresh cache of BANC meta information

`banc_meta_create_cache()` builds or refreshes an in-memory cache of
BANC metadata for efficient repeated lookups. The default
`source = "gcs"` reads the public compiled meta feather
(`gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/banc_888/banc_888_meta.feather`)
and needs no authentication beyond network access. The main accessor
[`banc_meta()`](https://natverse.github.io/bancr/reference/banc_meta.md)
always reads from the most recently created cache.

## Usage

``` r
banc_meta_create_cache(
  source = c("gcs", "cave", "seatable"),
  overwrite = FALSE,
  use_seatable = NULL,
  return = FALSE
)
```

## Arguments

- source:

  Character. Where to read the meta from. One of `"gcs"` (default),
  `"cave"`, `"seatable"`. See **Details**.

- overwrite:

  Logical. If `TRUE` and `source = "gcs"`, re-download the feather even
  if a cached copy exists.

- use_seatable:

  Deprecated. If supplied, `TRUE` maps to `source = "seatable"` and
  `FALSE` (the old default) maps to `source = "cave"` (the previous
  default before GCS).

- return:

  Logical; if `TRUE`, return the cache tibble; otherwise invisible
  `NULL`.

## Value

Invisibly returns the cache (data.frame) if `return=TRUE`; otherwise
invisibly `NULL`.

## Details

BANC meta queries can be slow; caching avoids repeated database access.
Rerun whenever labels are updated upstream.

Three sources are supported:

- `"gcs"` (default): downloads `banc_888_meta.feather` from the public
  bucket (cached under `tools::R_user_dir("bancr", "cache")`). This is
  the recommended path for almost all users; it does not require BANC
  CAVE or SeaTable credentials.

- `"cave"`: builds the cache live from
  [`banc_cell_info()`](https://natverse.github.io/bancr/reference/banc_cave_tables.md) +
  [`banc_codex_annotations()`](https://natverse.github.io/bancr/reference/banc_codex_annotations.md).
  Requires authenticated BANC CAVE access. Use this when you need
  fresher annotations than the latest GCS snapshot.

- `"seatable"`: pulls the in-progress draft `banc_meta` SeaTable.
  **Restricted to the BANC production team** (requires a
  `BANCTABLE_TOKEN`); the rest of the `banctable_*` family is in the
  same category.

## See also

Other coconatfly:
[`register_banc_coconat()`](https://natverse.github.io/bancr/reference/register_banc_coconat.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Default: download once, cache locally, then look up
banc_meta_create_cache()
result <- banc_meta()

# Live from CAVE (needs BANC CAVE auth)
banc_meta_create_cache(source = "cave")

# SeaTable (production team only; needs BANCTABLE_TOKEN)
banc_meta_create_cache(source = "seatable")

# Use the cache to drive a coconatfly plot
library(coconatfly)
register_banc_coconat()
cf_cosine_plot(cf_ids('/type:LAL0(08|09|10|42)',
                      datasets = c("banc", "hemibrain")))
} # }
```
