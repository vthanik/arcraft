####----------------------------------------------------------------------####
# Program Name: adpr.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Emdadul Haque / eh605853
# Purpose: Creation of the Procedures Analysis Dataset (ADPR)
#
# Input:
#   - SDTM: PR, SUPPPR
#   - ADaM: ADBS (external)
#
# Output:
#   - prod/adamdata/adpr.parquet
#   - prod/submission/datasets/adpr.xpt
#
# Spec: inputdata/300382_ADPR_Spec.xlsx
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

metacore <- file.path(g_paths$inputdata, "300382_ADPR_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADPR") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load Input Datasets
# =============================================================================

pr  <- read_data_catalog(sdtmdata$pr)
spr <- read_data_catalog(sdtmdata$supppr)
prx <- combine_supp(pr, spr) |> rename_with(tolower)

adsl <- read_data_catalog(adamdata_ext$adbs) |>
  rename_with(tolower) |>
  select(-studyid)

pr2 <- inner_join(adsl, prx, by = "usubjid")


# =============================================================================
# STEP 3: Derive Core Analysis Variables
# =============================================================================

pr3 <- pr2 |>
  mutate(
    trtp    = str_trim(trt01p),
    trtpn   = trt01pn,
    trta    = str_trim(trt01a),
    trtan   = trt01an,
    avisit  = str_trim(visit),
    avisitn = visitnum,
    # Start date: full dates only
    astdt  = if_else(nchar(prstdtc) == 10, ymd(prstdtc), as.Date(NA)),
    astdtl = case_when(
      nchar(prstdtc) == 10 ~ toupper(format(ymd(prstdtc), "%d%b%Y")),
      nchar(prstdtc) == 7  ~ toupper(format(ymd(paste0(prstdtc, "-01")), "%b%Y")),
      nchar(prstdtc) == 4  ~ prstdtc
    ),
    # End date: full dates only
    aendt  = if_else(nchar(prendtc) == 10, ymd(prendtc), as.Date(NA)),
    aendtl = case_when(
      nchar(prendtc) == 10 ~ toupper(format(ymd(prendtc), "%d%b%Y")),
      nchar(prendtc) == 7  ~ toupper(format(ymd(paste0(prendtc, "-01")), "%b%Y")),
      nchar(prendtc) == 4  ~ prendtc
    ),
    astdy  = prstdy,
    aendy  = prendy,
    # "Other" specify handling
    prdosu = if_else(prdosu == "Other" & !is.na(prdosusp), paste0("Other: ", prdosusp), prdosu),
    prloc  = if_else(prloc == "OTHER" & !is.na(prlocoth), paste0("Other: ", prlocoth), prloc)
  )


# =============================================================================
# STEP 4: Derive PRINDC and Sequence
# =============================================================================

pr4 <- pr3 |>
  rowwise() |>
  mutate(
    prindc = case_when(
      prindc == "Other Indication" ~ paste0("Other: ", toupper(prindcsp)),
      prindc == "MULTIPLE"         ~ paste(na.omit(c_across(prindc1:prindc8)), collapse = ", "),
      prindc == "ADVERSE EVENT"    ~ paste0("Adverse Event: ", paste(na.omit(c_across(praerel1:praerel3)), collapse = ", ")),
      prindc == "MEDICAL HISTORY"  ~ paste0("Medical History: ", paste(na.omit(c_across(prmhrel1:prmhrel3)), collapse = ", ")),
      .default = str_trim(prindc)
    )
  ) |>
  ungroup() |>
  arrange(studyid, usubjid, prseq, astdt) |>
  mutate(aseq = row_number(), .by = usubjid)


# =============================================================================
# STEP 5: Select Final Variables and Export
# =============================================================================

pr5 <- pr4 |>
  rename_with(toupper) |>
  arrange(USUBJID, PRSEQ, ASTDT) |>
  select(
    STUDYID, USUBJID, SUBJID, SITEID, SAFFL, TRTP, TRTA, TRTPN, TRTAN,
    COHORT, COHORTN, COHGL, COHGLN, COHAGR1, COHAGR1N, PHASE, PHASEN,
    DOSELVL, DOSELVLN, AGE, AGEU, AGEGR1, AGEGR1N, SEX, RACE, ARM,
    TRT01P, TRT01PN, TRT01A, TRT01AN, DOSGRP, DOSGRPN, COUNTRY, ENRLFL,
    TRTSDT, TRTSDTM, TRTEDT, TRTEDTM, ASEQ, PRSEQ, PRTRT, PRDECOD, PRCAT,
    PROCCUR, PRPRESP, PRINDC, PRLOC, PRDOSE, PRDOSTXT, PRDOSU, VISIT,
    VISITNUM, AVISIT, AVISITN, PRSTDTC, ASTDT, ASTDY, ASTDTL, PRENDTC,
    AENDT, AENDY, AENDTL, PRSTRTPT, PRSTTPT, PRENRTPT, PRENTPT, PRRSDISC,
    PRRSDOTH, PRREASOC, PRHLGT, PRHLGTCD, PRHLT, PRHLTCD, PRLLT,
    PRLLTCD, PRPTCD, PRSOC, PRSOCCD
  )


# =============================================================================
# STEP 6: Apply Metadata Labels and Export
# =============================================================================

pr5 |>
  save_adam(metacore, "ADPR")
