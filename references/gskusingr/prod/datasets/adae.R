####----------------------------------------------------------------------####
# Program Name: adae.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Shilpa Kolli / sk575206
# Purpose: Creation of the Adverse Events Analysis Dataset (ADAE)
#
# Input:
#   - SDTM: AE, SUPPAE, HO, SUPPCM, SUPPPR
#   - ADaM: ADSL
#
# Output:
#   - prod/adamdata/adae.parquet
#   - prod/submission/datasets/adae.xpt
#
# Spec: inputdata/300382_ADAE_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "tidyr", "purrr", "stringr", "lubridate",
  "admiral", "metacore", "metatools", "xportr",
  "readxl", "janitor", "rlang"
)

metacore <- file.path(g_paths$inputdata, "300382_ADAE_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADAE") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================

adsl   <- read_data_catalog(adamdata$adsl)
ae     <- read_data_catalog(sdtmdata$ae)
suppae <- read_data_catalog(sdtmdata$suppae) |>
  mutate(QVAL = if_else(QVAL == "NA", "NOT APPLICABLE", QVAL))
ho     <- read_data_catalog(sdtmdata$ho)
suppcm <- read_data_catalog(sdtmdata$suppcm)
supppr <- read_data_catalog(sdtmdata$supppr)

# Combine AE with SUPPAE and merge ADSL
ae_supp <- combine_supp(ae, suppae) |>
  convert_blanks_to_na()

ae_supp_sl <- left_join(ae_supp, adsl, by = c("STUDYID", "USUBJID"))


# =============================================================================
# STEP 3: Derive Date/Time Variables
# =============================================================================

adae1 <- ae_supp_sl |>
  # AE start/end date-time with imputation
  derive_vars_dtm(
    dtc = AESTDTC, new_vars_prefix = "AST",
    highest_imputation = "M", min_dates = exprs(TRTSDT)
  ) |>
  derive_vars_dtm(
    dtc = AEENDTC, new_vars_prefix = "AEN",
    highest_imputation = "M", date_imputation = "last",
    time_imputation = "last", max_dates = exprs(DTHDT, EOSDT)
  ) |>
  derive_vars_dtm_to_dt(source_vars = exprs(ASTDTM, AENDTM)) |>
  derive_vars_dtm_to_tm(source_vars = exprs(ASTDTM, AENDTM)) |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(ASTDT)) |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(AENDT)) |>
  # SAE date-time variables
  derive_vars_dtm("SAEB", dtc = SAEDTC) |>
  derive_vars_dtm_to_dt(source_vars = exprs(SAEBDTM)) |>
  derive_vars_dtm_to_tm(source_vars = exprs(SAEBDTM)) |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(SAEBDT)) |>
  mutate(
    SAEBTM = if_else(
      as.character(SAEBTM) %in% c("00:00:00", "0"), NA, SAEBTM
    )
  ) |>
  # SAE awareness date-time
  derive_vars_dtm("SAEAW", dtc = SAEAWARE) |>
  derive_vars_dtm_to_dt(source_vars = exprs(SAEAWDTM)) |>
  derive_vars_dtm_to_tm(source_vars = exprs(SAEAWDTM)) |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(SAEAWDT)) |>
  # SAE last dose date
  derive_vars_dtm("SAELD", dtc = SAELSDTC) |>
  derive_vars_dtm_to_dt(source_vars = exprs(SAELDDTM)) |>
  # Treatment response date
  derive_vars_dtm("TRTR", dtc = TRTRESDT) |>
  derive_vars_dtm_to_dt(source_vars = exprs(TRTRDTM))


# =============================================================================
# STEP 4: Ensure Required Columns Exist
# =============================================================================
# Some variables may not yet be present in the SDTM data; add them as NA
# to avoid downstream errors.

variables_to_ensure <- c(
  "AEACN3",
  paste0("DLTCRI", sprintf("%02d", 1:14)),
  paste0("SAEPRRL", 1:9),
  paste0("SAENAR", 1:10),
  paste0("SAECSP", sprintf("%02d", 1:5)),
  paste0("SAECAU", sprintf("%02d", 1:5))
)

