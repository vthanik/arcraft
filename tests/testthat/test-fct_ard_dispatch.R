# Tests for dispatch system — demographics only (Phase 1)

adsl <- readRDS(system.file("data", "adsl.rds", package = "arbuilder"))

grouping <- list(
  trt_var = "TRT01P",
  trt_levels = sort(unique(adsl$TRT01P)),
  include_total = TRUE,
  analysis_vars = c("AGE", "SEX")
)

datasets <- list(adsl = adsl)

# ── Dispatch ──

test_that("dispatch routes demog correctly", {
  ard <- fct_ard_dispatch("demog", datasets, grouping,
    list(AGE = list(type = "continuous", stats = c("n"), decimals = 1),
         SEX = list(type = "categorical", cat_format = "npct")))
  expect_s3_class(ard, "tbl_df")
  expect_true(nrow(ard) > 0)
  expect_true("Total" %in% names(ard))
})

test_that("unknown template throws error", {
  expect_error(fct_ard_dispatch("nonexistent", datasets, grouping, list()),
               "not yet implemented")
})

# ── Template Registry ──

test_that("template registry has demog template", {
  reg <- template_registry()
  expect_true(length(reg) >= 1)
  ids <- vapply(reg, function(t) t$id, character(1))
  expect_true("demog" %in% ids)
})

test_that("get_template_def returns correct template", {
  def <- get_template_def("demog")
  expect_equal(def$name, "Demographics")
  expect_equal(def$category, "Study Information")
})

# ── Suggest Vars ──

test_that("suggest vars returns correct vars for demog", {
  vars <- fct_suggest_vars("demog", adsl)
  expect_true("AGE" %in% vars)
  expect_true("SEX" %in% vars)
})

# ── Output Type ──

test_that("output type detection works", {
  expect_equal(fct_template_output_type("demog"), "table")
})
