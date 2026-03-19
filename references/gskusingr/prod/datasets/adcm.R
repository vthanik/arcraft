####----------------------------------------------------------------------####
# Program Name: adcm.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Shilpa Kolli / sk575206
# Purpose: Creation of the Concomitant Medications Analysis Dataset (ADCM)
#
# Input:
#   - SDTM: CM, SUPPCM
#   - ADaM: ADSL
#
# Output:
#   - prod/adamdata/adcm.parquet
#   - prod/submission/datasets/adcm.xpt
#
# Spec: inputdata/300382_ADCM_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "tidyr", "purrr", "stringr", "lubridate",
  "admiral", "metacore", "metatools", "xportr",
  "readxl"
)

metacore <- file.path(g_paths$inputdata, "300382_ADCM_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADCM") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================

adsl   <- read_data_catalog(adamdata$adsl)
cm     <- read_data_catalog(sdtmdata$cm)
suppcm <- read_data_catalog(sdtmdata$suppcm) |>
  mutate(QVAL = if_else(QVAL == "NA", "NOT APPLICABLE", QVAL))

cm_supp <- combine_supp(cm, suppcm) |>
  convert_blanks_to_na()

cm_supp_sl <- left_join(cm_supp, adsl, by = c("STUDYID", "USUBJID"))


# =============================================================================
# STEP 3: Derive Date/Time and Core Analysis Variables
# =============================================================================

# Helper: format partial dates to display label
format_date_label <- function(dtc) {
  case_when(
    !is.na(dtc) & grepl("^\\d{4}-\\d{2}-\\d{2}$", dtc) ~
      toupper(format(ymd(dtc, quiet = TRUE), "%d%b%Y")),
    !is.na(dtc) & grepl("^[A-Z]{3}\\d{4}$", toupper(dtc)) ~
      toupper(format(my(dtc, quiet = TRUE), "%b%Y")),
    !is.na(dtc) & grepl("^\\d{4}-\\d{2}$", dtc) ~
      toupper(format(ym(dtc, quiet = TRUE), "%b%Y")),
    !is.na(dtc) & grepl("^\\d{4}$", dtc) ~ toupper(dtc),
    !is.na(parse_date_time(dtc, orders = c("dmy", "ymd", "mdy"), quiet = TRUE)) ~
      toupper(format(parse_date_time(dtc, orders = c("dmy", "ymd", "mdy"), quiet = TRUE), "%d%b%Y")),
    .default = NA_character_
  )
}

adcm1 <- cm_supp_sl |>
  # Derive start/end date-times with imputation
  derive_vars_dtm(
    dtc = CMSTDTC, new_vars_prefix = "AST",
    highest_imputation = "M", min_dates = exprs(TRTSDT)
  ) |>
  derive_vars_dtm(
    dtc = CMENDTC, new_vars_prefix = "AEN",
    highest_imputation = "M", date_imputation = "last",
    time_imputation = "last", max_dates = exprs(DTHDT, EOSDT, LSTALVDT)
  ) |>
  derive_vars_dtm_to_dt(source_vars = exprs(ASTDTM, AENDTM)) |>
  derive_vars_dtm_to_tm(source_vars = exprs(ASTDTM, AENDTM)) |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(ASTDT)) |>
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(AENDT)) |>
  mutate(
    # ATC codes
    ATC1   = CMATC1,   ATC2   = CMATC2,
    ATC3   = CMATC3,   ATC4   = CMATC4,
    ATC1CD = CMATCCD1, ATC2CD = CMATCCD2,
    ATC3CD = CMATCCD3, ATC4CD = CMATCCD4,
    # Treatment variables
    TRTP  = TRT01P,  TRTA  = TRT01A,
    TRTPN = TRT01PN, TRTAN = TRT01AN,
    # Recode "OTHER" with specify text
    CMROUTE  = if_else(CMROUTE == "OTHER", paste0("Other: ", CMROUTSP), CMROUTE),
    CMDOSFRQ = if_else(CMDOSFRQ == "OTHER", paste0("Other: ", CMFRQSP), CMDOSFRQ),
    CMDOSFRM = if_else(CMDOSFRM == "OTHER", paste0("Other: ", CMFRMSP), CMDOSFRM),
    CMDOSU   = if_else(CMDOSU == "OTHER", paste0("Other: ", CMDOSUSP), CMDOSU),
    CMINDC   = str_to_title(CMINDC),
    # Partial date display labels
    ASTDT_L = format_date_label(CMSTDTC),
    AENDT_L = format_date_label(CMENDTC),
    # Treatment status classification
    CMTRSTAT = case_when(
      !is.na(AENDT) & AENDT < TRTSDT ~ "Prior",
      (!is.na(ASTDT) | !is.na(AENDT)) &
        (ASTDT >= TRTSDT | AENDT >= TRTSDT) ~ "Concomitant",
      .default = NA_character_
    )
  )


