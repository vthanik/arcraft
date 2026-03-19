####----------------------------------------------------------------------####
# Program Name: advs.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: Creation of the Vital Signs Analysis Dataset (ADVS)
#
# Input:
#   - SDTM: VS
#   - ADaM: ADSL
#
# Output:
#   - prod/adamdata/advs.parquet
#   - prod/submission/datasets/advs.xpt
#
# Spec: inputdata/300382_ADVS_Spec.xlsx
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

metacore <- file.path(g_paths$inputdata, "300382_ADVS_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADVS") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Helper Functions for Blood Pressure Categories
# =============================================================================

format_avalcat <- function(x) {
  case_when(
    x == 1 ~ "<120",     x == 2 ~ "120-139",
    x == 3 ~ "140-159",  x == 4 ~ ">=160",
    x == 5 ~ "<80",      x == 6 ~ "80-89",
    x == 7 ~ "90-99",    x == 8 ~ ">=100",
    .default = NA_character_
  )
}

format_avalcatn <- function(x) {
  case_when(
    x == "<120"    ~ 1, x == "120-139" ~ 2,
    x == "140-159" ~ 3, x == ">=160"   ~ 4,
    x == "<80"     ~ 5, x == "80-89"   ~ 6,
    x == "90-99"   ~ 7, x == ">=100"   ~ 8
  )
}


# =============================================================================
# STEP 3: Load and Merge Input Datasets
# =============================================================================

adsl <- read_data_catalog(adamdata$adsl) |>
  convert_blanks_to_na()

vs <- read_data_catalog(sdtmdata$vs) |>
  convert_blanks_to_na()

adsl_vars <- exprs(TRTSDT, TRTEDT, TRTSDTM, TRTSTM, TRTEDTM, TRTETM, TRT01A, TRT01P)

advs <- derive_vars_merged(
  vs,
  dataset_add = adsl,
  new_vars    = adsl_vars,
  by_vars     = exprs(STUDYID, USUBJID)
)


# =============================================================================
# STEP 4: Derive Date/Time and Parameter Variables
# =============================================================================

advs1 <- advs |>
  derive_vars_dt(new_vars_prefix = "A", dtc = VSDTC) |>
  derive_vars_dtm(new_vars_prefix = "A", dtc = VSDTC, ignore_seconds_flag = TRUE) |>
  derive_vars_dtm_to_tm(exprs(ADTM)) |>
  mutate(
    ATM  = if_else(ATM == hms("00:00:00"), NA, ATM),
    ADTM = if_else(ATM == hms("00:00:00"), NA, ADTM),
    # Parameter mapping
    PARAM = case_when(
      VSTEST == "Vital Signs"              ~ "Vital Signs",
      VSTEST == "Respiratory Rate"          ~ "Respiratory Rate (breaths/min)",
      VSTEST == "Temperature"               ~ "Temperature (C)",
      VSTEST == "Weight"                    ~ "Weight (kg)",
      VSTEST == "Heart Rate"                ~ "Heart Rate (beats/min)",
      VSTEST == "Diastolic Blood Pressure"  ~ "Diastolic Blood Pressure (mmHg)",
      VSTEST == "Systolic Blood Pressure"   ~ "Systolic Blood Pressure (mmHg)",
      VSTEST == "Oxygen Saturation"         ~ "Oxygen Saturation (%)",
      is.na(VSSTRESU)                       ~ VSTEST,
      .default = paste0(VSTEST, " (", VSSTRESU, ")")
    ),
    PARAMCD = case_when(
      VSTEST == "Height"                   ~ "HEIGHT",
      VSTEST == "Weight"                   ~ "WEIGHT",
      VSTEST == "Temperature"              ~ "TEMP",
      VSTEST == "Systolic Blood Pressure"  ~ "SYSBP",
      VSTEST == "Diastolic Blood Pressure" ~ "DIABP",
      VSTEST == "Heart Rate"               ~ "HR",
      VSTEST == "Oxygen Saturation"        ~ "OXYSAT",
      VSTEST == "Respiratory Rate"         ~ "RESP",
      VSTEST == "Vital Signs"              ~ "VSALL"
    ),
    PARAMN = case_when(
      PARAMCD == "HEIGHT" ~ 1, PARAMCD == "WEIGHT" ~ 2,
      PARAMCD == "TEMP"   ~ 3, PARAMCD == "SYSBP"  ~ 4,
      PARAMCD == "DIABP"  ~ 5, PARAMCD == "HR"     ~ 6,
      PARAMCD == "RESP"   ~ 7, PARAMCD == "OXYSAT" ~ 8,
      PARAMCD == "VSALL"  ~ 9
    ),
    AVAL   = VSSTRESN,
    AVISIT = case_when(
      str_detect(VISIT, "Unsch")      ~ NA_character_,
      !is.na(VISIT)                   ~ str_to_title(VISIT)
    ),
    AVISIT = if_else(AVISIT == "End Of Treatment", "End of Treatment", AVISIT),
    AVISITN = if_else(str_detect(VISIT, "Unsch"), NA_real_, VISITNUM),
    ATPT   = VSTPT,
    ATPTN  = VSTPTNUM
  )


