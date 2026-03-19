test_that("fct_detect_pop_flags finds standard flags", {
  cols <- c("STUDYID", "USUBJID", "SAFFL", "ITTFL", "AGE")
  result <- fct_detect_pop_flags(cols)
  expect_equal(result, c("SAFFL", "ITTFL"))
})

test_that("fct_detect_pop_flags returns empty when none", {
  cols <- c("STUDYID", "USUBJID", "AGE")
  result <- fct_detect_pop_flags(cols)
  expect_length(result, 0)
})

test_that("fct_detect_trt_vars finds treatment variables", {
  cols <- c("STUDYID", "TRT01P", "TRT01PN", "TRT01A", "ARM", "AGE")
  result <- fct_detect_trt_vars(cols)
  expect_true("TRT01P" %in% result)
  expect_true("TRT01A" %in% result)
  expect_true("ARM" %in% result)
  # Numeric vars excluded
  expect_false("TRT01PN" %in% result)
})

test_that("fct_detect_var_type identifies types correctly", {
  df <- data.frame(
    age = c(50, 60, 70),
    sex = c("M", "F", "M"),
    dt = as.Date(c("2024-01-01", "2024-02-01", "2024-03-01")),
    stringsAsFactors = FALSE
  )
  expect_equal(fct_detect_var_type(df, "age"), "continuous")
  expect_equal(fct_detect_var_type(df, "sex"), "categorical")
  expect_equal(fct_detect_var_type(df, "dt"), "date")
})

test_that("fct_detect_demog_vars finds standard demog vars", {
  adsl <- readRDS("/home/vignesh/R_Projects/adam_pilot/data/adsl.rds")
  result <- fct_detect_demog_vars(adsl)
  expect_true("AGE" %in% result)
  expect_true("SEX" %in% result)
  expect_true("RACE" %in% result)
})

test_that("fct_get_var_label returns label or var name", {
  df <- data.frame(x = 1:3)
  expect_equal(fct_get_var_label(df, "x"), "x")

  attr(df$x, "label") <- "My Label"
  expect_equal(fct_get_var_label(df, "x"), "My Label")
})
