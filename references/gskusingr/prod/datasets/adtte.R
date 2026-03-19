####----------------------------------------------------------------------####
# Program Name: adtte.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Pragya Tripathi / ps209009
# Purpose: Creation of the Time-to-Event Analysis Dataset (ADTTE)
#
# Input:
#   - ADaM: ADBS (external), ADEFF (external), ADCM (external)
#
# Output:
#   - prod/adamdata/adtte.parquet
#   - prod/submission/datasets/adtte.xpt
#
# Spec: inputdata/300382_ADTTE_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "lubridate", "tidyr", "purrr",
  "admiral", "metacore", "metatools", "xportr",
  "readr", "readxl", "janitor"
)

metacore <- file.path(g_paths$inputdata, "300382_ADTTE_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADTTE") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================

adbs <- read_data_catalog(adamdata_ext$adbs) |>
  filter(EFFL == "Y") |>
  select(
    STUDYID, USUBJID, SUBJID, SITEID, SAFFL, EFFL,
    TRT01P, TRT01PN, TRT01A, TRT01AN,
    COHORT, COHORTN, COHGL, COHGLN, COHAGR1, COHAGR1N,
    PHASE, PHASEN, LINEOT, LINEOTN, DOSELVL, DOSELVLN
  )

# Subsequent anti-cancer therapy dates for censoring
adcm_dates <- read_data_catalog(adamdata_ext$adcm) |>
  filter(CMCAT == "SUBSEQUENT ANTI-CANCER THERAPY") |>
  arrange(USUBJID, ASTDT, AENDT) |>
  summarise(
    FIRST_ASTDT = min(ASTDT, na.rm = TRUE),
    LAST_AENDT  = max(AENDT, na.rm = TRUE),
    .by = USUBJID
  )

adcm_final <- adcm_dates |>
  left_join(
    read_data_catalog(adamdata_ext$adbs) |> select(USUBJID, TRTSDT, DTHDT),
    by = "USUBJID"
  ) |>
  filter(!is.na(DTHDT), is.na(TRTSDT) | DTHDT >= TRTSDT)

adeff <- read_data_catalog(adamdata_ext$adeff) |>
  filter(
    EFFL == "Y",
    PARAMCD %in% c("MISASSDT", "PDDT", "DTHDT", "LSTASSDT", "TRTSDT", "TTRDT", "LSTALVDT", "DORDT")
  ) |>
  mutate(ADT_NUM = as.numeric(as.Date(AVALC, format = "%d%b%Y")))

acat2_levels <- c("INVESTIGATOR", "INDEPENDENT ASSESSOR")

adeff_base <- adeff |>
  select(USUBJID, ACAT1, ACAT1N, ACAT2, PARAMCD) |>
  rename(ADT_SRCCD = PARAMCD)


# =============================================================================
# STEP 3: Prepare PFS Data
# =============================================================================

process_adeff_pfs <- function(acat2_val) {
  adeff |>
    filter(PARAMCD %in% c("MISASSDT", "PDDT", "DTHDT", "LSTASSDT", "TRTSDT"), ACAT2 == acat2_val) |>
    select(USUBJID, PARAMCD, ADT_NUM) |>
    pivot_wider(id_cols = USUBJID, names_from = PARAMCD, values_from = ADT_NUM) |>
    left_join(
      adcm_final |> mutate(NEWTRTDT_NUM = as.numeric(as.Date(FIRST_ASTDT))) |> select(USUBJID, NEWTRTDT_NUM),
      by = "USUBJID"
    ) |>
    mutate(
      ADT_SRC = coalesce(
        MISASSDT, PDDT,
        if_else(!is.na(DTHDT) & (is.na(NEWTRTDT_NUM) | DTHDT < NEWTRTDT_NUM), DTHDT, NA_real_),
        LSTASSDT, TRTSDT
      ),
      ADT_SRCCD = case_when(
        !is.na(MISASSDT) ~ "MISASSDT",
        !is.na(PDDT) ~ "PDDT",
        !is.na(DTHDT) & (is.na(NEWTRTDT_NUM) | DTHDT < NEWTRTDT_NUM) ~ "DTHDT",
        !is.na(LSTASSDT) ~ "LSTASSDT",
        !is.na(TRTSDT) ~ "TRTSDT"
      ),
      ACAT2 = acat2_val
    ) |>
    select(USUBJID, ACAT2, ADT_SRC, ADT_SRCCD)
}