# =============================================================================
# STEP 5: Derive Baseline Flag and Baseline Values
# =============================================================================

advs_bsfl <- restrict_derivation(
  advs1,
  derivation = derive_var_extreme_flag,
  args = params(
    by_vars = exprs(STUDYID, USUBJID, PARAMCD),
    order   = exprs(ADT, 100000 - VISITNUM, !is.na(VSTPTNUM), VSTPTNUM, VSSEQ),
    new_var = ABLFL,
    mode    = "last"
  ),
  filter = (!is.na(AVAL) & (ADTM <= TRTSDTM | ADT <= TRTSDT) & VSTPTNUM %in% c(NA, 0.1))
)

advs_base <- advs_bsfl |>
  derive_var_base(by_vars = exprs(STUDYID, USUBJID, PARAMCD), source_var = ADTM, new_var = BLADTM) |>
  derive_var_base(by_vars = exprs(STUDYID, USUBJID, PARAMCD), source_var = ADT,  new_var = BLADT) |>
  derive_var_base(by_vars = exprs(STUDYID, USUBJID, PARAMCD), source_var = AVAL, new_var = BASE)


# =============================================================================
# STEP 6: Derive Change from Baseline
# =============================================================================

advs_chg <- advs_base |>
  mutate(
    CHG = case_when(
      (ADTM >= TRTSDTM | (is.na(ADTM) & ADT >= TRTSDT)) &
        is.na(ABLFL) & !is.na(BASE) & !is.na(AVAL)
      ~ as.numeric(AVAL) - BASE
    ),
    PCHG = if_else(!is.na(CHG) & BASE != 0, as.numeric(CHG / BASE * 100), NA_real_)
  )


# =============================================================================
# STEP 7: Derive Blood Pressure Category and Shift Variables
# =============================================================================

advs_acat <- advs_chg |>
  mutate(
    AVALCAT1 = case_when(
      PARAMCD == "SYSBP" & !is.na(AVAL) ~ case_when(
        AVAL < 120                  ~ "<120",
        AVAL >= 120 & AVAL <= 139   ~ "120-139",
        AVAL >= 140 & AVAL <= 159   ~ "140-159",
        AVAL >= 160                 ~ ">=160"
      ),
      PARAMCD == "DIABP" & !is.na(AVAL) ~ case_when(
        AVAL < 80                   ~ "<80",
        AVAL >= 80 & AVAL <= 89     ~ "80-89",
        AVAL >= 90 & AVAL <= 99     ~ "90-99",
        AVAL >= 100                 ~ ">=100"
      )
    ),
    AVALCA1N = format_avalcatn(AVALCAT1)
  )

# Baseline category and shift variables
advs_basec <- advs_acat |>
  mutate(
    BASECAT1   = first(na.omit(if_else(ABLFL == "Y" & PARAMCD %in% c("SYSBP", "DIABP"), AVALCAT1, NA_character_))),
    BASECA1N   = first(na.omit(if_else(ABLFL == "Y" & PARAMCD %in% c("SYSBP", "DIABP"), AVALCA1N, NA_real_))),
    PBASECAT1  = if_else(is.na(BASECAT1) | is.na(CHG), NA_character_, AVALCAT1),
    PBASECAT1N = if_else(is.na(BASECA1N) | is.na(CHG), NA_integer_, AVALCA1N),
    .by = c(USUBJID, PARAMCD)
  )

