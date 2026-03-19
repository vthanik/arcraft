test_that("fct_ard_demog produces correct structure", {
  adsl <- readRDS("/home/vignesh/R_Projects/adam_pilot/data/adsl.rds")

  grouping <- list(
    trt_var = "TRT01P",
    trt_levels = sort(unique(adsl$TRT01P)),
    include_total = TRUE,
    analysis_vars = c("AGE", "SEX")
  )

  var_configs <- list(
    AGE = list(type = "continuous", stats = c("n", "mean_sd", "median"), decimals = 1),
    SEX = list(type = "categorical", cat_format = "npct", pct_dec = 1, zero_style = "A",
               levels = c("F", "M"))
  )

  ard <- fct_ard_demog(adsl, grouping, var_configs)

  expect_s3_class(ard, "data.frame")
  expect_true(nrow(ard) > 0)
  expect_true("variable" %in% names(ard))
  expect_true("var_label" %in% names(ard))
  expect_true("stat_label" %in% names(ard))
  expect_true("Total" %in% names(ard))

  # Check AGE has 3 stat rows (n, mean_sd, median)
  age_rows <- ard[ard$variable == "AGE", ]
  expect_equal(nrow(age_rows), 3)

  # Check SEX has 2 rows (F, M)
  sex_rows <- ard[ard$variable == "SEX", ]
  expect_equal(nrow(sex_rows), 2)
})

test_that("fct_ard_demog respects decimal config", {
  adsl <- readRDS("/home/vignesh/R_Projects/adam_pilot/data/adsl.rds")

  grouping <- list(
    trt_var = "TRT01P",
    trt_levels = sort(unique(adsl$TRT01P)),
    include_total = FALSE,
    analysis_vars = c("AGE")
  )

  var_configs <- list(
    AGE = list(type = "continuous", stats = c("mean_sd"), decimals = 2)
  )

  ard <- fct_ard_demog(adsl, grouping, var_configs)
  # Mean SD should have 2 decimal places
  val <- ard[["Drug A 200mg"]][1]
  # Check it has decimals (format like "56.52 (12.34)")
  expect_match(val, "\\d+\\.\\d{2}")
})

test_that("fct_ard_demog without total excludes Total column", {
  adsl <- readRDS("/home/vignesh/R_Projects/adam_pilot/data/adsl.rds")

  grouping <- list(
    trt_var = "TRT01P",
    trt_levels = sort(unique(adsl$TRT01P)),
    include_total = FALSE,
    analysis_vars = c("SEX")
  )

  var_configs <- list(
    SEX = list(type = "categorical", cat_format = "npct", pct_dec = 1, zero_style = "A",
               levels = c("F", "M"))
  )

  ard <- fct_ard_demog(adsl, grouping, var_configs)
  expect_false("Total" %in% names(ard))
})
