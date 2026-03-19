# Protocol Violations template specification — Table 14.1.6

spec_protocol_violations <- function(data = NULL) {
  default_vars <- c("DVCAT", "DVTERM")
  avail_vars <- if (!is.null(data)) intersect(default_vars, names(data)) else default_vars
  if (length(avail_vars) == 0) avail_vars <- default_vars[1]

  var_configs <- list()
  for (v in avail_vars) {
    var_configs[[v]] <- list(
      type = "categorical", cat_format = "npct",
      zero_style = "A", pct_dec = 1,
      levels = if (!is.null(data) && v %in% names(data)) {
        sort(unique(stats::na.omit(data[[v]])))
      }
    )
  }

  list(
    template = "protocol_violations",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = avail_vars),
    var_configs = var_configs,
    fmt = list(
      titles = list(
        list(text = "Table 14.1.6", bold = TRUE),
        list(text = "Summary of Protocol Deviations", bold = FALSE)
      ),
      footnotes = list(list(text = "Percentages based on N in column header.")),
      population = "All Randomized Subjects",
      source = "Source: ADSL",
      title_align = "center",
      cols = list(stub_width = 2.5, body_align = "center", n_counts = TRUE, n_format = "(N={n})"),
      page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                  font_size = 9, margins = c(1, 1, 1, 1), col_gap = 0.1),
      rules = list(hline_preset = "header", vline_preset = "none")
    )
  )
}
