# Regression tests for bugs fixed during redesign

# ── Zero format: style A should show just "0", not "0 (0)" ──
test_that("zero format style A shows just 0", {
  expect_equal(fmt_npct(0, 100, "A", 1), "0")
  expect_equal(fmt_npct(0, 250, "A", 0), "0")
})

test_that("zero format style D shows 0 (0.0)", {
  expect_equal(fmt_npct(0, 100, "D", 1), "0 (0.0)")
  expect_equal(fmt_npct(0, 100, "D", 0), "0 (0)")
})

test_that("fmt_nn_pct zero style A shows just 0", {
  expect_equal(fmt_nn_pct(0, 100, "A", 1), "0")
})

# ── Categorical n row ──
test_that("categorical variables include n row", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  grp <- defaults$grouping
  grp$trt_levels <- sort(unique(adsl[[grp$trt_var]]))
  grp$include_total <- TRUE; grp$total_label <- "Total"
  grp$combined_groups <- list(); grp$by_var <- NULL

  ard <- fct_ard_dispatch("demog", list(adsl = adsl), grp, defaults$var_configs)

  for (v in c("AGEGR1", "SEX", "RACE", "ETHNIC")) {
    sub <- ard[ard$variable == v, ]
    expect_true(any(trimws(sub$stat_label) == "n"),
      info = paste(v, "should have an n row"))
  }
})

test_that("show_n = FALSE omits n row", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  grp <- defaults$grouping
  grp$trt_levels <- sort(unique(adsl[[grp$trt_var]]))
  grp$include_total <- TRUE; grp$total_label <- "Total"
  grp$combined_groups <- list(); grp$by_var <- NULL

  vc <- defaults$var_configs
  vc[["SEX"]]$show_n <- FALSE
  ard <- fct_ard_dispatch("demog", list(adsl = adsl), grp, vc)

  sex_rows <- ard[ard$variable == "SEX", ]
  expect_false(any(trimws(sex_rows$stat_label) == "n"))
})

# ── Per-stat decimal defaults ──
test_that("spec_demog uses per-stat decimals not scalar", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  decs <- defaults$var_configs[["AGE"]]$decimals
  expect_true(is.list(decs), "decimals should be a list, not scalar")
  expect_equal(decs$n, 0)
  expect_equal(decs$sd, 2)
  expect_equal(decs$min, 0)
  expect_equal(decs$max, 0)
})

# ── group_value column ──
test_that("group_value is first column when by_var is set", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  grp <- defaults$grouping
  grp$trt_levels <- sort(unique(adsl[[grp$trt_var]]))
  grp$include_total <- TRUE; grp$total_label <- "Total"
  grp$combined_groups <- list()
  grp$by_var <- "SEX"; grp$by_levels <- c("F", "M")

  ard <- fct_ard_dispatch("demog", list(adsl = adsl), grp, defaults$var_configs)
  expect_equal(names(ard)[1], "group_value")
  expect_equal(sort(unique(ard$group_value)), c("F", "M"))
})

test_that("group_value not present without by_var", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  grp <- defaults$grouping
  grp$trt_levels <- sort(unique(adsl[[grp$trt_var]]))
  grp$include_total <- TRUE; grp$total_label <- "Total"
  grp$combined_groups <- list(); grp$by_var <- NULL

  ard <- fct_ard_dispatch("demog", list(adsl = adsl), grp, defaults$var_configs)
  expect_false("group_value" %in% names(ard))
})

# ── IR ──
test_that("fct_build_ir returns all sections", {
  fmt <- normalize_fmt(list())
  ir <- fct_build_ir(fmt)
  expected <- c("cols", "titles", "footnotes", "header", "spans", "page",
                "rules", "rows", "pagehead", "pagefoot", "spacing",
                "styles", "output_format")
  expect_equal(sort(names(ir)), sort(expected))
})

# ── n_format stores literal backslash-n ──
test_that("n_format default has literal backslash-n, not newline", {
  fmt <- normalize_fmt(list())
  n_fmt <- fmt$cols$n_format
  expect_equal(nchar(n_fmt), 16)  # {label}\n(N={n}) = 16 chars with literal \n
  expect_true(grepl("\\\\n", n_fmt))  # contains literal \n
  expect_false(grepl("\n", n_fmt, fixed = TRUE))  # no actual newline
})

# ── Render validates column existence for fr_rows ──
test_that("render skips page_by for non-existent column", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  grp <- defaults$grouping
  grp$trt_levels <- sort(unique(adsl[[grp$trt_var]]))
  grp$include_total <- TRUE; grp$total_label <- "Total"
  grp$combined_groups <- list(); grp$by_var <- NULL

  ard <- fct_ard_dispatch("demog", list(adsl = adsl), grp, defaults$var_configs)
  fmt <- normalize_fmt(defaults$fmt)
  fmt$rows$page_by <- "group_value"  # doesn't exist in ARD without by_var

  # Should NOT error — render should skip the missing column
  expect_no_error({
    html <- fct_render_html_preview(ard, fmt)
  })
})

# ── Codegen skips page_by for non-existent column ──
test_that("codegen omits page_by when column not in ARD", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  grp <- defaults$grouping
  grp$trt_levels <- sort(unique(adsl[[grp$trt_var]]))
  grp$include_total <- TRUE; grp$total_label <- "Total"
  grp$combined_groups <- list(); grp$by_var <- NULL

  fmt <- normalize_fmt(defaults$fmt)
  fmt$rows$page_by <- "group_value"

  code <- fct_codegen_dispatch("demog", list(dataset = "adsl", pop_flag = "SAFFL"),
    grp, defaults$var_configs, fmt)
  expect_false(grepl("page_by", code))
})

