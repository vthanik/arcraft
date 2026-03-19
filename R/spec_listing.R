# Listing template specifications — factory for all listing types

.listing_base_fmt <- function(table_num, title_text, src) {
  list(
    titles = list(list(text = table_num, bold = TRUE), list(text = title_text, bold = FALSE)),
    footnotes = list(),
    population = "Safety Analysis Set", source = src,
    title_align = "left",
    cols = list(stub_width = 1, body_align = "left", n_counts = FALSE),
    page = list(orientation = "landscape", paper = "letter", font_family = "Courier New",
                font_size = 8, margins = c(0.75, 0.75, 0.75, 0.75), col_gap = 0.05),
    rules = list(hline_preset = "header", vline_preset = "none")
  )
}

spec_listing_demographics <- function(data = NULL) {
  list(template = "listing_demographics",
    grouping = list(trt_var = "TRT01P", include_total = FALSE, analysis_vars = character(0)),
    var_configs = list(
      .listing_cols = c("USUBJID", "SITEID", "AGE", "SEX", "RACE", "ETHNIC", "TRT01P"),
      .sort_by = "USUBJID"
    ),
    fmt = .listing_base_fmt("Listing 16.2.4", "Listing of Demographics and Baseline Characteristics", "Source: ADSL"))
}

spec_listing_ae <- function(data = NULL) {
  list(template = "listing_ae",
    grouping = list(trt_var = "TRT01P", include_total = FALSE, analysis_vars = character(0)),
    var_configs = list(
      .listing_cols = c("USUBJID", "TRT01P", "AEBODSYS", "AEDECOD",
                         "AESTDTC", "AEENDTC", "AESEV", "AESER", "AEREL", "AEOUT"),
      .sort_by = c("USUBJID", "AESTDTC")
    ),
    fmt = .listing_base_fmt("Listing 16.2.7", "Listing of Adverse Events", "Source: ADSL, ADAE"))
}

spec_listing_lab <- function(data = NULL) {
  list(template = "listing_lab",
    grouping = list(trt_var = "TRT01P", include_total = FALSE, analysis_vars = character(0)),
    var_configs = list(
      .listing_cols = c("USUBJID", "TRT01P", "PARAMCD", "PARAM",
                         "AVISIT", "AVAL", "BASE", "CHG", "ANRIND"),
      .sort_by = c("USUBJID", "PARAMCD", "AVISIT")
    ),
    fmt = .listing_base_fmt("Listing 16.2.8", "Listing of Laboratory Results", "Source: ADSL, ADLB"))
}

spec_listing_discontinued <- function(data = NULL) {
  list(template = "listing_discontinued",
    grouping = list(trt_var = "TRT01P", include_total = FALSE, analysis_vars = character(0)),
    var_configs = list(
      .listing_cols = c("USUBJID", "SITEID", "AGE", "SEX", "TRT01P", "EOSSTT", "DCREASCD"),
      .sort_by = "USUBJID"
    ),
    fmt = .listing_base_fmt("Listing 16.2.1", "Listing of Discontinued Subjects", "Source: ADSL"))
}

spec_listing_custom <- function(data = NULL) {
  list(template = "listing_custom",
    grouping = list(trt_var = "TRT01P", include_total = FALSE, analysis_vars = character(0)),
    var_configs = list(.listing_cols = NULL, .sort_by = "USUBJID"),
    fmt = .listing_base_fmt("Listing 16.x", "Custom Data Listing", "Source: data"))
}