for (col_name in variables_to_ensure) {
  if (!(col_name %in% names(adae1))) {
    adae1[[col_name]] <- NA_character_
  }
}


# =============================================================================
# STEP 5: Derive Analysis Variables
# =============================================================================

adae2 <- adae1 |>
  derive_var_trtemfl(
    trt_start_date = TRTSDT, trt_end_date = TRTEDT, end_window = 30
  ) |>
  mutate(
    SAEBDM  = SAEBTM,
    SAEAWDM = SAEAWTM,
    ADURU   = "DAYS",
    APHASE  = NA_character_,
    PREFL   = if_else(
      !is.na(AESTDTC) & !is.na(ASTDT) & ASTDT < TRTSDT,
      "Y", NA_character_
    ),
    # Treatment variables
    TRTP  = TRT01P,
    TRTA  = TRT01A,
    TRTPN = TRT01PN,
    TRTAN = TRT01AN,
    # Toxicity grade (numeric)
    AETOXGRN = as.numeric(AETOXGR),
    ASTDT    = as.Date(ASTDT),
    AENDT    = as.Date(AENDT),
    # Recode "NOT APPLICABLE" to "NA" for specific flags
    AEDLT    = if_else(AEDLTFL == "NOT APPLICABLE", "NA", AEDLTFL),
    ABATTRTE = if_else(ABATTRTE == "NOT APPLICABLE", "NA", ABATTRTE),
    SAECMREL = if_else(SAECMREL == "NOT APPLICABLE", "NA", SAECMREL),
    SAEMHREL = if_else(SAEMHREL == "NOT APPLICABLE", "NA", SAEMHREL),
    # Action taken numeric codes
    AEACNN = case_when(
      AEACN == "DRUG INTERRUPTED" ~ 1,
      AEACN == "DRUG WITHDRAWN"   ~ 2,
      AEACN == "DOSE REDUCED"     ~ 3,
      AEACN == "DOSE NOT CHANGED" ~ 4,
      AEACN == "NOT APPLICABLE"   ~ 5,
      .default = NA_real_
    ),
    AEACN2N = case_when(
      AEACN2 == "DRUG INTERRUPTED" ~ 1,
      AEACN2 == "DRUG WITHDRAWN"   ~ 2,
      AEACN2 == "DOSE REDUCED"     ~ 3,
      .default = NA_real_
    ),
    AEACN3N = case_when(
      AEACN3 == "DRUG INTERRUPTED" ~ 1,
      AEACN3 == "DRUG WITHDRAWN"   ~ 2,
      AEACN3 == "DOSE REDUCED"     ~ 3,
      .default = NA_real_
    ),
    # Relationship numeric code
    AERELN = case_when(
      AEREL == "RELATED"          ~ 1,
      AEREL == "POSSIBLY RELATED" ~ 2,
      AEREL == "UNLIKELY RELATED" ~ 3,
      AEREL == "NOT RELATED"      ~ 4,
      .default = NA_real_
    ),
    # Analysis relatedness (binary: Related / Unrelated)
    AREL = case_when(
      AEREL %in% c("RELATED", "POSSIBLY RELATED") ~ "Related",
      AEREL %in% c("UNLIKELY RELATED", "NOT RELATED") ~ "Unrelated",
      is.na(AEREL) & ASTDT < TRTSDT  ~ "Unrelated",
      is.na(AEREL) & ASTDT >= TRTSDT ~ "Related",
      .default = NA_character_
    ),
    ARELN = if_else(AREL == "Related", 1, if_else(AREL == "Unrelated", 2, NA_real_)),
    # Toxicity grade analysis variables
    ATOXGR  = if_else(!is.na(AETOXGR), paste0("Grade ", AETOXGR), NA_character_),
    ATOXGRN = as.numeric(str_extract(ATOXGR, "\\d")),
    # Outcome analysis variables
    AOUT = case_when(
      AEOUT == "RECOVERED/RESOLVED"                ~ "RED",
      AEOUT == "RECOVERING/RESOLVING"              ~ "RVING",
      AEOUT == "NOT RECOVERED/NOT RESOLVED"        ~ "NRED",
      AEOUT == "RECOVERED/RESOLVED WITH SEQUELAE"  ~ "REDWSEQ",
      .default = AEOUT
    ),
    AOUTN = case_when(
      AEOUT == "FATAL"                              ~ 1,
      AEOUT == "NOT RECOVERED/NOT RESOLVED"         ~ 2,
      AEOUT == "RECOVERED/RESOLVED"                 ~ 3,
      AEOUT == "RECOVERED/RESOLVED WITH SEQUELAE"   ~ 4,
      AEOUT == "RECOVERING/RESOLVING"               ~ 5,
      AEOUT == "UNKNOWN"                            ~ 6,
      .default = NA_real_
    )
  )