adeff_pfs <- map_dfr(acat2_levels, process_adeff_pfs) |>
  left_join(adeff_base, by = c("USUBJID", "ACAT2", "ADT_SRCCD")) |>
  mutate(
    ACAT2N   = if_else(ACAT2 == "INVESTIGATOR", 1, 2),
    ADT      = toupper(format(as.Date(ADT_SRC, origin = "1970-01-01"), "%d%b%Y")),
    PARAM    = "Progression-free Survival (month)",
    PARAMCD  = "PFS",
    PARAMN   = 2,
    CNSR     = if_else(ADT_SRCCD %in% c("PDDT", "DTHDT"), 0, 1),
    SRCSEQ = case_when(
      ADT_SRCCD == "PDDT"     & CNSR == 0 & ACAT2 == "INVESTIGATOR"           ~ 4,
      ADT_SRCCD == "PDDT"     & CNSR == 0 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 16,
      ADT_SRCCD == "DTHDT"    & CNSR == 0 & ACAT2 == "INVESTIGATOR"           ~ 7,
      ADT_SRCCD == "DTHDT"    & CNSR == 0 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 19,
      ADT_SRCCD == "MISASSDT" & CNSR == 1 & ACAT2 == "INVESTIGATOR"           ~ 10,
      ADT_SRCCD == "MISASSDT" & CNSR == 1 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 22,
      ADT_SRCCD == "LSTASSDT" & CNSR == 1 & ACAT2 == "INVESTIGATOR"           ~ 8,
      ADT_SRCCD == "LSTASSDT" & CNSR == 1 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 20,
      ADT_SRCCD == "TRTSDT"   & CNSR == 1 & ACAT2 == "INVESTIGATOR"           ~ 12,
      ADT_SRCCD == "TRTSDT"   & CNSR == 1 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 24
    ),
    EVNTDESC = case_when(
      ADT_SRCCD == "PDDT"     & CNSR == 0 ~ "Documented Progression",
      ADT_SRCCD == "DTHDT"    & CNSR == 0 ~ "Death",
      ADT_SRCCD == "MISASSDT" & CNSR == 1 ~ "Progression or death after two or more missing assessment",
      ADT_SRCCD == "LSTASSDT" & CNSR == 1 ~ "No progression (or death)",
      ADT_SRCCD == "TRTSDT"   & CNSR == 1 ~ "No post baseline disease assessment"
    ),
    CNSDTDSC = case_when(
      ADT_SRCCD == "MISASSDT" & CNSR == 1 ~ "Date of last assessment prior to missed assessments",
      ADT_SRCCD == "LSTASSDT" & CNSR == 1 ~ "Date of last assessment",
      ADT_SRCCD == "TRTSDT"   & CNSR == 1 ~ "Date of first IDRX-42 dose"
    )
  )


# =============================================================================
# STEP 4: Prepare DOR Data
# =============================================================================

process_adeff_dor <- function(acat2_val) {
  adeff |>
    filter(PARAMCD %in% c("MISASSDT", "PDDT", "DTHDT", "LSTASSDT"), ACAT2 == acat2_val) |>
    select(USUBJID, PARAMCD, ADT_NUM) |>
    pivot_wider(id_cols = USUBJID, names_from = PARAMCD, values_from = ADT_NUM) |>
    left_join(
      adcm_final |> mutate(NEWTRTDT_NUM = as.numeric(as.Date(FIRST_ASTDT))) |> select(USUBJID, NEWTRTDT_NUM),
      by = "USUBJID"
    ) |>
    mutate(
      ADT_SRC = coalesce(
        MISASSDT, PDDT,
        if_else(!is.na(DTHDT) & (is.na(NEWTRTDT_NUM) | DTHDT < NEWTRTDT_NUM), DTHDT, NA_real_),
        LSTASSDT
      ),
      ADT_SRCCD = case_when(
        !is.na(MISASSDT) ~ "MISASSDT",
        !is.na(PDDT) ~ "PDDT",
        !is.na(DTHDT) & (is.na(NEWTRTDT_NUM) | DTHDT < NEWTRTDT_NUM) ~ "DTHDT",
        !is.na(LSTASSDT) ~ "LSTASSDT"
      ),
      ACAT2 = acat2_val
    ) |>
    select(USUBJID, ACAT2, ADT_SRC, ADT_SRCCD)
}

