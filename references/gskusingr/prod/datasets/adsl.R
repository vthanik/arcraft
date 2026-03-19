####----------------------------------------------------------------------####
# Program Name: adsl.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Vignesh Thanikachalam / vt704670
# Purpose: Creation of the Subject-Level Analysis Dataset (ADSL)
#
# Input:
#   - SDTM: DM, SUPPDM, EX, DD, DS, GF, PC, AE, SUPPAE, EC, SUPPEC,
#           RS, SUPPRS, VS, MH, CM, SUPPCM
#   - External: rawdata/*.csv (ctDNA reports),
#               rawdata/lot0428_Medical Review_15SEP2025_GC.xlsx
#
# Output:
#   - prod/adamdata/adsl.parquet
#   - prod/submission/datasets/adsl.xpt
#
# Spec: inputdata/300382_ADSL_Spec.xlsx
#
#-----------------------------------------------------------------------------


# =============================================================================
# STEP 1: Load Required Packages and Metacore Specification
# =============================================================================

pkg_load(
  "dplyr", "tidyr", "purrr", "stringr", "lubridate",
  "admiral", "metacore", "metatools", "xportr",
  "readr", "readxl",
  "janitor"
)

metacore <- file.path(g_paths$inputdata, "300382_ADSL_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADSL") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load and Prepare Input Datasets
# =============================================================================
# Predecessor: DM.STUDYID, DM.USUBJID, DM.SUBJID, DM.SITEID, DM.AGE, DM.AGEU,
#              DM.SEX, DM.RACE, DM.ETHNIC, DM.COUNTRY, DM.ARM, DM.ARMCD,
#              DM.ACTARM, DM.ACTARMCD, DM.BRTHDTC, DM.DTHFL
# Predecessor: SUPPDM.QVAL where QNAM in (RACE1-4, RACEOTH, STDYPHS, COHORT,
#              COHORTNM, DOSFRM, DOSFRQ)

read_sdtm <- function(domain, supp_domain = NULL) {
  df <- read_data_catalog(domain)
  if (!is.null(supp_domain)) {
    df <- combine_supp(df, read_data_catalog(supp_domain))
  }
  df
}

dm_df <- read_sdtm(sdtmdata$dm, sdtmdata$suppdm)
ex_df <- read_sdtm(sdtmdata$ex)
dd_df <- read_sdtm(sdtmdata$dd)
ds_df <- read_sdtm(sdtmdata$ds)
gf_df <- read_sdtm(sdtmdata$gf)
pc_df <- read_sdtm(sdtmdata$pc)
ae_df <- read_sdtm(sdtmdata$ae, sdtmdata$suppae)
ec_df <- read_sdtm(sdtmdata$ec, sdtmdata$suppec)
rs_df <- read_sdtm(sdtmdata$rs, sdtmdata$supprs)
vs_df <- read_sdtm(sdtmdata$vs)
mh_df <- read_sdtm(sdtmdata$mh)
cm_df <- read_sdtm(sdtmdata$cm, sdtmdata$suppcm)


# =============================================================================
# STEP 3: Pre-computation of Key Variables and Flags
# =============================================================================


# -- 3a. Treatment Start and End Dates (MT.ADSL.TRTSDT/TRTSDTM/TRTEDT/TRTEDTM)
# MT.ADSL.TRTSDT: "Derived from EX.EXSTDTC where EX.EXDOSE > 0. Earliest date."
# MT.ADSL.TRTSDTM: "Derived from EX.EXSTDTC where EX.EXDOSE > 0. Earliest datetime."
# MT.ADSL.TRTEDT: "Derived from EX.EXENDTC where EX.EXDOSE > 0. Latest date."
# MT.ADSL.TRTEDTM: "Derived from EX.EXENDTC where EX.EXDOSE > 0. Latest datetime."

ex_start_date_df <- ex_df |>
  filter(
    EXTRT == "IDRX-42",
    EXCAT == "IDRX-42 ADMINISTRATION",
    !is.na(EXSTDTC)
  ) |>
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "EXST",
    ignore_seconds_flag = TRUE
  ) |>
  slice_min(order_by = EXSTDTM, n = 1, by = USUBJID, with_ties = FALSE) |>
  mutate(
    USUBJID,
    TRTSDTM = if_else(nchar(EXSTDTC) == 10L, NA_POSIXct_, EXSTDTM),
    TRTSDT  = as_date(EXSTDTM),
    .keep = "none"
  )

