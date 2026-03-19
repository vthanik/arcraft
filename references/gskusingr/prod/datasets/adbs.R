####----------------------------------------------------------------------####
# Program Name: adbs.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Emdadul Haque / eh605853
# Purpose: Creation of the Base Subject-Level Dataset (ADBS)
#          Extends ADSL with study-specific variables: GIST mutation,
#          ctDNA exon flags, line of therapy, and dose group.
#
# Input:
#   - SDTM: GF, CM
#   - ADaM: ADSL
#   - External: rawdata/*.csv (ctDNA reports),
#               rawdata/lot0428_Medical Review_15SEP2025_GC.xlsx
#
# Output:
#   - prod/adamdata/adbs.parquet
#   - prod/submission/datasets/adbs.xpt
#
# Spec: N/A (derived from ADSL spec + study-level derivations)
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages
# =============================================================================

pkg_load(
  "dplyr", "readr", "readxl", "stringr", "haven",
  "janitor", "purrr"
)


# =============================================================================
# STEP 2: Load and Combine External ctDNA Data
# =============================================================================

ctdna_files <- c(
  "20250410_IDRX_SOW01_882Samples_G360Report.csv",
  "20250815_GSK_SOW35_16Samples_Guardant360Report.csv",
  "20251022_GSK_SOW35_158Samples_G360Report.csv"
)

ctdna_reports <- ctdna_files |>
  map(\(f) read_csv(
    file.path(g_paths$rawdata, f),
    show_col_types = FALSE,
    col_types = cols(.default = "c")
  )) |>
  list_rbind()

# SOW02 file uses a different header layout (skip first row)
ctdat1 <- read_csv(
  file.path(g_paths$rawdata, "20250314_IDRX_SOW02_20Samples_G360Report.csv"),
  skip = 1, show_col_types = FALSE,
  col_types = cols(.default = "c")
)

ctdna_long_raw <- bind_rows(ctdat1, ctdna_reports) |>
  clean_names()


# =============================================================================
# STEP 3: Process ctDNA Data to Subject-Level Exon Flags
# =============================================================================

ctdna_long <- ctdna_long_raw |>
  mutate(
    is_valid_record = toupper(sample_status) == "SUCCESS" &
      toupper(gene) == "KIT" &
      toupper(visit_name) == "C1D1D" &
      toupper(somatic_status) != "GERMLINE",
    `_ctexon9`  = if_else(is_valid_record & exon == 9,  "Y", NA_character_),
    `_ctexon11` = if_else(is_valid_record & exon == 11, "Y", NA_character_),
    `_ctexon13` = if_else(is_valid_record & exon == 13, "Y", NA_character_),
    `_ctexon14` = if_else(is_valid_record & exon == 14, "Y", NA_character_),
    `_ctexon17` = if_else(is_valid_record & exon == 17, "Y", NA_character_),
    `_ctexon18` = if_else(is_valid_record & exon == 18, "Y", NA_character_),
    subjid = if_else(
      nchar(str_extract(patient_id, "^[^-]+")) == 3,
      paste0("0", patient_id), patient_id
    )
  )

ctdna_summary_wide <- ctdna_long |>
  summarise(
    CTEXON9  = if_else(any(`_ctexon9`  == "Y", na.rm = TRUE), "Y", NA_character_),
    CTEXON11 = if_else(any(`_ctexon11` == "Y", na.rm = TRUE), "Y", NA_character_),
    CTEXON13 = if_else(any(`_ctexon13` == "Y", na.rm = TRUE), "Y", NA_character_),
    CTEXON14 = if_else(any(`_ctexon14` == "Y", na.rm = TRUE), "Y", NA_character_),
    CTEXON17 = if_else(any(`_ctexon17` == "Y", na.rm = TRUE), "Y", NA_character_),
    CTEXON18 = if_else(any(`_ctexon18` == "Y", na.rm = TRUE), "Y", NA_character_),
    .by = subjid
  )


# =============================================================================
# STEP 4: Process Line of Therapy (LOT) Data
# =============================================================================

lot_summary <- read_excel(
  file.path(g_paths$rawdata, "lot0428_Medical Review_15SEP2025_GC.xlsx")
) |>
  clean_names() |>
  filter(!is.na(lot)) |>
  mutate(LOTNUM = as.numeric(str_extract(lot, "\\d+$")), SUBJID = subject) |>
  select(SUBJID, LOTNUM)


# =============================================================================
# STEP 5: Load Core ADaM and SDTM Data
# =============================================================================

adsl <- read_data_catalog(adamdata$adsl)
gf   <- read_data_catalog(sdtmdata$gf)

gf_screening <- gf |>
  filter(toupper(VISIT) == "SCREENING") |>
  distinct(USUBJID, GFSYM)


# =============================================================================
# STEP 6: Join All Datasets
# =============================================================================

join1 <- adsl |>
  left_join(ctdna_summary_wide, by = c("SUBJID" = "subjid")) |>
  left_join(lot_summary, by = "SUBJID") |>
  left_join(gf_screening, by = "USUBJID")

# Calculate LOT from unique prior therapies (fallback)
calculated_lot <- read_data_catalog(sdtmdata$cm) |>
  filter(CMCAT == "PRIOR CANCER THERAPY") |>
  summarise(CALCULATED_LOTNUM = n_distinct(CMTRT) + 1, .by = USUBJID)

