# Concomitant Medications template specification — Table 14.1.9

spec_conmed <- function(data = NULL) {
  list(
    template = "concomitant_meds",
    grouping = list(trt_var = "TRT01P", include_total = TRUE,
                    analysis_vars = c("CMCLAS", "CMDECOD")),
    var_configs = list(
      .parent_var = "CMCLAS",
      .child_var = "CMDECOD"
    ),
    fmt = list(
      titles = list(
        list(text = "Table 14.1.9", bold = TRUE),
        list(text = "Concomitant Medications by Class and Preferred Name", bold = FALSE)
      ),
      footnotes = list(
        list(text = "ATC class. Subjects counted once per class and medication name."),
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
