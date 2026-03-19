test_that("fct_codegen generates parseable R code", {
  data_cfg <- list(dataset = "adsl", path = "data/adsl.rds", pop_flag = "SAFFL")
  grouping <- list(
    trt_var = "TRT01P", trt_levels = c("Placebo", "Drug A"),
    include_total = TRUE, analysis_vars = c("AGE", "SEX")
  )
  var_configs <- list(
    AGE = list(type = "continuous", stats = c("n", "mean_sd"), decimals = 1),
    SEX = list(type = "categorical", cat_format = "npct")
  )
  format_cfg <- list(
    titles = list(list(text = "Table 14.1.1")),
    footnotes = list(list(text = "Note 1")),
    population = "Safety",
    source = "Source: ADSL",
    page = list(orientation = "landscape", font_family = "Courier New", font_size = 9),
    rules = list(hline_preset = "header")
  )

  code <- fct_codegen(data_cfg, grouping, var_configs, format_cfg)

  expect_type(code, "character")
  expect_true(nzchar(code))

  # Code must parse without error
  expect_no_error(parse(text = code))
})

test_that("fct_codegen_data includes population filter", {
  cfg <- list(dataset = "adsl", path = "data/adsl.rds", pop_flag = "SAFFL")
  code <- fct_codegen_data(cfg)
  expect_match(code, "SAFFL")
  expect_match(code, "readRDS")
})

test_that("fct_codegen_header includes libraries", {
  code <- fct_codegen_header()
  expect_match(code, "library\\(dplyr\\)")
  expect_match(code, "library\\(arframe\\)")
})