ex_end_date_df <- ex_df |>
  filter(EXTRT == "IDRX-42") |>
  pivot_longer(
    cols      = c(EXSTDTC, EXENDTC),
    names_to  = "SRC",
    values_to = "EXDTC"
  ) |>
  filter(!is.na(EXDTC)) |>
  derive_vars_dtm(
    dtc = EXDTC,
    new_vars_prefix = "EX",
    ignore_seconds_flag = TRUE
  ) |>
  slice_max(order_by = EXDTM, n = 1, by = USUBJID, with_ties = FALSE) |>
  mutate(
    USUBJID,
    TRTEDTM = if_else(nchar(EXDTC) == 10L, NA_POSIXct_, EXDTM),
    TRTEDT  = as_date(EXDTM),
    .keep = "none"
  )


# -- 3b. PK Concentration Population Flag (MT.ADSL.PKFL) --------------------
# "Y for subjects with >= 1 dose and >= 1 post-dose measurable concentration"

pc_ms_conc_df <- inner_join(
  pc_df |> filter(PCTPT == "PREDOSE", !is.na(PCSTRESN)) |> distinct(USUBJID),
  pc_df |> filter(PCTPTNUM > 0, !is.na(PCSTRESN)) |> distinct(USUBJID),
  by = "USUBJID"
) |>
  mutate(PKCONCFL = "Y")


# -- 3c. DLT Flag for Cycle 1 (MT.ADSL.DLTFL) ------------------------------
# "Y if Phase 1 Dose Escalation and (DLT in first 28 days or compliance >= 75%)"

dlt_cycle1_df <- ae_df |>
  filter(AEDLTFL == "Y") |>
  derive_vars_dt(new_vars_prefix = "AEST", dtc = AESTDTC) |>
  inner_join(ex_start_date_df |> select(USUBJID, TRTSDT), by = "USUBJID") |>
  filter(AESTDT >= TRTSDT, AESTDT <= TRTSDT + 27L) |>
  distinct(USUBJID) |>
  mutate(HAS_DLT = "Y")


# -- 3d. Dose Compliance in Cycle 1 -----------------------------------------

dose_compliance_df <- ec_df |>
  filter(ECCAT == "STUDY DRUG RECORD", ECPRESP == "Y") |>
  inner_join(ex_start_date_df, by = "USUBJID") |>
  mutate(
    ECSTDT = as_date(ECSTDTC),
    ECENDT = as_date(ECENDTC),
    DLTEDT = TRTSDT + 27L
  ) |>
  filter(ECSTDT < DLTEDT) |>
  mutate(
    ECENDT       = if_else(ECENDT > DLTEDT, DLTEDT, ECENDT, missing = DLTEDT),
    DAYS         = as.numeric(ECENDT - ECSTDT + 1L),
    DOSE_PER_DAY = if_else(ECDOSFRQ == "BID", DAYS * 2, DAYS)
  ) |>
  reframe(
    ACTUAL_DOSE  = sum(DOSE_PER_DAY[ECOCCUR == "Y"], na.rm = TRUE),
    PLANNED_DOSE = sum(
      DOSE_PER_DAY[ECOCCUR == "Y" | ECDOSST == "DOSE MISSED"],
      na.rm = TRUE
    ),
    .by = USUBJID
  ) |>
  mutate(
    COMPL_PCT = if_else(PLANNED_DOSE > 0, (ACTUAL_DOSE / PLANNED_DOSE) * 100, NA_real_)
  )


# -- 3e. Response and Disease Progression Dates -----------------------------
# MT.ADSL.PROGDT: "From DS.DSSTDTC where DS.DSDECOD = 'PROGRESSIVE DISEASE'"

first_resp_df <- rs_df |>
  filter(RSCAT == "MRECIST DEMETRI 2013") |>
  slice_min(order_by = RSDTC, n = 1, by = USUBJID, with_ties = FALSE) |>
  mutate(USUBJID, RS_DATE = as_date(RSDTC), .keep = "none")

pd_dth_dates_df <- full_join(
  ds_df |>
    filter(DSDECOD == "PROGRESSIVE DISEASE") |>
    mutate(USUBJID, PD_DATE = as_date(DSSTDTC), .keep = "none"),
  ds_df |>
    filter(DSDECOD == "DEATH") |>
    mutate(USUBJID, DTH_DATE = as_date(DSSTDTC), .keep = "none"),
  by = "USUBJID"
)


