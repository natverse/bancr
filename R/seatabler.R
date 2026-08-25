# The BANC SeaTable connection, and the banctable_* functions that are now thin
# wrappers over the generic seatabler package.
#
# bancr grew its own SeaTable client because fafbseg's was hard-wired to the
# Cambridge server. seatabler is that client made server-agnostic, so the BANC
# server configuration collapses to a single connection object and the generic
# code lives in one place. The banctable_* names and signatures are unchanged:
# there is a lot of analysis code calling them.
#
# As of bancr 0.3.8 the whole generic surface has moved: queries, row writes,
# schema, big data and snapshots. seatabler 0.2.2 applies column types from the
# table schema, so reads match what bancr used to return.

#' The BANC SeaTable connection
#'
#' @description Builds the [seatabler::seatable_connection] pointing at the BANC
#'   annotation tables, which every `banctable_*` function uses. You rarely need
#'   this directly; it is exported so you can pass it to a generic
#'   `seatabler::seatable_*` function that bancr does not wrap.
#'
#' @param token_name Name of the environment variable holding your SeaTable API
#'   token. Set it with [banctable_set_token()].
#' @param url The SeaTable server hosting the BANC tables.
#' @param workspace_id The workspace holding the BANC bases.
#'
#' @return A `seatable_connection`.
#' @export
#' @examples
#' \dontrun{
#' con <- banc_seatable_connection()
#' seatabler::seatable_alltables(con = con)
#' }
banc_seatable_connection <- function(token_name = "BANCTABLE_TOKEN",
                                     url = "https://cloud.seatable.io/",
                                     workspace_id = "57832") {
  seatabler::seatable_connection(url = url, token_envvar = token_name,
                                 workspace_id = workspace_id, name = "banc")
}

#' Read and write columns of a BANC SeaTable table
#'
#' @description `banctable_columns()` lists a table's columns, their SeaTable
#'   types and the R types they map to. `banctable_add_column()` and
#'   `banctable_add_columns()` extend a table's schema;
#'   `banctable_delete_column()` removes a column and everything in it.
#'
#' @details These wrap the generic equivalents in seatabler, supplying the BANC
#'   connection. `include_key = TRUE` returns SeaTable's internal column key,
#'   which `banctable_delete_column()` needs and which is what SeaTable's error
#'   messages refer to when they name a column like `"8blF"`.
#'
#' @param table Name of the table.
#' @param base Base name or `Base` object; discovered from `table` when `NULL`.
#' @param include_key Whether to include the internal SeaTable column key.
#' @param workspace_id,token_name SeaTable connection arguments; see
#'   [banc_seatable_connection()].
#'
#' @return For `banctable_columns()`, a data frame with `name`, `type`, `rtype`
#'   and optionally `key`.
#' @export
#' @examples
#' \dontrun{
#' banctable_columns("banc_meta")
#' }
banctable_columns <- function(table, base = NULL, workspace_id = "57832",
                              token_name = "BANCTABLE_TOKEN",
                              include_key = TRUE) {
  con <- banc_seatable_connection(token_name = token_name,
                                  workspace_id = workspace_id)
  seatabler::seatable_columns(table = table, base = base, con = con,
                              include_key = include_key)
}

#' @rdname banctable_columns
#' @param column_name Name of the new column.
#' @param column_type SeaTable column type, e.g. `"text"`, `"number"`, `"date"`,
#'   `"checkbox"`, `"single-select"`, `"multiple-select"`.
#' @param column_data Optional list of type-specific settings, e.g. the options
#'   of a select column.
#' @param column_key For `banctable_add_column()`, the key of an existing column
#'   to insert after. For `banctable_delete_column()`, the key of the column to
#'   delete, from `banctable_columns(include_key = TRUE)`.
#' @export
banctable_add_column <- function(table, column_name, column_type = "text",
                                 base = NULL, column_data = NULL,
                                 column_key = NULL, workspace_id = "57832",
                                 token_name = "BANCTABLE_TOKEN") {
  con <- banc_seatable_connection(token_name = token_name,
                                  workspace_id = workspace_id)
  seatabler::seatable_add_column(table = table, column_name = column_name,
                                 column_type = column_type, base = base,
                                 con = con, column_data = column_data,
                                 column_key = column_key)
}

#' @rdname banctable_columns
#' @param columns A data frame with `name` and `type` columns. Columns that
#'   already exist are skipped.
#' @param progress Whether to report each column as it is added.
#' @export
banctable_add_columns <- function(table, columns, base = NULL,
                                  workspace_id = "57832",
                                  token_name = "BANCTABLE_TOKEN",
                                  progress = TRUE) {
  con <- banc_seatable_connection(token_name = token_name,
                                  workspace_id = workspace_id)
  seatabler::seatable_add_columns(table = table, columns = columns, base = base,
                                  con = con, progress = progress)
}

#' @rdname banctable_columns
#' @export
banctable_delete_column <- function(table, column_key, base = NULL,
                                    workspace_id = "57832",
                                    token_name = "BANCTABLE_TOKEN") {
  con <- banc_seatable_connection(token_name = token_name,
                                  workspace_id = workspace_id)
  seatabler::seatable_delete_column(table = table, column_key = column_key,
                                    base = base, con = con)
}

#' List snapshots of a BANC SeaTable base
#'
#' @description SeaTable snapshots the BANC bases periodically. A snapshot is
#'   the only way back from a bad bulk write to `banc_meta`, so it is worth
#'   knowing how far back they go before you run one.
#'
#' @param base_name Name of the base.
#' @param workspace_id,token_name SeaTable connection arguments; see
#'   [banc_seatable_connection()].
#'
#' @return A data frame of snapshots, one row each.
#' @export
#' @examples
#' \dontrun{
#' banctable_snapshots()
#' }
banctable_snapshots <- function(base_name = "banc_meta",
                                workspace_id = "57832",
                                token_name = "BANCTABLE_TOKEN") {
  con <- banc_seatable_connection(token_name = token_name,
                                  workspace_id = workspace_id)
  seatabler::seatable_snapshots(base_name = base_name, con = con,
                                workspace_id = workspace_id)
}
