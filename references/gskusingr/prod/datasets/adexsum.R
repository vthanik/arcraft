####----------------------------------------------------------------------####
# Program Name: adexsum.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Mariam Alaverdyan / ma584118
# Purpose: Creation of the Exposure Summary Analysis Dataset (ADEXSUM)
#
# Input:
#   - ADaM: ADEX, ADBS (external)
#
# Output:
#   - prod/adamdata/adexsum.parquet
#   - prod/submission/datasets/adexsum.xpt
#
# Spec: inputdata/300382_ADEXSUM_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "stringr", "tidyr", "purrr", "lubridate",
  "admiral", "metacore", "metatools", "xportr",
  "cards", "hms"
)

# Helper: SAS-style rounding (round half up)
round_sum <- function(x, digits = 0) {
  posneg <- sign(x)
  z <- abs(x) * 10^digits
  z <- floor(z + 0.5)
  posneg * z / 10^digits
}

metacore <- file.path(g_paths$inputdata, "300382_ADEXSUM_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADEXSUM") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================

adsl <- read_data_catalog(adamdata_ext$adbs) |>
  select(
    STUDYID, USUBJID, SUBJID, SITEID, SEX, RACE, COUNTRY,
    starts_with("TRT"), starts_with("AGE"), SAFFL, ENRLFL, ARM,
    COHAGR1, EOTSTT, starts_with("DOSGRP")
  ) |>
  mutate(
    TRTA = TRT01A, TRTP = TRT01P, TRTAN = TRT01AN, TRTPN = TRT01PN,
    # Derive planned daily dose from cohort grouping
    DOSEU  = str_trim(str_split(COHAGR1, "/", simplify = TRUE)[, 1]),
    DOSE   = as.numeric(gsub("[^0-9]", "", DOSEU)),
    EXDOSE = case_when(
      !is.na(DOSEU) & str_detect(DOSEU, "T") & DOSE == 100 ~ DOSE * 1.2,
      !is.na(DOSEU) & str_detect(DOSEU, "T") & DOSE == 200 ~ DOSE * 1.2,
      !is.na(DOSEU) & str_detect(DOSEU, "T") & DOSE == 300 ~ (DOSE * 4) / 3,
      !is.na(DOSEU) & str_detect(DOSEU, "T") & DOSE == 400 ~ DOSE * 1.125,
      !is.na(DOSEU) & str_detect(DOSEU, "T") & DOSE == 500 ~ DOSE,
      !is.na(DOSEU) & str_detect(DOSEU, "T") & DOSE == 600 ~ DOSE,
      .default = DOSE
    ),
    EXDOSE = if_else(!is.na(DOSEU) & str_detect(DOSEU, "BID"), DOSE * 2, EXDOSE)
  ) |>
  select(-DOSE, -DOSEU) |>
  filter(!is.na(EXDOSE))

adex <- read_data_catalog(adamdata_ext$adex) |>
  select(STUDYID, USUBJID, starts_with("EC"), CYCLES, ADOSE, ADOSU)

adex1 <- derive_vars_merged(adex, dataset_add = adsl, by_vars = exprs(STUDYID, USUBJID))


# =============================================================================
# STEP 3: Derive Exposure Summary Parameters
# =============================================================================

# --- 3a. TRTDUR: Duration of Exposure (days) ---
TRTDUR <- derive_var_trtdurd(adsl, start_date = TRTSDT, end_date = TRTEDT) |>
  mutate(
    DCODAT   = dmy(g_config$datadate),
    AVAL     = if_else(EOTSTT == "Ongoing Treatment", as.numeric(DCODAT - TRTSDT) + 1, TRTDURD),
    AVALC    = as.character(AVAL),
    AVALCAT1 = NA_character_,
    AVALCA1N = NA_real_,
    PARAM    = "Duration of Exposure, days",
    PARAMCD  = "TRTDUR",
    PARAMN   = 1
  ) |>
  distinct(USUBJID, .keep_all = TRUE) |>
  select(-TRTDURD, -DCODAT)

# --- 3b. NUMCYCLE: Number of Treatment Cycles Started ---
NUMCYCLE <- adex1 |>
  slice_tail(n = 1, by = USUBJID) |>
  mutate(
    AVALC    = paste0(CYCLES),
    AVAL     = as.numeric(AVALC),
    AVALCAT1 = NA_character_,
    AVALCA1N = NA_real_,
    PARAM    = "Number of Treatment Cycles Started",
    PARAMCD  = "NUMCYCLE",
    PARAMN   = 2
  ) |>
  select(-starts_with("EC"), -CYCLES)

# --- 3c. PLADOSE: Total Planned Dose ---
PLADOSE <- TRTDUR |>
  rename(TRTDUR_VAL = AVAL) |>
  mutate(
    AVAL     = EXDOSE * TRTDUR_VAL,
    AVALC    = as.character(AVAL),
    AVALCAT1 = NA_character_,
    AVALCA1N = NA_real_,
    PARAM    = "Total Planned Dose",
    PARAMCD  = "PLADOSE",
    PARAMN   = 3
  ) |>
  select(-TRTDUR_VAL)

# --- 3d. NUMDOSE: Number of Doses Received ---
dosmiss <- adex1 |>
  filter(ECOCCUR == "Y") |>
  mutate(
    DCODAT     = dmy(g_config$datadate),
    ECENDY     = if_else(
      EOTSTT == "Ongoing Treatment" & row_number() == n(),
      as.numeric(DCODAT - TRTSDT) + 1, ECENDY
    ),
    reciev_day = ECENDY - ECSTDY + (ECENDY >= ECSTDY),
    .by = USUBJID
  ) |>
  summarise(AVAL = sum(reciev_day), .by = USUBJID)

