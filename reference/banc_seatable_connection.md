# The BANC SeaTable connection

Builds the
[seatabler::seatable_connection](https://rdrr.io/pkg/seatabler/man/seatable_connection.html)
pointing at the BANC annotation tables, which every `banctable_*`
function uses. You rarely need this directly; it is exported so you can
pass it to a generic `seatabler::seatable_*` function that bancr does
not wrap.

## Usage

``` r
banc_seatable_connection(
  token_name = "BANCTABLE_TOKEN",
  url = "https://cloud.seatable.io/",
  workspace_id = "57832"
)
```

## Arguments

- token_name:

  Name of the environment variable holding your SeaTable API token. Set
  it with
  [`banctable_set_token()`](https://natverse.github.io/bancr/reference/banctable_query.md).

- url:

  The SeaTable server hosting the BANC tables.

- workspace_id:

  The workspace holding the BANC bases.

## Value

A `seatable_connection`.

## Examples

``` r
if (FALSE) { # \dontrun{
con <- banc_seatable_connection()
seatabler::seatable_alltables(con = con)
} # }
```
