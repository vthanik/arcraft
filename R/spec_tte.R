# Time-to-Event template specification — Tables 14.2.1.1-4

spec_tte <- function(data = NULL) {
  list(
    template = "tte",
    grouping = list(trt_var = "TRT01P", include_total = FALSE,
                    analysis_vars = c("PARAMCD", "AVAL", "CNSR")),
    var_configs = list(paramcd = "OS", decimals = 1),
    fmt = list(
      titles = list(
        list(text = "Table 14.2.1", bold = TRUE),
        list(text = "Summary of Time-to-Event Analysis", bold = FALSE)
      ),
      footnotes = list(
        list(text = "KM estimate of median with 95% CI."),
        list(text = "Hazard ratio from Cox proportional hazards model."),
        list(text = "P-value from stratified log-rank test.")
      ),
      population = "Intent-to-Treat Analysis Set",
      source = "Source: ADSL, ADTTE",
      title_align = "center",
      cols = list(stub_width = 2.5, body_align = "center", n_counts = TRUE, n_format = "(N={n})"),
      page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                  font_size = 9, margins = c(1, 1, 1, 1), col_gap = 0.1),
      rules = list(hline_preset = "header", vline_preset = "none")
    )
  )
}
