####----------------------------------------------------------------------####
# Program Name: adrs.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Mariam Alaverdyan / ma584118
# Purpose: Creation of the Tumor Response Analysis Dataset (ADRS)
#
# Input:
#   - SDTM: RS, SUPPRS
#   - ADaM: ADBS (external)
#
# Output:
#   - prod/adamdata/adrs.parquet
#   - prod/submission/datasets/adrs.xpt
#
# Spec: inputdata/300382_ADRS_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "stringr", "tidyr", "purrr", "lubridate",
  "admiral", "metacore", "metatools", "xportr",
  "hms"
)

metacore <- file.path(g_paths$inputdata, "300382_ADRS_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADRS") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================

adsl <- read_data_catalog(adamdata_ext$adbs) |>
  select(
    STUDYID, USUBJID, SUBJID, SITEID, starts_with("TRT"),
    SAFFL, ENRLFL, starts_with("AGE"), starts_with("DOSGRP"),
    SEX, RACE, COUNTRY, ARM
  ) |>
  mutate(TRTA = TRT01A, TRTP = TRT01P, TRTAN = TRT01AN, TRTPN = TRT01PN)

rs     <- read_data_catalog(sdtmdata$rs)
supprs <- read_data_catalog(sdtmdata$supprs)

# Merge SUPPRS (handle case where SUPPRS may be empty)
rs_supprs <- if (nrow(supprs) > 0) {
  combine_supp(rs, supprs)
} else {
  warning("SUPPRS is missing in SDTM")
  rs
}

rs_supprs <- derive_vars_merged(
  rs_supprs,
  dataset_add = adsl,
  by_vars     = exprs(STUDYID, USUBJID)
)


# =============================================================================
# STEP 3: Derive Analysis Variables and Export
# =============================================================================

adrs1 <- rs_supprs |>
  filter(RSTESTCD == "OVRLRESP") |>
  mutate(
    PARAM   = RSTEST,
    PARAMCD = RSTESTCD,
    AVAL    = case_when(
      RSSTRESC == "CR" ~ 1, RSSTRESC == "PR" ~ 2,
      RSSTRESC == "SD" ~ 3, RSSTRESC == "PD" ~ 4,
      RSSTRESC == "NE" ~ 5
    ),
    PARCAT1 = RSCAT,
    AVALC   = RSSTRESC,
    AVISIT  = if_else(str_detect(VISIT, "Uns"), NA_character_, VISIT),
    AVISITN = if_else(str_detect(VISIT, "Uns"), NA_real_, VISITNUM)
  ) |>
  derive_vars_dt(dtc = RSDTC, new_vars_prefix = "A") |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(ADT))


# =============================================================================
# STEP 4: Apply Metadata Labels and Export
# =============================================================================

adrs1 |>
  save_adam(metacore, "ADRS")