# -- 3f. Baseline Height and Weight (MT.ADSL.HEIGHTBL / MT.ADSL.WEIGHTBL) ---
# "Last non-missing value from VS on or before first dose date"

baseline_ht_wt_df <- vs_df |>
  filter(VSTESTCD %in% c("HEIGHT", "WEIGHT"), is.na(VSSTAT)) |>
  inner_join(
    ex_start_date_df |> select(USUBJID, TRTSDTM),
    by = "USUBJID"
  ) |>
  derive_vars_dtm(
    dtc = VSDTC,
    new_vars_prefix = "A",
    ignore_seconds_flag = TRUE
  ) |>
  filter(ADTM <= TRTSDTM) |>
  slice_max(
    order_by  = ADTM,
    n         = 1,
    by        = c(USUBJID, VSTESTCD),
    with_ties = FALSE
  ) |>
  select(USUBJID, VSTESTCD, VSSTRESN) |>
  pivot_wider(
    names_from  = VSTESTCD,
    values_from = VSSTRESN,
    names_glue  = "{VSTESTCD}BL"
  )


# -- 3g. GIST Diagnosis Date (MT.ADSL.GISTDT) ------------------------------
# "Earliest date from MH where MHCAT='GIST DIAGNOSIS' and MHTERM='GIST'.
#  Partial date imputation: first of month, bounded below by TRTSDT."

gist_date_df <- mh_df |>
  filter(MHCAT == "GIST DIAGNOSIS", MHTERM == "GIST") |>
  left_join(ex_start_date_df, by = "USUBJID") |>
  derive_vars_dt(
    dtc              = MHSTDTC,
    new_vars_prefix  = "GIST",
    highest_imputation = "M",
    date_imputation  = "first",
    min_dates        = exprs(TRTSDT)
  ) |>
  select(USUBJID, GISTDT)


# -- 3h. ctDNA Mutation Summary (MT.ADSL.CTKITMUT) --------------------------
# "See Appendix III of the Reviewer's Guide"

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
  ))

ctdat1 <- read_csv(
  file.path(g_paths$rawdata, "20250314_IDRX_SOW02_20Samples_G360Report.csv"),
  skip           = 1,
  show_col_types = FALSE,
  col_types      = cols(.default = "c")
)

ctdna_mutations_df <- bind_rows(ctdat1, ctdna_reports) |>
  clean_names() |>
  filter(
    toupper(sample_status)  == "SUCCESS",
    toupper(gene)           == "KIT",
    toupper(visit_name)     == "C1D1D",
    toupper(somatic_status) != "GERMLINE",
    !is.na(exon)
  ) |>
  mutate(
    SUBJID = if_else(
      nchar(str_extract(patient_id, "^[^-]+")) == 3L,
      paste0("0", patient_id),
      patient_id
    )
  ) |>
  distinct(SUBJID, exon) |>
  arrange(SUBJID, as.numeric(exon)) |>
  summarise(CTKITMUT = paste("EXON", exon, collapse = ", "), .by = SUBJID)


# -- 3i. Line of Therapy (MT.ADSL.LINETHPY) ---------------------------------
# "See Appendix II of the Reviewer's Guide"

lot_summary_df <- file.path(
  g_paths$rawdata,
  "lot0428_Medical Review_15SEP2025_GC.xlsx"
) |>
  read_excel() |>
  clean_names() |>
  filter(!is.na(lot)) |>
  mutate(
    SUBJID = subject,
    LOTNUM  = as.numeric(str_extract(lot, "\\d+$")),
    .keep = "none"
  )

calc_lot_df <- cm_df |>
  filter(CMCAT == "PRIOR CANCER THERAPY") |>
  summarise(CALCULATED_LOTNUM = n_distinct(CMTRT) + 1L, .by = USUBJID)


# -- 3j. Known KIT Mutations (MT.ADSL.KNKITMUT) ----------------------------
# "From GF where VISIT='Screening' and GFTESTCD='SNV'. Clean GFGENSR
#  (remove parentheses). Sorted comma-separated unique locations per subject."

known_mut_df <- gf_df |>
  filter(VISIT == "Screening", GFTESTCD == "SNV") |>
  mutate(CLEANED_LOCATION = str_remove(GFGENSR, " \\(.*\\)")) |>
  summarise(
    KNKITMUT = paste(sort(unique(CLEANED_LOCATION)), collapse = ", "),
    .by = USUBJID
  )


