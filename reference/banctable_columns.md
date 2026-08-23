# Read and write columns of a BANC SeaTable table

`banctable_columns()` lists a table's columns, their SeaTable types and
the R types they map to. `banctable_add_column()` and
`banctable_add_columns()` extend a table's schema;
`banctable_delete_column()` removes a column and everything in it.

## Usage

``` r
banctable_columns(
  table,
  base = NULL,
  workspace_id = "57832",
  token_name = "BANCTABLE_TOKEN",
  include_key = TRUE
)

banctable_add_column(
  table,
  column_name,
  column_type = "text",
  base = NULL,
  column_data = NULL,
  column_key = NULL,
  workspace_id = "57832",
  token_name = "BANCTABLE_TOKEN"
)

banctable_add_columns(
  table,
  columns,
  base = NULL,
  workspace_id = "57832",
  token_name = "BANCTABLE_TOKEN",
  progress = TRUE
)

banctable_delete_column(
  table,
  column_key,
  base = NULL,
  workspace_id = "57832",
  token_name = "BANCTABLE_TOKEN"
)
```

## Arguments

- table:

  Name of the table.

- base:

  Base name or `Base` object; discovered from `table` when `NULL`.

- workspace_id, token_name:

  SeaTable connection arguments; see
  [`banc_seatable_connection()`](https://natverse.github.io/bancr/reference/banc_seatable_connection.md).

- include_key:

  Whether to include the internal SeaTable column key.

- column_name:

  Name of the new column.

- column_type:

  SeaTable column type, e.g. `"text"`, `"number"`, `"date"`,
  `"checkbox"`, `"single-select"`, `"multiple-select"`.

- column_data:

  Optional list of type-specific settings, e.g. the options of a select
  column.

- column_key:

  For `banctable_add_column()`, the key of an existing column to insert
  after. For `banctable_delete_column()`, the key of the column to
  delete, from `banctable_columns(include_key = TRUE)`.

- columns:

  A data frame with `name` and `type` columns. Columns that already
  exist are skipped.

- progress:

  Whether to report each column as it is added.

## Value

For `banctable_columns()`, a data frame with `name`, `type`, `rtype` and
optionally `key`.

## Details

These wrap the generic equivalents in seatabler, supplying the BANC
connection. `include_key = TRUE` returns SeaTable's internal column key,
which `banctable_delete_column()` needs and which is what SeaTable's
error messages refer to when they name a column like `"8blF"`.

## Examples

``` r
if (FALSE) { # \dontrun{
banctable_columns("banc_meta")
} # }
```
