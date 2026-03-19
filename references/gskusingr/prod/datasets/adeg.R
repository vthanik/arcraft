####----------------------------------------------------------------------####
# Program Name: adeg.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1
# Developer: Emdadul Haque / eh605853
# Purpose: Creation of the ECG Analysis Dataset (ADEG)
#
# Input:
#   - SDTM: EG, SUPPEG, PP
#   - ADaM: ADBS (external)
#
# Output:
#   - prod/adamdata/adeg.parquet
#   - prod/submission/datasets/adeg.xpt
#
# Spec: inputdata/300382_ADEG_Spec.xlsx
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

metacore <- file.path(g_paths$inputdata, "300382_ADEG_Spec.xlsx") |>
  spec_to_metacore(where_sep_sheet = FALSE, quiet = TRUE) |>
  select_dataset("ADEG") |>
  suppressWarnings()


# =============================================================================
# STEP 2: Load Input Datasets
# =============================================================================

eg  <- read_data_catalog(sdtmdata$eg)
seg <- read_data_catalog(sdtmdata$suppeg)

egx <- combine_supp(eg, seg) |>
  rename_with(str_to_lower) |>
  select(-studyid)

pp <- read_data_catalog(sdtmdata$pp) |>
  rename_with(tolower)

adsl <- read_data_catalog(adamdata_ext$adbs) |>
  rename_with(tolower)


# =============================================================================
# STEP 3: Create Mean ECG Records
# =============================================================================
# For averaging parameters, compute the mean of replicate ECG measurements
# within each subject/test/visit/timepoint combination.

mean_testcds <- c("EGHRMN", "PRAG", "QRSAG", "QTAG", "QTCBAG", "QTCFAG")

mean_records <- egx |>
  filter(egtestcd %in% mean_testcds) |>
  select(
    usubjid, egtestcd, visitnum, visit, egtptnum, egtpt,
    egdtc, egseq, egcat, egscat, egstresn, egstresu
  ) |>
  mutate(
    egstresn = mean(egstresn, na.rm = TRUE),
    .by = c(usubjid, egtestcd, visitnum, visit, egtptnum, egtpt)
  ) |>
  arrange(usubjid, egtestcd, visitnum, visit, egtptnum, egtpt, egdtc) |>
  slice_tail(n = 1, by = c(usubjid, egtestcd, visitnum, visit, egtptnum, egtpt)) |>
  mutate(
    egtestcd = paste0("M", egtestcd)
  )

egf <- bind_rows(egx, mean_records)


# =============================================================================
# STEP 4: Merge with ADSL and Derive Core Variables
# =============================================================================

param_order <- c(
  "EGALL", "AVCOND", "AXISVOLT", "CHYPTENL", "EGHRMN", "INTP",
  "IVTIACD", "PRAG", "QRSAG", "QTAG", "QTCBAG", "QTCFAG",
  "RRAG", "STSTWUW", "SNRARRY", "SPRARRY", "TECHQUAL",
  "MEGHRMN", "MPRAG", "MQRSAG", "MQTAG", "MQTCBAG", "MQTCFAG",
  "VTARRY", "SPRTARRY", "MI"
)

eg2 <- inner_join(adsl, egf, by = "usubjid") |>
  mutate(
    trtp    = str_trim(trt01p),
    trtpn   = trt01pn,
    trta    = str_trim(trt01a),
    trtan   = trt01an,
    aval    = round(egstresn, 2),
    aval    = na_if(aval, NaN),
    avalc   = as.character(aval),
    avalc   = if_else(is.na(aval), egstresc, avalc),
    avalu   = egstresu,
    param   = str_trim(egtest),
    paramcd = str_trim(egtestcd),
    paramn  = match(paramcd, param_order),
    avisit  = str_trim(visit),
    avisitn = visitnum,
    adt     = ymd(substr(egdtc, 1, 10)),
    adtm    = ymd_hms(egdtc),
    atm     = as_hms(adtm),
    ady     = as.integer(adt - trtsdt) + if_else(adt >= trtsdt, 1L, 0L)
  )


# =============================================================================
# STEP 5: Derive Baseline
# =============================================================================

eg3 <- eg2 |>
  mutate(
    adtms    = if_else(!is.na(adtm), as.numeric(adtm), as.numeric(adt) * 86400),
    trtsdtms = if_else(!is.na(trtsdtm), as.numeric(trtsdtm), as.numeric(trtsdt) * 86400),
    pre      = if_else(adtms <= trtsdtms, "Y", "N")
  )

baseline <- eg3 |>
  filter(pre == "Y", !is.na(aval)) |>
  arrange(usubjid, paramcd, param, desc(adtms)) |>
  slice(1, .by = c(usubjid, paramcd, param)) |>
  rename(bsdtms = adtms, base = aval, bdy = ady) |>
  select(usubjid, paramcd, param, bsdtms, base, bdy)

eg4 <- left_join(eg3, baseline, by = c("usubjid", "paramcd", "param")) |>
  mutate(
    ablfl = if_else(adtms == bsdtms, "Y", NA_character_),
    chg   = if_else(!is.na(aval) & !is.na(base) & pre == "N", aval - base, NA_real_),
    pchg  = round(if_else(!is.na(base) & base != 0, 100 * chg / base, NA_real_), 1),
    CHGCAT1  = if_else(paramcd == "MQTCFAG" & chg > 30, ">30 msec", NA_character_),
    CHGCAT1N = if_else(paramcd == "MQTCFAG" & chg > 30, 1, NA_real_),
    CHGCAT2  = if_else(paramcd == "MQTCFAG" & chg > 60, ">60 msec", NA_character_),
    CHGCAT2N = if_else(paramcd == "MQTCFAG" & chg > 60, 2, NA_real_)
  ) |>
  arrange(usubjid, paramcd, egseq, adt, adtm, adtms)