base <- join1 |>
  left_join(calculated_lot, by = "USUBJID") |>
  mutate(
    CALCLOT = !is.na(TRTSDT) & is.na(LOTNUM) & !is.na(CALCULATED_LOTNUM),
    LOTNUM  = if_else(
      !is.na(TRTSDT), coalesce(LOTNUM, CALCULATED_LOTNUM, 1), NA_real_
    )
  ) |>
  select(-CALCULATED_LOTNUM)


# =============================================================================
# STEP 7: Derive Final Variables
# =============================================================================

keepvars <- c(
  "STUDYID", "USUBJID", "SUBJID", "SITEID",
  "AGE", "AGEU", "BRTHDTC", "BRTHYR", "AGEGR1", "AGEGR1N",
  "SEX", "SEXN", "ASEX", "RACE", "RACEN", "RACEOTH", "ARACE", "ARACEN",
  "RACE1", "RACE2", "RACE3", "RACE4", "COUNTRY", "ETHNIC", "ETHNICN",
  "AETHNIC", "AETHNICN",
  "ARM", "ACTARM", "COHORT", "COHORTN", "COHORTNM", "COHPGR1", "COHPGR1N",
  "COHAGR1", "COHAGR1N", "COHGL", "COHGLN", "PHASE", "PHASEN",
  "LINEOT", "LINEOTN", "HEIGHTBL", "WEIGHTBL", "BMIBL", "BSABL", "ECOGBL",
  "RFSTDT", "RFENDT", "RFICDT", "RFXSTDT",
  "TRTSDTM", "TRTSDT", "TRTSTM", "TRTEDTM", "TRTEDT", "TRTEDY", "TRTETM",
  "RFXENDT", "EOTSTT", "EOTDT", "EOTDY", "DCTREAS", "DCTREASP",
  "EOSSTT", "EOSDT", "EOSDY", "DCSREAS", "DCSREASP",
  "DTHFL", "DTHDT", "DTHDY", "DTHCAUS", "DTHCAUSP", "DTH30TFL", "DTHA30FL",
  "LSTALVDT", "PROGDT", "PROGDY", "GISTDT", "TIMGIST",
  "TRT01P", "TRT01A", "TRT01PN", "TRT01AN",
  "DOSELVL", "DOSELVLN", "DOSFRM", "DOSFRQ",
  "SCRFFL", "ENRLFL", "SAFFL", "PKFL", "DLTFL", "EFFL",
  "GISTMUT", "GISTMUTN",
  "CTEXON9", "CTEXON11", "CTEXON13", "CTEXON14", "CTEXON17", "CTEXON18",
  "LINETHPY", "LOTCAT", "LOTCATN", "DOSGRP", "DOSGRPN"
)

var_labels <- list(
  GISTMUT  = "GIST Mutation",     GISTMUTN = "GIST Mutation (N)",
  CTEXON9  = "ctDNA Exon 9",      CTEXON11 = "ctDNA Exon 11",
  CTEXON13 = "ctDNA Exon 13",     CTEXON14 = "ctDNA Exon 14",
  CTEXON17 = "ctDNA Exon 17",     CTEXON18 = "ctDNA Exon 18",
  LINETHPY = "Line of Therapy",   LOTCAT   = "Line of Therapy Category",
  LOTCATN  = "Line of Therapy Category (N)",
  DOSGRP   = "Dose Group",        DOSGRPN  = "Dose Group (N)"
)

adbs <- base |>
  mutate(
    GISTMUT  = str_trim(GFSYM),
    GISTMUTN = case_when(GISTMUT == "KIT" ~ 1, GISTMUT == "PDGFRA" ~ 2),
    LINETHPY = LOTNUM,
    LOTCATN  = case_when(LOTNUM == 1 ~ 1, LOTNUM == 2 ~ 2, LOTNUM >= 3 ~ 3),
    LOTCAT = case_when(
      LOTCATN == 1 ~ "1st-line",
      LOTCATN == 2 ~ "2nd-line",
      LOTCATN == 3 ~ "3rd or later-line"
    ),
    DOSGRP = case_when(
      COHORTNM == "120MG QD CAPSULE"                          ~ "C120",
      COHORTNM %in% c("200MG QD TABLET", "240MG QD CAPSULE") ~ "T200/C240",
      COHORTNM %in% c("400MG QD CAPSULE", "300MG QD TABLET") ~ "T300/C400",
      COHORTNM == "500MG QD TABLET"                           ~ "T500",
      COHORTNM %in% c("600MG QD CAPSULE", "600MG QD TABLET") ~ "T600/C600",
      COHORTNM == "400MG BID CAPSULE"                         ~ "C800",
      COHORTNM == "600MG BID CAPSULE"                         ~ "C1200"
    ),
    DOSGRPN = case_when(
      DOSGRP == "C120"      ~ 1, DOSGRP == "T200/C240" ~ 2,
      DOSGRP == "T300/C400" ~ 3, DOSGRP == "T500"      ~ 4,
      DOSGRP == "T600/C600" ~ 5, DOSGRP == "C800"      ~ 6,
      DOSGRP == "C1200"     ~ 7
    )
  ) |>
  select(any_of(keepvars))

# Apply labels to study-specific variables
for (var in names(var_labels)) {
  if (var %in% names(adbs)) {
    attr(adbs[[var]], "label") <- var_labels[[var]]
  }
}


# =============================================================================
# STEP 8: Save the Final ADaM Dataset
# =============================================================================

haven::write_xpt(adbs, file.path(g_paths$submission_data, "adbs.xpt"))
arrow::write_parquet(adbs, file.path(g_paths$adamdata, "adbs.parquet"))
