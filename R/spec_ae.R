# AE template specifications — defaults for AE Overall and AE by SOC/PT

spec_ae_overall <- function(data = NULL) {
  # All possible AE flag/category configs — keyed by CDISC column name
  # Includes both AESER and AESERI (some datasets use one or the other)
  all_ae_configs <- list(
    AESER = list(
      type = "categorical", cat_format = "npct", pct_dec = 1,
      label = "Serious Adverse Event",
      exclude_levels = "N",
      level_labels = list("Y" = "Serious AE (SAE)")
    ),
    AESERI = list(
      type = "categorical", cat_format = "npct", pct_dec = 1,
      label = "Serious Adverse Event",
      exclude_levels = "N",
      level_labels = list("Y" = "Serious AE (SAE)")
    ),
    AEREL = list(
      type = "categorical", cat_format = "npct", pct_dec = 1,
      label = "Relationship to Study Drug",
      exclude_levels = c("NOT RELATED", "NONE"),
      level_labels = list("RELATED" = "Related AE",
                          "POSSIBLE" = "Possibly Related",
                          "PROBABLE" = "Probably Related")
    ),
    AESDTH = list(
      type = "categorical", cat_format = "npct", pct_dec = 1,
      label = "AE Leading to Death",
      exclude_levels = "N",
      level_labels = list("Y" = "AE Leading to Death")
    ),
    AESEV = list(
      type = "categorical", cat_format = "npct", pct_dec = 1,
      label = "Maximum Severity"
    ),
    AEOUT = list(
      type = "categorical", cat_format = "npct", pct_dec = 1,
      label = "Outcome of Adverse Event"
    )
  )

  # Candidate columns in priority order (TRTEMFL is a filter, not an analysis var)
  candidate_cols <- c("AESER", "AESERI", "AEREL", "AESDTH", "AESEV", "AEOUT")

  # Filter to columns that exist in data (prefer AESER over AESERI)
  if (!is.null(data)) {
    available <- intersect(candidate_cols, names(data))
    # If both AESER and AESERI exist, drop AESERI
    if ("AESER" %in% available && "AESERI" %in% available) {
      available <- setdiff(available, "AESERI")
    }
  } else {
    available <- c("AESER", "AEREL", "AESDTH", "AESEV", "AEOUT")
  }

  # Build configs only for available columns
  ae_configs <- all_ae_configs[available]

  # Populate levels from data
  if (!is.null(data)) {
    for (v in names(ae_configs)) {
      if (v %in% names(data)) {
        all_levels <- sort(unique(as.character(data[[v]][!is.na(data[[v]])])))
        excl <- ae_configs[[v]]$exclude_levels %||% character(0)
        ae_configs[[v]]$levels <- all_levels
        ae_configs[[v]]$visible_levels <- setdiff(all_levels, excl)
      }
    }
  }

  list(
    template = "ae_overall",
    grouping = list(
      trt_var = "TRT01A",
      include_total = TRUE,
      total_label = "Total",
      analysis_vars = available
    ),
    var_configs = ae_configs,
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
      AEBODSYS = list(type = "hierarchy", label = "System Organ Class", pct_dec = 1),
      AEDECOD = list(type = "hierarchy", label = "Preferred Term", pct_dec = 1),
      sort_order = "frequency",
      filter_flag = "TRTEMFL",
      include_overall = TRUE,
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
        col_gap = 4L
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
