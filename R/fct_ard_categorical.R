# Generic categorical ARD builder — reusable for simple count tables
# Used for: Enrollment (14.1.1), Site-by-Treatment (14.1.4), Protocol Violations (14.1.6)

fct_ard_categorical <- function(adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  analysis_vars <- grouping$analysis_vars

  stopifnot("Treatment var must exist" = trt_var %in% names(adsl))

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  ard_rows <- list()

  for (var in analysis_vars) {
    if (!var %in% names(adsl)) next

    config <- var_configs[[var]] %||% list()
    dec <- config$pct_dec %||% 1
    fmt_type <- config$cat_format %||% "npct"
    style <- config$zero_style %||% "A"
    label <- safe_label(adsl, var)

    levels_order <- if (!is.null(config$levels)) {
      config$levels
    } else if (is.factor(adsl[[var]])) {
      levels(adsl[[var]])
    } else {
      sort(unique(stats::na.omit(adsl[[var]])))
    }

    for (lev in levels_order) {
      vals <- vapply(groups, function(grp) {
        subset <- if (grp == "Total") adsl else adsl[adsl[[trt_var]] == grp, ]
        n <- sum(subset[[var]] == lev, na.rm = TRUE)
        N <- nrow(subset)
        switch(fmt_type,
          npct = fmt_npct(n, N, style, dec),
          n = fmt_count(n),
          nn_pct = fmt_nn_pct(n, N, style, dec),
          fmt_npct(n, N, style, dec)
        )
      }, character(1))

      ard_rows <- c(ard_rows, list(c(
        list(variable = var, var_label = label, var_type = "categorical",
             stat_label = paste0("  ", lev)),
        stats::setNames(as.list(vals), groups)
      )))
    }
  }

  dplyr::bind_rows(ard_rows)
}
