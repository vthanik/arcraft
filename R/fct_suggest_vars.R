# Variable suggestions per template
# Returns candidate column names from the appropriate dataset

fct_suggest_vars <- function(template, data) {
  cols <- names(data)
  candidates <- switch(template,
    demog = c("AGE", "AGEGR1", "SEX", "RACE", "ETHNIC",
              "HEIGHTBL", "WEIGHTBL", "BMIBL", "BMIGR1",
              "ECOGBL", "COUNTRY"),
    ae_overall = c("AESER", "AEREL", "AESDTH", "AEACN", "AESEV",
                    "TRTEMFL", "AEOUT"),
    ae_socpt = c("AEBODSYS", "AEDECOD", "AEHLT", "AESOC",
                  "AELLT", "AEBODSYS"),
    ae_severity = c("AEBODSYS", "AEDECOD", "AESEV", "AETOXGR"),
    character(0)
  )
  intersect(unique(candidates), cols)
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
    lab_summary = "adlb",
    lab_shift = "adlb",
    tte_km = "adtte",
    listing_ae = "adae",
    listing_conmed = "adcm",
    "adsl"
  )
}
