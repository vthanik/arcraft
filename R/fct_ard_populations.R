# Analysis Populations ARD builder — pure R, no Shiny
# Table 14.1.2: Analysis population counts by flag

fct_ard_populations <- function(adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  pop_flags <- grouping$analysis_vars

  stopifnot("Treatment var must exist" = trt_var %in% names(adsl))

  # If no analysis vars specified, detect all population flags

  if (length(pop_flags) == 0) {
    pop_flags <- fct_detect_pop_flags(names(adsl))
  }

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  # Randomized/enrolled N row
  ard_rows <- list()

  # N row
  vals <- vapply(groups, function(grp) {
    subset <- if (grp == "Total") adsl else adsl[adsl[[trt_var]] == grp, ]
    fmt_count(nrow(subset))
  }, character(1))
  ard_rows <- c(ard_rows, list(c(
    list(variable = "N", var_label = "Subjects", var_type = "header",
         stat_label = "  Randomized"),
    stats::setNames(as.list(vals), groups)
  )))

  # Each population flag
  flag_labels <- c(
    SAFFL = "Safety Analysis Set",
    ITTFL = "Intent-to-Treat Set",
    EFFFL = "Efficacy Analysis Set",
    FASFL = "Full Analysis Set",
    PPROTFL = "Per-Protocol Set",
    COMP8FL = "Completers (Week 8)",
    COMP16FL = "Completers (Week 16)",
    COMP24FL = "Completers (Week 24)"
  )

  for (fl in pop_flags) {
    if (!fl %in% names(adsl)) next
    label <- flag_labels[fl] %||% fl

    vals <- vapply(groups, function(grp) {
      subset <- if (grp == "Total") adsl else adsl[adsl[[trt_var]] == grp, ]
      n <- sum(subset[[fl]] == "Y", na.rm = TRUE)
      N <- nrow(subset)
      fmt_npct(n, N, "A", 1)
    }, character(1))

    ard_rows <- c(ard_rows, list(c(
      list(variable = fl, var_label = label, var_type = "categorical",
           stat_label = paste0("  ", label)),
      stats::setNames(as.list(vals), groups)
    )))
  }

  dplyr::bind_rows(ard_rows)
}