# ── Codegen with group_value + page_by works ──
test_that("codegen includes page_by when group_value exists", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  grp <- defaults$grouping
  grp$trt_levels <- sort(unique(adsl[[grp$trt_var]]))
  grp$include_total <- TRUE; grp$total_label <- "Total"
  grp$combined_groups <- list()
  grp$by_var <- "SEX"; grp$by_levels <- c("F", "M")

  fmt <- normalize_fmt(defaults$fmt)
  fmt$rows$page_by <- "group_value"

  code <- fct_codegen_dispatch("demog", list(dataset = "adsl", pop_flag = "SAFFL"),
    grp, defaults$var_configs, fmt)
  expect_true(grepl("page_by.*group_value", code))
})

# ── Generated code runs without error ──
test_that("generated code executes without error (basic)", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  grp <- defaults$grouping
  grp$trt_levels <- sort(unique(adsl[[grp$trt_var]]))
  grp$include_total <- TRUE; grp$total_label <- "Total"
  grp$combined_groups <- list(); grp$by_var <- NULL

  fmt <- normalize_fmt(defaults$fmt)
  code <- fct_codegen_dispatch("demog", list(dataset = "adsl", pop_flag = "SAFFL"),
    grp, defaults$var_configs, fmt)

  # Fix path for test
  code <- sub('readRDS\\("data/adsl.rds"\\)',
    'readRDS(system.file("data", "adsl.rds", package = "arbuilder"))', code)

  tmp <- tempfile(fileext = ".R")
  writeLines(code, tmp)
  env <- new.env(parent = globalenv())
  expect_no_error(source(tmp, local = env))
  expect_true(exists("tbl_data", envir = env))
  expect_true(exists("tbl", envir = env))
})

test_that("generated code executes without error (group var)", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  grp <- defaults$grouping
  grp$trt_levels <- sort(unique(adsl[[grp$trt_var]]))
  grp$include_total <- TRUE; grp$total_label <- "Total"
  grp$combined_groups <- list()
  grp$by_var <- "SEX"; grp$by_levels <- c("F", "M")

  fmt <- normalize_fmt(defaults$fmt)
  fmt$rows$page_by <- "group_value"
  fmt$rows$group_by <- "var_label"

  code <- fct_codegen_dispatch("demog", list(dataset = "adsl", pop_flag = "SAFFL"),
    grp, defaults$var_configs, fmt)
  code <- sub('readRDS\\("data/adsl.rds"\\)',
    'readRDS(system.file("data", "adsl.rds", package = "arbuilder"))', code)

  tmp <- tempfile(fileext = ".R")
  writeLines(code, tmp)
  env <- new.env(parent = globalenv())
  expect_no_error(source(tmp, local = env))
  expect_true("group_value" %in% names(env$tbl_data))
})

# ── STAT_LABELS constant used correctly ──
test_that("STAT_LABELS has all expected keys", {
  expected <- c("n", "mean", "sd", "mean_sd", "median", "q1", "q3", "q1_q3",
                "min", "max", "min_max", "geo_mean", "cv", "geo_mean_cv")
  for (k in expected) {
    expect_true(k %in% names(STAT_LABELS), info = paste(k, "missing from STAT_LABELS"))
  }
})

# ── Default treatment variable ──
test_that("spec_demog defaults to TRT01A", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  expect_equal(defaults$grouping$trt_var, "TRT01A")
})

# ── Title not bold by default ──
test_that("spec_demog titles are not bold by default", {
  adsl_path <- system.file("data", "adsl.rds", package = "arbuilder"); skip_if_not(nzchar(adsl_path))
  adsl <- readRDS(adsl_path)
  defaults <- spec_demog(adsl)
  expect_false(defaults$fmt$titles[[1]]$bold)
  expect_false(defaults$fmt$titles[[2]]$bold)
})

# ── Filter validation helper ──
test_that("validate_filter_expr handles valid expression", {
  d <- data.frame(AGE = c(30, 50, 70), SEX = c("F", "M", "F"))
  result <- validate_filter_expr("AGE > 40", d, "rows")
  expect_true(grepl("2 of 3", as.character(result)))
})

test_that("validate_filter_expr handles invalid column with suggestion", {
  d <- data.frame(AGE = c(30, 50), SEX = c("F", "M"))
  result <- validate_filter_expr("AGEE > 40", d, "rows")
  result_text <- as.character(result)
  expect_true(grepl("not found", result_text))
  expect_true(grepl("AGE", result_text))  # should suggest AGE
})

test_that("validate_filter_expr handles NULL/empty", {
  d <- data.frame(x = 1:3)
  expect_null(validate_filter_expr(NULL, d))
  expect_null(validate_filter_expr("", d))
})

# ── resolve_newlines utility ──
test_that("resolve_newlines converts literal backslash-n", {
  expect_equal(resolve_newlines("hello\\nworld"), "hello\nworld")
  expect_equal(resolve_newlines("no change"), "no change")
  expect_null(resolve_newlines(NULL))
  expect_equal(resolve_newlines("a\\nb\\nc"), "a\nb\nc")
  expect_equal(resolve_newlines(42), 42)  # non-character passthrough
})
