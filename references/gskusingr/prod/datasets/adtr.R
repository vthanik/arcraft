####----------------------------------------------------------------------####
# Program Name: adtr.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Shilpa Kolli / sk575206
# Purpose: Creation of the Tumor Results Analysis Dataset (ADTR)
#
# Input:
#   - SDTM: TR, TU, SUPPTU
#   - ADaM: ADSL
#
# Output:
#   - prod/adamdata/adtr.parquet
#   - prod/submission/datasets/adtr.xpt
#
# Spec: inputdata/300382_ADTR_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "tidyr", "purrr", "stringr", "lubridate",
  "admiral", "admiralonco", "metacore", "metatools", "xportr",
  "readxl", "rlang"
)

metacore <- file.path(g_paths$inputdata, "300382_ADTR_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADTR") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================

adsl   <- read_data_catalog(adamdata$adsl)
tr     <- read_data_catalog(sdtmdata$tr) |>
  filter(TRTESTCD %in% c("LDIAM", "SUMNLNLD", "TUMSTATE", "DIAMETER"))
tu     <- read_data_catalog(sdtmdata$tu)
supptu <- read_data_catalog(sdtmdata$supptu)

tu_supp <- combine_supp(tu, supptu)

# Combine TR and TU (supplemented)
tr_tu <- left_join(
  tr, tu_supp,
  by = c("STUDYID", "USUBJID", "TRLNKID" = "TULNKID"),
  relationship = "many-to-many"
)

# Merge with ADSL
tr_sl <- left_join(tr_tu, adsl, by = c("STUDYID", "USUBJID"))


# =============================================================================
# STEP 3: Derive Core Analysis Variables
# =============================================================================

adtr1 <- tr_sl |>
  derive_vars_dt(new_vars_prefix = "A", dtc = TRDTC, highest_imputation = "M") |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(ADT)) |>
  mutate(
    LNKID   = TRLNKID,
    LESNUM  = str_pad(str_extract(LNKID, "\\d+"), width = 2, side = "left", pad = "0"),
    METHOD  = TRMETHOD,
    LOCAT   = TULOC,
    LOCO    = TULOCO,
    LESLOC  = TULOCSP,
    TRTP    = TRT01P,
    TRTA    = TRT01A,
    TRTPN   = TRT01PN,
    TRTAN   = TRT01AN,
    PARCAT1 = TUORRES,
    PARAM   = TRTEST,
    PARAMCD = TRTESTCD,
    AVAL    = TRSTRESN,
    AVALC   = TRSTRESC,
    AVALU   = TRSTRESU,
    VISIT   = VISIT.x,
    VISITNUM = VISITNUM.x,
    AVISIT  = if_else(str_detect(VISIT, "Unscheduled"), NA_character_, VISIT),
    AVISITN = if_else(str_detect(VISIT, "Unscheduled"), NA_real_, VISITNUM)
  )


# =============================================================================
# STEP 4: Derive Baseline, Change, and Percent Change
# =============================================================================

adtr1 <- adtr1 |>
  restrict_derivation(
    derivation = derive_var_extreme_flag,
    args = params(
      by_vars = exprs(STUDYID, USUBJID, TRLNKID, PARAMCD),
      order   = exprs(ADT, VISITNUM, TRLNKID),
      new_var = ABLFL,
      mode    = "last"
    ),
    filter = (!is.na(AVAL) & ADT <= TRTSDT)
  ) |>
  derive_var_base(
    by_vars    = exprs(STUDYID, USUBJID, TRLNKID, PARAMCD),
    source_var = AVAL,
    new_var    = BASE
  ) |>
  derive_var_chg() |>
  derive_var_pchg() |>
  mutate(
    ANL01FL = if_else(!is.na(ADY) & ADY > 1, "Y", NA_character_),
    CHG     = if_else(ADT > TRTSDT, CHG, NA_real_),
    PCHG    = if_else(ADT > TRTSDT, PCHG, NA_real_)
  )


# =============================================================================
# STEP 5: Derive NADIR Variables for Sum of Longest Diameters
# =============================================================================

adtr_sum <- adtr1 |>
  filter(PARAMCD == "SUMNLNLD", !is.na(AVAL)) |>
  arrange(USUBJID, ADT) |>
  mutate(
    NADIR = map_dbl(
      seq_along(AVAL),
      ~ if (.x == 1) NA_real_ else min(AVAL[1:(.x - 1)], na.rm = TRUE)
    ),
    NADRCHG  = if_else(is.na(NADIR), NA_real_, AVAL - NADIR),
    PNADRCHG = if_else(
      is.na(NADIR) | NADIR == 0, NA_real_,
      round_half_up(100 * (AVAL - NADIR) / NADIR, 2)
    ),
    .by = c(USUBJID, PARAMCD)
  ) |>
  select(STUDYID, USUBJID, TRLNKID, PARAMCD, ADT, AVISITN, NADIR, NADRCHG, PNADRCHG)


# =============================================================================
# STEP 6: Merge NADIR, Sequence, and Export
# =============================================================================

adtr <- left_join(
  adtr1, adtr_sum,
  by = c("STUDYID", "USUBJID", "TRLNKID", "PARAMCD", "ADT", "AVISITN")
) |>
  derive_var_obs_number(
    by_vars    = exprs(USUBJID),
    order      = exprs(STUDYID, USUBJID, PARAMCD, VISITNUM, TRSPID, TRLNKID),
    new_var    = ASEQ,
    check_type = "error"
  ) |>
  mutate(ASEQ = as.numeric(ASEQ))


# =============================================================================
# STEP 7: Apply Metadata Labels and Export
# =============================================================================

adtr |>
  save_adam(metacore, "ADTR")
