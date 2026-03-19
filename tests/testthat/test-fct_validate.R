test_that("fct_validate_pipeline checks all conditions", {
  # Empty store snapshot
  snapshot <- list(
    datasets = list(),
    template = NULL,
    grouping = list(trt_var = NULL, analysis_vars = list()),
    fmt = list(titles = list(), page = list())
  )

  checks <- fct_validate_pipeline(snapshot)
  expect_type(checks, "list")
  expect_false(checks$data_loaded$pass)
  expect_false(checks$template_selected$pass)
  expect_false(checks$trt_var$pass)
  expect_false(checks$analysis_vars$pass)
  expect_false(checks$titles$pass)
})

test_that("fct_validate_pipeline passes with complete config", {
  snapshot <- list(
    datasets = list(adsl = data.frame(x = 1)),
    template = "demog",
    grouping = list(trt_var = "TRT01P", analysis_vars = c("AGE", "SEX")),
    fmt = list(
      titles = list(list(text = "Title")),
      page = list(orientation = "landscape", font_family = "Courier New", font_size = 9)
    )
  )

  checks <- fct_validate_pipeline(snapshot)
  expect_true(checks$data_loaded$pass)
  expect_true(checks$template_selected$pass)
  expect_true(checks$trt_var$pass)
  expect_true(checks$analysis_vars$pass)
  expect_true(checks$titles$pass)
  expect_true(checks$page$pass)
})
