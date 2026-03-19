# Continuous Efficacy ARD builder — pure R, no Shiny
# Tables 14.2.3.1-5: Baseline, post-baseline by visit, change from baseline

fct_ard_efficacy_cont <- function(adeff, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  paramcd <- var_configs$paramcd %||% unique(adeff[["PARAMCD"]])[1]

  stopifnot("Data required" = !is.null(adeff))
  stopifnot("Must have PARAMCD" = "PARAMCD" %in% names(adeff))
  stopifnot("Must have AVAL" = "AVAL" %in% names(adeff))

  # Filter to parameter
  eff_data <- adeff[adeff[["PARAMCD"]] == paramcd, ]

  # Merge treatment if needed
  if (!trt_var %in% names(eff_data)) {
    eff_data <- dplyr::inner_join(eff_data, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")
  dec <- var_configs$decimals %||% 1

  param_label <- if ("PARAM" %in% names(eff_data) && nrow(eff_data) > 0) {
    eff_data[["PARAM"]][1]
  } else paramcd

  ard_rows <- list()

  # Helper: summarize continuous stats for a subset
  summarize_group <- function(x, dec) {
    x <- stats::na.omit(x)
    n <- length(x)
    list(
      n = fmt_count(n),
      mean_sd = if (n > 0) fmt_mean_sd(mean(x), stats::sd(x), dec) else "",
      median = if (n > 0) fmt_median_only(stats::median(x), dec) else "",
      q1_q3 = if (n > 0) fmt_q1_q3(stats::quantile(x, 0.25), stats::quantile(x, 0.75), dec) else "",
      min_max = if (n > 0) fmt_min_max(min(x), max(x), dec) else ""
    )
  }

  # Baseline statistics
  baseline_flag <- if ("ABLFL" %in% names(eff_data)) "ABLFL" else NULL
  if (!is.null(baseline_flag)) {
    bl_data <- eff_data[eff_data[[baseline_flag]] == "Y", ]
  } else {
    bl_data <- eff_data[0, ]
  }

  if (nrow(bl_data) > 0) {
    for (stat in c("n", "mean_sd", "median", "q1_q3", "min_max")) {
      row_data <- list(variable = paramcd, var_label = paste0(param_label, " - Baseline"),
                       var_type = "continuous",
                       stat_label = paste0("  ", switch(stat,
                         n = "n", mean_sd = "Mean (SD)", median = "Median",
                         q1_q3 = "Q1, Q3", min_max = "Min, Max")))
      for (grp in groups) {
        subset <- if (grp == "Total") bl_data else bl_data[bl_data[[trt_var]] == grp, ]
        vals <- summarize_group(subset[["AVAL"]], dec)
        row_data[[grp]] <- vals[[stat]]
      }
      ard_rows <- c(ard_rows, list(row_data))
    }
  }

  # Post-baseline by visit (change from baseline)
  if ("CHG" %in% names(eff_data) && "AVISIT" %in% names(eff_data)) {
    post_data <- eff_data[!is.na(eff_data[["CHG"]]), ]
    if (!is.null(baseline_flag)) {
      post_data <- post_data[is.na(post_data[[baseline_flag]]) | post_data[[baseline_flag]] != "Y", ]
    }

    visits <- unique(stats::na.omit(post_data[["AVISIT"]]))
    # Sort visits — try numeric extraction
    visit_nums <- suppressWarnings(as.numeric(gsub("[^0-9]", "", visits)))
    visits <- visits[order(visit_nums, na.last = TRUE)]

    for (visit in visits) {
      visit_data <- post_data[post_data[["AVISIT"]] == visit, ]

      for (stat in c("n", "mean_sd", "median")) {
        row_data <- list(
          variable = paramcd,
          var_label = paste0(param_label, " - ", visit, " (CFB)"),
          var_type = "continuous", timepoint = visit,
          stat_label = paste0("  ", switch(stat,
            n = "n", mean_sd = "Mean (SD)", median = "Median")))
        for (grp in groups) {
          subset <- if (grp == "Total") visit_data else visit_data[visit_data[[trt_var]] == grp, ]
          vals <- summarize_group(subset[["CHG"]], dec)
          row_data[[grp]] <- vals[[stat]]
        }
        ard_rows <- c(ard_rows, list(row_data))
      }
    }
  }

  dplyr::bind_rows(ard_rows)
}
