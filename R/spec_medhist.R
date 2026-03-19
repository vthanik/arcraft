# Medical History template specification — Table 14.1.7

spec_medhist <- function(data = NULL) {
  list(
    template = "medical_history",
    grouping = list(trt_var = "TRT01P", include_total = TRUE,
                    analysis_vars = c("MHBODSYS", "MHDECOD")),
    var_configs = list(
      .parent_var = "MHBODSYS",
      .child_var = "MHDECOD"
    ),
    fmt = list(
      titles = list(
        list(text = "Table 14.1.7", bold = TRUE),
        list(text = "Medical History by System Organ Class and Preferred Term", bold = FALSE)
      ),
      footnotes = list(
        list(text = "MedDRA preferred terms. Subjects counted once per SOC and PT."),
        list(text = "Percentages based on N in column header.")
      ),
      population = "Safety Analysis Set",
      source = "Source: ADSL, ADCM",
      title_align = "center",
      cols = list(stub_width = 3, body_align = "center", n_counts = TRUE, n_format = "(N={n})"),
      page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                  font_size = 9, margins = c(1, 1, 1, 1), col_gap = 0.1),
      rules = list(hline_preset = "header", vline_preset = "none")
    )
  )
}
