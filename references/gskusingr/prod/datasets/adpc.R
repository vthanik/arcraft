####----------------------------------------------------------------------####
# Program Name: adpc.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Emdadul Haque / eh605853
# Purpose: Creation of the Pharmacokinetic Concentrations Dataset (ADPC)
#
# Input:
#   - SDTM: PC
#   - ADaM: ADBS (external)
#
# Output:
#   - prod/adamdata/adpc.parquet
#   - prod/submission/datasets/adpc.xpt
#
# Spec: inputdata/300382_ADPC_Spec.xlsx
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

metacore <- file.path(g_paths$inputdata, "300382_ADPC_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADPC") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load Input Datasets
# =============================================================================

pc <- read_data_catalog(sdtmdata$pc) |>
  rename_with(tolower) |>
  select(-studyid)

adsl <- read_data_catalog(adamdata_ext$adbs) |>
  rename_with(tolower)

pc2 <- inner_join(adsl, pc, by = "usubjid")


# =============================================================================
# STEP 3: Derive Analysis Variables
# =============================================================================

pc3 <- pc2 |>
  mutate(
    trtp    = str_trim(trt01p),
    trtpn   = trt01pn,
    trta    = str_trim(trt01a),
    trtan   = trt01an,
    avisit  = str_trim(visit),
    avisitn = visitnum,
    atpt    = pctpt,
    atptn   = pctptnum,
    adt     = ymd(substr(pcdtc, 1, 10)),
    adtm    = ymd_hm(pcdtc),
    atm     = as_hms(adtm),
    aval    = pcstresn,
    avalc   = str_trim(pcstresc),
    avalu   = pcstresu,
    param   = str_trim(pctest),
    paramcd = str_trim(pctestcd),
    ady     = as.integer(adt - trtsdt) + if_else(adt >= trtsdt, 1L, 0L),
    paramn  = 1,
    parcat1 = str_trim(pccat),
    NDFL    = if_else(pcstat == "NOT DONE", "Y", ""),
    avisitn = if_else(str_detect(avisit, "Unsch"), NA_real_, avisitn),
    avisit  = if_else(str_detect(avisit, "Unsch"), "", avisit)
  ) |>
  arrange(studyid, usubjid, paramcd, adt, adtm, avisitn) |>
  mutate(aseq = row_number(), .by = usubjid)


# =============================================================================
# STEP 4: Apply Metadata Labels and Export
# =============================================================================

pc3 |>
  rename_with(toupper) |>
  save_adam(metacore, "ADPC")