# =============================================================================
# STEP 4: Derive Occurrence Flags
# =============================================================================

# AOCCFL - First occurrence within subject
occ_1 <- adcm1 |>
  distinct(USUBJID, ASTDT) |>
  restrict_derivation(
    derivation = derive_var_extreme_flag,
    args = params(
      by_vars = exprs(USUBJID),
      order   = exprs(USUBJID, ASTDT),
      new_var = AOCCFL,
      mode    = "first"
    ),
    filter = !is.na(USUBJID)
  ) |>
  filter(!is.na(AOCCFL)) |>
  select(USUBJID, ASTDT, AOCCFL)

# AOCC01FL - First occurrence of ATC Level 1
occ_2 <- adcm1 |>
  distinct(USUBJID, ATC1, ASTDT) |>
  restrict_derivation(
    derivation = derive_var_extreme_flag,
    args = params(
      by_vars = exprs(USUBJID, ATC1),
      order   = exprs(USUBJID, ATC1, ASTDT),
      new_var = AOCC01FL,
      mode    = "first"
    ),
    filter = !is.na(USUBJID)
  ) |>
  filter(!is.na(AOCC01FL)) |>
  select(USUBJID, ATC1, ASTDT, AOCC01FL)

# AOCC02FL - First occurrence of ATC Level 2
occ_3 <- adcm1 |>
  distinct(USUBJID, ASTDT, CMDECOD, ATC1, ATC2, ATC3) |>
  restrict_derivation(
    derivation = derive_var_extreme_flag,
    args = params(
      by_vars = exprs(USUBJID, ASTDT, CMDECOD, ATC1, ATC2),
      order   = exprs(USUBJID, ASTDT, CMDECOD, ATC1, ATC2, ATC3),
      new_var = AOCC02FL,
      mode    = "first"
    ),
    filter = !is.na(CMDECOD)
  ) |>
  filter(!is.na(AOCC02FL)) |>
  select(USUBJID, ASTDT, CMDECOD, ATC1, ATC2, AOCC02FL)

# AOCCPFL - First occurrence of preferred term
occ_4 <- adcm1 |>
  distinct(USUBJID, ASTDT, CMDECOD) |>
  restrict_derivation(
    derivation = derive_var_extreme_flag,
    args = params(
      by_vars = exprs(USUBJID, ASTDT, CMDECOD),
      order   = exprs(USUBJID, ASTDT, CMDECOD),
      new_var = AOCCPFL,
      mode    = "first"
    ),
    filter = !is.na(CMDECOD)
  ) |>
  filter(!is.na(AOCCPFL)) |>
  select(USUBJID, ASTDT, CMDECOD, AOCCPFL)


# =============================================================================
# STEP 5: Derive Unique Prior Therapy Counts
# =============================================================================

# CMUPRTH - Count of unique prior cancer therapies
cmuprth <- adcm1 |>
  filter(CMCAT == "PRIOR CANCER THERAPY") |>
  summarise(CMUPRTH = as.numeric(n_distinct(CMDECOD)), .by = c(USUBJID, CMCAT))

# CMUNTK - Count of unique tyrosine kinase therapies
cmuntk <- adcm1 |>
  filter(CMCAT == "PRIOR CANCER THERAPY", CMSCAT == "TYROSINE KINASE THERAPY") |>
  summarise(CMUNTK = as.numeric(n_distinct(CMDECOD)), .by = c(USUBJID, CMCAT, CMSCAT))


# =============================================================================
# STEP 6: Merge Occurrence Flags and Therapy Counts
# =============================================================================

adcm2 <- adcm1 |>
  left_join(occ_1,   by = c("USUBJID", "ASTDT")) |>
  left_join(occ_2,   by = c("USUBJID", "ASTDT", "ATC1")) |>
  left_join(occ_3,   by = c("USUBJID", "ASTDT", "CMDECOD", "ATC1", "ATC2")) |>
  left_join(occ_4,   by = c("USUBJID", "ASTDT", "CMDECOD")) |>
  left_join(cmuprth, by = c("USUBJID", "CMCAT")) |>
  left_join(cmuntk,  by = c("USUBJID", "CMCAT", "CMSCAT"))


# =============================================================================
# STEP 7: Derive ACMINDC and ACMINDC1 (Aggregated Indication)
# =============================================================================
# Aggregate medical history and adverse event related QVALs from SUPPCM,
# then derive the combined indication text with word-boundary-safe truncation.

