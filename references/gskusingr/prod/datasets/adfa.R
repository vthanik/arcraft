####----------------------------------------------------------------------####
# Program Name: adfa.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: Creation of the Findings About Analysis Dataset (ADFA)
#
# Input:
#   - SDTM: FA, GF, SUPPGF
#   - ADaM: ADSL
#
# Output:
#   - prod/adamdata/adfa.parquet
#   - prod/submission/datasets/adfa.xpt
#
# Spec: inputdata/300382_ADFA_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "tidyr", "purrr", "stringr", "lubridate",
  "admiral", "metacore", "metatools", "xportr",
  "readr", "readxl", "janitor"
)

metacore <- file.path(g_paths$inputdata, "300382_ADFA_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADFA") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================

adsl <- read_data_catalog(adamdata$adsl) |>
  select(
    STUDYID, USUBJID, SUBJID, SITEID, AGE, AGEU, AGEGR1, AGEGR1N,
    SEX, RACE, COUNTRY, ENRLFL, SAFFL, ARM, DOSGRP, DOSGRPN,
    TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, TRTSDTM, TRTEDT, TRTEDTM, LSTALVDT
  ) |>
  mutate(TRTP = TRT01P, TRTA = TRT01A, TRTPN = TRT01PN, TRTAN = TRT01AN)

fa     <- read_sas_local(sdtmdata$fa)
gf     <- read_sas_local(sdtmdata$gf)
suppgf <- read_sas_local(sdtmdata$suppgf) |> convert_blanks_to_na()
supp_gf <- combine_supp(gf, suppgf)

# Merge with ADSL
fa1 <- fa |>
  derive_vars_merged(dataset_add = adsl, by = exprs(STUDYID, USUBJID))

gf1 <- supp_gf |>
  derive_vars_merged(dataset_add = adsl, by = exprs(STUDYID, USUBJID))


# =============================================================================
# STEP 3: Derive Date of Initial GIST Diagnosis Parameters
# =============================================================================

fa_ingis <- fa1 |>
  filter(FATESTCD == "DATE", FAOBJ == "Date of Initial GIST Diagnosis") |>
  derive_vars_dt(
    new_vars_prefix = "AV", dtc = FASTRESC,
    highest_imputation = "M", date_imputation = "first",
    min_dates = exprs(TRTSDT), flag_imputation = "none"
  ) |>
  mutate(
    AVDT    = if_else(AVDT > LSTALVDT, LSTALVDT, AVDT),
    PARAM   = "Date of Initial GIST Diagnosis",
    PARAMN  = 1,
    PARAMCD = "INGISTDT",
    AVALC   = toupper(format(AVDT, "%d%b%Y"))
  )

# Time since initial GIST diagnosis (months)
fa_timg <- fa_ingis |>
  select(-PARAM, -PARAMCD, -PARAMN, -AVALC, -VISIT, -VISITNUM, -VISITDY) |>
  mutate(
    PARAM   = "Time Since Date of Initial Diagnosis (months)",
    PARAMN  = 2,
    PARAMCD = "TIMGIST",
    AVAL    = if_else(
      !is.na(TRTSDT) & !is.na(AVDT),
      round((as.numeric(TRTSDT - AVDT) + 1) / 30.4375, 2), NA_real_
    ),
    AVALC = as.character(AVAL)
  )


# =============================================================================
# STEP 4: Derive Tumor Size and Mitotic Count Parameters
# =============================================================================

fa_size_mio <- fa1 |>
  filter(FATESTCD %in% c("SIZE", "OBJNUM")) |>
  mutate(
    PARAM = case_when(
      FATESTCD == "SIZE"   ~ "Size of the Primary Tumor (cm)",
      FATESTCD == "OBJNUM" ~ "Mitotic Count of Primary Tumor"
    ),
    PARAMN = case_when(FATESTCD == "SIZE" ~ 6, FATESTCD == "OBJNUM" ~ 7),
    PARAMCD = case_when(FATESTCD == "SIZE" ~ "SIZE", FATESTCD == "OBJNUM" ~ "MIOTCNT"),
    AVALC = FASTRESC
  )


# =============================================================================
# STEP 5: Derive Confirmed Metastatic GIST Diagnosis Parameters
# =============================================================================

