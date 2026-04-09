# Variable / parameter suggestions per template
#
# For demographics/AE templates: returns column names (intersected with names(data))
# For BDS/response templates: returns PARAMCDs (intersected with unique(data[["PARAMCD"]]))
# Use fct_suggests_paramcds() to distinguish which mode a template uses.

fct_suggest_vars <- function(template, data) {
  candidates <- switch(template,
    # Column-name templates (variable_stat, flag_summary, hierarchical)
    demog = c("AGE", "AGEGR1", "SEX", "RACE", "ETHNIC",
              "HEIGHTBL", "WEIGHTBL", "BMIBL", "BMIGR1",
              "ECOGBL", "COUNTRY"),
    ae_overall = c("AESER", "AESERI", "AEREL", "AESDTH", "AESEV", "AEOUT"),
    ae_socpt = c("AEBODSYS", "AEDECOD", "AEHLT", "AESOC", "AELLT"),
    ae_severity = c("AEBODSYS", "AEDECOD", "AESEV", "AETOXGR"),

    # PARAMCD templates (parameter_visit, response_summary)
    vitals_summary = c("SYSBP", "DIABP", "PULSE", "TEMP", "RESP", "WEIGHT"),
    lab_summary = c("ALT", "AST", "BILI", "CREAT", "ALB", "HGB", "WBC", "PLAT"),
    ecg_summary = c("QTCF", "QT", "HR", "PR", "QRS"),
    resp_summary = c("BOR", "CBOR", "OVRLRESP"),

    character(0)
  )

  if (fct_suggests_paramcds(template)) {
    # Intersect against PARAMCD values in data
    if (!is.null(data) && "PARAMCD" %in% names(data)) {
      available <- unique(as.character(data[["PARAMCD"]]))
      intersect(candidates, available)
    } else {
      candidates
    }
  } else {
    # Intersect against column names
    intersect(unique(candidates), names(data))
  }
}

# Returns TRUE if template uses PARAMCDs (not column names) for variable suggestions
fct_suggests_paramcds <- function(template) {
  if (is.null(template)) return(FALSE)
  template %in% c("vitals_summary", "lab_summary", "ecg_summary", "resp_summary")
}

# Get the primary dataset name for a template's variable list
fct_template_var_dataset <- function(template) {
  if (is.null(template)) return("adsl")
  switch(template,
    demog = "adsl",
    ae_overall = "adae",
    ae_socpt = "adae",
    ae_severity = "adae",
    disposition = "adsl",
    vitals_summary = "advs",
    lab_summary = "adlb",
    ecg_summary = "adeg",
    lab_shift = "adlb",
    resp_summary = "adrs",
    tte_km = "adtte",
    listing_ae = "adae",
    listing_conmed = "adcm",
    "adsl"
  )
}