# -- 3k. LINEOT / LINEOTN (MT.ADSL.LINEOT / MT.ADSL.LINEOTN) ---------------
# "Derived from SUPPCM.QVAL where QNAM = 'CMLINE'."

lineot_df <- cm_df |>
  filter(!is.na(CMLINE)) |>
  distinct(USUBJID, CMLINE) |>
  mutate(
    LINEOT = case_when(
      CMLINE == "SECOND LINE"                                    ~ "2nd-line therapy",
      CMLINE %in% c("THIRD LINE", "FOURTH LINE", "FIFTH LINE")  ~ "3rd- or later-line therapy",
      .default = NA_character_
    ),
    LINEOTN = case_when(
      LINEOT == "2nd-line therapy"              ~ 1,
      LINEOT == "3rd- or later-line therapy"    ~ 2
    )
  ) |>
  select(USUBJID, LINEOT, LINEOTN)


# =============================================================================
# STEP 4: Assemble the Final ADSL Dataset
# =============================================================================

# -- 4a. Collect all intermediate datasets for joining ---------------------
datasets_to_join <- list(
  ex_start_date_df,
  ex_end_date_df,
  # MT.ADSL.DTHCAUS: "DD.DDSTRESC where DD.DDTESTCD='PRCDTH'"
  # MT.ADSL.DTHCAUSP: "DD.DDORRES where DD.DDSTRESC in ('OTHER','ADVERSE EVENT')"
  dd_df |>
    filter(DDTESTCD == "PRCDTH") |>
    select(USUBJID, DTHCAUS = DDSTRESC, DTHCAUSP = DDORRES),
  # MT.ADSL.GISTMUT: "GF.GFSYM where GF.VISIT='SCREENING'"
  gf_df |>
    filter(GFTESTCD == "SNV") |>
    distinct(USUBJID, GISTMUT = GFSYM),
  pc_ms_conc_df,
  dlt_cycle1_df,
  dose_compliance_df,
  first_resp_df,
  pd_dth_dates_df,
  baseline_ht_wt_df,
  # MT.ADSL.ECOGBL: "RS.RSSTRESN where RS.RSCAT='ECOG' and RS.RSBLFL='Y'"
  rs_df |>
    filter(RSTESTCD == "ECOG101", RSBLFL == "Y") |>
    select(USUBJID, ECOGBL = RSSTRESN),
  gist_date_df,
  calc_lot_df,
  known_mut_df,
  lineot_df
)