adeff_dor <- map_dfr(acat2_levels, process_adeff_dor) |>
  left_join(adeff_base, by = c("USUBJID", "ACAT2", "ADT_SRCCD")) |>
  mutate(
    ACAT2N   = if_else(ACAT2 == "INVESTIGATOR", 1, 2),
    ADT      = toupper(format(as.Date(ADT_SRC, origin = "1970-01-01"), "%d%b%Y")),
    PARAM    = "Duration of Response (month)",
    PARAMCD  = "DOR",
    PARAMN   = 1,
    CNSR     = if_else(ADT_SRCCD %in% c("PDDT", "DTHDT"), 0, 1),
    SRCSEQ = case_when(
      ADT_SRCCD == "PDDT"     & CNSR == 0 & ACAT2 == "INVESTIGATOR"           ~ 4,
      ADT_SRCCD == "PDDT"     & CNSR == 0 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 16,
      ADT_SRCCD == "DTHDT"    & CNSR == 0 & ACAT2 == "INVESTIGATOR"           ~ 7,
      ADT_SRCCD == "DTHDT"    & CNSR == 0 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 19,
      ADT_SRCCD == "MISASSDT" & CNSR == 1 & ACAT2 == "INVESTIGATOR"           ~ 10,
      ADT_SRCCD == "MISASSDT" & CNSR == 1 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 22,
      ADT_SRCCD == "LSTASSDT" & CNSR == 1 & ACAT2 == "INVESTIGATOR"           ~ 8,
      ADT_SRCCD == "LSTASSDT" & CNSR == 1 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 20
    ),
    EVNTDESC = case_when(
      ADT_SRCCD == "PDDT"     & CNSR == 0 ~ "Documented Progression",
      ADT_SRCCD == "DTHDT"    & CNSR == 0 ~ "Death",
      ADT_SRCCD == "MISASSDT" & CNSR == 1 ~ "Progression or death after two or more missing assessment",
      ADT_SRCCD == "LSTASSDT" & CNSR == 1 ~ "No progression (or death)"
    ),
    CNSDTDSC = case_when(
      ADT_SRCCD == "MISASSDT" & CNSR == 1 ~ "Date of last assessment prior to missed assessments",
      ADT_SRCCD == "LSTASSDT" & CNSR == 1 ~ "Date of last assessment"
    )
  )

# Filter to subjects with confirmed response (DORDT exists in ADEFF)
adeff_dor <- read_data_catalog(adamdata_ext$adeff) |>
  filter(PARAMCD == "DORDT", !is.na(AVALC)) |>
  distinct(USUBJID, ACAT2) |>
  left_join(adeff_dor, by = c("USUBJID", "ACAT2"))


# =============================================================================
# STEP 5: Prepare OS Data
# =============================================================================

process_adeff_os <- function(acat2_val) {
  adeff |>
    filter(PARAMCD %in% c("DTHDT", "LSTALVDT"), ACAT2 == acat2_val) |>
    select(USUBJID, PARAMCD, ADT_NUM) |>
    pivot_wider(id_cols = USUBJID, names_from = PARAMCD, values_from = ADT_NUM) |>
    mutate(
      ADT_SRC   = coalesce(DTHDT, LSTALVDT),
      ADT_SRCCD = if_else(!is.na(DTHDT), "DTHDT", if_else(!is.na(LSTALVDT), "LSTALVDT", NA_character_)),
      ACAT2     = acat2_val
    ) |>
    select(USUBJID, ACAT2, ADT_SRC, ADT_SRCCD)
}