fa_cms <- fa1 |>
  filter(
    FATESTCD == "DATE",
    FAOBJ == "Date of Confirmed Metastatic and/or Surgically Unresectable GIST Diagnosis"
  ) |>
  derive_vars_dt(
    new_vars_prefix = "AV", dtc = FASTRESC,
    highest_imputation = "M", date_imputation = "first",
    min_dates = exprs(TRTSDT), flag_imputation = "none"
  ) |>
  mutate(
    AVDT    = if_else(AVDT > LSTALVDT, LSTALVDT, AVDT),
    PARAM   = "Date of Confirmed Metastatic and/or Surgically Unresectable GIST Diagnosis",
    PARAMN  = 8,
    PARAMCD = "CMSUDT",
    AVALC   = toupper(format(AVDT, "%d%b%Y"))
  )

# Time since confirmed metastatic diagnosis
fa_timc <- fa_cms |>
  select(-PARAM, -PARAMCD, -PARAMN, -AVALC, -VISIT, -VISITNUM, -VISITDY) |>
  mutate(
    PARAM   = "Time Since Date of Confirmed Metastatic and/or Surgically Unresectable GIST Diagnosis",
    PARAMN  = 9,
    PARAMCD = "TIMCMS",
    AVAL    = if_else(
      !is.na(TRTSDT) & !is.na(AVDT),
      round((as.numeric(TRTSDT - AVDT) + 1) / 30.4375, 2), NA_real_
    ),
    AVALC = as.character(AVAL)
  )


# =============================================================================
# STEP 6: Derive Mutation Parameters from GF Domain
# =============================================================================

gf_mut <- gf1 |>
  filter(GFTESTCD == "SNV", !is.na(GFSYM)) |>
  mutate(PARAM = "Mutations", PARAMN = 3, PARAMCD = "MUTATION", AVALC = GFSYM, SPID = GFSPID)

gf_mutloc <- gf1 |>
  filter(GFTESTCD == "SNV", !is.na(GFGENSR)) |>
  mutate(PARAM = "Mutation Location", PARAMN = 4, PARAMCD = "MUTLOC", AVALC = GFGENSR, SPID = GFSPID)

gf_mutgen <- gf1 |>
  filter(GFTESTCD == "SNV", !is.na(GFSTRESC)) |>
  mutate(PARAM = "Mutation Genotype", PARAMN = 5, PARAMCD = "MUTGENTP", AVALC = GFSTRESC, SPID = GFSPID)


# =============================================================================
# STEP 7: Stack All Parameters, Sequence, and Finalize
# =============================================================================

fa_gf_combined <- bind_rows(
  fa_ingis, fa_timg, gf_mut, gf_mutloc, gf_mutgen, fa_size_mio, fa_cms, fa_timc
)

adfa <- fa_gf_combined |>
  mutate(
    PARCAT1 = "GIST DIAGNOSIS",
    AVISIT  = VISIT,
    AVISITN = VISITNUM,
    ANL01FL = if_else(is.na(AVALC), NA_character_, "Y")
  ) |>
  derive_var_obs_number(
    by_vars    = exprs(STUDYID, USUBJID, SUBJID),
    order      = exprs(STUDYID, USUBJID, SUBJID, PARAMN, AVISITN, SPID),
    new_var    = ASEQ,
    check_type = "none"
  ) |>
  mutate(ASEQ = as.numeric(ASEQ)) |>
  select(
    STUDYID, USUBJID, SUBJID, SITEID, AGE, AGEU, DOSGRP, DOSGRPN,
    AGEGR1, AGEGR1N, SEX, RACE, COUNTRY, ENRLFL, SAFFL, ARM,
    TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, TRTSDTM, TRTEDT, TRTEDTM,
    TRTP, TRTA, TRTPN, TRTAN, SPID, VISIT, VISITNUM, VISITDY,
    AVISIT, AVISITN, ASEQ, PARCAT1, PARAM, PARAMN, PARAMCD, AVAL, AVALC, ANL01FL
  ) |>
  arrange(STUDYID, USUBJID, ASEQ, AVISITN, PARCAT1, PARAMN)


# =============================================================================
# STEP 8: Apply Metadata Labels and Export
# =============================================================================

adfa |>
  save_adam(metacore, "ADFA")
