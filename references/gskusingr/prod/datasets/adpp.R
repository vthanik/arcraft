####----------------------------------------------------------------------####
# Program Name: adpp.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Emdadul Haque / eh605853
# Purpose: Creation of the Pharmacokinetic Parameters Dataset (ADPP)
#
# Input:
#   - SDTM: PP
#   - ADaM: ADBS (external)
#
# Output:
#   - prod/adamdata/adpp.parquet
#   - prod/submission/datasets/adpp.xpt
#
# Spec: inputdata/300382_ADPP_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "tidyr", "purrr", "stringr", "lubridate",
  "admiral", "metacore", "metatools", "xportr",
  "readr", "readxl", "janitor", "hms"
)

metacore <- file.path(g_paths$inputdata, "300382_ADPP_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADPP") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load Input Datasets
# =============================================================================

pp <- read_data_catalog(sdtmdata$pp) |>
  rename_with(tolower) |>
  select(-studyid)

adsl <- read_data_catalog(adamdata_ext$adbs) |>
  rename_with(tolower)

pp2 <- inner_join(adsl, pp, by = "usubjid")


# =============================================================================
# STEP 3: Derive Analysis Variables
# =============================================================================

param_order <- c(
  "AUCINT", "ARAUCINT", "ARCMAX", "LAMZHL", "LAMZ", "CLST",
  "CMAX", "TMAX", "TLST", "CLFO", "VZFO", "CLSSF",
  "VDSSF", "CTAU", "AUC0-8"
)

pp3 <- pp2 |>
  mutate(
    trtp    = str_trim(trt01p),
    trtpn   = trt01pn,
    trta    = str_trim(trt01a),
    trtan   = trt01an,
    avisit  = str_trim(visit),
    avisitn = visitnum,
    adt     = ymd(substr(ppdtc, 1, 10)),
    adtm    = ymd_hm(ppdtc),
    atm     = as_hms(adtm),
    aval    = ppstresn,
    avalc   = if_else(is.na(aval), str_trim(ppstresc), ""),
    avalu   = ppstresu,
    param   = str_trim(pptest),
    paramcd = str_trim(pptestcd),
    ady     = as.integer(adt - trtsdt) + if_else(adt >= trtsdt, 1L, 0L),
    paramn  = match(paramcd, param_order),
    parcat1 = str_trim(ppcat),
    NDFL    = if_else(ppstat == "NOT DONE", "Y", ""),
    avisitn = if_else(str_detect(avisit, "Unsch"), NA_real_, avisitn),
    avisit  = if_else(str_detect(avisit, "Unsch"), "", avisit)
  ) |>
  arrange(studyid, usubjid, paramcd, adt, adtm, avisitn) |>
  mutate(aseq = row_number(), .by = usubjid)


# =============================================================================
# STEP 4: Apply Metadata Labels and Export
# =============================================================================

pp3 |>
  rename_with(toupper) |>
  save_adam(metacore, "ADPP")
