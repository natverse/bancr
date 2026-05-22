# Read BANC-FlyWireCodex annotation table

Provides access to centralised cell type annotations from the BANC core
team, which are the official annotations available on FlyWireCodex.
These standardised annotations ensure consistency across the dataset and
serve as the authoritative cell type classifications for the BANC
connectome.

## Usage

``` r
banc_codex_annotations(
  rootids = NULL,
  live = TRUE,
  source = c("gcs", "cave"),
  fallback = TRUE,
  ...
)
```

## Arguments

- rootids:

  Character vector specifying one or more BANC rootids. As a convenience
  this argument is passed to
  [`banc_ids`](https://natverse.github.io/bancr/reference/banc_ids.md)
  allowing you to pass in data.frames, BANC URLs or simple ids.

- live:

  logical, get the most recent data or pull from the latest
  materialisation

- source:

  `"gcs"` (default; reads the public
  `neuron_annotations/v888/codex_annotations.parquet` snapshot, no
  authentication required) or `"cave"` (live CAVE materialised query).

- fallback:

  Logical, default `TRUE`. On primary-source failure, retry the
  alternative source and emit a warning. Set `FALSE` to surface the
  original error.

- ...:

  method passed to
  [`banc_cave_query`](https://natverse.github.io/bancr/reference/banc_cave_query.md).

## Value

A `data.frame` describing that should be similar to what you find for
BANC in FlyWireCodex.

## Details

This function accesses centralised cell type annotations curated by the
BANC core team, in contrast to
[`banc_cell_info`](https://natverse.github.io/bancr/reference/banc_cave_tables.md)
which contains non-centralised annotations from the broader research
community. The centralised annotations provide standardised cell type
classifications that are displayed on FlyWireCodex and serve as the
official reference for BANC cell types.

## See also

[`banc_cave_tables`](https://natverse.github.io/bancr/reference/banc_cave_tables.md),
[`banc_cell_info`](https://natverse.github.io/bancr/reference/banc_cave_tables.md)

## Examples

``` r
if (FALSE) { # \dontrun{
banc.meta <- banc_codex_annotations()
} # }
```