# Shift analysis: max post-baseline category within subject-parameter
shift <- advs_basec |>
  mutate(
    # DIABP shift
    PBASECATM = if_else(
      PARAMCD == "DIABP" & any(!is.na(PBASECAT1N)),
      max(PBASECAT1N, na.rm = TRUE), NA_integer_
    ),
    PBASECAT = if_else(PARAMCD == "DIABP", format_avalcat(PBASECATM), NA_character_),
    # SYSBP shift
    PBASES  = if_else(
      PARAMCD == "SYSBP" & any(!is.na(PBASECAT1N)),
      max(PBASECAT1N, na.rm = TRUE), NA_integer_
    ),
    PBASES1 = if_else(PARAMCD == "SYSBP", format_avalcat(PBASES), NA_character_),
    # Build shift strings
    SHIFT2  = if_else(PARAMCD == "DIABP" & !is.na(AVAL), paste0(BASECAT1, " to ", PBASECAT), NA_character_),
    SHIFT2  = if_else(is.na(CHG), NA_character_, SHIFT2),
    SHIFT2N = case_when(
      SHIFT2 == "<80 to <80"       ~ 1,  SHIFT2 == "<80 to 80-89"     ~ 2,
      SHIFT2 == "<80 to 90-99"     ~ 3,  SHIFT2 == "<80 to >=100"     ~ 4,
      SHIFT2 == "80-89 to <80"     ~ 5,  SHIFT2 == "80-89 to 80-89"   ~ 6,
      SHIFT2 == "80-89 to 90-99"   ~ 7,  SHIFT2 == "80-89 to >=100"   ~ 8,
      SHIFT2 == "90-99 to <80"     ~ 9,  SHIFT2 == "90-99 to 80-89"   ~ 10,
      SHIFT2 == "90-99 to 90-99"   ~ 11, SHIFT2 == "90-99 to >=100"   ~ 12,
      SHIFT2 == ">=100 to <80"     ~ 13, SHIFT2 == ">=100 to 80-89"   ~ 14,
      SHIFT2 == ">=100 to 90-99"   ~ 15, SHIFT2 == ">=100 to >=100"   ~ 16,
      .default = NA_integer_
    ),
    SHIFT1  = if_else(PARAMCD == "SYSBP" & !is.na(AVAL), paste0(BASECAT1, " to ", PBASES1), NA_character_),
    SHIFT1  = if_else(is.na(CHG), NA_character_, SHIFT1),
    SHIFT1N = case_when(
      SHIFT1 == "<120 to <120"     ~ 1,  SHIFT1 == "<120 to 120-139"   ~ 2,
      SHIFT1 == "<120 to 140-159"  ~ 3,  SHIFT1 == "<120 to >=160"     ~ 4,
      SHIFT1 == "120-139 to <120"  ~ 5,  SHIFT1 == "120-139 to 120-139" ~ 6,
      SHIFT1 == "120-139 to 140-159" ~ 7, SHIFT1 == "120-139 to >=160"  ~ 8,
      SHIFT1 == "140-159 to <120"  ~ 9,  SHIFT1 == "140-159 to 120-139" ~ 10,
      SHIFT1 == "140-159 to 140-159" ~ 11, SHIFT1 == "140-159 to >=160" ~ 12,
      SHIFT1 == ">=160 to <120"    ~ 13, SHIFT1 == ">=160 to 120-139"   ~ 14,
      SHIFT1 == ">=160 to 140-159" ~ 15, SHIFT1 == ">=160 to >=160"     ~ 16,
      .default = NA_integer_
    ),
    .by = c(USUBJID, PARAMCD)
  ) |>
  ungroup()


# =============================================================================
# STEP 8: Merge ADSL Variables, Derive Sequence, and Finalize
# =============================================================================

adsl_vars <- exprs(
  STUDYID, USUBJID, SUBJID, SITEID, AGE, AGEU, DOSGRP, DOSGRPN,
  AGEGR1, AGEGR1N, SEX, RACE, COUNTRY, ENRLFL, SAFFL, ARM, TRT01PN, TRT01AN
)

advs_fin <- derive_vars_merged(
  shift,
  dataset_add = adsl,
  new_vars    = adsl_vars,
  by_vars     = exprs(STUDYID, USUBJID)
) |>
  derive_var_obs_number(
    by_vars    = exprs(STUDYID, USUBJID, SUBJID),
    order      = exprs(STUDYID, USUBJID, VISITNUM, ADT, ADTM, PARAMCD),
    new_var    = ASEQ,
    check_type = "none"
  ) |>
  mutate(
    ADY   = VSDY,
    TRTP  = TRT01P,  TRTA  = TRT01A,
    TRTPN = TRT01PN, TRTAN = TRT01AN
  ) |>
  select(
    STUDYID, USUBJID, SUBJID, SITEID, AGE, AGEU, DOSGRP, DOSGRPN,
    AGEGR1, AGEGR1N, SEX, RACE, COUNTRY, ENRLFL, SAFFL, ARM,
    TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, TRTSDTM, TRTEDT, TRTEDTM,
    TRTP, TRTA, TRTPN, TRTAN, VISIT, VISITNUM, VSDTC, VSTPT, VSTPTNUM,
    ADT, ATM, ADTM, ADY, ATPT, ATPTN, AVISIT, AVISITN,
    PARAM, PARAMCD, PARAMN, AVAL, ABLFL, BASE, CHG, PCHG,
    AVALCAT1, AVALCA1N, BASECAT1, BASECA1N,
    SHIFT1, SHIFT1N, SHIFT2, SHIFT2N, VSSEQ
  ) |>
  arrange(STUDYID, USUBJID, VISITNUM, ADT, ADTM, PARAMCD)


# =============================================================================
# STEP 9: Apply Metadata Labels and Export
# =============================================================================

advs_fin |>
  save_adam(metacore, "ADVS")
