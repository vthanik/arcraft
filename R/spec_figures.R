# Figure template specifications

spec_km_plot <- function(data = NULL) {
  list(template = "km_plot",
    grouping = list(trt_var = "TRT01P", include_total = FALSE, analysis_vars = c("PARAMCD", "AVAL", "CNSR")),
    var_configs = list(paramcd = "OS"),
    fig_configs = list(show_ci = TRUE, show_risk_table = TRUE, show_censoring = TRUE, time_unit = "months"),
    fmt = list(
      titles = list(list(text = "Figure 14.2.1", bold = TRUE),
                    list(text = "Kaplan-Meier Curve for Overall Survival", bold = FALSE)),
      footnotes = list(list(text = "Shaded area: 95% confidence interval. + = censored.")),
      population = "Intent-to-Treat Analysis Set", source = "Source: ADSL, ADTTE",
      title_align = "center",
      page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                  font_size = 9, margins = c(1, 1, 1, 1)),
      rules = list()
    ))
}

spec_waterfall <- function(data = NULL) {
  list(template = "waterfall",
    grouping = list(trt_var = "TRT01P", include_total = FALSE, analysis_vars = c("PCHG", "AVALC")),
    var_configs = list(),
    fig_configs = list(threshold_lower = -30, threshold_upper = 20),
    fmt = list(
      titles = list(list(text = "Figure 14.2.2", bold = TRUE),
                    list(text = "Waterfall Plot of Best % Change from Baseline in Tumor Size", bold = FALSE)),
      footnotes = list(list(text = "Dashed lines at -30% (PR) and +20% (PD) per RECIST v1.1.")),
      population = "Efficacy Analysis Set", source = "Source: ADSL, ADRS",
      title_align = "center",
      page = list(orientation = "landscape", paper = "letter"),
      rules = list()
    ))
}

spec_forest <- function(data = NULL) {
  list(template = "forest",
    grouping = list(trt_var = "TRT01P", include_total = FALSE, analysis_vars = c("PARAMCD", "AVAL", "CNSR")),
    var_configs = list(paramcd = "OS"),
    fig_configs = list(subgroup_vars = c("SEX", "AGEGR1", "RACE"), scale = "log"),
    fmt = list(
      titles = list(list(text = "Figure 14.2.3", bold = TRUE),
                    list(text = "Forest Plot of Hazard Ratios by Subgroup", bold = FALSE)),
      footnotes = list(list(text = "HR from Cox PH model. Dashed line = HR of 1 (no effect).")),
      population = "Intent-to-Treat Analysis Set", source = "Source: ADSL, ADTTE",
      title_align = "center",
      page = list(orientation = "landscape", paper = "letter"),
      rules = list()
    ))
}

spec_swimmer <- function(data = NULL) {
  list(template = "swimmer",
    grouping = list(trt_var = "TRT01P", include_total = FALSE, analysis_vars = c("PARAMCD", "AVAL", "CNSR")),
    var_configs = list(paramcd = "OS"),
    fig_configs = list(max_subjects = 50, sort_by = "duration"),
    fmt = list(
      titles = list(list(text = "Figure 14.2.4", bold = TRUE),
                    list(text = "Swimmer Plot of Individual Subject Treatment Duration", bold = FALSE)),
      footnotes = list(list(text = "Triangle = ongoing (censored). Bars ordered by duration.")),
      population = "Efficacy Analysis Set", source = "Source: ADSL, ADTTE, ADRS",
      title_align = "center",
      page = list(orientation = "landscape", paper = "letter"),
      rules = list()
    ))
}
