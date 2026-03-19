# Time-to-Event ARD builder — pure R, no Shiny
# Tables 14.2.1.1-4: KM median, HR, log-rank p, event-free rates

fct_ard_tte <- function(adtte, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  paramcd <- var_configs$paramcd %||% "OS"

  stopifnot("ADTTE required" = !is.null(adtte))
  stopifnot("ADTTE must have PARAMCD" = "PARAMCD" %in% names(adtte))
  stopifnot("ADTTE must have AVAL" = "AVAL" %in% names(adtte))
  stopifnot("ADTTE must have CNSR" = "CNSR" %in% names(adtte))

  # Filter to selected parameter
  tte_data <- adtte[adtte[["PARAMCD"]] == paramcd, ]

  # Merge treatment if needed
  if (!trt_var %in% names(tte_data)) {
    tte_data <- dplyr::inner_join(tte_data, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  # Fit KM per group
  ard_rows <- list()

  # N, events, censored per group
  for (grp in groups) {
    subset <- if (grp == "Total") tte_data else tte_data[tte_data[[trt_var]] == grp, ]
    n <- nrow(subset)
    events <- sum(subset[["CNSR"]] == 0, na.rm = TRUE)
    censored <- sum(subset[["CNSR"]] == 1, na.rm = TRUE)

    ard_rows <- c(ard_rows, list(tibble::tibble(
      variable = paramcd, var_label = safe_label(adtte, "PARAM"),
      var_type = "tte", stat_label = "  N", !!grp := fmt_count(n)
    )))
    ard_rows <- c(ard_rows, list(tibble::tibble(
      variable = paramcd, var_label = safe_label(adtte, "PARAM"),
      var_type = "tte", stat_label = "  Events", !!grp := fmt_count(events)
    )))
    ard_rows <- c(ard_rows, list(tibble::tibble(
      variable = paramcd, var_label = safe_label(adtte, "PARAM"),
      var_type = "tte", stat_label = "  Censored", !!grp := fmt_count(censored)
    )))
  }

  # Combine all N/events/censored rows
  # Need to merge across groups — restructure
  stat_labels <- c("  N", "  Events", "  Censored")
  merged_rows <- list()

  for (sl in stat_labels) {
    row_data <- list(variable = paramcd,
                     var_label = if ("PARAM" %in% names(adtte)) adtte[["PARAM"]][adtte[["PARAMCD"]] == paramcd][1] else paramcd,
                     var_type = "tte", stat_label = sl)

    for (grp in groups) {
      subset <- if (grp == "Total") tte_data else tte_data[tte_data[[trt_var]] == grp, ]
      val <- switch(trimws(sl),
        N = fmt_count(nrow(subset)),
        Events = fmt_count(sum(subset[["CNSR"]] == 0, na.rm = TRUE)),
        Censored = fmt_count(sum(subset[["CNSR"]] == 1, na.rm = TRUE)),
        ""
      )
      row_data[[grp]] <- val
    }
    merged_rows <- c(merged_rows, list(row_data))
  }

  # KM median + 95% CI per group
  km_vals <- list()
  for (grp in groups) {
    subset <- if (grp == "Total") tte_data else tte_data[tte_data[[trt_var]] == grp, ]
    if (nrow(subset) > 0) {
      fit <- tryCatch(
        survival::survfit(survival::Surv(AVAL, 1 - CNSR) ~ 1, data = subset),
        error = function(e) NULL
      )
      if (!is.null(fit)) {
        med <- summary(fit)$table["median"]
        ci_lo <- summary(fit)$table["0.95LCL"]
        ci_hi <- summary(fit)$table["0.95UCL"]
        km_vals[[grp]] <- fmt_km_median(med, ci_lo, ci_hi)
      } else {
        km_vals[[grp]] <- "NE"
      }
    } else {
      km_vals[[grp]] <- "NE"
    }
  }

  km_row <- c(
    list(variable = paramcd, var_label = "KM Estimate", var_type = "tte",
         stat_label = "  Median (95% CI)"),
    km_vals
  )
  merged_rows <- c(merged_rows, list(km_row))

  # Hazard ratio (if 2+ treatment groups, not Total)
  if (length(trt_levels) >= 2 && nrow(tte_data) > 0) {
    tryCatch({
      cox_fit <- survival::coxph(
        survival::Surv(AVAL, 1 - CNSR) ~ factor(get(trt_var)),
        data = tte_data
      )
      cox_tidy <- broom::tidy(cox_fit, conf.int = TRUE, exponentiate = TRUE)
      if (nrow(cox_tidy) > 0) {
        hr <- cox_tidy$estimate[1]
        ci_lo <- cox_tidy$conf.low[1]
        ci_hi <- cox_tidy$conf.high[1]

        hr_row <- list(variable = paramcd, var_label = "Hazard Ratio",
                       var_type = "tte", stat_label = "  HR (95% CI)")
        for (grp in groups) hr_row[[grp]] <- ""
        hr_row[[groups[1]]] <- fmt_hr(hr, ci_lo, ci_hi)
        merged_rows <- c(merged_rows, list(hr_row))
      }
    }, error = function(e) NULL)

    # Log-rank p-value
    tryCatch({
      lr <- survival::survdiff(
        survival::Surv(AVAL, 1 - CNSR) ~ factor(get(trt_var)),
        data = tte_data
      )
      p <- 1 - stats::pchisq(lr$chisq, df = length(lr$n) - 1)

      p_row <- list(variable = paramcd, var_label = "Log-rank Test",
                     var_type = "tte", stat_label = "  P-value")
      for (grp in groups) p_row[[grp]] <- ""
      p_row[[groups[1]]] <- fmt_pval(p)
      merged_rows <- c(merged_rows, list(p_row))
    }, error = function(e) NULL)
  }

  dplyr::bind_rows(merged_rows)
}