# =============================================================================
# STEP 6: Derive CMMEDAE / CMMEDAE1 from SUPPCM
# =============================================================================
# Extract concomitant medication details linked to adverse events.

truncate_long_qval <- function(qval_string) {
  if (is.na(qval_string) || nchar(qval_string) <= 200) return(NA_character_)
  first_200 <- substr(qval_string, 1, 200)
  split_pos <- str_locate_all(first_200, "[, ]")[[1]][, "end"]
  last_pos  <- max(split_pos[is.finite(split_pos)])
  if (is.finite(last_pos) && last_pos > 0) substr(first_200, 1, last_pos) else first_200
}

# Date pattern used in SUPPCM/SUPPPR QVAL parsing
date_pattern <- "\\d{2}\\s*(?:JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\\s*\\d{4}"

suppcm1 <- suppcm |>
  mutate(
    AESPID   = str_extract(QVAL, "(?<=#)\\d{3}(?=:)"),
    CMMEDAE  = str_trim(str_extract(
      QVAL,
      paste0("(?<=:)\\s*(.*?)(?=-", date_pattern, ")")
    )),
    aestdtc_raw = str_extract(QVAL, date_pattern),
    AESTDTC  = format(parse_date_time(aestdtc_raw, orders = "dmy"), "%Y-%m-%d"),
    CMMEDAE1 = sapply(QVAL, truncate_long_qval, USE.NAMES = FALSE)
  ) |>
  select(USUBJID, AESPID, CMMEDAE, CMMEDAE1, AESTDTC) |>
  filter(!is.na(CMMEDAE) | !is.na(CMMEDAE1)) |>
  distinct()


# =============================================================================
# STEP 7: Derive PROCAE / PROCAE1 from SUPPPR
# =============================================================================

supppr1 <- supppr |>
  mutate(
    AESPID  = str_extract(QVAL, "(?<=#)\\d{3}(?=:)"),
    PROCAE  = str_trim(str_extract(
      QVAL,
      paste0("(?<=:)\\s*(.*?)(?=-", date_pattern, ")")
    )),
    aestdtc_raw = str_extract(QVAL, date_pattern),
    AESTDTC = format(parse_date_time(aestdtc_raw, orders = "dmy"), "%Y-%m-%d"),
    PROCAE1 = sapply(QVAL, truncate_long_qval, USE.NAMES = FALSE)
  ) |>
  select(USUBJID, AESPID, PROCAE, PROCAE1, AESTDTC) |>
  filter(!is.na(PROCAE) | !is.na(PROCAE1)) |>
  distinct()


# =============================================================================
# STEP 8: Merge Supplemental Data and Hospitalization Dates
# =============================================================================

adae3 <- adae2 |>
  left_join(suppcm1, by = c("USUBJID", "AESPID", "AESTDTC")) |>
  left_join(supppr1, by = c("USUBJID", "AESPID", "AESTDTC"))

# Hospitalization start/end dates from HO domain
adae <- adae3 |>
  left_join(
    ho |>
      select(USUBJID, AELNKGRP = HOLNKID, HOSTDTC, HOENDTC),
    by = c("USUBJID", "AELNKGRP")
  ) |>
  derive_vars_dtm("HOST", dtc = HOSTDTC) |>
  derive_vars_dtm_to_dt(source_vars = exprs(HOSTDTM)) |>
  derive_vars_dtm("HOEN", dtc = HOENDTC) |>
  derive_vars_dtm_to_dt(source_vars = exprs(HOENDTM))


# =============================================================================
# STEP 9: Apply Metadata Labels and Export
# =============================================================================

adae |>
  save_adam(metacore, "ADAE")
