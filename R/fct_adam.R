# ADaM detection utilities — pure R, no Shiny

fct_detect_pop_flags <- function(cols) {
  flags <- c("SAFFL", "ITTFL", "EFFFL", "FASFL", "PPROTFL",
             "COMP8FL", "COMP16FL", "COMP24FL")
  intersect(flags, cols)
}

fct_detect_trt_vars <- function(cols) {
  trt_pattern <- "^(TRT|ARM|ACTARM)"
  trt_cols <- grep(trt_pattern, cols, value = TRUE)
  # Prefer planned treatment character vars (not N suffixed)
  trt_cols <- grep("N$", trt_cols, value = TRUE, invert = TRUE)
  trt_cols
}

fct_detect_var_type <- function(data, var) {
  x <- data[[var]]
  if (is.numeric(x)) return("continuous")
  if (is.factor(x) || is.character(x)) return("categorical")
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return("date")
  "categorical"
}

fct_get_var_label <- function(data, var) {
  lbl <- attr(data[[var]], "label")
  if (is.null(lbl) || !nzchar(lbl)) return(var)
  lbl
}

fct_detect_grouping_vars <- function(data) {
  cols <- names(data)

  # Treatment: TRT*, ARM, ACTARM (exclude N-suffixed numerics)
  trt <- grep("^(TRT[0-9]|ARM$|ACTARM$)", cols, value = TRUE)
  trt <- grep("N$", trt, value = TRUE, invert = TRUE)

  # Phase/Cohort/Dose/Sequence/Geography
  phase_cohort <- grep("^(PHASE|APHASE|COHORT|COHORTNM|COHGR|COHPGR|DOSGRP|DOSELVL|TRTSEQP|TRTSEQA|SITEGR|REGION)", cols, value = TRUE)
  phase_cohort <- grep("N$", phase_cohort, value = TRUE, invert = TRUE)

  # Custom: all other categorical with <50 unique values
  cat_cols <- cols[vapply(data, function(x) {
    if (!(is.character(x) || is.factor(x))) return(FALSE)
    nu <- length(get_unique_levels(x))
    nu > 1 && nu < 50
  }, logical(1))]
  exclude_patterns <- c("^USUBJID$", "^SUBJID$", "^STUDYID$", "DT$", "DTM$", "DTC$", "FL$", "FN$")
  exclude <- grep(paste(exclude_patterns, collapse = "|"), cat_cols, value = TRUE)
  custom <- setdiff(cat_cols, c(trt, phase_cohort, exclude))

  list(Treatment = trt, `Phase / Cohort` = phase_cohort, Custom = custom)
}

fct_detect_demog_vars <- function(data) {
  cols <- names(data)
  demog_candidates <- c("AGE", "AGEGR1", "SEX", "RACE", "ETHNIC",
                         "HEIGHTBL", "WEIGHTBL", "BMIBL", "BMIGR1",
                         "ECOGBL", "COUNTRY")
  intersect(demog_candidates, cols)
}
