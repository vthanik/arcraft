####------------------------------------------------------------------------####
# Program Name: qc_f_ef_waterfall_muttstt_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Waterfall Plot by KIT (Exon) Mutation Status by Line of Therapy 
# (Phase 1 & 1b pooled).
#
# Input:
#   - sdtmdata: [N/A]
#   - adamdata: adbs
# Output:
#   - adamdata: [N/A]
#   - dddata: [N/A]
#   - file: qc_f_ef_waterfall_muttstt_r.lst
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# Load Libraries
libs <- c("admiral","dplyr", "survival", "survminer", "ggplot2","diffdf")
pkg_attach(libs)

# ---------------------------------------------------------
# 1. Prepare analysis data set (ONE RECORD PER SUBJECT)
# ---------------------------------------------------------
# Load base data
adbs <- read_data_catalog(adamdata$adbs)
adbs_1 <- convert_blanks_to_na(adbs)

treatment_group_levels <- adbs_1 |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)
lot_category_levels <- adbs_1 |>
  distinct(LOTCATN, LOTCAT) |>
  arrange(LOTCATN) |>
  pull(LOTCAT)

adeff <- read_data_catalog(adamdata$adeff) |>
  filter(ACAT2N == 1 & PARAMCD=="BOR") |> 
  select(USUBJID,AVALC) |> 
  mutate(BOR=case_when(
    AVALC== "6 <= SD < 16 weeks" ~ "SD",
    AVALC== "SD >= 16 weeks" ~ "SD",
    TRUE ~ AVALC
  )
  ) |> 
  left_join(adbs_1,select(USUBJID,SUBJID,DOSGRP,DOSGRPN,EFFL,LOTCAT,LOTCATN,
                          EOTSTT,CTEXON9,CTEXON11,CTEXON13),by = "USUBJID") |> 
  filter(EFFL == "Y" & !is.na(DOSGRP)) |> 
  mutate(DISCFL=grepl("Discontinued", EOTSTT, ignore.case = TRUE)) |> 
  select(USUBJID,SUBJID,DOSGRP,DOSGRPN,LOTCAT,LOTCATN,DISCFL,EOTSTT,CTEXON9,
         CTEXON11,CTEXON13,BOR)

