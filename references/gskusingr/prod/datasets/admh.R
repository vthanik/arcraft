####----------------------------------------------------------------------####
# Program Name: admh.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Vignesh Thanikachalam / vt704670
# Purpose: Creation of the Medical History Analysis Dataset (ADMH)
#
# Input:
#   - SDTM: MH
#   - ADaM: ADSL, ADBS (external - for COHGL, COHAGR1, DOSELVL)
#
# Output:
#   - prod/adamdata/admh.parquet
#   - prod/submission/datasets/admh.xpt
#
# Spec: inputdata/300382_ADMH_Spec.xlsx
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

metacore <- file.path(g_paths$inputdata, "300382_ADMH_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADMH") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================
# Spec predecessor sources:
#   - MH domain (SDTM): MH.MHSEQ, MH.MHCAT, MH.MHTERM, MH.MHDECOD, etc.
#   - ADSL: AGE, AGEU, SEX, RACE, COUNTRY, ARM, TRT01P/A/PN/AN,
#           TRTSDT/M, TRTEDT/M, DOSGRP/N, ENRLFL, SAFFL, EFFL,
#           PHASE, PHASEN, COHORT, COHORTN
#   - ADBS (external): COHGL, COHGLN, COHAGR1, COHAGR1N, DOSELVL, DOSELVLN
#     (spec says ADSL but these only exist in ADBS in this study)

mh <- read_data_catalog(sdtmdata$mh) |>
  convert_blanks_to_na()

# Read ADSL for variables that exist in ADSL per spec
adsl <- read_data_catalog(adamdata$adsl) |>
  convert_blanks_to_na()

# Read ADBS for variables that only exist in ADBS (COHGL, COHAGR1, DOSELVL)
adbs <- read_data_catalog(adamdata_ext$adbs) |>
  select(USUBJID, COHGL, COHGLN, COHAGR1, COHAGR1N, DOSELVL, DOSELVLN)


# =============================================================================
# STEP 3: Merge MH with Subject-Level Variables
# =============================================================================
# Predecessor: ADSL.STUDYID, ADSL.USUBJID, ADSL.SUBJID, ADSL.SITEID,
#              ADSL.AGE, ADSL.AGEU, ADSL.AGEGR1, ADSL.AGEGR1N,
#              ADSL.SEX, ADSL.RACE, ADSL.COUNTRY, ADSL.ARM,
#              ADSL.TRT01P, ADSL.TRT01PN, ADSL.TRT01A, ADSL.TRT01AN,
#              ADSL.TRTSDT, ADSL.TRTSDTM, ADSL.TRTEDT, ADSL.TRTEDTM,
#              ADSL.DOSGRP, ADSL.DOSGRPN, ADSL.ENRLFL, ADSL.SAFFL, ADSL.EFFL,
#              ADSL.PHASE, ADSL.PHASEN, ADSL.COHORT, ADSL.COHORTN

adsl_vars <- exprs(
  STUDYID, USUBJID, SUBJID, SITEID,
  AGE, AGEU, AGEGR1, AGEGR1N, SEX, RACE, COUNTRY,
  ARM, TRT01P, TRT01PN, TRT01A, TRT01AN,
  TRTSDT, TRTSDTM, TRTEDT, TRTEDTM,
  DOSGRP, DOSGRPN,
  ENRLFL, SAFFL, EFFL,
  PHASE, PHASEN, COHORT, COHORTN
)

admh <- derive_vars_merged(
  mh,
  dataset_add = adsl,
  new_vars    = adsl_vars,
  by_vars     = exprs(STUDYID, USUBJID)
)

# Predecessor: ADBS.COHGL, ADBS.COHGLN, ADBS.COHAGR1, ADBS.COHAGR1N,
#              ADBS.DOSELVL, ADBS.DOSELVLN
admh <- left_join(admh, adbs, by = "USUBJID")


