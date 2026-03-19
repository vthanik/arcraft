# Disposition ARD builder — pure R, no Shiny
# Table 14.1.3: Subject disposition by treatment group

fct_ard_disposition <- function(adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE

  stopifnot("ADSL must have EOSSTT" = "EOSSTT" %in% names(adsl))
  stopifnot("Treatment var must exist" = trt_var %in% names(adsl))

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  ard_rows <- list()

  # 1. Completion status (COMPLETED / DISCONTINUED / ONGOING)
  statuses <- sort(unique(stats::na.omit(adsl[["EOSSTT"]])))
  for (status in statuses) {
    vals <- vapply(groups, function(grp) {
      subset <- if (grp == "Total") adsl else adsl[adsl[[trt_var]] == grp, ]
      n <- sum(subset[["EOSSTT"]] == status, na.rm = TRUE)
      N <- nrow(subset)
      fmt_npct(n, N, "A", 1)
    }, character(1))

    ard_rows <- c(ard_rows, list(c(
      list(variable = "EOSSTT", var_label = "End of Study Status",
           var_type = "categorical", stat_label = paste0("  ", status)),
      stats::setNames(as.list(vals), groups)
    )))
  }

  # 2. Discontinuation reasons (if DCREASCD exists)
  disc_var <- if ("DCREASCD" %in% names(adsl)) "DCREASCD"
              else if ("DCSREAS" %in% names(adsl)) "DCSREAS"
              else NULL

  if (!is.null(disc_var)) {
    disc_data <- adsl[!is.na(adsl[["EOSSTT"]]) & adsl[["EOSSTT"]] == "DISCONTINUED", ]

    if (nrow(disc_data) > 0) {
      reasons <- sort(unique(stats::na.omit(disc_data[[disc_var]])))

      for (reason in reasons) {
        vals <- vapply(groups, function(grp) {
          subset <- if (grp == "Total") disc_data else disc_data[disc_data[[trt_var]] == grp, ]
          n <- sum(subset[[disc_var]] == reason, na.rm = TRUE)
          N <- if (grp == "Total") nrow(adsl) else sum(adsl[[trt_var]] == grp)
          fmt_npct(n, N, "A", 1)
        }, character(1))

        ard_rows <- c(ard_rows, list(c(
          list(variable = disc_var, var_label = "Reason for Discontinuation",
               var_type = "categorical", stat_label = paste0("    ", reason)),
          stats::setNames(as.list(vals), groups)
        )))
      }
    }
  }

  dplyr::bind_rows(ard_rows)
}
