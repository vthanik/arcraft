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

# ── BDS Detection Helpers ──

#' Detect visit-like variable pairs from a BDS dataset
#' Looks for character/numeric pairs: AVISIT/AVISITN, ATPT/ATPTN, VISIT/VISITNUM
#' @return List of lists, each with char and num column names, ordered by priority
fct_detect_visit_pairs <- function(data) {
  cols <- names(data)

  # Priority-ordered candidate pairs
  candidates <- list(
    list(char = "AVISIT",  num = "AVISITN"),
    list(char = "ATPT",    num = "ATPTN"),
    list(char = "VISIT",   num = "VISITNUM"),
    list(char = "AVISIT1", num = "AVISIT1N"),
    list(char = "APHASE",  num = "APHASEN")
  )

  found <- list()
  for (pair in candidates) {
    if (pair$char %in% cols && pair$num %in% cols) {
      found <- c(found, list(pair))
    }
  }

  # Exclude known non-visit pairs that match *N pattern
  exclude_prefixes <- c("TRT", "PARAM", "ARM", "ACTARM", "STRAT", "PARCAT",
                         "AVALCAT", "BASECAT", "CHGCAT", "PCHGCAT", "SHIFT",
                         "CRIT", "MCRIT", "BTOXGR", "ATOXGR")

  # Also detect any custom *N pairs not in the candidate list
  char_cols <- cols[vapply(data, is.character, logical(1)) | vapply(data, is.factor, logical(1))]
  for (cc in char_cols) {
    # Skip known non-visit prefixes
    is_excluded <- any(vapply(exclude_prefixes, function(p) startsWith(cc, p), logical(1)))
    if (is_excluded) next

    num_name <- paste0(cc, "N")
    if (num_name %in% cols && is.numeric(data[[num_name]])) {
      already <- vapply(found, function(p) p$char, character(1))
      if (!cc %in% already) {
        found <- c(found, list(list(char = cc, num = num_name)))
      }
    }
  }

  found
}

#' Detect analysis columns available in a BDS dataset
#' Groups by type: continuous (AVAL, CHG, PCHG, BASE, R2BASE, BCHG, PBCHG)
#' and categorical (AVALC, AVALCATy, ANRIND, BNRIND, ATOXGR, BTOXGR, SHIFTy, CHGCATy)
#' @return List of lists, each with name, label, type, and default_selected
fct_detect_analysis_columns <- function(data) {
  cols <- names(data)

  # Continuous analysis columns (ordered by analysis priority)
  cont_candidates <- list(
    list(name = "AVAL",    label = "Analysis Value",              default = TRUE),
    list(name = "CHG",     label = "Change from Baseline",        default = TRUE),
    list(name = "PCHG",    label = "Percent Change from Baseline", default = FALSE),
    list(name = "BASE",    label = "Baseline Value",              default = FALSE),
    list(name = "R2BASE",  label = "Ratio to Baseline",           default = FALSE),
    list(name = "BCHG",    label = "Change to Baseline",          default = FALSE),
    list(name = "PBCHG",   label = "Percent Change to Baseline",  default = FALSE)
  )

  # Categorical analysis columns
  cat_candidates <- list(
    list(name = "AVALC",   label = "Analysis Value (Character)",  default = FALSE),
    list(name = "ANRIND",  label = "Reference Range Indicator",   default = FALSE),
    list(name = "BNRIND",  label = "Baseline Ref Range Indicator", default = FALSE),
    list(name = "ATOXGR",  label = "Analysis Toxicity Grade",     default = FALSE),
    list(name = "BTOXGR",  label = "Baseline Toxicity Grade",     default = FALSE)
  )

  result <- list()

  for (c in cont_candidates) {
    if (c$name %in% cols && is.numeric(data[[c$name]])) {
      lbl <- attr(data[[c$name]], "label")
      result <- c(result, list(list(
        name = c$name,
        label = if (!is.null(lbl) && nzchar(lbl)) lbl else c$label,
        type = "continuous",
        default_selected = c$default
      )))
    }
  }

  for (c in cat_candidates) {
    if (c$name %in% cols) {
      lbl <- attr(data[[c$name]], "label")
      result <- c(result, list(list(
        name = c$name,
        label = if (!is.null(lbl) && nzchar(lbl)) lbl else c$label,
        type = "categorical",
        default_selected = c$default
      )))
    }
  }

  # Detect AVALCATy pattern (AVALCAT1, AVALCAT2, ...)
  avalcat_cols <- grep("^AVALCAT[0-9]+$", cols, value = TRUE)
  for (ac in avalcat_cols) {
    lbl <- attr(data[[ac]], "label")
    result <- c(result, list(list(
      name = ac,
      label = if (!is.null(lbl) && nzchar(lbl)) lbl else paste0("Analysis Value Category ", sub("AVALCAT", "", ac)),
      type = "categorical",
      default_selected = FALSE
    )))
  }

  # Detect SHIFTy pattern (SHIFT1, SHIFT2, ...)
  shift_cols <- grep("^SHIFT[0-9]+$", cols, value = TRUE)
  for (sc in shift_cols) {
    lbl <- attr(data[[sc]], "label")
    result <- c(result, list(list(
      name = sc,
      label = if (!is.null(lbl) && nzchar(lbl)) lbl else paste0("Shift ", sub("SHIFT", "", sc)),
      type = "categorical",
      default_selected = FALSE
    )))
  }

  # Detect CHGCATy pattern (CHGCAT1, CHGCAT2, ...)
  chgcat_cols <- grep("^CHGCAT[0-9]+$", cols, value = TRUE)
  for (cc in chgcat_cols) {
    lbl <- attr(data[[cc]], "label")
    result <- c(result, list(list(
      name = cc,
      label = if (!is.null(lbl) && nzchar(lbl)) lbl else paste0("Change Category ", sub("CHGCAT", "", cc)),
      type = "categorical",
      default_selected = FALSE
    )))
  }

  result
}
