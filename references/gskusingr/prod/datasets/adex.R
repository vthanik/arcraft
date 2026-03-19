####----------------------------------------------------------------------####
# Program Name: adex.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Mariam Alaverdyan / ma584118
# Purpose: Creation of the Exposure Analysis Dataset (ADEX)
#
# Input:
#   - SDTM: EC, SUPPEC
#   - ADaM: ADBS (external)
#
# Output:
#   - prod/adamdata/adex.parquet
#   - prod/submission/datasets/adex.xpt
#
# Spec: inputdata/300382_ADEX_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "stringr", "tidyr", "purrr",
  "admiral", "metacore", "metatools", "xportr",
  "hms", "lubridate"
)

metacore <- file.path(g_paths$inputdata, "300382_ADEX_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADEX") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================

adsl <- read_data_catalog(adamdata_ext$adbs) |>
  select(
    STUDYID, USUBJID, SUBJID, SITEID, SEX, RACE, COUNTRY,
    starts_with("TRT"), starts_with("AGE"), SAFFL, ENRLFL, ARM,
    starts_with("DOSGRP")
  ) |>
  mutate(TRTA = TRT01A, TRTP = TRT01P, TRTAN = TRT01AN, TRTPN = TRT01PN)

ec     <- read_data_catalog(sdtmdata$ec)
suppec <- read_data_catalog(sdtmdata$suppec)

# Merge SUPPEC to EC (handle case where SUPPEC may be empty)
ec_suppec <- if (nrow(suppec) > 0) {
  combine_supp(ec, suppec)
} else {
  warning("SUPPEC is missing in SDTM")
  ec
}

ec_suppec <- derive_vars_merged(
  ec_suppec,
  dataset_add = adsl,
  by_vars     = exprs(STUDYID, USUBJID)
) |>
  select(-DOMAIN, -EPOCH, -ECSCAT)


# =============================================================================
# STEP 3: Separate Scheduled and Performed Records
# =============================================================================

scheduled <- ec_suppec |>
  filter(str_detect(ECSPID, "STUDY DRUG RECORD"), ECMOOD == "SCHEDULED") |>
  select(USUBJID, ECSPID, ECTRT, ECDOSE, ECDOSU)

performed <- ec_suppec |>
  filter(str_detect(ECSPID, "STUDY DRUG RECORD"), ECMOOD == "PERFORMED") |>
  rename(ADOSE = ECDOSE, ADOSU = ECDOSU) |>
  mutate(
    ECNDAE  = str_c(ECNDAE1, ECNDAE2, ECNDAE3, sep = ", "),
    AVISIT  = paste(ECSPID),
    AVISITN = as.numeric(paste0(
      str_trim(str_split(ECSPID, "-", simplify = TRUE)[, 2]), "9999"
    ))
  ) |>
  derive_vars_dtm(dtc = ECSTDTC, highest_imputation = "M", new_vars_prefix = "AST", flag_imputation = "none") |>
  derive_vars_dt(dtc = ECSTDTC, new_vars_prefix = "AST") |>
  derive_vars_dtm_to_tm(exprs(ASTDTM)) |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(ASTDT)) |>
  derive_vars_dtm(dtc = ECENDTC, highest_imputation = "M", new_vars_prefix = "AEN", flag_imputation = "none") |>
  derive_vars_dt(dtc = ECENDTC, new_vars_prefix = "AEN") |>
  derive_vars_dtm_to_tm(exprs(AENDTM)) |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(AENDT))


# =============================================================================
# STEP 4: Derive Cycle Count
# =============================================================================

cycle <- ec_suppec |>
  filter(ECCAT == "IDRX-42 ADMINISTRATION", !str_detect(ECSPID, "UNSCHEDULED")) |>
  arrange(USUBJID, ECSEQ) |>
  slice_tail(n = 1, by = USUBJID) |>
  mutate(CYCLES = str_trim(str_split(ECSPID, " ", simplify = TRUE)[, 2])) |>
  select(USUBJID, CYCLES)


# =============================================================================
# STEP 5: Combine, Sequence, and Export
# =============================================================================

adex0 <- merge(scheduled, performed, by = c("USUBJID", "ECSPID", "ECTRT"), all = TRUE) |>
  select(-ECMOOD, -ECSEQ, -ECROUTE, -ECNDAE1, -ECNDAE2, -ECNDAE3)

adex1 <- left_join(adex0, cycle, by = "USUBJID") |>
  derive_var_obs_number(
    new_var = ASEQ,
    by_vars = exprs(STUDYID, USUBJID),
    order   = exprs(ECTRT, ASTDTM)
  ) |>
  mutate(
    ASEQ  = as.numeric(ASEQ),
    ASTTM = if_else(as.character(ASTTM) == "00:00:00", NA_character_, as.character(ASTTM)),
    AENTM = if_else(as.character(AENTM) == "00:00:00", NA_character_, as.character(AENTM)),
    ASTTM = as_hms(ASTTM),
    AENTM = as_hms(AENTM)
  )


# =============================================================================
# STEP 6: Apply Metadata Labels and Export
# =============================================================================

adex1 |>
  save_adam(metacore, "ADEX")
