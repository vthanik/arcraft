# Exposure ARD builder — pure R, no Shiny
# Tables 14.3.1.1.1-4: Treatment exposure summary

fct_ard_exposure <- function(adex, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  analysis_vars <- grouping$analysis_vars

  stopifnot("Treatment var must exist in ADSL" = trt_var %in% names(adsl))

  # If ADEX has per-record data, summarize to subject level first
  if ("PARAMCD" %in% names(adex)) {
    # Use AVAL from ADEX for exposure duration
    if (length(analysis_vars) > 0 && "PARAMCD" %in% names(adex)) {
      paramcd_filter <- var_configs$paramcd %||% unique(adex[["PARAMCD"]])[1]
      adex <- adex[adex[["PARAMCD"]] == paramcd_filter, ]
    }
  }

  # Merge treatment from ADSL if needed
  if (!trt_var %in% names(adex)) {
    adex <- dplyr::inner_join(adex, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  # Determine the value variable
  val_var <- if ("AVAL" %in% names(adex)) "AVAL"
             else if ("EXDUR" %in% names(adex)) "EXDUR"
             else names(adex)[vapply(adex, is.numeric, logical(1))][1]

  label <- safe_label(adex, val_var)

  stats_list <- c("n", "mean_sd", "median", "q1_q3", "min_max")
  ard_rows <- list()

  for (stat in stats_list) {
    vals <- vapply(groups, function(grp) {
      subset <- if (grp == "Total") adex else adex[adex[[trt_var]] == grp, ]
      x <- stats::na.omit(subset[[val_var]])
      n <- length(x)
      dec <- var_configs$decimals %||% 1

      switch(stat,
        n = fmt_count(n),
        mean_sd = if (n > 0) fmt_mean_sd(mean(x), stats::sd(x), dec) else "",
        median = if (n > 0) fmt_median_only(stats::median(x), dec) else "",
        q1_q3 = if (n > 0) fmt_q1_q3(stats::quantile(x, 0.25), stats::quantile(x, 0.75), dec) else "",
        min_max = if (n > 0) fmt_min_max(min(x), max(x), dec) else "",
        ""
      )
    }, character(1))

    stat_label <- switch(stat,
      n = "n", mean_sd = "Mean (SD)", median = "Median",
      q1_q3 = "Q1, Q3", min_max = "Min, Max", stat
    )

    ard_rows <- c(ard_rows, list(c(
      list(variable = val_var, var_label = label, var_type = "continuous",
           stat_label = paste0("  ", stat_label)),
      stats::setNames(as.list(vals), groups)
    )))
  }

  # Duration categories (if applicable)
  if (!is.null(val_var) && val_var %in% names(adex)) {
    x_all <- stats::na.omit(adex[[val_var]])
    if (length(x_all) > 0) {
      breaks <- c(0, 30, 90, 180, 365, Inf)
      labels <- c("<1 month", "1-<3 months", "3-<6 months", "6-<12 months", ">=12 months")

      for (i in seq_along(labels)) {
        vals <- vapply(groups, function(grp) {
          subset <- if (grp == "Total") adex else adex[adex[[trt_var]] == grp, ]
          x <- stats::na.omit(subset[[val_var]])
          n <- sum(x >= breaks[i] & x < breaks[i + 1])
          N <- length(x)
          fmt_npct(n, N, "A", 1)
        }, character(1))

        ard_rows <- c(ard_rows, list(c(
          list(variable = "DURATION_CAT", var_label = "Duration Category",
               var_type = "categorical", stat_label = paste0("  ", labels[i])),
          stats::setNames(as.list(vals), groups)
        )))
      }
    }
  }

  dplyr::bind_rows(ard_rows)
}