# Helper: split long text at word boundary
split_text_by_word_boundary <- function(text, max_len = 200) {
  if (is.na(text) || nchar(text) <= max_len) {
    return(list(part1 = text, part2 = NA_character_))
  }
  words <- unlist(str_split(text, "\\s+"))
  current_length <- 0
  split_idx <- 0
  for (i in seq_along(words)) {
    add_len <- nchar(words[i]) + if (i > 1) 1 else 0
    if (current_length + add_len <= max_len) {
      current_length <- current_length + add_len
    } else {
      split_idx <- i
      break
    }
  }
  part1 <- paste(words[1:(split_idx - 1)], collapse = " ")
  part2 <- str_trim(paste(words[split_idx:length(words)], collapse = " "))
  list(part1 = part1, part2 = part2)
}

# Aggregate MH and AE related QVALs from SUPPCM
mh_supp_agg <- suppcm |>
  filter(QNAM %in% c("CMMHREL1", "CMMHREL2", "CMMHREL3")) |>
  summarise(
    MH_REL_AGG = paste(str_to_upper(unique(QVAL)), collapse = ", "),
    .by = c(USUBJID, IDVARVAL)
  ) |>
  mutate(CMSEQ = as.numeric(IDVARVAL))

ae_supp_agg <- suppcm |>
  filter(QNAM %in% c("CMAEREL1", "CMAEREL2", "CMAEREL3")) |>
  summarise(
    AE_REL_AGG = paste(str_to_upper(unique(QVAL)), collapse = ", "),
    .by = c(USUBJID, IDVARVAL)
  ) |>
  mutate(CMSEQ = as.numeric(IDVARVAL))

cm_supp_sl_joined <- adcm2 |>
  left_join(mh_supp_agg, by = c("USUBJID", "CMSEQ")) |>
  left_join(ae_supp_agg, by = c("USUBJID", "CMSEQ")) |>
  mutate(
    MH_REL_AGG = coalesce(MH_REL_AGG, ""),
    AE_REL_AGG = coalesce(AE_REL_AGG, "")
  )

# Build ACMINDC from indication type and aggregated text
adcm_output <- cm_supp_sl_joined |>
  mutate(
    cmin1_text_temp = case_when(
      is.na(CMINDC1) | CMINDC1 == "" ~ "",
      str_to_upper(CMINDC1) == "ADVERSE EVENT" ~
        if_else(AE_REL_AGG != "", paste0(str_to_title(CMINDC1), ": ", AE_REL_AGG), str_to_title(CMINDC1)),
      str_to_upper(CMINDC1) == "MEDICAL HISTORY" ~
        if_else(MH_REL_AGG != "", paste0(str_to_title(CMINDC1), ": ", MH_REL_AGG), str_to_title(CMINDC1)),
      .default = str_to_title(CMINDC1)
    ),
    cmin2_text_temp = case_when(
      is.na(CMINDC2) | CMINDC2 == "" ~ "",
      str_to_upper(CMINDC2) == "MEDICAL HISTORY" ~
        if_else(MH_REL_AGG != "", paste0(str_to_title(CMINDC2), ": ", MH_REL_AGG), str_to_title(CMINDC2)),
      str_to_upper(CMINDC2) == "ADVERSE EVENT" ~
        if_else(AE_REL_AGG != "", paste0(str_to_title(CMINDC2), ": ", AE_REL_AGG), str_to_title(CMINDC2)),
      .default = str_to_title(CMINDC2)
    ),
    cmin3_text_temp = if_else(is.na(CMINDC3) | CMINDC3 == "", "", str_to_title(CMINDC3)),
    cmin4_text_temp = if_else(is.na(CMINDCSP) | CMINDCSP == "", "", paste0("Other: ", CMINDCSP)),
    ACMINDC = case_when(
      CMINDC == "Other Indication" ~
        if_else(!is.na(CMINDCSP) & CMINDCSP != "", paste0("Other: ", toupper(CMINDCSP)), "Other Indication"),
      CMINDC == "Medical History" ~
        if_else(MH_REL_AGG != "", paste0("Medical History: ", MH_REL_AGG), "Medical History"),
      CMINDC == "Adverse Event" ~
        if_else(AE_REL_AGG != "", paste0("Adverse Event: ", AE_REL_AGG), "Adverse Event"),
      CMINDC == "Multiple" ~ pmap_chr(
        list(cmin1_text_temp, cmin2_text_temp, cmin3_text_temp, cmin4_text_temp),
        function(p1, p2, p3, p4) {
          parts <- c(p1, p2, p3, p4)
          paste(parts[parts != ""], collapse = ", ")
        }
      ),
      .default = CMINDC
    ),
    ACMINDC = str_squish(ACMINDC)
  )

# Split ACMINDC into two parts if > 200 characters
adcm <- adcm_output |>
  mutate(split_results = map(ACMINDC, ~ split_text_by_word_boundary(.x, 200))) |>
  unnest_wider(split_results, names_sep = "_") |>
  mutate(
    ACMINDC  = split_results_part1,
    ACMINDC1 = split_results_part2
  )


# =============================================================================
# STEP 8: Apply Metadata Labels and Export
# =============================================================================

adcm |>
  save_adam(metacore, "ADCM")
