# Statistical format functions for clinical tables

# Helper: format a number with fixed decimals — no trailing dot when dec = 0
fmt_num <- function(x, dec) {
  formatC(round(x, dec), format = "f", digits = dec)
}

fmt_count <- function(n) {
  as.character(n)
}

fmt_npct <- function(n, N, style = "A", dec = 1) {
  if (N == 0) return("0")
  if (n == 0 && style == "A") return("0")
  pct <- n / N * 100
  pct_str <- fmt_pct_value(pct, dec, style)
  paste0(n, " (", pct_str, ")")
}

fmt_nn_pct <- function(n, N, style = "A", dec = 1) {
  if (N == 0) return("0/0")
  if (n == 0 && style == "A") return("0")
  pct <- n / N * 100
  pct_str <- fmt_pct_value(pct, dec, style)
  paste0(n, "/", N, " (", pct_str, ")")
}

fmt_pct_only <- function(n, N, dec = 1) {
  if (N == 0) return("")
  pct <- n / N * 100
  fmt_num(pct, dec)
}

fmt_pct_value <- function(pct, dec = 1, style = "A") {
  if (pct == 0) {
    if (style == "A") return("0") else return(fmt_num(0, dec))
  }
  if (pct == 100) {
    if (style == "A") return("100") else return(fmt_num(100, dec))
  }
  if (pct > 0 && pct < (10^(-dec))) return(paste0("<", fmt_num(10^(-dec), dec)))
  if (pct > (100 - 10^(-dec)) && pct < 100) return(paste0(">", fmt_num(100 - 10^(-dec), dec)))
  fmt_num(pct, dec)
}

fmt_mean_sd <- function(mean_val, sd_val, dec = 1, mean_dec = NULL, sd_dec = NULL) {
  md <- mean_dec %||% dec
  sd <- sd_dec %||% dec
  paste0(fmt_num(mean_val, md), " (", fmt_num(sd_val, sd), ")")
}

fmt_median_only <- function(med, dec = 1) {
  fmt_num(med, dec)
}

fmt_median_range <- function(med, min_val, max_val, dec = 1) {
  paste0(fmt_num(med, dec), " (", fmt_num(min_val, dec), ", ", fmt_num(max_val, dec), ")")
}

fmt_min_max <- function(min_val, max_val, dec = 1, min_dec = NULL, max_dec = NULL) {
  md <- min_dec %||% dec
  xd <- max_dec %||% dec
  paste0(fmt_num(min_val, md), ", ", fmt_num(max_val, xd))
}

fmt_q1_q3 <- function(q1, q3, dec = 1, q1_dec = NULL, q3_dec = NULL) {
  qd1 <- q1_dec %||% dec
  qd3 <- q3_dec %||% dec
  paste0(fmt_num(q1, qd1), ", ", fmt_num(q3, qd3))
}

fmt_pval <- function(p, dec = 3) {
  if (is.na(p)) return("")
  threshold <- 10^(-dec)
  if (p < threshold) return(paste0("<", fmt_num(threshold, dec)))
  fmt_num(p, dec)
}

fmt_ci <- function(est, lo, hi, dec = 2) {
  paste0(fmt_num(est, dec), " (", fmt_num(lo, dec), ", ", fmt_num(hi, dec), ")")
}

fmt_geo_mean_cv <- function(geo_mean, cv_pct, dec = 2, gm_dec = NULL, cv_dec = NULL) {
  gd <- gm_dec %||% dec
  cd <- cv_dec %||% 1
  paste0(fmt_num(geo_mean, gd), " (", fmt_num(cv_pct, cd), "%)")
}

# ── KM / Survival formats ──

fmt_km_median <- function(median, ci_lo, ci_hi, dec = 1) {
  m <- if (is.na(median) || is.null(median)) "NR" else fmt_num(median, dec)
  lo <- if (is.na(ci_lo) || is.null(ci_lo)) "NE" else fmt_num(ci_lo, dec)
  hi <- if (is.na(ci_hi) || is.null(ci_hi)) "NE" else fmt_num(ci_hi, dec)
  paste0(m, " (", lo, ", ", hi, ")")
}

fmt_event_free_rate <- function(rate, se, dec = 1) {
  r <- if (is.na(rate)) "NE" else fmt_num(rate * 100, dec)
  s <- if (is.na(se)) "" else paste0(" (", fmt_num(se * 100, dec), ")")
  paste0(r, s)
}

# ── HR / OR / Risk formats ──

fmt_hr <- function(hr, ci_lo, ci_hi, dec = 3) {
  paste0(fmt_num(hr, dec), " (", fmt_num(ci_lo, dec), ", ", fmt_num(ci_hi, dec), ")")
}

fmt_odds_ratio <- function(or_val, ci_lo, ci_hi, dec = 2) {
  paste0(fmt_num(or_val, dec), " (", fmt_num(ci_lo, dec), ", ", fmt_num(ci_hi, dec), ")")
}

fmt_risk_diff <- function(diff, ci_lo, ci_hi, dec = 1) {
  paste0(fmt_num(diff, dec), " (", fmt_num(ci_lo, dec), ", ", fmt_num(ci_hi, dec), ")")
}

# ── Response formats ──

fmt_response_rate <- function(n, N, pct, ci_lo, ci_hi, dec = 1) {
  if (N == 0) return("0/0")
  p <- fmt_num(pct, dec)
  lo <- if (is.na(ci_lo)) "NE" else fmt_num(ci_lo, dec)
  hi <- if (is.na(ci_hi)) "NE" else fmt_num(ci_hi, dec)
  paste0(n, "/", N, " (", p, "%) [", lo, ", ", hi, "]")
}

# ── LS Mean formats ──

fmt_lsmean_se <- function(lsmean, se, dec = 2) {
  paste0(fmt_num(lsmean, dec), " (", fmt_num(se, dec), ")")
}

fmt_lsmean_diff <- function(diff, ci_lo, ci_hi, dec = 2) {
  paste0(fmt_num(diff, dec), " (", fmt_num(ci_lo, dec), ", ", fmt_num(ci_hi, dec), ")")
}

# ── PK formats ──

fmt_gmr_ci <- function(gmr, ci_lo, ci_hi, dec = 2) {
  paste0(fmt_num(gmr, dec), " (", fmt_num(ci_lo, dec), ", ", fmt_num(ci_hi, dec), ")")
}

# ── Exposure formats ──

fmt_exposure_rate <- function(n_events, person_years, dec = 1) {
  if (is.na(person_years) || person_years == 0) return("NE")
  rate <- n_events / person_years * 100
  paste0(fmt_num(rate, dec), " per 100 PY")
}

# ── P-value with >0.999 handling ──

fmt_pval_full <- function(p, dec = 3) {
  if (is.na(p)) return("")
  threshold_lo <- 10^(-dec)
  threshold_hi <- 1 - 10^(-dec)
  if (p < threshold_lo) return(paste0("<", fmt_num(threshold_lo, dec)))
  if (p > threshold_hi) return(paste0(">", fmt_num(threshold_hi, dec)))
  fmt_num(p, dec)
}
