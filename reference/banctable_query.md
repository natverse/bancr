# Read and write to the seatable for draft BANC annotations

These functions use the logic and wrap some code from the `flytable_.*`
functions in the `fafbseg` R package. `banctable_set_token` will obtain
and store a permanent seatable user-level API token. `banctable_query`
performs a SQL query against a banctable database. You can omit the
`base` argument unless you have tables of the same name in different
bases. `banctable_base` returns a `base` object (equivalent to a mysql
database) which allows you to access one or more tables, logging in to
the service if necessary. The returned base object give you full access
to the Python
[`Base`](https://seatable.github.io/seatable-scripts/python/base/) API
allowing a range of row/column manipulations. `banctable_update_rows`
updates existing rows in a table, returning TRUE on success.
`banctable_append_rows` appends new rows to a table. When
`bigdata=TRUE`, rows are added directly to the big data backend using
the `/add-archived-rows/` endpoint. `banctable_move_to_bigdata` moves
rows between normal backend and big data backend. When `invert=FALSE`
(archive), it moves all rows from a specified view to big data storage.
When `invert=TRUE` (unarchive), it moves specific rows by row_id from
big data storage back to normal backend. Note: The big data backend must
be enabled in your base for these functions to work.

`franken_meta()` returns the BANC project's reformulated views of each
external connectome (FAFB-FlyWire, MANC, Hemibrain and maleCNS),
re-keyed into BANC's annotation scheme (the same `flow` / `super_class`
/ `cell_class` / `cell_sub_class` / `cell_type` / `hemilineage` /
`region` / `nerve` / `neuromere` / function / body_part / neurochemistry
vocabularies
[`banc_meta()`](https://natverse.github.io/bancr/reference/banc_meta.md)
uses). Each row can be compared directly against the corresponding BANC
neuron; source-specific identifiers and labels are retained alongside
the BANC-shaped columns.

## Usage

``` r
banctable_query(
  sql = "SELECT * FROM banc_meta",
  limit = 200000L,
  base = NULL,
  python = FALSE,
  convert = TRUE,
  ac = NULL,
  token_name = "BANCTABLE_TOKEN",
  workspace_id = "57832",
  retries = 3,
  table.max = 10000L
)

banctable_set_token(
  user,
  pwd,
  url = "https://cloud.seatable.io/",
  token_name = "BANCTABLE_TOKEN"
)

banctable_login(
  url = "https://cloud.seatable.io/",
  token_name = "BANCTABLE_TOKEN"
)

banctable_update_rows(
  df,
  table,
  base = NULL,
  append_allowed = FALSE,
  chunksize = 1000L,
  workspace_id = "57832",
  token_name = "BANCTABLE_TOKEN",
  ...
)

banctable_move_to_bigdata(
  table = "banc_meta",
  base = "banc_meta",
  url = "https://cloud.seatable.io/",
  workspace_id = "57832",
  token_name = "BANCTABLE_TOKEN",
  view_name = "archive",
  view_id = NULL,
  where = NULL,
  invert = FALSE,
  row_ids = NULL
)

franken_meta(
  tables = c("fafb", "manc"),
  source = c("gcs", "seatable", "legacy"),
  overwrite = FALSE,
  sql = NULL,
  base = "cns_meta",
  ...
)

banctable_append_rows(
  df,
  table,
  bigdata = FALSE,
  base = NULL,
  chunksize = 1000L,
  workspace_id = "57832",
  token_name = "BANCTABLE_TOKEN",
  ...
)
```

## Arguments

- sql:

  Optional. If supplied, bypasses the table-union logic and passes the
  SQL verbatim to `banctable_query()`. Mainly used to query a SeaTable
  table directly, e.g.
  `franken_meta(sql = "SELECT * FROM franken_meta")`.

- limit:

  An optional limit, which only applies if you do not specify a limit
  directly in the `sql` query. By default seatable limits SQL queries to
  100 rows. We increase the limit to 100000 rows by default.

- base:

  SeaTable base name (only used when `source` is `"seatable"` or
  `"legacy"`). Defaults to `"cns_meta"`.

- python:

  Logical. Whether to return a Python pandas DataFrame. The default of
  FALSE returns an R data.frame

- convert:

  Expert use only: Whether or not to allow the Python seatable module to
  process raw output from the database. This is is principally for
  debugging purposes. NB this imposes a requirement of seatable_api
  \>=2.4.0.

- ac:

  A seatable connection object as returned by `banctable_login`.

- token_name:

  The name of the token in your .Renviron file, should be
  `BANCTABLE_TOKEN`.

- workspace_id:

  A numeric id specifying the workspace. Advanced use only

- retries:

  if a request to the seatable API fails, the number of times to re-try
  with a 0.1 second pause.

- table.max:

  the maximum number of rows to read from the seatable at one time,
  which is capped at 10000L by seatable.

- user, pwd:

  banctable user and password used by `banctable_set_token` to obtain a
  token

- url:

  Optional URL to the server

- df:

  A data.frame containing the data to upload including an `_id` column
  that can identify each row in the remote table.

- table:

  Character vector specifying a table foe which you want a `base`
  object.

- append_allowed:

  Logical. Whether rows without row identifiers can be appended.

- chunksize:

  To split large requests into smaller ones with max this many rows.

- ...:

  Passed to `banctable_query()` when reading from SeaTable.

- view_name:

  Character, the name of the view containing rows to archive (required
  for archive operation). Mutually exclusive with view_id.

- view_id:

  Character, the ID of the view containing rows to archive (alternative
  to view_name). Mutually exclusive with view_name.

- where:

  DEPRECATED. The API no longer supports WHERE clauses. Use view_name or
  view_id instead.

- invert:

  Logical. If `FALSE` (default), archives rows from normal backend to
  big data backend (requires view_name or view_id). If `TRUE`,
  unarchives rows from big data backend back to normal backend (requires
  row_ids).

- row_ids:

  Character vector of seatable row IDs. Required for unarchive operation
  (when invert=TRUE). These are the specific rows to move from big data
  backend back to normal backend. Use the table_id (not table_name) for
  unarchive operations.

- tables:

  Character vector of source tables to read and append. Any combination
  of `"fafb"`, `"manc"`, `"hemibrain"`, `"malecns"`. Defaults to
  `c("fafb", "manc")` — the FAFB+MANC union, the closest equivalent to
  the historical single `franken_meta` table.

- source:

  `"gcs"` (default, public feathers), `"seatable"` (BANC production team
  only) or `"legacy"` (deprecated single SeaTable).

- overwrite:

  Logical. If `TRUE` and `source = "gcs"`, re-download the cached
  feathers even if they already exist.

- bigdata:

  Logical. If `TRUE`, new rows are added directly to the big data
  backend using the `/add-archived-rows/` API endpoint. If `FALSE`
  (default), rows are added to the normal backend. Note: The big data
  backend must be enabled in your base for this to work.

## Value

a `data.frame` of results. There should be 0 rows if no rows matched
query.

A data frame with one row per neuron across the chosen source tables.
When more than one source table is read, a unified `neuron_id` column is
added: each row carries the ID from its originating table's per-source
ID column (`fafb_id` / `fafb_783_id`, `manc_id` / `manc_121_id`,
`hemibrain_id` / `hemibrain_121_id`, `malecns_id` / `malecns_09_id`),
coalesced into the single `neuron_id`. The original per-source ID
columns are preserved.

## Details

Two sources of these tables are supported. The default `"gcs"` reads
per-dataset feathers from the public bucket at
`gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/<slug>/<slug>_meta.feather`
(slugs `fafb_783`, `manc_121`, `hemibrain_121`, `malecns_09`). No
authentication is required and the feathers are cached locally under
`tools::R_user_dir("bancr", "cache")`. This is the recommended path for
almost all users.

The `"seatable"` source is restricted to the BANC production team and
reads the in-progress per-source SeaTable tables (`fafb`, `manc`,
`hemibrain`, `malecns`) in the `cns_meta` base via `banctable_query()`.
It requires a valid `BANCTABLE_TOKEN`. The `"legacy"` source reads the
single, deprecated `franken_meta` SeaTable as a backup; it is no longer
the source of truth post-2026-05-15.

When multiple `tables` are requested,
[`dplyr::bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html)
takes the column-union; FAFB\_*, MANC\_*, hemibrain-specific and
malecns-specific columns survive only on the rows that come from the
table that owns them.

## See also

[`flytable_query`](https://rdrr.io/pkg/fafbseg/man/flytable-queries.html)

## Examples

``` r
if (FALSE) { # \dontrun{
# Do this once
banctable_set_token(user="MY_EMAIL_FOR_SEATABLE.com",
                    pwd="MY_SEATABLE_PASSWORD",
                    url="https://cloud.seatable.io/")

# Query a table:
banc.meta <- banctable_query()

# Archive rows to big data backend (requires a view):
banctable_move_to_bigdata(
  table = "banc_meta",
  base = "banc_meta",
  view_name = "optic_region_view"
)

# Alternative: use view_id instead of view_name:
banctable_move_to_bigdata(
  table = "banc_meta",
  view_id = "0000"
)

# Unarchive specific rows from big data backend:
banctable_move_to_bigdata(
  table = "banc_meta",
  invert = TRUE,
  row_ids = c("FoDxhChYQSycLm88JZ11RA", "AnotherRowId123")
)

# Append rows directly to big data backend:
new_data <- data.frame(
  root_id = c("720575940626768442", "720575940636821616"),
  cell_type = c("DNa02", "DNa02")
)
banctable_append_rows(
  df = new_data,
  table = "banc_meta",
  base = "banc_meta",
  bigdata = TRUE
)
} # }
if (FALSE) { # \dontrun{
# Default: FAFB + MANC union read from the public GCS feathers.
fk <- franken_meta()

# Only the FAFB rows
fafb <- franken_meta(tables = "fafb")

# All four source tables, column-unioned
all <- franken_meta(tables = c("fafb", "manc", "hemibrain", "malecns"))

# Force a fresh download of the cached feathers
fk_fresh <- franken_meta(overwrite = TRUE)

# BANC production team: pull the in-progress SeaTable instead.
fk_st <- franken_meta(source = "seatable")

# Legacy single-table SeaTable read (deprecated; still available)
legacy <- franken_meta(source = "legacy")
} # }
```
