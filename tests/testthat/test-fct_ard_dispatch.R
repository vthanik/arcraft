# Tests for dispatch system and new ARD builders

adsl <- readRDS("/home/vignesh/R_Projects/adam_pilot/data/adsl.rds")
adae <- readRDS("/home/vignesh/R_Projects/adam_pilot/data/adae.rds")
adtte <- readRDS("/home/vignesh/R_Projects/adam_pilot/data/adtte.rds")
adlb <- readRDS("/home/vignesh/R_Projects/adam_pilot/data/adlb.rds")

grouping <- list(
  trt_var = "TRT01P",
  trt_levels = sort(unique(adsl$TRT01P)),
  include_total = TRUE,
  analysis_vars = c("AGE", "SEX")
)

datasets <- list(adsl = adsl, adae = adae, adtte = adtte, adlb = adlb)

# ── Dispatch ──

test_that("dispatch routes demog correctly", {
  ard <- fct_ard_dispatch("demog", datasets, grouping,
    list(AGE = list(type = "continuous", stats = c("n"), decimals = 1),
         SEX = list(type = "categorical", cat_format = "npct")))
  expect_s3_class(ard, "tbl_df")
  expect_true(nrow(ard) > 0)
  expect_true("Total" %in% names(ard))
})

test_that("dispatch routes disposition correctly", {
  ard <- fct_ard_dispatch("disposition", datasets, grouping, list())
  expect_s3_class(ard, "tbl_df")
  expect_true(nrow(ard) > 0)
  expect_true("EOSSTT" %in% ard$variable)
})

test_that("dispatch routes ae_summary correctly", {
  ard <- fct_ard_dispatch("ae_summary", datasets, grouping, list())
  expect_s3_class(ard, "tbl_df")
  expect_true(nrow(ard) == 7)
  expect_true(any(grepl("Any TEAE", ard$stat_label)))
})

test_that("dispatch routes ae_socpt correctly", {
  ard <- fct_ard_dispatch("ae_socpt", datasets, grouping, list())
  expect_true(nrow(ard) > 10)
  expect_true("row_type" %in% names(ard))
  expect_true("any" %in% ard$row_type)
  expect_true("parent" %in% ard$row_type)
  expect_true("child" %in% ard$row_type)
})

test_that("dispatch routes ae_serious correctly", {
  ard <- fct_ard_dispatch("ae_serious", datasets, grouping, list())
  # May be empty if no serious AEs
  expect_s3_class(ard, "tbl_df")
})

test_that("unknown template throws error", {
  expect_error(fct_ard_dispatch("nonexistent", datasets, grouping, list()),
               "Unknown template")
})

# ── Disposition ──

test_that("disposition has completion status and disc reasons", {
  ard <- fct_ard_disposition(adsl, grouping, list())
  expect_true("EOSSTT" %in% ard$variable)
  # Check has completion statuses
  statuses <- ard$stat_label[ard$variable == "EOSSTT"]
  expect_true(any(grepl("COMPLETED", statuses)))
})

# ── Populations ──

test_that("populations shows all flags", {
  grouping_pop <- grouping
  grouping_pop$analysis_vars <- c("SAFFL", "ITTFL", "EFFFL")
  ard <- fct_ard_populations(adsl, grouping_pop, list())
  expect_true(nrow(ard) >= 3)
  expect_true(any(grepl("Safety", ard$stat_label)))
})

# ── Hierarchical ──

test_that("hierarchical AE builder produces SOC/PT hierarchy", {
  ard <- fct_ard_hierarchical(adae, adsl, grouping, list(),
    parent_var = "AEBODSYS", child_var = "AEDECOD")
  expect_true("row_type" %in% names(ard))
  expect_true(all(c("any", "parent", "child") %in% ard$row_type))
})

# ── TTE ──

test_that("TTE produces KM median and HR", {
  grouping_tte <- grouping
  grouping_tte$include_total <- FALSE
  ard <- fct_ard_tte(adtte, adsl, grouping_tte, list(paramcd = "OS"))
  expect_true(any(grepl("Median", ard$stat_label)))
  expect_true(any(grepl("HR", ard$stat_label)))
  expect_true(any(grepl("P-value", ard$stat_label)))
})

# ── BDS ──

test_that("BDS lab results have timepoint column", {
  params <- unique(adlb$PARAMCD)[1:2]
  ard <- fct_ard_bds(adlb, adsl, grouping, list(paramcds = params, decimals = 1))
  expect_true("timepoint" %in% names(ard))
  expect_true(nrow(ard) > 0)
})

# ── Template Registry ──

test_that("template registry has all expected templates", {
  reg <- template_registry()
  expect_true(length(reg) >= 30)
  ids <- vapply(reg, function(t) t$id, character(1))
  expect_true("demog" %in% ids)
  expect_true("ae_socpt" %in% ids)
  expect_true("tte" %in% ids)
  expect_true("km_plot" %in% ids)
  expect_true("listing_ae" %in% ids)
})

test_that("get_template_def returns correct template", {
  def <- get_template_def("demog")
  expect_equal(def$name, "Demographics")
  expect_equal(def$category, "Study Information")
})

# ── Suggest Vars ──

test_that("suggest vars returns correct vars for templates", {
  vars <- fct_suggest_vars("demog", adsl)
  expect_true("AGE" %in% vars)
  expect_true("SEX" %in% vars)

  vars <- fct_suggest_vars("ae_socpt", adae)
  expect_true("AEBODSYS" %in% vars)
  expect_true("AEDECOD" %in% vars)
})

# ── Output Type ──

test_that("output type detection works", {
  expect_equal(fct_template_output_type("demog"), "table")
  expect_equal(fct_template_output_type("km_plot"), "figure")
  expect_equal(fct_template_output_type("listing_ae"), "listing")
})

# ── Format Functions ──

test_that("new format functions work", {
  expect_equal(fmt_km_median(12.5, 8.2, 18.3), "12.5 (8.2, 18.3)")
  expect_equal(fmt_km_median(NA, 8.2, NA), "NR (8.2, NE)")
  expect_equal(fmt_hr(0.75, 0.55, 1.02), "0.750 (0.550, 1.020)")
  expect_equal(fmt_response_rate(10, 50, 20, 10.5, 33.2), "10/50 (20.0%) [10.5, 33.2]")
  expect_equal(fmt_pval_full(0.0001, 3), "<0.001")
  expect_equal(fmt_pval_full(0.9999, 3), ">0.999")
  expect_equal(fmt_exposure_rate(10, 50), "20.0 per 100 PY")
})
