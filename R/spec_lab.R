# Lab/Vitals/ECG template specifications — factory pattern

spec_lab <- function(data = NULL) {
  list(
    template = "lab_results",
    grouping = list(trt_var = "TRT01P", include_total = TRUE,
                    analysis_vars = c("PARAMCD", "PARAM", "AVAL", "BASE", "CHG", "AVISIT")),
    var_configs = list(paramcds = NULL, decimals = 1),
    fmt = list(
      titles = list(list(text = "Table 14.3.4.1", bold = TRUE),
                    list(text = "Summary of Laboratory Results by Parameter and Visit", bold = FALSE)),
      footnotes = list(list(text = "Statistics: n, Mean (SD), Median, Q1-Q3, Min-Max.")),
      population = "Safety Analysis Set", source = "Source: ADSL, ADLB",
      title_align = "center",
      cols = list(stub_width = 2.5, body_align = "center", n_counts = TRUE, n_format = "(N={n})"),
      page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                  font_size = 8, margins = c(0.75, 0.75, 0.75, 0.75), col_gap = 0.1),
      rules = list(hline_preset = "header", vline_preset = "none")
    )
  )
}

spec_vitals <- function(data = NULL) {
  s <- spec_lab(data)
  s$template <- "vitals"
  s$fmt$titles <- list(
    list(text = "Table 14.3.5.1", bold = TRUE),
    list(text = "Summary of Vital Signs by Parameter and Visit", bold = FALSE)
  )
  s$fmt$source <- "Source: ADSL, ADVS"
  s
}

spec_shift <- function(data = NULL) {
  list(
    template = "lab_shift",
    grouping = list(trt_var = "TRT01P", include_total = TRUE,
                    analysis_vars = c("PARAMCD", "BTOXGR", "ATOXGR")),
    var_configs = list(paramcds = NULL),
    fmt = list(
      titles = list(list(text = "Table 14.3.4.2", bold = TRUE),
                    list(text = "CTCAE Grade Shift Table — Baseline to Worst Post-Baseline", bold = FALSE)),
      footnotes = list(
        list(text = "Shift table shows baseline CTCAE grade (rows) vs worst post-baseline grade (columns)."),
        list(text = "Counts represent number of subjects.")
      ),
      population = "Safety Analysis Set", source = "Source: ADSL, ADLB",
      title_align = "center",
      cols = list(stub_width = 2.5, body_align = "center", n_counts = TRUE, n_format = "(N={n})"),
      page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                  font_size = 9, margins = c(1, 1, 1, 1), col_gap = 0.1),
      rules = list(hline_preset = "all", vline_preset = "all")
    )
  )
}

spec_marked_abnorm <- function(data = NULL) {
  list(
    template = "marked_abnorm",
    grouping = list(trt_var = "TRT01P", include_total = TRUE,
                    analysis_vars = c("PARAMCD", "AVAL", "ANRHI", "ANRLO")),
    var_configs = list(paramcds = NULL),
    fmt = list(
      titles = list(list(text = "Table 14.3.4.5", bold = TRUE),
                    list(text = "Subjects with Marked Laboratory Abnormalities", bold = FALSE)),
      footnotes = list(
        list(text = "Marked High: AVAL > 2 × ULN. Marked Low: AVAL < 0.5 × LLN."),
        list(text = "Subjects counted once per parameter.")
      ),
      population = "Safety Analysis Set", source = "Source: ADSL, ADLB",
      title_align = "center",
      cols = list(stub_width = 3, body_align = "center", n_counts = TRUE, n_format = "(N={n})"),
      page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                  font_size = 9, margins = c(1, 1, 1, 1), col_gap = 0.1),
      rules = list(hline_preset = "header", vline_preset = "none")
    )
  )
}
