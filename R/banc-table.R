#' @title Read and write to the seatable for draft BANC annotations
#'
#' @description These functions use the logic and wrap some code
#' from the `flytable_.*` functions in the `fafbseg` R package.
#' \code{banctable_set_token} will obtain and store a permanent
#'   seatable user-level API token.
#'   \code{banctable_query} performs a SQL query against a banctable
#'   database. You can omit the \code{base} argument unless you have tables of
#'   the same name in different bases.
#'   \code{banctable_base} returns a \code{base} object (equivalent to
#'   a mysql database) which allows you to access one or more tables, logging in
#'   to the service if necessary. The returned base object give you full access
#'   to the Python
#'   \href{https://seatable.github.io/seatable-scripts/python/base/}{\code{Base}}
#'    API allowing a range of row/column manipulations.
#'    \code{banctable_update_rows} updates existing rows in a table, returning TRUE on success.
#'    \code{banctable_append_rows} appends new rows to a table. When \code{bigdata=TRUE}, rows are
#'    added directly to the big data backend using the \code{/add-archived-rows/} endpoint.
#'    \code{banctable_move_to_bigdata} moves rows between normal backend and big data backend.
#'    When \code{invert=FALSE} (archive), it moves all rows from a specified view to big data storage.
#'    When \code{invert=TRUE} (unarchive), it moves specific rows by row_id from big data storage back to normal backend.
#'    Note: The big data backend must be enabled in your base for these functions to work.
#'
#' @param sql A SQL query string. See examples and
#'   \href{https://seatable.github.io/seatable-scripts/python/query/}{seatable
#'   docs}.
#' @param limit An optional limit, which only applies if you do not specify a
#'   limit directly in the \code{sql} query. By default seatable limits SQL
#'   queries to 100 rows. We increase the limit to 100000 rows by default.
#' @param convert Expert use only: Whether or not to allow the Python seatable
#'   module to process raw output from the database. This is is principally for
#'   debugging purposes. NB this imposes a requirement of seatable_api >=2.4.0.
#' @param python Logical. Whether to return a Python pandas DataFrame. The default of FALSE returns an R data.frame
#' @param base Character vector specifying the \code{base}
#' @param table Character vector specifying a table foe which you want a
#'   \code{base} object.
#' @param workspace_id A numeric id specifying the workspace. Advanced use only
#   since we can normally figure this out from \code{base_name}.
# @param cached Whether to use a cached base object
# @param token normally retrieved from \code{BANCTABLE_TOKEN} environment variable.
#' @param user,pwd banctable user and password used by \code{banctable_set_token}
#'   to obtain a token
#' @param url Optional URL to the server
#' @param ac A seatable connection object as returned by \code{banctable_login}.
#' @param df A data.frame containing the data to upload including an `_id`
#' column that can identify each row in the remote table.
#' @param append_allowed Logical. Whether rows without row identifiers can be appended.
#' @param chunksize To split large requests into smaller ones with max this many rows.
#' @param token_name The name of the token in your .Renviron file, should be \code{BANCTABLE_TOKEN}.
#' @param view_name Character, the name of the view containing rows to archive (required for archive operation). Mutually exclusive with view_id.
#' @param view_id Character, the ID of the view containing rows to archive (alternative to view_name). Mutually exclusive with view_name.
#' @param where DEPRECATED. The API no longer supports WHERE clauses. Use view_name or view_id instead.
#' @param bigdata Logical. If `TRUE`, new rows are added directly to the big data backend using the `/add-archived-rows/` API endpoint. If `FALSE` (default), rows are added to the normal backend. Note: The big data backend must be enabled in your base for this to work.
#' @param invert Logical. If `FALSE` (default), archives rows from normal backend to big data backend (requires view_name or view_id). If `TRUE`, unarchives rows from big data backend back to normal backend (requires row_ids).
#' @param table.max the maximum number of rows to read from the seatable at one time, which is capped at 10000L by seatable.
#' @param row_ids Character vector of seatable row IDs. Required for unarchive operation (when invert=TRUE). These are the specific rows to move from big data backend back to normal backend. Use the table_id (not table_name) for unarchive operations.
#' @param ... Additional arguments passed to the underlying parallel processing functions which might include cl=2 to specify a number of parallel jobs to run.
#' @param retries if a request to the seatable API fails, the number of times to re-try with a 0.1 second pause.
#' @return a \code{data.frame} of results. There should be 0 rows if no rows
#'   matched query.
#'
#' @seealso \code{\link[fafbseg]{flytable_query}}
#' @examples
#' \dontrun{
#' # Do this once
#' banctable_set_token(user="MY_EMAIL_FOR_SEATABLE.com",
#'                     pwd="MY_SEATABLE_PASSWORD",
#'                     url="https://cloud.seatable.io/")
#'
#' # Query a table:
#' banc.meta <- banctable_query()
#'
#' # Archive rows to big data backend (requires a view):
#' banctable_move_to_bigdata(
#'   table = "banc_meta",
#'   base = "banc_meta",
#'   view_name = "optic_region_view"
#' )
#'
#' # Alternative: use view_id instead of view_name:
#' banctable_move_to_bigdata(
#'   table = "banc_meta",
#'   view_id = "0000"
#' )
#'
#' # Unarchive specific rows from big data backend:
#' banctable_move_to_bigdata(
#'   table = "banc_meta",
#'   invert = TRUE,
#'   row_ids = c("FoDxhChYQSycLm88JZ11RA", "AnotherRowId123")
#' )
#'
#' # Append rows directly to big data backend:
#' new_data <- data.frame(
#'   root_id = c("720575940626768442", "720575940636821616"),
#'   cell_type = c("DNa02", "DNa02")
#' )
#' banctable_append_rows(
#'   df = new_data,
#'   table = "banc_meta",
#'   base = "banc_meta",
#'   bigdata = TRUE
#' )
#' }
#' @export
#' @rdname banctable_query
banctable_query <- function (sql = "SELECT * FROM banc_meta",
                             limit = 200000L,
                             base = NULL,
                             python = FALSE,
                             convert = TRUE,
                             ac = NULL,
                             token_name = "BANCTABLE_TOKEN",
                             workspace_id = "57832",
                             retries = 3,
                             table.max = 10000L){
  if(is.null(ac)) ac <- banctable_login(token_name=token_name)
  table.max <- 10000L
  if(limit>table.max){
    offset <- 0
    df <- data.frame()
    while(offset<limit){
      cat("reading from row: ", offset, "\n")
      sql.new <- sprintf("%s LIMIT %d OFFSET %d", sql, table.max, offset)
      tries <- retries
      bc <- data.frame()
      while(tries>0&&!nrow(bc)){
        bc <- banctable_query(sql=sql.new,
                              limit=FALSE,
                              base=base,
                              python=python,
                              convert=convert,
                              ac=ac,
                              token_name=token_name,
                              workspace_id=workspace_id)
        tries <- tries - 1
        if (!nrow(bc) && tries > 0) {
          # Exponential backoff: 1s, 2s, 4s
          wait <- 2^(retries - tries - 1)
          warning(sprintf("  Retry %d/%d for offset %d (waiting %ds)",
                          retries - tries, retries, offset, wait))
          Sys.sleep(wait)
        }
      }
      if (!nrow(bc)) {
        warning(sprintf("All %d retries exhausted at offset %d -- returning %d rows so far",
                        retries, offset, nrow(df)))
        if (nrow(df)) return(df) else return(NULL)
      }
      df <- rbind(df,bc)
      offset <- offset+nrow(bc)
      if(!length(bc)|nrow(bc)<table.max){
        cat("read rows: ",nrow(df), " read columns:", ncol(df), "\n")
        return(df)
      }
    }
    cat("read rows: ",nrow(df), " read columns:", ncol(df), "\n")
    return(df)
  }
  if (!requireNamespace("checkmate", quietly = TRUE)) {
    stop("Package 'checkmate' is required for this function. Please install it with: install.packages('checkmate')")
  }
  if (!requireNamespace("stringr", quietly = TRUE)) {
    stop("Package 'stringr' is required for this function. Please install it with: install.packages('stringr')")
  }
  checkmate::assert_character(sql, len = 1, pattern = "select",
                              ignore.case = T)
  res = stringr::str_match(sql, stringr::regex("\\s+FROM\\s+[']{0,1}([^, ']+).*",
                                               ignore_case = T))
  if (any(is.na(res)[, 2]))
    stop("Cannot identify a table name in your sql statement!
")
  table = res[, 2]
  if (is.null(base)) {
    base = try(banctable_base(table = table, workspace_id = workspace_id, token_name = token_name))
    if (inherits(base, "try-error"))
      stop("I inferred table_name: ", table, " from your SQL query but couldn't connect to a base with this table!")
  }
  else if (is.character(base))
    base = banctable_base(base_name = base, workspace_id = workspace_id, token_name = token_name)
  if (!isTRUE(grepl("\\s+limit\\s+\\d+", sql)) && !isFALSE(limit)) {
    if (!is.finite(limit))
      limit = .Machine$integer.max
    sql = paste(sql, "LIMIT", limit)
  }
  pyout <- reticulate::py_capture_output(ll <- try(reticulate::py_call(base$query,
                                                                       sql, convert = convert), silent = T))
  if (inherits(ll, "try-error")) {
    is_rate_limit <- grepl("429|too many requests|rate.limit", pyout, ignore.case = TRUE)
    if (is_rate_limit) {
      warning("SeaTable API rate limit exceeded (HTTP 429). ",
              "Check your monthly quota at https://cloud.seatable.io. ",
              "Python output: ", pyout)
    } else {
      warning(paste("No rows returned by banctable", pyout, collapse = "\n"))
    }
    return(NULL)
  }
  pd = reticulate::import("pandas")
  reticulate::py_capture_output(pdd <- reticulate::py_call(pd$DataFrame,
                                                           ll))
  if (python)
    pdd
  else {
    colinfo = fafbseg::flytable_columns(table, base)
    df = banctable2df(fafbseg:::pandas2df(pdd, use_arrow = F), tidf = colinfo)
    fields = fafbseg:::sql2fields(sql)
    if (length(fields) == 1 && fields == "*") {
      toorder = intersect(colinfo$name, colnames(df))
    }
    else {
      toorder = intersect(fafbseg:::sql2fields(sql), colnames(df))
    }
    rest = setdiff(colnames(df), toorder)
    df[c(toorder, rest)]
  }
}

#' @export
#' @rdname banctable_query
banctable_set_token <- function(user,
                                pwd,
                                url = "https://cloud.seatable.io/",
                                token_name = "BANCTABLE_TOKEN"){
  con <- banc_seatable_connection(token_name = token_name, url = url)
  # seatabler replaces an existing line in ~/.Renviron rather than appending a
  # second one, and sets the variable for this session too.
  seatabler::seatable_generate_token(user = user, pwd = pwd, con = con)
  invisible(NULL)
}

#' @export
#' @rdname banctable_query
banctable_login <- function(url = "https://cloud.seatable.io/",
                            token_name = "BANCTABLE_TOKEN"){
  con <- banc_seatable_connection(token_name = token_name, url = url)
  seatabler::seatable_login(con = con)
}


#' @export
#' @rdname banctable_query
banctable_update_rows <- function (df,
                                   table,
                                   base = NULL,
                                   append_allowed = FALSE,
                                   chunksize = 1000L,
                                   workspace_id = "57832",
                                   token_name = "BANCTABLE_TOKEN",
                                   ...) {
  con <- banc_seatable_connection(token_name = token_name,
                                  workspace_id = workspace_id)
  # seatabler detects multiple-select columns from the table schema and routes
  # them through its own list-per-cell path, so the comma-splitting bancr used
  # to do by hand is no longer needed here.
  seatabler::seatable_update_rows(df = df, table = table, base = base,
                                  con = con, append_allowed = append_allowed,
                                  chunksize = chunksize, ...)
}

# hidden
# The BANC base object. seatabler::seatable_base() already memoises the base and
# re-fetches it when the JWT is close to expiry, so this is now just the BANC
# connection bound to that generic.
banctable_base <- function(base_name = "banc_meta",
                           table = NULL,
                           url = "https://cloud.seatable.io/",
                           token_name = "BANCTABLE_TOKEN",
                           workspace_id = "57832",
                           cached = TRUE,
                           ac = NULL) {
  # `ac` is accepted for backwards compatibility and ignored: seatabler logs in
  # from the connection itself.
  con <- banc_seatable_connection(token_name = token_name, url = url,
                                  workspace_id = workspace_id)
  seatabler::seatable_base(base_name = base_name, table = table, con = con,
                           workspace_id = workspace_id, cached = cached)
}

# hidden
# Kept as an alias so older internal callers keep working.
banctable_base_impl <- function(base_name = "banc_meta",
                                table = NULL,
                                url = "https://cloud.seatable.io/",
                                workspace_id = "57832",
                                token_name = "BANCTABLE_TOKEN",
                                ac = NULL) {
  banctable_base(base_name = base_name, table = table, url = url,
                 token_name = token_name, workspace_id = workspace_id)
}

#' @export
#' @rdname banctable_query
banctable_move_to_bigdata <- function(table = "banc_meta",
                                      base = "banc_meta",
                                      url = "https://cloud.seatable.io/",
                                      workspace_id = "57832",
                                      token_name = "BANCTABLE_TOKEN",
                                      view_name = "archive",
                                      view_id = NULL,
                                      where = NULL,
                                      invert = FALSE,
                                      row_ids = NULL){
  if (!is.null(where)) {
    warning("The 'where' parameter is deprecated. SeaTable now archives the ",
            "rows of a view, so pass 'view_name' or 'view_id' instead.")
  }
  con <- banc_seatable_connection(token_name = token_name, url = url,
                                  workspace_id = workspace_id)
  if (invert) {
    seatabler::seatable_unarchive_rows(table = table, row_ids = row_ids,
                                       base = base, con = con)
  } else {
    # seatabler wants exactly one of the two; drop this function's default
    # view_name when the caller gave a view_id instead.
    if (!is.null(view_id)) view_name <- NULL
    seatabler::seatable_archive_rows(table = table, view_name = view_name,
                                     view_id = view_id, base = base, con = con)
  }
}

#' Read harmonised meta-data tables for the external connectomes
#'
#' `franken_meta()` returns the BANC project's reformulated views of
#' each external connectome (FAFB-FlyWire, MANC, Hemibrain and maleCNS),
#' re-keyed into BANC's annotation scheme (the same `flow` /
#' `super_class` / `cell_class` / `cell_sub_class` / `cell_type` /
#' `hemilineage` / `region` / `nerve` / `neuromere` / function /
#' body_part / neurochemistry vocabularies `banc_meta()` uses). Each row
#' can be compared directly against the corresponding BANC neuron;
#' source-specific identifiers and labels are retained alongside the
#' BANC-shaped columns.
#'
#' @details
#' Two sources of these tables are supported. The default `"gcs"` reads
#' per-dataset feathers from the public bucket at
#' `gs://lee-lab_brain-and-nerve-cord-fly-connectome/compiled_data/<slug>/<slug>_meta.feather`
#' (slugs `fafb_783`, `manc_121`, `hemibrain_121`, `malecns_09`). No
#' authentication is required and the feathers are cached locally under
#' `tools::R_user_dir("bancr", "cache")`. This is the recommended path
#' for almost all users.
#'
#' The `"seatable"` source is restricted to the BANC production team and
#' reads the in-progress per-source SeaTable tables (`fafb`, `manc`,
#' `hemibrain`, `malecns`) in the `cns_meta` base via [banctable_query()].
#' It requires a valid `BANCTABLE_TOKEN`. The `"legacy"` source reads the
#' single, deprecated `franken_meta` SeaTable as a backup; it is no
#' longer the source of truth post-2026-05-15.
#'
#' When multiple `tables` are requested, `dplyr::bind_rows()` takes the
#' column-union; FAFB_*, MANC_*, hemibrain-specific and malecns-specific
#' columns survive only on the rows that come from the table that owns
#' them.
#'
#' @param tables Character vector of source tables to read and append.
#'   Any combination of `"fafb"`, `"manc"`, `"hemibrain"`, `"malecns"`.
#'   Defaults to `c("fafb", "manc")` — the FAFB+MANC union, the closest
#'   equivalent to the historical single `franken_meta` table.
#' @param source `"gcs"` (default, public feathers), `"seatable"` (BANC
#'   production team only) or `"legacy"` (deprecated single SeaTable).
#' @param overwrite Logical. If `TRUE` and `source = "gcs"`, re-download
#'   the cached feathers even if they already exist.
#' @param sql Optional. If supplied, bypasses the table-union logic and
#'   passes the SQL verbatim to `banctable_query()`. Mainly used to
#'   query a SeaTable table directly, e.g.
#'   `franken_meta(sql = "SELECT * FROM franken_meta")`.
#' @param base SeaTable base name (only used when `source` is
#'   `"seatable"` or `"legacy"`). Defaults to `"cns_meta"`.
#' @param ... Passed to `banctable_query()` when reading from SeaTable.
#'
#' @return A data frame with one row per neuron across the chosen
#'   source tables. When more than one source table is read, a unified
#'   `neuron_id` column is added: each row carries the ID from its
#'   originating table's per-source ID column (`fafb_id` / `fafb_783_id`,
#'   `manc_id` / `manc_121_id`, `hemibrain_id` / `hemibrain_121_id`,
#'   `malecns_id` / `malecns_09_id`), coalesced into the single
#'   `neuron_id`. The original per-source ID columns are preserved.
#'
#' @examples
#' \dontrun{
#' # Default: FAFB + MANC union read from the public GCS feathers.
#' fk <- franken_meta()
#'
#' # Only the FAFB rows
#' fafb <- franken_meta(tables = "fafb")
#'
#' # All four source tables, column-unioned
#' all <- franken_meta(tables = c("fafb", "manc", "hemibrain", "malecns"))
#'
#' # Force a fresh download of the cached feathers
#' fk_fresh <- franken_meta(overwrite = TRUE)
#'
#' # BANC production team: pull the in-progress SeaTable instead.
#' fk_st <- franken_meta(source = "seatable")
#'
#' # Legacy single-table SeaTable read (deprecated; still available)
#' legacy <- franken_meta(source = "legacy")
#' }
#'
#' @export
#' @rdname banctable_query
franken_meta <- function(tables = c("fafb", "manc"),
                         source = c("gcs", "seatable", "legacy"),
                         overwrite = FALSE,
                         sql = NULL,
                         base = "cns_meta",
                         ...){
  source <- match.arg(source)
  if (!is.null(sql) && nzchar(sql)) {
    # Caller supplied explicit SQL → straight passthrough (SeaTable only).
    return(banctable_query(sql = sql, base = base, ...))
  }
  if (source == "legacy") {
    return(banctable_query(sql = "SELECT * FROM franken_meta",
                           base = base, ...))
  }
  valid_tables <- c("fafb", "manc", "hemibrain", "malecns")
  bad <- setdiff(tables, valid_tables)
  if (length(bad)) {
    stop("Unknown source table(s): ", paste(bad, collapse = ", "),
         "\n  Valid: ", paste(valid_tables, collapse = ", "))
  }
  if (!length(tables)) {
    stop("`tables` cannot be empty. Pass one or more of: ",
         paste(valid_tables, collapse = ", "))
  }
  if (source == "gcs") {
    # Map the short source name to the compiled_data/<slug>/ slug.
    slug_map <- c(fafb = "fafb_783",
                  manc = "manc_121",
                  hemibrain = "hemibrain_121",
                  malecns = "malecns_09")
    parts <- lapply(tables, function(t) {
      banc_gcs_meta_feather(slug_map[[t]], overwrite = overwrite)
    })
  } else {
    # source == "seatable"
    parts <- lapply(tables, function(t) {
      banctable_query(sql = sprintf("SELECT * FROM %s", t),
                      base = base, ...)
    })
  }
  if (length(parts) == 1L) return(parts[[1]])
  # Per-dataset feathers occasionally diverge on column type (e.g.
  # neurotransmitter_score is character in fafb_783 / hemibrain_121 but
  # double in manc_121 / malecns_09), which bind_rows() refuses to
  # combine. Coerce any column whose type differs across the parts to
  # character before unioning, then bind.
  all_cols <- unique(unlist(lapply(parts, names)))
  for (col in all_cols) {
    types <- unique(vapply(parts, function(p) {
      if (col %in% names(p)) class(p[[col]])[1] else NA_character_
    }, character(1)))
    types <- types[!is.na(types)]
    if (length(types) > 1L) {
      parts <- lapply(parts, function(p) {
        if (col %in% names(p)) p[[col]] <- as.character(p[[col]])
        p
      })
    }
  }
  combined <- dplyr::bind_rows(parts)
  # Each source table has its own per-row ID column. Coalesce them into
  # a single `neuron_id` so callers can key rows uniformly across sources.
  # Both schemas (SeaTable's stripped names and GCS's slug-suffixed names)
  # are covered so the column survives whichever source supplied it.
  id_cols <- c("fafb_id", "fafb_783_id",
               "manc_id", "manc_121_id",
               "hemibrain_id", "hemibrain_121_id",
               "malecns_id", "malecns_09_id")
  present <- intersect(id_cols, names(combined))
  if (length(present)) {
    combined$neuron_id <- do.call(
      dplyr::coalesce,
      lapply(present, function(co) as.character(combined[[co]]))
    )
    combined <- dplyr::relocate(combined, "neuron_id")
  }
  combined
}

#' @export
#' @rdname banctable_query
banctable_append_rows <- function (df,
                                   table,
                                   bigdata = FALSE,
                                   base = NULL,
                                   chunksize = 1000L,
                                   workspace_id = "57832",
                                   token_name = "BANCTABLE_TOKEN",
                                   ...) {
  con <- banc_seatable_connection(token_name = token_name,
                                  workspace_id = workspace_id)
  # bigdata rows go to the api-gateway add-archived-rows endpoint; seatabler
  # handles both that and the ordinary SDK path.
  seatabler::seatable_append_rows(df = df, table = table, base = base,
                                  con = con, bigdata = bigdata,
                                  chunksize = chunksize, ...)
}

# banctable_update_rows()'s multi-select payload builder retired: seatabler
# builds the payload now.


# hidden, modified to enable working with list columns
banctable2df <- function (df, tidf = NULL) {
  if (!isTRUE(ncol(df) > 0))
    return(df)
  nr = nrow(df)
  # Convert any columns still stored as Python objects (numpy arrays) to native R.
  # py_to_r(DataFrame) can leave columns as numpy.ndarray objects; these cause
  # crashes in downstream flytable_fix_coltypes (e.g. x[is.na(x)] on a Python
  # array triggers IndexError from wrong-length boolean index).
  for (i in seq_along(df)) {
    if (is.environment(df[[i]])) {
      df[[i]] <- tryCatch(
        df[[i]]$tolist(),  # auto-converts to R via reticulate
        error = function(e) rep(NA_character_, nr)
      )
    }
  }
  listcols = sapply(df, is.list)
  for (i in which(listcols)) {
    li = lengths(df[[i]])
    if (isTRUE(all(li == 1))) {
      ul = unlist(df[[i]])
      if (!isTRUE(length(ul) == nr))
        ul = sapply(ul,paste,collapse=",")
      else df[[i]] = ul
    }
    else if (isTRUE(all(li %in% 0:1))) {
      tryCatch({
        df[[i]][!nzchar(df[[i]])] = NA
      }, error = function(e) {
        df[[i]] <<- vapply(df[[i]], function(x) {
          if (is.null(x) || length(x) == 0) NA_character_
          else {
            s <- tryCatch(as.character(x)[1], error = function(e2) NA_character_)
            if (is.na(s) || !nzchar(s)) NA_character_ else s
          }
        }, character(1))
      })
      df[[i]] = fafbseg:::null2na(df[[i]])
    }
    else df[[i]] = sapply(df[[i]],paste,collapse=",")
  }
  if (is.null(tidf))
    df
  else {
    if (is.character(tidf))
      tidf = fafbseg::flytable_columns(tidf)
    fafbseg:::flytable_fix_coltypes(df, tidf = tidf)
  }
}

# hidden, helper function to update status column
banc_update_status <- function(df,
                               update,
                               col = "status",
                               wipe = FALSE){
  if(wipe){
    df$status <- ""
  }else{
    df$status[is.na(df$status)] <- ""
    df$status[df$status%in%c("NA","NaN")] <- ""
  }
  update.col <- sapply(df$status, function(x){
    x=paste(c(x,update),collapse=",")
    paste(sort(unique(unlist(strsplit(x,split=",|, ")))),collapse=",")
  }
  )
  update.col <- gsub("^,","",update.col)
  df[[col]] <- update.col
  df
}

# # # Example of adding a labels to the status column
# bc <- banctable_query()
# sizes <- as.numeric(bc$l2_cable_length_um)
# sizes[is.na(sizes)] <- 0
# tadpoles <- bc[sizes>1&sizes<10,]
# tadpoles <- banc_update_status(tadpoles,update="TOO_SMALL")
# banctable_update_rows(base = 'banc_meta',
#                       table = "banc_meta",
#                       df = tadpoles[,c("_id","super_class","status")],
#                       append_allowed = FALSE,
#                       chunksize = 100)

# Update the BANC IDs
banctable_updateids <- function(){

  # Get cell info table
  cat('reading cell info cave table...
')
  info <- banc_cell_info(rawcoords = TRUE)  %>%
    dplyr::mutate(pt_position = xyzmatrix2str(.data$pt_position)) %>%
    dplyr::select(.data$pt_root_id, .data$pt_supervoxel_id, .data$pt_position) %>%
    rbind(banc_backbone_proofread() %>%
            dplyr::select(.data$pt_root_id, .data$pt_supervoxel_id, .data$pt_position) %>%
            dplyr::mutate(pt_position = xyzmatrix2str(.data$pt_position))) %>%
    rbind(banc_neck_connective_neurons() %>%
            dplyr::select(.data$pt_root_id, .data$pt_supervoxel_id, .data$pt_position) %>%
            dplyr::mutate(pt_position = xyzmatrix2str(.data$pt_position))) %>%
    dplyr::mutate(pt_root_id=as.character(.data$pt_root_id),
                  pt_supervoxel_id=as.character(.data$pt_supervoxel_id)) %>%
    dplyr::distinct(.data$pt_supervoxel_id, .keep_all = TRUE) %>%
    dplyr::rowwise()

  # Get current table
  cat('reading banc meta seatable...
')
  bc <- banctable_query(sql = 'select _id, root_id, supervoxel_id, position, banc_match, banc_match_supervoxel_id, banc_png_match, banc_png_match_supervoxel_id, banc_nblast_match, banc_nblast_match_supervoxel_id from banc_meta') %>%
    dplyr::select(.data$root_id, .data$supervoxel_id, .data$position,
                  .data$banc_match, .data$banc_match_supervoxel_id, .data$banc_png_match, .data$banc_png_match_supervoxel_id, .data$banc_nblast_match, .data$banc_nblast_match_supervoxel_id,
                  .data$`_id`)
  bc[bc=="0"] <- NA
  bc[bc==""] <- NA

  # Update
  cat('updating column: root_id ...
')
  bc.new <- bc %>%
    dplyr::left_join(info,
                     by = c("supervoxel_id"="pt_supervoxel_id")) %>%
    dplyr::mutate(root_id = ifelse(is.na(.data$pt_root_id), .data$root_id, .data$pt_root_id)) %>%
    dplyr::mutate(position = ifelse(is.na(.data$position), .data$pt_position, .data$position)) %>%
    dplyr::select(-.data$pt_root_id, -.data$pt_position)

  # Update root IDs directly where needed
  bc.new <- banc_updateids(bc.new,
                           root.column = "root_id",
                           supervoxel.column = "supervoxel_id",
                           position.column = "position")

  # Make sure supervoxel and root position information that is missing, is filled in
  bc.new <- bc.new %>%
    dplyr::left_join(info %>% dplyr::distinct(.data$pt_root_id, .keep_all = TRUE),
                     by = c("root_id"="pt_root_id")) %>%
    dplyr::mutate(supervoxel_id = ifelse(is.na(.data$supervoxel_id), .data$pt_supervoxel_id, .data$supervoxel_id)) %>%
    dplyr::mutate(position = ifelse(is.na(.data$position), .data$pt_position, .data$position)) %>%
    dplyr::select(-.data$pt_supervoxel_id, -.data$pt_position)

  # Update match columns
  lookup <- bc.new %>%
    dplyr::select(.data$root_id, .data$supervoxel_id) %>%
    dplyr::rename(lookup_root_id=.data$root_id,
                  lookup_supervoxel_id=.data$supervoxel_id) %>%
    dplyr::filter(!is.na(.data$lookup_supervoxel_id), .data$lookup_supervoxel_id!="0",
                  !is.na(.data$lookup_root_id), .data$lookup_root_id!="0") %>%
    dplyr::distinct(.data$lookup_root_id, .data$lookup_supervoxel_id)
  bc.new <- bc.new %>%
    dplyr::left_join(lookup, by = c("banc_match_supervoxel_id"="lookup_supervoxel_id")) %>%
    dplyr::mutate(banc_match = dplyr::case_when(
      !is.na(.data$lookup_root_id) ~ .data$lookup_root_id,
      TRUE ~ .data$banc_match
    )) %>%
    dplyr::select(-.data$lookup_root_id) %>%
    dplyr::left_join(lookup, by = c("banc_png_match_supervoxel_id"="lookup_supervoxel_id")) %>%
    dplyr::mutate(banc_png_match = dplyr::case_when(
      !is.na(.data$lookup_root_id) ~ .data$lookup_root_id,
      TRUE ~ .data$banc_png_match
    )) %>%
    dplyr::select(-.data$lookup_root_id) %>%
    dplyr::left_join(lookup, by = c("banc_nblast_match_supervoxel_id"="lookup_supervoxel_id")) %>%
    dplyr::mutate(banc_nblast_match = dplyr::case_when(
      !is.na(.data$lookup_root_id) ~ .data$lookup_root_id,
      TRUE ~ .data$banc_nblast_match
    )) %>%
    dplyr::select(-.data$lookup_root_id)

  # Update directly
  cat('updating column: banc_match ...
')
  bc.new[!is.na(bc.new$banc_match),] <- banc_updateids(bc.new[!is.na(bc.new$banc_match),],
                                                       root.column = "banc_match",
                                                       supervoxel.column = "banc_match_supervoxel_id",
                                                       position.column = "banc_match_position")
  cat('updating column: banc_png_match ...
')
  bc.new[!is.na(bc.new$banc_png_match),] <- banc_updateids(bc.new[!is.na(bc.new$banc_png_match),],
                                                       root.column = "banc_png_match",
                                                       supervoxel.column = "banc_png_match_supervoxel_id",
                                                       position.column = "banc_png_match_position")
  cat('updating column: banc_nblast_match ...
')
  bc.new[!is.na(bc.new$banc_nblast_match),] <- banc_updateids(bc.new[!is.na(bc.new$banc_nblast_match),],
                                                       root.column = "banc_nblast_match",
                                                       supervoxel.column = "banc_nblast_match_supervoxel_id",
                                                       position.column = "banc_nblast_match_position")
  bc.new <- bc.new %>%
    dplyr::left_join(lookup %>%dplyr::distinct(.data$lookup_root_id, .keep_all=TRUE),
                     by = c("banc_match"="lookup_root_id")) %>%
    dplyr::mutate(banc_match_supervoxel_id = dplyr::case_when(
      is.na(.data$banc_match_supervoxel_id)&!is.na(.data$lookup_supervoxel_id) ~ .data$lookup_supervoxel_id,
      TRUE ~ .data$banc_match_supervoxel_id
    )) %>%
    dplyr::select(-.data$lookup_supervoxel_id) %>%
    dplyr::left_join(lookup %>%dplyr::distinct(.data$lookup_root_id, .keep_all=TRUE),
                     by = c("banc_png_match"="lookup_root_id")) %>%
    dplyr::mutate(banc_png_match_supervoxel_id = dplyr::case_when(
      is.na(.data$banc_png_match_supervoxel_id)&!is.na(.data$lookup_supervoxel_id) ~ .data$lookup_supervoxel_id,
      TRUE ~ .data$banc_png_match_supervoxel_id
    )) %>%
    dplyr::select(-.data$lookup_supervoxel_id) %>%
    dplyr::left_join(lookup %>%dplyr::distinct(.data$lookup_root_id, .keep_all=TRUE),
                     by = c("banc_nblast_match"="lookup_root_id")) %>%
    dplyr::mutate(banc_nblast_match_supervoxel_id = dplyr::case_when(
      is.na(.data$banc_nblast_match_supervoxel_id)&!is.na(.data$lookup_supervoxel_id) ~ .data$lookup_supervoxel_id,
      TRUE ~ .data$banc_nblast_match_supervoxel_id
    )) %>%
    dplyr::select(-.data$lookup_supervoxel_id)

  # Update
  cat('updating banc meta seatable...
')
  bc.new <- bc.new %>%
    dplyr::filter(!is.na(.data$`_id`)) %>%
    dplyr::distinct(.data$`_id`, .keep_all = TRUE)
  bc.new[is.na(bc.new)] <- ''
  bc.new[bc.new=="0"] <- ''
  banctable_update_rows(df = bc.new,
                        base = "banc_meta",
                        table = "banc_meta",
                        append_allowed = FALSE,
                        chunksize = 1000)
  cat('done.')

  # Return
  invisible()
}

banctable_annotate <- function(root_ids,
                               update,
                               overwrite = FALSE,
                               append = FALSE,
                               column="notes"){


  # Get current table
  cat('reading banc meta seatable...
')
  bc <- banctable_query(sql = sprintf('select _id, root_id, supervoxel_id, %s from banc_meta',column)) %>%
    dplyr::filter(.data$root_id %in% root_ids)
  if(!nrow(bc)){
    message("root_ids not in BANC meta")
    return(invisible())
  }
  bc[bc=="0"] <- NA
  bc[bc==""] <- NA

  # Update
  cat('updating column: root_id ...
')
  bc.new <- bc
  if(overwrite){
    bc.new[[column]] <- NA
  }
  if(append){
    bc.new <- bc.new %>%
      dplyr::rowwise() %>%
      dplyr::mutate(update = dplyr::case_when(
        is.na(.data[[column]]) ~ update,
        TRUE ~ paste(.data[[column]], update, sep = ", ", collapse = ", "),
      )
      )
  }else{
    bc.new <- bc.new %>%
      dplyr::rowwise() %>%
      dplyr::mutate(update = dplyr::case_when(
        is.na(.data[[column]]) ~ update,
        TRUE ~ .data[[column]],
      )
    )
  }
  changed <- sum(bc.new[[column]] != bc.new$update, na.rm = TRUE)
  bc.new[[column]] <- bc.new$update
  bc.new$update <- NULL

  # Summarise update
  message("Changed ", changed, " rows")
  cat(sprintf("%s before update:
",column))
  if(nrow(bc.new)==1){
    cat(bc[[column]])
  }else{
    cat(sort(table(bc[[column]])))
  }
  cat(sprintf("
 %s after update:
",column))
  if(nrow(bc.new)==1){
    cat(bc.new[[column]])
  }else{
    cat(sort(table(bc.new[[column]])))
  }

  # Update
  cat('updating banc meta seatable...
')
  bc.new <- as.data.frame(bc.new)
  bc.new[is.na(bc.new)] <- ''
  bc.new[bc.new=="0"] <- ''
  banctable_update_rows(df = bc.new,
                        base = "banc_meta",
                        table = "banc_meta",
                        append_allowed = FALSE,
                        chunksize = 1000)
  cat('done.')

  # Return
  invisible()

}


# banctable_snapshots() now lives in R/seatabler.R, wrapping
# seatabler::seatable_snapshots().




