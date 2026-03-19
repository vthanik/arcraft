# Template-aware variable suggestions — pure R, no Shiny
# Returns candidate analysis variables based on template + available data columns

fct_suggest_vars <- function(template, data) {
  cols <- names(data)

  candidates <- switch(template,
    # Demographics — baseline characteristics
    demog = c("AGE", "AGEGR1", "SEX", "RACE", "ETHNIC",
              "HEIGHTBL", "WEIGHTBL", "BMIBL", "BMIGR1",
              "ECOGBL", "COUNTRY"),

    # Disposition
    disposition = c("EOSSTT", "DCSREAS", "DCREASCD", "DCSREASP",
                     "EOTSTT", "EOSSTT", "DCTREAS"),

    # Analysis populations
    populations = c("SAFFL", "ITTFL", "EFFFL", "FASFL", "PPROTFL",
                     "COMP8FL", "COMP16FL", "COMP24FL"),

    # Enrollment
    enrollment = c("SITEID", "COUNTRY", "REGION1"),

    # Site-by-Treatment
    site_trt = c("SITEID"),

    # Protocol violations
    protocol_violations = c("DVCAT", "DVTERM", "DVREAS"),

    # Medical history (ADCM or ADMH)
    medical_history = c("MHBODSYS", "MHDECOD", "MHTERM"),

    # Prior/concomitant meds
    prior_meds = c("CMCLAS", "CMDECOD", "CMTRT"),
    concomitant_meds = c("CMCLAS", "CMDECOD", "CMTRT"),

    # AE tables — all use ADAE columns
    ae_summary = c("AEBODSYS", "AEDECOD"),
    ae_socpt = c("AEBODSYS", "AEDECOD"),
    ae_related = c("AEBODSYS", "AEDECOD"),
    ae_grade34 = c("AEBODSYS", "AEDECOD"),
    ae_serious = c("AEBODSYS", "AEDECOD"),
    ae_fatal = c("AEBODSYS", "AEDECOD"),
    ae_dose_reduced = c("AEBODSYS", "AEDECOD"),
    ae_drug_interrupted = c("AEBODSYS", "AEDECOD"),
    ae_drug_withdrawn = c("AEBODSYS", "AEDECOD"),
    ae_by_severity = c("AEBODSYS", "AEDECOD", "AESEV", "AETOXGR"),
    ae_frequency = c("AEBODSYS", "AEDECOD"),

    # Exposure
    exposure = c("AVAL", "EXDOSE", "EXDUR", "PARAMCD"),

    # TTE — time-to-event
    tte = c("PARAMCD", "PARAM", "AVAL", "CNSR", "EVNTDESC"),

    # Response
    response = c("PARAMCD", "PARAM", "AVALC", "RSCAT"),

    # Continuous efficacy
    efficacy_cont = c("PARAMCD", "PARAM", "AVAL", "BASE", "CHG", "AVISIT"),

    # Lab results
    lab_results = c("PARAMCD", "PARAM", "AVAL", "BASE", "CHG", "AVISIT", "ANRIND"),
    vitals = c("PARAMCD", "PARAM", "AVAL", "BASE", "CHG", "AVISIT", "ANRIND"),
    ecg = c("PARAMCD", "PARAM", "AVAL", "BASE", "CHG", "AVISIT"),

    # Shift tables
    lab_shift = c("PARAMCD", "PARAM", "BTOXGR", "ATOXGR", "BNRIND", "ANRIND"),
    vitals_shift = c("PARAMCD", "PARAM", "BNRIND", "ANRIND"),
    ecg_shift = c("PARAMCD", "PARAM", "BNRIND", "ANRIND"),

    # Marked abnormalities
    marked_abnorm = c("PARAMCD", "PARAM", "AVAL", "ANRHI", "ANRLO", "R2ANRHI", "R2ANRLO"),

    # Default
    character(0)
  )

  intersect(candidates, cols)
}

# Get the template category for grouping in UI
fct_template_category <- function(template) {
  switch(template,
    demog =, disposition =, populations =, enrollment =,
    site_trt =, protocol_violations =, medical_history =,
    prior_meds =, concomitant_meds = "study_info",

    ae_summary =, ae_socpt =, ae_related =, ae_grade34 =,
    ae_serious =, ae_fatal =, ae_dose_reduced =,
    ae_drug_interrupted =, ae_drug_withdrawn =,
    ae_by_severity =, ae_frequency =, exposure = "safety",

    tte =, response =, efficacy_cont = "efficacy",

    lab_results =, vitals =, ecg =,
    lab_shift =, vitals_shift =, ecg_shift =,
    marked_abnorm = "lab_vitals",

    km_plot =, waterfall =, swimmer =,
    forest =, spider =, bar_chart = "figures",

    listing_discontinued =, listing_protocol_dev =,
    listing_demographics =, listing_compliance =,
    listing_ae =, listing_lab =, listing_custom = "listings",

    "other"
  )
}

# Get output type for a template
fct_template_output_type <- function(template) {
  if (template %in% c("km_plot", "waterfall", "swimmer", "forest", "spider", "bar_chart")) {
    return("figure")
  }
  if (grepl("^listing_", template)) {
    return("listing")
  }
  "table"
}

# Get required ADaM datasets for a template
fct_template_required_datasets <- function(template) {
  switch(template,
    demog =, disposition =, populations =, enrollment =,
    site_trt =, protocol_violations = "adsl",

    medical_history = c("adsl", "adcm"),
    prior_meds =, concomitant_meds = c("adsl", "adcm"),

    ae_summary =, ae_socpt =, ae_related =, ae_grade34 =,
    ae_serious =, ae_fatal =, ae_dose_reduced =,
    ae_drug_interrupted =, ae_drug_withdrawn =,
    ae_by_severity =, ae_frequency = c("adsl", "adae"),

    exposure = c("adsl", "adex"),

    tte = c("adsl", "adtte"),
    response = c("adsl", "adrs"),
    efficacy_cont = c("adsl", "adeff"),

    lab_results =, lab_shift =, marked_abnorm = c("adsl", "adlb"),
    vitals =, vitals_shift = c("adsl", "advs"),
    ecg =, ecg_shift = c("adsl", "adeg"),

    km_plot =, forest = c("adsl", "adtte"),
    waterfall = c("adsl", "adrs"),
    swimmer = c("adsl", "adtte", "adrs"),
    spider = c("adsl", "adtr"),

    listing_discontinued =, listing_protocol_dev =,
    listing_demographics = "adsl",
    listing_compliance = c("adsl", "adex"),
    listing_ae = c("adsl", "adae"),
    listing_lab = c("adsl", "adlb"),

    "adsl"
  )
}
