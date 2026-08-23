# List snapshots of a BANC SeaTable base

SeaTable snapshots the BANC bases periodically. A snapshot is the only
way back from a bad bulk write to `banc_meta`, so it is worth knowing
how far back they go before you run one.

## Usage

``` r
banctable_snapshots(
  base_name = "banc_meta",
  workspace_id = "57832",
  token_name = "BANCTABLE_TOKEN"
)
```

## Arguments

- base_name:

  Name of the base.

- workspace_id, token_name:

  SeaTable connection arguments; see
  [`banc_seatable_connection()`](https://natverse.github.io/bancr/reference/banc_seatable_connection.md).

## Value

A data frame of snapshots, one row each.

## Examples

``` r
if (FALSE) { # \dontrun{
banctable_snapshots()
} # }
```
