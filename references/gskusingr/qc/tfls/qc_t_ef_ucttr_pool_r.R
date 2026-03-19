####------------------------------------------------------------------------####
# Program Name: qc_t_ef_ucttr_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Table 14.2.5.1c Summary of Unconfirmed Time to Response (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adtte]
# Output:
#   - dd []
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------
# --- Load Libraries ---
pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "tfrmt","admiral")

# --- Load base data ---
adbs <- read_data_catalog(adamdata$adbs)
adbs <- convert_blanks_to_na(adbs)  |>
  filter(EFFL == "Y") |>
  select(USUBJID, DOSGRP,TRTSDT)

adbs_t <- adbs |> mutate(DOSGRP="Total")

adbs_1 <- rbind(adbs,adbs_t)


bigN <- adbs_1 |>
  distinct(USUBJID, DOSGRP) |>
  count(DOSGRP, name = "popn") |> 
  mutate(
    stat=popn,
    stat_name="popn",
    stat_label="n",
    variable=NA
  ) |> 
  select(-popn)

# --- Load ADEFF data ---
adeff_boru <- read_sas_local(adamdata$adeff) |> 
  filter(ACAT2N==1,PARAMCD == "BORU", (AVALC %in% c("CR","PR"))) |> 
  select(USUBJID,PARAMCD,AVALC,SRCDOM,SRCVAR,SRCSEQ)

# # --- Load raw RS data ---
rs <- read_sas_local(sdtmdata$rs) |>
  filter(RSEVAL=="INVESTIGATOR",RSTESTCD=="OVRLRESP") |>
  select(USUBJID,RSSEQ,RSTESTCD,RSSTRESC,RSDTC) |>
  mutate(SRCSEQ=RSSEQ)
  
adeff_rs <-  left_join(adeff_boru,rs,by=c("USUBJID","SRCSEQ")) |> 
  left_join(adbs,by="USUBJID") 

adeff_rs_t <- adeff_rs |> mutate(DOSGRP="Total")

adeff_rs_1 <- rbind(adeff_rs,adeff_rs_t)

adeff_rs_1 <- adeff_rs_1 |> 
  mutate(dt= (as.numeric(as.Date(RSDTC, "%Y-%m-%d") -as.Date(TRTSDT, "%Y-%m-%d"))+1)/30.4375) |> 
  group_by(DOSGRP) |>
  summarise(
    n      = sum(!is.na(dt)),
    Mean   = mean(dt, na.rm = TRUE),
    SD     = sd(dt, na.rm = TRUE),
    Median = median(dt, na.rm = TRUE),
    Min.    = min(dt, na.rm = TRUE),
    Max.    = max(dt, na.rm = TRUE),
    .groups = "drop"
  )

adeff_rs_long <- adeff_rs_1 |>
  pivot_longer(
    cols = c(n, Mean, SD, Median, Min., Max.),
    names_to  = "stat_label",
    values_to = "stat"
  ) |>
  mutate(
    stat_name = tolower(stat_label),
    stat_name = if_else(stat_name == "n", "N", stat_name),
    stat_name = if_else(stat_name == "min.", "min", stat_name),
    stat_name = if_else(stat_name == "max.", "max", stat_name),
  ) |> 
  mutate(variable="Time to Response (Unconfirmed), month") |> 
  arrange(DOSGRP, stat_label)

qc <- rbind(adeff_rs_long,bigN) |> 
  arrange(DOSGRP, stat_label)


prod <- arrow::read_parquet(file.path(g_paths$dddata,"t_ef_ucttr_pool_r.parquet")) |> 
  arrange(DOSGRP, stat_label)

result <- diffdf::diffdf(
  prod,
  qc
)

