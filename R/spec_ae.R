# AE template specifications — defaults for AE Overall and AE by SOC/PT

spec_ae_overall <- function(data = NULL) {
  list(
    template = "ae_overall",
    grouping = list(
      trt_var = "TRT01A",
      include_total = TRUE,
      total_label = "Total",
      analysis_vars = c("any_teae", "any_sae", "any_related", "any_death", "max_sev")
    ),
    var_configs = list(
      filter_flag = "TRTEMFL",
      flag_vars = c("any_teae", "any_sae", "any_related", "any_death"),
      severity_var = "max_sev"
    ),
    fmt = list(
      titles = list(
        list(text = "Table 14.3.1", bold = FALSE),
        list(text = "Overview of Adverse Events", bold = FALSE)
      ),
      footnotes = list(
        list(text = "TEAEs defined as AEs with onset on or after first dose of study drug."),
        list(text = "Related = Investigator-assessed relationship of Possible or Probable."),
        list(text = "Percentages based on N in column header.")
      ),
      title_defaults = list(align = "center", bold = FALSE),
      cols = list(
        stub_width = 3.2,
        default_align = "center",
        n_counts = TRUE,
        n_format = "{label}\\n(N={n})"
      ),
      page = list(
        orientation = "landscape",
        paper = "letter",
        font_family = "Courier New",
        font_size = 9,
        margins = c(1, 1, 1, 1),
        col_gap = 4L
      ),
      rules = list(
        hline_preset = "header",
        vline_preset = "none"
      ),
      rows = list(
        group_by = "category",
        group_label = "stat_label"
      ),
      styles = list(
        bold_teae = list(
          type = "row_match",
          col = "stat_label",
          value = "Any TEAE",
          bold = TRUE
        )
      )
    )
  )
}

spec_ae_socpt <- function(data = NULL) {
  list(
    template = "ae_socpt",
    grouping = list(
      trt_var = "TRT01A",
      include_total = TRUE,
      total_label = "Total",
      analysis_vars = c("AEBODSYS", "AEDECOD")
    ),
    var_configs = list(
      soc_var = "AEBODSYS",
      pt_var = "AEDECOD",
      sort_order = "frequency",
      filter_flag = "TRTEMFL",
      overall_label = "Subjects with at Least One TEAE"
    ),
    fmt = list(
      titles = list(
        list(text = "Table 14.3.1.3", bold = FALSE),
        list(text = "TEAEs by System Organ Class and Preferred Term", bold = FALSE)
      ),
      footnotes = list(
        list(text = "Subject counted once per SOC and PT."),
        list(text = "MedDRA version XX.X."),
        list(text = "Percentages based on N in column header.")
      ),
      title_defaults = list(align = "center", bold = FALSE),
      cols = list(
        stub_width = 3.5,
        stub_col = "pt",
        default_align = "center",
        n_counts = TRUE,
        n_format = "{label}\\n(N={n})",
        per_col = list(
          pt = list(label = "System Organ Class\n  Preferred Term")
        )
      ),
      page = list(
        orientation = "landscape",
        paper = "letter",
        font_family = "Courier New",
        font_size = 9,
        margins = c(1, 1, 1, 1),
        col_gap = 4L,
        continuation = "(continued)"
      ),
      rules = list(
        hline_preset = "header",
        vline_preset = "none"
      ),
      rows = list(
        group_by = "soc",
        indent_by = "pt"
      ),
      styles = list(
        bold_soc = list(
          type = "row_match",
          col = "row_type",
          value = "soc",
          bold = TRUE
        ),
        bold_overall = list(
          type = "row_match",
          col = "row_type",
          value = "overall",
          bold = TRUE
        )
      )
    )
  )
}
