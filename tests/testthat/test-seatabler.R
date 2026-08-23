test_that("banc_seatable_connection describes the BANC server", {
  con <- banc_seatable_connection()
  expect_s3_class(con, "seatable_connection")
  expect_equal(con$url, "https://cloud.seatable.io/")
  expect_equal(con$token_envvar, "BANCTABLE_TOKEN")
  expect_identical(con$workspace_id, "57832")
})

test_that("the SeaTable python stack is reachable", {
  # bancr's other tests never touch this path, so a seatabler that cannot reach
  # its python dependencies used to pass the whole suite and only fail in use.
  skip_if_not_installed("seatabler")
  skip_if_not_installed("reticulate")
  skip_if_not(reticulate::py_available(initialize = TRUE))
  skip_if(Sys.getenv("BANCTABLE_TOKEN") == "", "no BANCTABLE_TOKEN set")

  expect_no_error(seatabler::seatable_module())
  expect_no_error(banctable_login())
})

test_that("banctable_columns returns a schema with keys", {
  skip_if_not_installed("seatabler")
  skip_if(Sys.getenv("BANCTABLE_TOKEN") == "", "no BANCTABLE_TOKEN set")

  cols <- banctable_columns("banc_meta")
  expect_s3_class(cols, "data.frame")
  expect_true(all(c("key", "name", "type", "rtype") %in% colnames(cols)))
  expect_true("root_id" %in% cols$name)
})