adeff_os <- map_dfr(acat2_levels, process_adeff_os) |>
  left_join(adeff_base, by = c("USUBJID", "ACAT2", "ADT_SRCCD")) |>
  mutate(
    ACAT2N   = if_else(ACAT2 == "INVESTIGATOR", 1, 2),
    ADT      = toupper(format(as.Date(ADT_SRC, origin = "1970-01-01"), "%d%b%Y")),
    PARAM    = "Overall Survival (month)",
    PARAMCD  = "OS",
    PARAMN   = 4,
    CNSR     = if_else(ADT_SRCCD == "DTHDT", 0, 1),
    SRCSEQ = case_when(
      CNSR == 0 & ACAT2 == "INVESTIGATOR"           ~ 7,
      CNSR == 0 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 19,
      CNSR == 1 & ACAT2 == "INVESTIGATOR"            ~ 11,
      CNSR == 1 & ACAT2 == "INDEPENDENT ASSESSOR"   ~ 23
    ),
    EVNTDESC = if_else(CNSR == 0, "Death", "No death"),
    CNSDTDSC = if_else(CNSR == 1, "Date of last known alive", NA_character_)
  )


# =============================================================================
# STEP 6: Prepare TTR Data
# =============================================================================

process_adeff_ttr <- function(acat2_val) {
  adeff |>
    filter(PARAMCD == "TTRDT", ACAT2 == acat2_val) |>
    select(USUBJID, PARAMCD, ACAT2, ADT_NUM) |>
    mutate(ADT_SRC = ADT_NUM, ADT_SRCCD = PARAMCD) |>
    select(USUBJID, ACAT2, ADT_SRC, ADT_SRCCD)
}

adeff_ttr <- map_dfr(acat2_levels, process_adeff_ttr) |>
  left_join(adeff_base, by = c("USUBJID", "ACAT2", "ADT_SRCCD")) |>
  mutate(
    ACAT2N   = if_else(ACAT2 == "INVESTIGATOR", 1, 2),
    ADT      = toupper(format(as.Date(ADT_SRC, origin = "1970-01-01"), "%d%b%Y")),
    PARAM    = "Time to Response (month)",
    PARAMCD  = "TTR",
    PARAMN   = 3,
    CNSR     = NA_real_,
    SRCSEQ   = if_else(ACAT2 == "INVESTIGATOR", 5, 17),
    EVNTDESC = NA_character_,
    CNSDTDSC = NA_character_
  )

# Filter to subjects with confirmed response (TTRDT exists in ADEFF)
adeff_ttr <- read_data_catalog(adamdata_ext$adeff) |>
  filter(PARAMCD == "TTRDT", !is.na(AVALC)) |>
  distinct(USUBJID, ACAT2) |>
  left_join(adeff_ttr, by = c("USUBJID", "ACAT2"))


# =============================================================================
# STEP 7: Combine All Parameters
# =============================================================================

adtte1 <- bind_rows(adeff_pfs, adeff_dor, adeff_os, adeff_ttr)


# =============================================================================
# STEP 8: Derive STARTDT, AVAL, SRCDOM
# =============================================================================

adeff_stdt <- function(acat2_val) {
  adeff |>
    filter(EFFL == "Y", PARAMCD %in% c("DORDT", "TRTSDT"), ACAT2 == acat2_val) |>
    select(USUBJID, PARAMCD, ACAT2, ADT_NUM) |>
    pivot_wider(id_cols = c(USUBJID, ACAT2), names_from = PARAMCD, values_from = ADT_NUM)
}

adeff_stdt_all <- map_dfr(acat2_levels, adeff_stdt)

adtte2 <- adtte1 |>
  left_join(adeff_stdt_all, by = c("USUBJID", "ACAT2")) |>
  mutate(
    DT      = if_else(PARAMCD == "DOR", DORDT, TRTSDT),
    STARTDT = as.Date(toupper(format(as.Date(DT, origin = "1970-01-01"), "%d%b%Y")), format = "%d%b%Y"),
    AVAL    = (ADT_SRC - DT + 1) / 30.4375,
    SRCDOM  = "ADEFF",
    ADT     = as.Date(ADT, format = "%d%b%Y")
  ) |>
  left_join(adbs, by = "USUBJID") |>
  select(-DT, -ADT_SRCCD, -ADT_SRC, -DORDT, -TRTSDT)


# =============================================================================
# STEP 9: Final Sequencing and Export
# =============================================================================

adtte3 <- adtte2 |>
  arrange(USUBJID, ACAT2N, PARAMN) |>
  mutate(ASEQ = as.integer(row_number()), .by = USUBJID)


# =============================================================================
# STEP 10: Apply Metadata Labels and Export
# =============================================================================

adtte3 |>
  save_adam(metacore, "ADTTE")