# =============================================================================
# STEP 4: Derive Analysis Start/End Dates
# =============================================================================
# MT.ADMH.ASTDT: "Derived as a numeric SAS date value from the date part
#                 of MH.MHSTDTC."
# MT.ADMH.AENDT: "Derived as a numeric SAS date value from the date part
#                 of MH.MHENDTC."

admh1 <- admh |>
  derive_vars_dt(
    dtc             = MHSTDTC,
    new_vars_prefix = "AST"
  ) |>
  derive_vars_dt(
    dtc             = MHENDTC,
    new_vars_prefix = "AEN"
  )


# =============================================================================
# STEP 5: Derive Analysis Relative Days
# =============================================================================
# Assigned: ADMH.ASTDY — Analysis Start Relative Day
# Assigned: ADMH.AENDY — Analysis End Relative Day
# Standard ADY logic: when ASTDT >= TRTSDT then ASTDT - TRTSDT + 1;
#                     when ASTDT <  TRTSDT then ASTDT - TRTSDT.

admh2 <- admh1 |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(ASTDT)) |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(AENDT))


# =============================================================================
# STEP 6: Derive Listing Date Labels and Treatment Variables
# =============================================================================
# MT.ADMH.ASTDT_L: "Derived from the date part of MH.MHSTDTC in
#                   character format."
# MT.ADMH.AENDT_L: "Derived from the date part of MH.MHENDTC in
#                   character format."
# Assigned: ADMH.TRTP  = TRT01P
# Assigned: ADMH.TRTA  = TRT01A
# Assigned: ADMH.TRTPN = TRT01PN
# Assigned: ADMH.TRTAN = TRT01AN

admh3 <- admh2 |>
  mutate(
    # Treatment variables (record-level from subject-level)
    TRTP  = TRT01P,
    TRTA  = TRT01A,
    TRTPN = TRT01PN,
    TRTAN = TRT01AN,

    # ASTDT_L: character date preserving partial date precision from MHSTDTC
    ASTDT_L = case_when(
      !is.na(MHSTDTC) & nchar(MHSTDTC) >= 10 ~
        toupper(format(as.Date(substr(MHSTDTC, 1, 10)), "%d%b%Y")),
      !is.na(MHSTDTC) & nchar(MHSTDTC) == 7 ~
        toupper(format(ym(MHSTDTC), "%b%Y")),
      !is.na(MHSTDTC) & nchar(MHSTDTC) == 4 ~
        MHSTDTC,
      .default = NA_character_
    ),

    # AENDT_L: character date preserving partial date precision from MHENDTC
    AENDT_L = case_when(
      !is.na(MHENDTC) & nchar(MHENDTC) >= 10 ~
        toupper(format(as.Date(substr(MHENDTC, 1, 10)), "%d%b%Y")),
      !is.na(MHENDTC) & nchar(MHENDTC) == 7 ~
        toupper(format(ym(MHENDTC), "%b%Y")),
      !is.na(MHENDTC) & nchar(MHENDTC) == 4 ~
        MHENDTC,
      .default = NA_character_
    )
  )


# =============================================================================
# STEP 7: Derive Analysis Sequence Number (ASEQ)
# =============================================================================
# MT.ADMH.ASEQ: "Sequential number identifying records within each USUBJID.
#                Sort by USUBJID and chronological order; assign ASEQ starting
#                at 1 and incrementing by 1 for each additional record."

admh4 <- admh3 |>
  derive_var_obs_number(
    by_vars    = exprs(STUDYID, USUBJID),
    order      = exprs(MHCAT, MHBODSYS, MHDECOD, ASTDT, MHSEQ),
    new_var    = ASEQ,
    check_type = "none"
  ) |>
  mutate(ASEQ = as.numeric(ASEQ))


# =============================================================================
# STEP 8: Apply Metadata Labels and Export
# =============================================================================

admh4 |>
  save_adam(metacore, "ADMH")
