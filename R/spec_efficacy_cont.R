# Continuous Efficacy template specification — Tables 14.2.3.1-5

spec_efficacy_cont <- function(data = NULL) {
  list(
    template = "efficacy_cont",
    grouping = list(trt_var = "TRT01P", include_total = TRUE,
                    analysis_vars = c("PARAMCD", "AVAL", "BASE", "CHG", "AVISIT")),
    var_configs = list(paramcd = NULL, decimals = 1),
    fmt = list(
      titles = list(
        list(text = "Table 14.2.3", bold = TRUE),
        list(text = "Summary of Continuous Efficacy Endpoint", bold = FALSE)
      ),
      footnotes = list(
        list(text = "Change from baseline = post-baseline value minus baseline value."),
        list(text = "Percentages based on N in column header.")
      ),
      population = "Efficacy Analysis Set",
      source = "Source: ADSL, ADEFF",
      title_align = "center",
      cols = list(stub_width = 2.5, body_align = "center", n_counts = TRUE, n_format = "(N={n})"),
      page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                  font_size = 9, margins = c(1, 1, 1, 1), col_gap = 0.1),
      rules = list(hline_preset = "header", vline_preset = "none")
    )
  )
}
