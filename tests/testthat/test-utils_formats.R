test_that("fmt_count returns character", {
  expect_equal(fmt_count(42), "42")
  expect_equal(fmt_count(0), "0")
})

test_that("fmt_npct handles basic cases", {
  result <- fmt_npct(10, 50, "A", 1)
  expect_match(result, "10 \\(20\\.0\\)")
})

test_that("fmt_npct handles zero", {
  expect_equal(fmt_npct(0, 50, "A", 1), "0")
  expect_equal(fmt_npct(0, 50, "D", 1), "0 (0.0)")
})

test_that("fmt_npct handles 100%", {
  expect_equal(fmt_npct(50, 50, "A", 1), "50 (100)")
})

test_that("fmt_npct handles N=0", {
  expect_equal(fmt_npct(0, 0, "A", 1), "0")
})

test_that("fmt_nn_pct works", {
  result <- fmt_nn_pct(10, 50, "A", 1)
  expect_match(result, "10/50")
  expect_match(result, "20\\.0")
})

test_that("fmt_mean_sd formats correctly", {
  result <- fmt_mean_sd(56.5, 12.3, 1)
  expect_equal(result, "56.5 (12.3)")
})

test_that("fmt_median_only formats correctly", {
  expect_equal(fmt_median_only(57.0, 1), "57.0")
  expect_equal(fmt_median_only(57.123, 2), "57.12")
})

test_that("fmt_min_max formats correctly", {
  result <- fmt_min_max(26, 83, 1)
  expect_equal(result, "26.0, 83.0")
})

test_that("fmt_q1_q3 formats correctly", {
  result <- fmt_q1_q3(47, 66, 1)
  expect_equal(result, "47.0, 66.0")
})

test_that("fmt_pval handles small values", {
  expect_equal(fmt_pval(0.0001, 3), "<0.001")
  expect_equal(fmt_pval(0.045, 3), "0.045")
  expect_equal(fmt_pval(NA, 3), "")
})

test_that("fmt_ci formats correctly", {
  result <- fmt_ci(1.5, 0.8, 2.2, 2)
  expect_match(result, "1\\.50")
  expect_match(result, "0\\.80.*2\\.20")
})

test_that("fmt_geo_mean_cv formats correctly", {
  result <- fmt_geo_mean_cv(10.5, 25.3, 2)
  expect_match(result, "10\\.50")
  expect_match(result, "25\\.3%")
})
