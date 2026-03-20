# Statistical format functions for clinical tables

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
  format(round(pct, dec), nsmall = dec)
}

fmt_pct_value <- function(pct, dec = 1, style = "A") {
  if (pct == 0) {
    if (style == "A") return("0") else return(format(0, nsmall = dec))
  }
  if (pct == 100) {
    if (style == "A") return("100") else return(format(100, nsmall = dec))
  }
  if (pct > 0 && pct < (10^(-dec))) return(paste0("<", format(10^(-dec), nsmall = dec)))
  if (pct > (100 - 10^(-dec)) && pct < 100) return(paste0(">", format(100 - 10^(-dec), nsmall = dec)))
  format(round(pct, dec), nsmall = dec)
}

fmt_mean_sd <- function(mean_val, sd_val, dec = 1, mean_dec = NULL, sd_dec = NULL) {
  md <- mean_dec %||% dec
  sd <- sd_dec %||% dec
  m <- format(round(mean_val, md), nsmall = md)
  s <- format(round(sd_val, sd), nsmall = sd)
  paste0(m, " (", s, ")")
}

fmt_median_only <- function(med, dec = 1) {
  format(round(med, dec), nsmall = dec)
}

fmt_median_range <- function(med, min_val, max_val, dec = 1) {
  m <- format(round(med, dec), nsmall = dec)
  lo <- format(round(min_val, dec), nsmall = dec)
  hi <- format(round(max_val, dec), nsmall = dec)
  paste0(m, " (", lo, ", ", hi, ")")
}

fmt_min_max <- function(min_val, max_val, dec = 1, min_dec = NULL, max_dec = NULL) {
  md <- min_dec %||% dec
  xd <- max_dec %||% dec
  lo <- format(round(min_val, md), nsmall = md)
  hi <- format(round(max_val, xd), nsmall = xd)
  paste0(lo, ", ", hi)
}

fmt_q1_q3 <- function(q1, q3, dec = 1, q1_dec = NULL, q3_dec = NULL) {
  qd1 <- q1_dec %||% dec
  qd3 <- q3_dec %||% dec
  a <- format(round(q1, qd1), nsmall = qd1)
  b <- format(round(q3, qd3), nsmall = qd3)
  paste0(a, ", ", b)
}

fmt_pval <- function(p, dec = 3) {
  if (is.na(p)) return("")
  threshold <- 10^(-dec)
  if (p < threshold) return(paste0("<", format(threshold, nsmall = dec)))
  format(round(p, dec), nsmall = dec)
}

fmt_ci <- function(est, lo, hi, dec = 2) {
  e <- format(round(est, dec), nsmall = dec)
  l <- format(round(lo, dec), nsmall = dec)
  h <- format(round(hi, dec), nsmall = dec)
  paste0(e, " (", l, ", ", h, ")")
}

fmt_geo_mean_cv <- function(geo_mean, cv_pct, dec = 2, gm_dec = NULL, cv_dec = NULL) {
  gd <- gm_dec %||% dec
  cd <- cv_dec %||% 1
  gm <- format(round(geo_mean, gd), nsmall = gd)
  cv <- format(round(cv_pct, cd), nsmall = cd)
  paste0(gm, " (", cv, "%)")
}

# ── KM / Survival formats ──

fmt_km_median <- function(median, ci_lo, ci_hi, dec = 1) {
  m <- if (is.na(median) || is.null(median)) "NR" else format(round(median, dec), nsmall = dec)
  lo <- if (is.na(ci_lo) || is.null(ci_lo)) "NE" else format(round(ci_lo, dec), nsmall = dec)
  hi <- if (is.na(ci_hi) || is.null(ci_hi)) "NE" else format(round(ci_hi, dec), nsmall = dec)
  paste0(m, " (", lo, ", ", hi, ")")
}

fmt_event_free_rate <- function(rate, se, dec = 1) {
  r <- if (is.na(rate)) "NE" else format(round(rate * 100, dec), nsmall = dec)
  s <- if (is.na(se)) "" else paste0(" (", format(round(se * 100, dec), nsmall = dec), ")")
  paste0(r, s)
}

# ── HR / OR / Risk formats ──

fmt_hr <- function(hr, ci_lo, ci_hi, dec = 3) {
  h <- format(round(hr, dec), nsmall = dec)
  lo <- format(round(ci_lo, dec), nsmall = dec)
  hi <- format(round(ci_hi, dec), nsmall = dec)
  paste0(h, " (", lo, ", ", hi, ")")
}

fmt_odds_ratio <- function(or_val, ci_lo, ci_hi, dec = 2) {
  o <- format(round(or_val, dec), nsmall = dec)
  lo <- format(round(ci_lo, dec), nsmall = dec)
  hi <- format(round(ci_hi, dec), nsmall = dec)
  paste0(o, " (", lo, ", ", hi, ")")
}

fmt_risk_diff <- function(diff, ci_lo, ci_hi, dec = 1) {
  d <- format(round(diff, dec), nsmall = dec)
  lo <- format(round(ci_lo, dec), nsmall = dec)
  hi <- format(round(ci_hi, dec), nsmall = dec)
  paste0(d, " (", lo, ", ", hi, ")")
}

# ── Response formats ──

fmt_response_rate <- function(n, N, pct, ci_lo, ci_hi, dec = 1) {
  if (N == 0) return("0/0")
  p <- format(round(pct, dec), nsmall = dec)
  lo <- if (is.na(ci_lo)) "NE" else format(round(ci_lo, dec), nsmall = dec)
  hi <- if (is.na(ci_hi)) "NE" else format(round(ci_hi, dec), nsmall = dec)
  paste0(n, "/", N, " (", p, "%) [", lo, ", ", hi, "]")
}

# ── LS Mean formats ──

fmt_lsmean_se <- function(lsmean, se, dec = 2) {
  m <- format(round(lsmean, dec), nsmall = dec)
  s <- format(round(se, dec), nsmall = dec)
  paste0(m, " (", s, ")")
}

fmt_lsmean_diff <- function(diff, ci_lo, ci_hi, dec = 2) {
  d <- format(round(diff, dec), nsmall = dec)
  lo <- format(round(ci_lo, dec), nsmall = dec)
  hi <- format(round(ci_hi, dec), nsmall = dec)
  paste0(d, " (", lo, ", ", hi, ")")
}

# ── PK formats ──

fmt_gmr_ci <- function(gmr, ci_lo, ci_hi, dec = 2) {
  g <- format(round(gmr, dec), nsmall = dec)
  lo <- format(round(ci_lo, dec), nsmall = dec)
  hi <- format(round(ci_hi, dec), nsmall = dec)
  paste0(g, " (", lo, ", ", hi, ")")
}

# ── Exposure formats ──

fmt_exposure_rate <- function(n_events, person_years, dec = 1) {
  if (is.na(person_years) || person_years == 0) return("NE")
  rate <- n_events / person_years * 100
  paste0(format(round(rate, dec), nsmall = dec), " per 100 PY")
}

# ── P-value with >0.999 handling ──

fmt_pval_full <- function(p, dec = 3) {
  if (is.na(p)) return("")
  threshold_lo <- 10^(-dec)
  threshold_hi <- 1 - 10^(-dec)
  if (p < threshold_lo) return(paste0("<", format(threshold_lo, nsmall = dec)))
  if (p > threshold_hi) return(paste0(">", format(threshold_hi, nsmall = dec)))
  format(round(p, dec), nsmall = dec)
}
