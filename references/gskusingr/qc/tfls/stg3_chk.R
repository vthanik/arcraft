####------------------------------------------------------------------------####
# Program Name: qc_t_sf_prior_systhpy_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: QC of Summary of Prior Systemic Cancer Therapy by Line of Therapy
#          (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adcm]
# Output:8
#   - dd []
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------
# --- Load Libraries ---
pkg_load("dplyr", "forcats", "stringr", "purrr", "cards","survival","tidyr")

adbs <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y") |> 
  select(USUBJID,DOSGRP,DOSGRPN,LOTCAT,LOTCATN)

adcm <- read_data_catalog(adamdata$adcm) |> 
  filter(CMCAT=="PRIOR CANCER THERAPY", CMTRT %in% c("BEZUCLASTINIB","NB003","THE-630")) |> 
  arrange(USUBJID) %>%        # optional but good practice
  group_by(USUBJID) %>%
  slice(1) %>%                # one record per subject
  ungroup() %>%
  left_join(adbs,by="USUBJID")
  


adeff <- read_data_catalog(adamdata$adeff) |> 
  semi_join(adcm,by="USUBJID") |> 
  filter(EFFL == "Y" ,ACAT2N==1, PARAMN %in% c(1,13) , AVALC=="Y", grepl("SD", AVALC),LOTCATN==2)

adtte <- read_data_catalog(adamdata$adtte) |>
  left_join(adbs,by="USUBJID")|> 
  filter(EFFL == "Y", ACAT2N==1,PARAMN==1,LOTCATN==2) 

fit <- survfit(
  Surv(AVAL, 1-CNSR) ~ 1,
  data = adtte,
  conf.type = "log-log"
)

qq <- quantile(fit, probs = c(0.25, 0.5, 0.75))

out <- data.frame(
  percent  = c("25%", "Median", "75%"),
  estimate = qq$quantile,
  lower    = qq$lower,
  upper    = qq$upper
)





adtr <- read_data_catalog(adamdata$adtr) |>
  filter(EFFL == "Y") |> 
  left_join(adbs,by="USUBJID")

adtrs <- read_data_catalog(adamdata$adtrs) |>
  filter(EFFL == "Y") |> 
  left_join(adbs,by="USUBJID")