# -- 4b. Sequential left joins --------------------------------------------
adsl <- reduce(
  datasets_to_join,
  \(df1, df2) left_join(df1, df2, by = "USUBJID"),
  .init = dm_df
) |>
  left_join(lot_summary_df, by = "SUBJID") |>
  left_join(ctdna_mutations_df, by = "SUBJID") |>
  # -- 4c. Last Alive Date (MT.ADSL.LSTALVDT) --------------------------------
  compute_lstalvdt(
    spec_path = file.path(g_paths$inputdata, "300382_ADSL_Spec.xlsx"),
    cutoffdt  = as.Date(g_config$datadate, "%d%b%Y"),
    sheet     = "Date Last Known Alive"
  ) |>

  # -- 4d. Derive core ADSL variables ----------------------------------------
  mutate(
    # ---- Reference Dates (MT.ADSL.RFSTDT / RFENDT / RFICDT / RFXSTDT / RFXENDT) ----
    # "Derived as numeric SAS date from DM.RFSTDTC / RFENDTC / RFICDTC / RFXSTDTC / RFXENDTC"
    RFSTDT  = as_date(RFSTDTC),
    RFENDT  = as_date(RFENDTC),
    RFICDT  = as_date(RFICDTC),
    RFXSTDT = as_date(RFXSTDTC),
    RFXENDT = as_date(RFXENDTC),

    # ---- Death Variables ----
    # MT.ADSL.DTHDT: "From DM.DTHDTC"
    DTHDT = as_date(DTHDTC),
    # MT.ADSL.DTHDY: "When DTHDT >= TRTSDT then DTHDT - TRTSDT + 1;
    #                 When DTHDT < TRTSDT then DTHDT - TRTSDT"
    DTHDY = case_when(
      !is.na(DTHDT) & !is.na(TRTSDT) & DTHDT >= TRTSDT ~ as.numeric(DTHDT - TRTSDT + 1L),
      !is.na(DTHDT) & !is.na(TRTSDT) & DTHDT <  TRTSDT ~ as.numeric(DTHDT - TRTSDT),
      .default = NA_real_
    ),
    DTHREL = as.numeric(DTHDT - TRTEDT + 1L),
    # MT.ADSL.DTH30TFL: "Y if 1 <= (DTHDT - TRTEDT + 1) <= 31"
    DTH30TFL = if_else(between(DTHREL, 1, 31), "Y", NA_character_),
    # MT.ADSL.DTHA30FL: "Y if (DTHDT - TRTEDT + 1) > 31"
    DTHA30FL = if_else(DTHREL > 31, "Y", NA_character_),
    # MT.ADSL.DTHCAUS: "DD.DDSTRESC where DD.DDTESTCD='PRCDTH'"
    DTHCAUS  = str_to_title(DTHCAUS),
    # MT.ADSL.DTHCAUSP: "DD.DDORRES where DD.DDSTRESC in ('OTHER','ADVERSE EVENT')"
    DTHCAUSP = if_else(
      DTHCAUS %in% c("Other", "Adverse Event"), DTHCAUSP, NA_character_
    ),

    # ---- Demographics (MT.ADSL.BRTHYR / AGEGR1 / ARACE / ASEX / AETHNIC) ----
    # MT.ADSL.BRTHYR: "Year part of DM.BRTHDTC"
    BRTHYR = substr(BRTHDTC, 1L, 4L),
    # MT.ADSL.AGEGR1: "'< 65' if AGE < 65; '>= 65' if AGE >= 65; else 'Missing'"
    AGEGR1 = case_when(
      AGE < 65  ~ "< 65",
      AGE >= 65 ~ ">= 65",
      .default  = "Missing"
    ),
    # MT.ADSL.ARACE: "Proper case of DM.RACE. When RACE='OTHER', concat with RACEOTH"
    ARACE = case_when(
      toupper(RACE) == "OTHER" & !is.na(RACEOTH) ~
        paste0("Other: ", tolower(RACEOTH)),
      .default = tools::toTitleCase(tolower(RACE))
    ),
    # MT.ADSL.ASEX: "Male if DM.SEX='M'; Female if 'F'; Undifferentiated if 'UNDIFFERENTIATED'"
    ASEX = case_when(
      SEX == "M" ~ "Male",
      SEX == "F" ~ "Female",
      SEX == "UNDIFFERENTIATED" ~ "Undifferentiated",
      .default = NA_character_
    ),
    # Predecessor: DM.ETHNIC -> AETHNIC (same value)
    AETHNIC = ETHNIC,

    # ---- Baseline Characteristics ----
    # MT.ADSL.BMIBL: "WEIGHTBL / (HEIGHTBL / 100)^2, rounded to 1 decimal"
    BMIBL   = cards::round5(WEIGHTBL / (HEIGHTBL / 100)^2, 1),
    # MT.ADSL.BSABL: "sqrt(HEIGHTBL * WEIGHTBL / 3600)"
    BSABL   = if_else(
      !is.na(HEIGHTBL) & !is.na(WEIGHTBL),
      sqrt(HEIGHTBL * WEIGHTBL / 3600),
      NA_real_
    ),
    # MT.ADSL.TIMGIST: "(TRTSDT - GISTDT + 1) / 30.4375, rounded to 2 decimals"
    TIMGIST = as.numeric(cards::round5((TRTSDT - GISTDT + 1L) / 30.4375, 2)),
    ECOGBL  = as.numeric(ECOGBL),

    # ---- Treatment Variables ----
    # MT.ADSL.TRT01P: "DM.ARM with '(Phase X)' removed. Missing if SCREEN FAILURE."
    TRT01P = if_else(
      !ARMNRS %in% "SCREEN FAILURE",
      str_remove(ARM, " \\(.*\\)"),
      NA_character_
    ),
    # MT.ADSL.TRT01A: "DM.ACTARM with '(Phase X)' removed. Missing if SCREEN FAILURE or NOT ASSIGNED."
    TRT01A = if_else(
      !ARMNRS %in% c("SCREEN FAILURE", "NOT ASSIGNED"),
      str_remove(ACTARM, " \\(.*\\)"),
      NA_character_
    ),
    # Predecessor: SUPPDM.QVAL where QNAM='STDYPHS'
    PHASE = STDYPHS,
    # Predecessor: SUPPDM.QVAL where QNAM='DOSFRM' / 'DOSFRQ'
    # (these come through combine_supp on DM+SUPPDM)

    # MT.ADSL.DOSGRP: "Based on COHORTNM"
    DOSGRP = case_when(
      COHORTNM == "120MG QD CAPSULE"                              ~ "C120",
      COHORTNM %in% c("200MG QD TABLET", "240MG QD CAPSULE")     ~ "T200/C240",
      COHORTNM %in% c("400MG QD CAPSULE", "300MG QD TABLET")     ~ "T300/C400",
      COHORTNM == "500MG QD TABLET"                               ~ "T500",
      COHORTNM %in% c("600MG QD CAPSULE", "600MG QD TABLET")     ~ "T600/C600",
      COHORTNM == "400MG BID CAPSULE"                             ~ "C800",
      COHORTNM == "600MG BID CAPSULE"                             ~ "C1200"
    ),

    # ---- Population Flags ----
    # MT.ADSL.SCRFFL: "Y if DM.ARMNRS='SCREEN FAILURE'; else N"
    SCRFFL = if_else(ARMNRS == "SCREEN FAILURE", "Y", "N", missing = "N"),
    # MT.ADSL.ENRLFL: "Y if DM.RFICDTC not missing; else N"
    ENRLFL = if_else(!is.na(RFICDTC), "Y", "N", missing = "N"),
    # MT.ADSL.SAFFL: "Y if enrolled and TRTSDT not missing; else N"
    SAFFL  = if_else(!is.na(TRTSDT), "Y", "N", missing = "N"),
    # MT.ADSL.PKFL: "Y if >= 1 dose and >= 1 post-dose measurable conc; else N"
    PKFL   = if_else(SAFFL == "Y" & PKCONCFL == "Y", "Y", "N", missing = "N"),
    # MT.ADSL.DLTFL: "Y if Phase 1 Dose Escalation and (DLT or compliance >= 75%)"
    DLTFL  = if_else(
      PHASE == "PHASE 1 DOSE ESCALATION" & (HAS_DLT == "Y" | COMPL_PCT >= 75),
      "Y", "N", missing = "N"
    ),
    # MT.ADSL.CQTCFL: "Y if SAFFL='Y' and enrolled in C-QTc sub-study with PK + ECG"
    # Placeholder — requires C-QTc sub-study enrollment data
    CQTCFL = NA_character_,

    # MT.ADSL.EFFL: "Y if >= 1 dose and (post-baseline tumor assessment or
    #                early progression/death); else N"
    FIRST_RSDATE = coalesce(RS_DATE, as.Date("9999-12-31")),
    EARLY_PD     = if_else(PD_DATE  < FIRST_RSDATE, "Y", "N"),
    EARLY_DTH    = if_else(DTH_DATE < FIRST_RSDATE, "Y", "N"),
    EFFL = if_else(
      SAFFL == "Y" & (!is.na(RS_DATE) | EARLY_PD == "Y" | EARLY_DTH == "Y"),
      "Y", "N", missing = "N"
    ),

    # MT.ADSL.PROGDT: "From DS.DSSTDTC where DS.DSDECOD='PROGRESSIVE DISEASE'"
    PROGDT = PD_DATE,

    # ---- Line of Therapy ----
    # MT.ADSL.LINETHPY: "See Appendix II"
    LINETHPY = if_else(
      SAFFL == "Y",
      coalesce(LOTNUM, CALCULATED_LOTNUM, 1),
      NA_real_
    ),
    # MT.ADSL.LOTCAT: "1st-line if 1; 2nd-line if 2; 3rd or later-line if >= 3"
    LOTCAT = case_when(
      LINETHPY == 1  ~ "1st-line",
      LINETHPY == 2  ~ "2nd-line",
      LINETHPY >= 3  ~ "3rd or later-line"
    ),

    # ---- Cohort/Dose Derivations ----
    # MT.ADSL.COHAGR1: "For Phase 1 DE: DOSE||DOSFRQ||DOSFRM. For Phase 1b: actual cohort."
    COHAGR1 = case_when(
      !is.na(COHORTNM) ~ COHORTNM,
      .default = NA_character_
    ),
    # MT.ADSL.COHGL: "For Phase 1 DE: COHAGR1. For Phase 1b: cohort description."
    COHGL = COHAGR1,
    # MT.ADSL.COHPGR1: "Pooled planned cohort"
    COHPGR1 = COHAGR1,
    # MT.ADSL.DOSELVL: "Dose level portion of TRT01P (e.g., '120 mg')"
    DOSELVL = str_extract(TRT01P, "\\d+\\s*mg"),
    DOSELVL = if_else(is.na(DOSELVL) & !is.na(TRT01P),
                      str_extract(TRT01P, "^[^/]+"), DOSELVL)
  ) |>

  # -- 4e. Disposition Status and Reason ------------------------------------
  # MT.ADSL.EOSSTT: "Off Study if DS DISPOSITION EVENT/TRIAL exists; else On Study"
  derive_vars_merged(
    dataset_add    = ds_df,
    by_vars        = exprs(STUDYID, USUBJID),
    filter_add     = DSCAT == "DISPOSITION EVENT" & DSSCAT == "TRIAL",
    new_vars       = exprs(EOSSTT = "Off Study"),
    missing_values = exprs(EOSSTT = "On Study")
  ) |>
  # MT.ADSL.EOSDT: "From DS.DSSTDTC where DISPOSITION EVENT/TRIAL"
  derive_vars_merged(
    dataset_add = ds_df,
    by_vars     = exprs(STUDYID, USUBJID),
    filter_add  = DSCAT == "DISPOSITION EVENT" & DSSCAT == "TRIAL",
    new_vars    = exprs(EOSDT = as_date(DSSTDTC))
  ) |>
  # MT.ADSL.DCSREAS: "Proper case of DS.DSDECOD; 'Study Completion' if COMPLETED"
  derive_vars_merged(
    dataset_add = ds_df,
    by_vars     = exprs(STUDYID, USUBJID),
    filter_add  = DSCAT == "DISPOSITION EVENT" & DSSCAT == "TRIAL",
    new_vars    = exprs(
      DCSREAS = if_else(
        DSDECOD == "COMPLETED", "Study Completion", tools::toTitleCase(tolower(DSDECOD))
      )
    )
  ) |>
  # MT.ADSL.DCSREASP: "Proper case of DS.DSTERM when DSDECOD='OTHER'"
  derive_vars_merged(
    dataset_add = ds_df,
    by_vars     = exprs(STUDYID, USUBJID),
    filter_add  = DSCAT == "DISPOSITION EVENT" & DSSCAT == "TRIAL" &
                  DSDECOD == "OTHER",
    new_vars    = exprs(DCSREASP = str_to_title(DSTERM))
  ) |>
  # MT.ADSL.EOTSTT: "Discontinued Treatment if DS TREATMENT exists; else Ongoing"
  derive_vars_merged(
    dataset_add    = ds_df,
    by_vars        = exprs(STUDYID, USUBJID),
    filter_add     = DSCAT == "DISPOSITION EVENT" & DSSCAT == "TREATMENT",
    new_vars       = exprs(EOTSTT = "Discontinued Treatment")
  ) |>
  mutate(
    EOTSTT = if_else(is.na(EOTSTT) & SAFFL == "Y", "Ongoing Treatment", EOTSTT)
  ) |>
  # MT.ADSL.EOTDT: "From DS.DSSTDTC where DISPOSITION EVENT/TREATMENT"
  derive_vars_merged(
    dataset_add = ds_df,
    by_vars     = exprs(STUDYID, USUBJID),
    filter_add  = DSCAT == "DISPOSITION EVENT" & DSSCAT == "TREATMENT",
    new_vars    = exprs(EOTDT = as_date(DSSTDTC))
  ) |>
  # MT.ADSL.DCTREAS: "Proper case based on DSDECOD with special mappings"
  derive_vars_merged(
    dataset_add = ds_df |>
      filter(DSCAT == "DISPOSITION EVENT", DSSCAT == "TREATMENT") |>
      mutate(
        DCTREAS = case_when(
          DSDECOD == "PROGRESSIVE DISEASE"    ~ str_to_title(DSTERM),
          DSDECOD == "WITHDRAWAL OF CONSENT"  ~ "Withdrawal of Consent by Patient",
          DSTERM == "INITIATION OF NON-STUDY SPECIFIC ANTI-NEOPLASTIC THERAPY" ~
            "Initiation of New Therapy",
          .default = str_to_title(DSDECOD)
        )
      ),
    by_vars  = exprs(STUDYID, USUBJID),
    new_vars = exprs(DCTREAS)
  ) |>
  # MT.ADSL.DCTREASP: "Proper case of DSTERM when DSDECOD in ('OTHER','ADVERSE EVENT')"
  derive_vars_merged(
    dataset_add = ds_df,
    by_vars     = exprs(STUDYID, USUBJID),
    filter_add  = DSCAT == "DISPOSITION EVENT" & DSSCAT == "TREATMENT" &
                  DSDECOD %in% c("OTHER", "ADVERSE EVENT"),
    new_vars    = exprs(DCTREASP = str_to_title(DSTERM))
  ) |>

  # -- 4f. Derive Day Variables and Time Components --------------------------
  mutate(
    # MT.ADSL.PROGDY: "From DS.DSSTDY where DSDECOD='PROGRESSIVE DISEASE'"
    PROGDY = case_when(
      !is.na(PROGDT) & !is.na(TRTSDT) & PROGDT >= TRTSDT ~ as.numeric(PROGDT - TRTSDT + 1L),
      !is.na(PROGDT) & !is.na(TRTSDT) & PROGDT <  TRTSDT ~ as.numeric(PROGDT - TRTSDT),
      .default = NA_real_
    ),
    # MT.ADSL.EOSDY: "From DS.DSSTDY where DISPOSITION EVENT/TRIAL"
    EOSDY = case_when(
      !is.na(EOSDT) & !is.na(TRTSDT) & EOSDT >= TRTSDT ~ as.numeric(EOSDT - TRTSDT + 1L),
      !is.na(EOSDT) & !is.na(TRTSDT) & EOSDT <  TRTSDT ~ as.numeric(EOSDT - TRTSDT),
      .default = NA_real_
    ),
    # MT.ADSL.EOTDY: "From DS.DSSTDY where DISPOSITION EVENT/TREATMENT"
    EOTDY = case_when(
      !is.na(EOTDT) & !is.na(TRTSDT) & EOTDT >= TRTSDT ~ as.numeric(EOTDT - TRTSDT + 1L),
      !is.na(EOTDT) & !is.na(TRTSDT) & EOTDT <  TRTSDT ~ as.numeric(EOTDT - TRTSDT),
      .default = NA_real_
    ),
    # TRTEDY (not in spec methods but used by ADBS)
    TRTEDY = case_when(
      !is.na(TRTEDT) & !is.na(TRTSDT) & TRTEDT >= TRTSDT ~ as.numeric(TRTEDT - TRTSDT + 1L),
      !is.na(TRTEDT) & !is.na(TRTSDT) & TRTEDT <  TRTSDT ~ as.numeric(TRTEDT - TRTSDT),
      .default = NA_real_
    )
  ) |>
  # MT.ADSL.TRTSTM / TRTETM: "Time part of TRTSDTM / TRTEDTM"
  derive_vars_dtm_to_tm(exprs(TRTSDTM, TRTEDTM)) |>

  # -- 4g. Assigned numeric codes via metacore codelists ---------------------
  create_var_from_codelist(metacore, input_var = SEX,    out_var = SEXN) |>
  create_var_from_codelist(metacore, input_var = AGEGR1, out_var = AGEGR1N) |>
  create_var_from_codelist(metacore, input_var = RACE,   out_var = RACEN) |>
  create_var_from_codelist(metacore, input_var = ARACE,  out_var = ARACEN) |>
  create_var_from_codelist(metacore, input_var = ETHNIC, out_var = ETHNICN) |>
  create_var_from_codelist(metacore, input_var = AETHNIC, out_var = AETHNICN, strict = FALSE) |>
  create_var_from_codelist(metacore, input_var = TRT01P, out_var = TRT01PN, strict = FALSE) |>
  create_var_from_codelist(metacore, input_var = TRT01A, out_var = TRT01AN, strict = FALSE) |>
  create_var_from_codelist(metacore, input_var = PHASE,  out_var = PHASEN,  strict = FALSE) |>
  create_var_from_codelist(metacore, input_var = COHORT, out_var = COHORTN, strict = FALSE) |>
  create_var_from_codelist(metacore, input_var = DOSGRP, out_var = DOSGRPN, strict = FALSE) |>
  create_var_from_codelist(metacore, input_var = COHAGR1, out_var = COHAGR1N, strict = FALSE) |>
  create_var_from_codelist(metacore, input_var = COHGL,   out_var = COHGLN,   strict = FALSE) |>
  create_var_from_codelist(metacore, input_var = COHPGR1, out_var = COHPGR1N, strict = FALSE) |>
  create_var_from_codelist(metacore, input_var = DOSELVL, out_var = DOSELVLN, strict = FALSE) |>
  mutate(
    COHORTN = as.numeric(COHORTN)
  ) |>

  # -- 4h. Apply metadata labels and export ----------------------------------
  save_adam(metacore, "ADSL")