# =============================================================================
# STEP 6: Derive Analysis Flags and Clinical Criteria
# =============================================================================

eg5 <- eg4 |>
  mutate(
    anl01fl = if_else(
      paramcd %in% c("MEGHRMN", "MPRAG", "MQRSAG", "MQTAG", "MQTCBAG", "MQTCFAG") &
        (ablfl == "Y" | pre == "N") & !is.na(aval),
      "Y", NA_character_
    ),
    # QTcF criteria (post-baseline only: ady >= bdy)
    crit1   = if_else(paramcd == "MQTCFAG" & !is.na(bdy) & ady >= bdy & aval > 450 & base <= 450,
                      ">450 and baseline <=450", NA_character_),
    crit1fl = if_else(!is.na(crit1), "Y", NA_character_),
    crit2   = if_else(paramcd == "MQTCFAG" & !is.na(bdy) & ady >= bdy & aval > 480 & base <= 480,
                      ">480 and baseline <=480", NA_character_),
    crit2fl = if_else(!is.na(crit2), "Y", NA_character_),
    crit3   = if_else(paramcd == "MQTCFAG" & !is.na(bdy) & ady >= bdy & aval > 500 & base <= 500,
                      ">500 and baseline <=500", NA_character_),
    crit3fl = if_else(!is.na(crit3), "Y", NA_character_),
    # Heart rate criteria
    crit4   = if_else(paramcd == "MEGHRMN" & !is.na(bdy) & ady >= bdy & aval < 40,
                      "<40", NA_character_),
    crit4fl = if_else(!is.na(crit4), "Y", NA_character_),
    crit5   = if_else(paramcd == "MEGHRMN" & !is.na(bdy) & ady >= bdy & aval < 40 & pchg <= -25,
                      "<40 and >=25% decrease from baseline", NA_character_),
    crit5fl = if_else(!is.na(crit5), "Y", NA_character_),
    crit6   = if_else(paramcd == "MEGHRMN" & !is.na(bdy) & ady >= bdy & aval > 110,
                      ">110", NA_character_),
    crit6fl = if_else(!is.na(crit6), "Y", NA_character_),
    crit7   = if_else(paramcd == "MEGHRMN" & !is.na(bdy) & ady >= bdy & aval > 110 & pchg >= 25,
                      ">110 and >=25% increase from baseline", NA_character_),
    crit7fl = if_else(!is.na(crit7), "Y", NA_character_)
  ) |>
  # Maximum change criteria (within subject-parameter)
  mutate(
    maxchg = max(chg, na.rm = TRUE),
    mcrit1ml = case_when(
      paramcd == "PRAG"   & aval < 100 & pchg <= -25 ~ "<100 and >=25% decrease from baseline",
      paramcd == "PRAG"   & aval > 220 & pchg >= 25  ~ ">220 and >=25% increase from baseline",
      paramcd == "QRSAG"  & aval > 120 & pchg >= 25  ~ ">120 and >=25% increase from baseline",
      paramcd == "QTAG"   & aval > 500 & base <= 500 ~ ">500 and baseline <=500",
      paramcd == "QTCFAG" & maxchg == 0              ~ "No increase",
      paramcd == "QTCFAG" & maxchg > 0  & maxchg < 30 ~ ">0 to <30 ms",
      paramcd == "QTCFAG" & maxchg >= 30 & maxchg <= 60 ~ "30 to 60 ms",
      paramcd == "QTCFAG" & maxchg > 60              ~ ">60 ms"
    ),
    mcrit1ml = if_else(
      (is.na(chg) | maxchg != chg) & paramcd == "QTCFAG", NA_character_, mcrit1ml
    ),
    mcrit1mn = case_when(
      mcrit1ml == "<100 and >=25% decrease from baseline" ~ 1,
      mcrit1ml == ">220 and >=25% increase from baseline" ~ 2,
      mcrit1ml == ">120 and >=25% increase from baseline" ~ 3,
      mcrit1ml == ">500 and baseline <=500"               ~ 4,
      mcrit1ml == "No increase"                           ~ 5,
      mcrit1ml == ">0 to <30 ms"                          ~ 6,
      mcrit1ml == "30 to 60 ms"                           ~ 7,
      mcrit1ml == ">60 ms"                                ~ 8
    ),
    .by = c(usubjid, paramcd)
  ) |>
  mutate(
    mcrit1 = case_when(
      paramcd == "PRAG"   ~ "PR CONDITION",
      paramcd == "QRSAG"  ~ "QRS CONDITION",
      paramcd == "QTAG"   ~ "QT CONDITION",
      paramcd == "QTCFAG" ~ "QTCF CONDITION"
    ),
    mcrit1 = if_else(is.na(aval), NA_character_, mcrit1)
  )


# =============================================================================
# STEP 7: Apply Metadata Labels and Export
# =============================================================================

eg5 |>
  rename_with(toupper) |>
  save_adam(metacore, "ADEG")
