# Analysis Populations template specification — Table 14.1.2

spec_populations <- function(data = NULL) {
  default_vars <- c("SAFFL", "ITTFL", "EFFFL", "FASFL", "PPROTFL")
  avail_vars <- if (!is.null(data)) intersect(default_vars, names(data)) else default_vars

  var_configs <- list()
  for (v in avail_vars) {
    var_configs[[v]] <- list(
      type = "categorical", cat_format = "npct",
      zero_style = "A", pct_dec = 1
    )
  }

  list(
    template = "populations",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = avail_vars),
    var_configs = var_configs,
    fmt = list(
      titles = list(
        list(text = "Table 14.1.2", bold = TRUE),
        list(text = "Summary of Analysis Populations", bold = FALSE)
      ),
      footnotes = list(list(text = "Percentages based on randomized subjects.")),
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
