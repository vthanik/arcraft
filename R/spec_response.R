# Response template specification — Tables 14.2.2.1-6

spec_response <- function(data = NULL) {
  list(
    template = "response",
    grouping = list(trt_var = "TRT01P", include_total = TRUE,
                    analysis_vars = c("PARAMCD", "AVALC")),
    var_configs = list(paramcd = "BOR", decimals = 1),
    fmt = list(
      titles = list(
        list(text = "Table 14.2.2", bold = TRUE),
        list(text = "Summary of Best Overall Response (RECIST v1.1)", bold = FALSE)
      ),
      footnotes = list(
        list(text = "ORR = CR + PR. CBR = CR + PR + SD."),
        list(text = "95% CI by Clopper-Pearson method."),
        list(text = "Percentages based on N in column header.")
      ),
      population = "Efficacy Analysis Set",
      source = "Source: ADSL, ADRS",
      title_align = "center",
      cols = list(stub_width = 3, body_align = "center", n_counts = TRUE, n_format = "(N={n})"),
      page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                  font_size = 9, margins = c(1, 1, 1, 1), col_gap = 0.1),
      rules = list(hline_preset = "header", vline_preset = "none")
    )
  )
}
