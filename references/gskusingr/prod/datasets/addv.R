####----------------------------------------------------------------------####
# Program Name: addv.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Mariam Alaverdyan / ma584118
# Purpose: Creation of the Protocol Deviation Analysis Dataset (ADDV)
#
# Input:
#   - SDTM: DV, SUPPDV
#   - ADaM: ADBS (external)
#
# Output:
#   - prod/adamdata/addv.parquet
#   - prod/submission/datasets/addv.xpt
#
# Spec: inputdata/300382_ADDV_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "tidyr", "purrr", "stringr", "lubridate",
  "admiral", "metacore", "metatools", "xportr",
  "readr", "readxl", "janitor"
)

metacore <- file.path(g_paths$inputdata, "300382_ADDV_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADDV") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================
# ADDV requires variables from ADBS (extended ADSL) which includes
# cohort groupings (COHAGR1, COHGL), phase, and dose level variables
# that are not present in standard ADSL.

adbs <- read_data_catalog(adamdata_ext$adbs) |>
  select(
    STUDYID, USUBJID, SUBJID, SITEID,
    AGE, AGEU, AGEGR1, AGEGR1N, SEX, RACE, COUNTRY,
    ARM, TRT01P, TRT01PN, TRT01A, TRT01AN,
    TRTSDT, TRTSDTM, TRTEDT, TRTEDTM,
    DOSGRP, DOSGRPN, DOSELVL, DOSELVLN,
    COHORT, COHORTN, COHAGR1, COHAGR1N, COHGL, COHGLN,
    PHASE, PHASEN,
    ENRLFL, SAFFL, EFFL
  ) |>
  mutate(
    TRTP  = TRT01P,
    TRTA  = TRT01A,
    TRTPN = TRT01PN,
    TRTAN = TRT01AN
  )

dv     <- read_data_catalog(sdtmdata$dv)
suppdv <- read_data_catalog(sdtmdata$suppdv)

# Merge SUPPDV to DV (handle case where SUPPDV may be empty)
dv_suppdv <- if (nrow(suppdv) > 0) {
  combine_supp(dv, suppdv)
} else {
  warning("SUPPDV is missing in SDTM")
  dv
}


# =============================================================================
# STEP 3: Merge DV with ADBS
# =============================================================================
# Merge subject-level variables from ADBS to provide demographics,
# treatment, population flags, and study-specific grouping variables.

dv0 <- derive_vars_merged(
  dv_suppdv,
  dataset_add = adbs,
  by_vars     = exprs(STUDYID, USUBJID)
) |>
  select(-any_of(c("DOMAIN", "EPOCH", "DVSTDY"))) |>
  mutate(DVSCAT = if_else(is.na(DVSCAT), "", paste(DVSCAT)))


# =============================================================================
# STEP 4: Derive Date/Time and Analysis Variables
# =============================================================================
# ASTDT: Analysis start date derived from DV start date (DVSTDTC)
# ASTDY: Analysis start relative day (relative to treatment start date)
# ASEQ:  Analysis sequence number within subject

addv1 <- dv0 |>
  # Derive analysis start date from DVSTDTC
  derive_vars_dt(
    dtc             = DVSTDTC,
    new_vars_prefix = "AST"
  ) |>
  # Derive analysis relative day
  derive_vars_dy(
    reference_date = TRTSDT,
    source_vars    = exprs(ASTDT)
  ) |>
  # Derive analysis sequence number
  derive_var_obs_number(
    by_vars    = exprs(USUBJID),
    order      = exprs(USUBJID, STUDYID, DVCAT, DVSCAT, DVTERM, ASTDT, DVSPID),
    new_var    = ASEQ,
    check_type = "error"
  ) |>
  mutate(
    # Clean up empty DVSCAT strings back to NA
    DVSCAT = if_else(DVSCAT == "", NA_character_, DVSCAT),
    ASEQ   = as.numeric(ASEQ)
  )


# =============================================================================
# STEP 5: Apply Metadata Labels and Export
# =============================================================================

addv1 |>
  save_adam(metacore, "ADDV")