NUMDOSE <- left_join(dosmiss, adsl, by = "USUBJID") |>
  mutate(
    AVALC    = as.character(AVAL),
    AVALCAT1 = NA_character_,
    AVALCA1N = NA_real_,
    PARAM    = "Number of Doses Received",
    PARAMCD  = "NUMDOSE",
    PARAMN   = 4
  )

# --- 3e. CUMDOSE: Cumulative Dose of IDRX-42 (mg) ---
totdose <- adex1 |>
  filter(ECOCCUR == "Y") |>
  select(USUBJID, ADOSU, ECDOSFRM, ECDOSFRQ, ECSTDY, ECENDY, ADOSE, EOTSTT, TRTSDT) |>
  mutate(
    DCODAT     = dmy(g_config$datadate),
    ECENDY     = if_else(
      EOTSTT == "Ongoing Treatment" & row_number() == n(),
      as.numeric(DCODAT - TRTSDT) + 1, ECENDY
    ),
    reciev_day = ECENDY - ECSTDY + (ECENDY >= ECSTDY),
    # Tablet dose equivalence adjustments
    ADOSE = case_when(
      !is.na(ADOSU) & str_detect(ECDOSFRM, "TABLET") & ADOSE == 100 ~ ADOSE * 1.2,
      !is.na(ADOSU) & str_detect(ECDOSFRM, "TABLET") & ADOSE == 200 ~ ADOSE * 1.2,
      !is.na(ADOSU) & str_detect(ECDOSFRM, "TABLET") & ADOSE == 300 ~ (ADOSE * 4) / 3,
      !is.na(ADOSU) & str_detect(ECDOSFRM, "TABLET") & ADOSE == 400 ~ ADOSE * 1.125,
      !is.na(ADOSU) & str_detect(ECDOSFRM, "TABLET") & ADOSE == 500 ~ ADOSE,
      !is.na(ADOSU) & str_detect(ECDOSFRM, "TABLET") & ADOSE == 600 ~ ADOSE,
      .default = ADOSE
    ),
    ADOSE = if_else(!is.na(ADOSU) & str_detect(ECDOSFRQ, "BID"), ADOSE * 2, ADOSE),
    .by = USUBJID
  ) |>
  summarise(AVAL = sum(ADOSE * reciev_day), .by = USUBJID)

CUMDOSE <- left_join(totdose, adsl, by = "USUBJID") |>
  mutate(
    AVALC    = as.character(AVAL),
    AVALCAT1 = NA_character_,
    AVALCA1N = NA_real_,
    PARAM    = "Cumulative Dose of IDRX-42 (mg)",
    PARAMCD  = "CUMDOSE",
    PARAMN   = 5
  )

# --- 3f. AVGDOSE: Average Daily Dose (mg) ---
TRTDURAT <- TRTDUR |> select(USUBJID, TRTDUR_VAL = AVAL)

AVGDOSE <- left_join(CUMDOSE, TRTDURAT, by = "USUBJID") |>
  rename(CUMDOS = AVAL) |>
  mutate(
    AVAL     = round_sum(CUMDOS / TRTDUR_VAL, 0),
    AVALC    = as.character(AVAL),
    AVALCAT1 = NA_character_,
    AVALCA1N = NA_real_,
    PARAM    = "Average Daily Dose (mg)",
    PARAMCD  = "AVGDOSE",
    PARAMN   = 6
  ) |>
  select(-CUMDOS, -TRTDUR_VAL)

# --- 3g. RELDOSE: Relative Dose Intensity (%) ---
PLANNED <- PLADOSE |> select(USUBJID, PLADOS = AVAL)

RELDOSE <- left_join(CUMDOSE, PLANNED, by = "USUBJID") |>
  rename(CUMDOS = AVAL) |>
  mutate(
    AVAL     = round_sum((CUMDOS / PLADOS) * 100, 0),
    AVALC    = as.character(AVAL),
    AVALCAT1 = case_when(
      AVAL < 80                  ~ "<80%",
      AVAL >= 80 & AVAL <= 120   ~ "80-120%",
      AVAL > 120                 ~ ">120%"
    ),
    AVALCA1N = case_when(
      AVAL < 80                  ~ 1,
      AVAL >= 80 & AVAL <= 120   ~ 2,
      AVAL > 120                 ~ 3
    ),
    PARAM    = "Relative dose intensity (%)",
    PARAMCD  = "RELDOSE",
    PARAMN   = 7
  ) |>
  select(-CUMDOS, -PLADOS)


# =============================================================================
# STEP 4: Stack Parameters, Sequence, and Export
# =============================================================================

adexsum1 <- bind_rows(TRTDUR, NUMCYCLE, PLADOSE, NUMDOSE, CUMDOSE, AVGDOSE, RELDOSE) |>
  select(-starts_with("EX"), -starts_with("ADOS"), -EOTSTT) |>
  derive_var_obs_number(
    new_var = ASEQ,
    by_vars = exprs(STUDYID, USUBJID),
    order   = exprs(PARAMN)
  ) |>
  mutate(ASEQ = as.numeric(ASEQ))


# =============================================================================
# STEP 5: Apply Metadata Labels and Export
# =============================================================================

adexsum1 |>
  save_adam(metacore, "ADEXSUM")
