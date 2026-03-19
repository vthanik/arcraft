# AE template specifications — factory for all AE variants

.ae_base_fmt <- function(table_num, title_text, pop = "Safety Analysis Set", src = "Source: ADSL, ADAE") {
  list(
    titles = list(list(text = table_num, bold = TRUE), list(text = title_text, bold = FALSE)),
    footnotes = list(
      list(text = "MedDRA preferred terms. Subjects counted once per SOC and PT."),
      list(text = "Percentages based on N in column header.")
    ),
    population = pop, source = src, title_align = "center",
    cols = list(stub_width = 3, body_align = "center", n_counts = TRUE, n_format = "(N={n})"),
    page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                font_size = 9, margins = c(1, 1, 1, 1), col_gap = 0.1),
    rules = list(hline_preset = "header", vline_preset = "none")
  )
}

spec_ae_summary <- function(data = NULL) {
  list(template = "ae_summary",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = c("AEBODSYS", "AEDECOD")),
    var_configs = list(), fmt = .ae_base_fmt("Table 14.3.1.2", "Overall Summary of Treatment-Emergent Adverse Events"))
}

spec_ae_socpt <- function(data = NULL) {
  list(template = "ae_socpt",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = c("AEBODSYS", "AEDECOD")),
    var_configs = list(), fmt = .ae_base_fmt("Table 14.3.1.3", "TEAEs by System Organ Class and Preferred Term"))
}

spec_ae_related <- function(data = NULL) {
  list(template = "ae_related",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = c("AEBODSYS", "AEDECOD")),
    var_configs = list(), fmt = .ae_base_fmt("Table 14.3.1.4", "Treatment-Related TEAEs by System Organ Class and Preferred Term"))
}

spec_ae_grade34 <- function(data = NULL) {
  list(template = "ae_grade34",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = c("AEBODSYS", "AEDECOD")),
    var_configs = list(), fmt = .ae_base_fmt("Table 14.3.1.5", "Grade 3 or Higher TEAEs by System Organ Class and Preferred Term"))
}

spec_ae_serious <- function(data = NULL) {
  list(template = "ae_serious",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = c("AEBODSYS", "AEDECOD")),
    var_configs = list(), fmt = .ae_base_fmt("Table 14.3.2.1", "Serious Adverse Events by System Organ Class and Preferred Term"))
}

spec_ae_fatal <- function(data = NULL) {
  list(template = "ae_fatal",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = c("AEBODSYS", "AEDECOD")),
    var_configs = list(), fmt = .ae_base_fmt("Table 14.3.2.3", "Fatal Adverse Events"))
}

spec_ae_by_severity <- function(data = NULL) {
  list(template = "ae_by_severity",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = c("AEBODSYS", "AEDECOD", "AESEV")),
    var_configs = list(),
    fmt = .ae_base_fmt("Table 14.3.1.6", "TEAEs by System Organ Class, Preferred Term and Maximum Severity"))
}

spec_ae_dose_reduced <- function(data = NULL) {
  list(template = "ae_dose_reduced",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = c("AEBODSYS", "AEDECOD")),
    var_configs = list(), fmt = .ae_base_fmt("Table 14.3.2.4", "TEAEs Leading to Dose Reduction"))
}

spec_ae_drug_withdrawn <- function(data = NULL) {
  list(template = "ae_drug_withdrawn",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = c("AEBODSYS", "AEDECOD")),
    var_configs = list(), fmt = .ae_base_fmt("Table 14.3.2.6", "TEAEs Leading to Treatment Discontinuation"))
}

spec_exposure <- function(data = NULL) {
  list(template = "exposure",
    grouping = list(trt_var = "TRT01P", include_total = TRUE, analysis_vars = c("AVAL")),
    var_configs = list(decimals = 1),
    fmt = list(
      titles = list(list(text = "Table 14.3.1.1", bold = TRUE),
                    list(text = "Summary of Treatment Exposure", bold = FALSE)),
      footnotes = list(list(text = "Duration in days.")),
      population = "Safety Analysis Set", source = "Source: ADSL, ADEX",
      title_align = "center",
      cols = list(stub_width = 2.5, body_align = "center", n_counts = TRUE, n_format = "(N={n})"),
      page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                  font_size = 9, margins = c(1, 1, 1, 1), col_gap = 0.1),
      rules = list(hline_preset = "header", vline_preset = "none")
    ))
}
