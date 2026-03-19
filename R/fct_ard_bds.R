# BDS (Basic Data Structure) ARD builder — pure R, no Shiny
# Tables 14.3.4.1, 14.3.5.1: Lab/Vitals/ECG results by parameter and visit

fct_ard_bds <- function(bds_data, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  dec <- var_configs$decimals %||% 1

  stopifnot("Data required" = !is.null(bds_data))
  stopifnot("Must have PARAMCD" = "PARAMCD" %in% names(bds_data))
  stopifnot("Must have AVAL" = "AVAL" %in% names(bds_data))

  # Filter to selected parameters if specified
  paramcds <- var_configs$paramcds %||% unique(bds_data[["PARAMCD"]])
  bds_data <- bds_data[bds_data[["PARAMCD"]] %in% paramcds, ]

  # Merge treatment if needed
  if (!trt_var %in% names(bds_data)) {
    bds_data <- dplyr::inner_join(bds_data, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  ard_rows <- list()
  stats_list <- c("n", "mean_sd", "median", "q1_q3", "min_max")

  for (pc in paramcds) {
    param_data <- bds_data[bds_data[["PARAMCD"]] == pc, ]
    if (nrow(param_data) == 0) next

    param_label <- if ("PARAM" %in% names(param_data)) param_data[["PARAM"]][1] else pc

    # Get visits
    if ("AVISIT" %in% names(param_data)) {
      visits <- unique(stats::na.omit(param_data[["AVISIT"]]))
      visit_nums <- suppressWarnings(as.numeric(gsub("[^0-9]", "", visits)))
      visits <- visits[order(visit_nums, na.last = TRUE)]
    } else {
      visits <- "Overall"
    }

    for (visit in visits) {
      if (visit == "Overall") {
        visit_data <- param_data
      } else {
        visit_data <- param_data[param_data[["AVISIT"]] == visit, ]
      }

      # AVAL stats
      for (stat in stats_list) {
        row_data <- list(
          variable = pc, var_label = param_label, var_type = "continuous",
          timepoint = visit,
          stat_label = paste0("  ", switch(stat,
            n = "n", mean_sd = "Mean (SD)", median = "Median",
            q1_q3 = "Q1, Q3", min_max = "Min, Max")))

        for (grp in groups) {
          subset <- if (grp == "Total") visit_data else visit_data[visit_data[[trt_var]] == grp, ]
          x <- stats::na.omit(subset[["AVAL"]])
          n <- length(x)

          row_data[[grp]] <- switch(stat,
            n = fmt_count(n),
            mean_sd = if (n > 0) fmt_mean_sd(mean(x), stats::sd(x), dec) else "",
            median = if (n > 0) fmt_median_only(stats::median(x), dec) else "",
            q1_q3 = if (n > 0) fmt_q1_q3(stats::quantile(x, 0.25), stats::quantile(x, 0.75), dec) else "",
            min_max = if (n > 0) fmt_min_max(min(x), max(x), dec) else "",
            ""
          )
        }
        ard_rows <- c(ard_rows, list(row_data))
      }

      # Change from baseline (if CHG column exists)
      if ("CHG" %in% names(visit_data)) {
        chg_data <- visit_data[!is.na(visit_data[["CHG"]]), ]
        if (nrow(chg_data) > 0) {
          for (stat in c("n", "mean_sd", "median")) {
            row_data <- list(
              variable = pc, var_label = paste0(param_label, " (CFB)"),
              var_type = "continuous", timepoint = visit,
              stat_label = paste0("  CFB ", switch(stat,
                n = "n", mean_sd = "Mean (SD)", median = "Median")))

            for (grp in groups) {
              subset <- if (grp == "Total") chg_data else chg_data[chg_data[[trt_var]] == grp, ]
              x <- stats::na.omit(subset[["CHG"]])
              n <- length(x)

              row_data[[grp]] <- switch(stat,
                n = fmt_count(n),
                mean_sd = if (n > 0) fmt_mean_sd(mean(x), stats::sd(x), dec) else "",
                median = if (n > 0) fmt_median_only(stats::median(x), dec) else "",
                ""
              )
            }
            ard_rows <- c(ard_rows, list(row_data))
          }
        }
      }
    }
  }

  dplyr::bind_rows(ard_rows)
}
