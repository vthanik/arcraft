####------------------------------------------------------------------------####
# Program Name: qc_f_ef_kmplot_1l_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Kaplan-Meier Plot for Progression-free Survival (1st Line of Therapy)
#          (Phase 1 & 1b pooled).
#
# Input:
#   - sdtmdata: [N/A]
#   - adamdata: adbs
# Output:
#   - adamdata: [N/A]
#   - dddata: [N/A]
#   - file: qc_f_ef_kmplot_1l_pool_r.lst
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# ---------------------------------------------------------
# Kaplan–Meier Plot for PFS (Phase 1 & 1b pooled, 1st line)
# ---------------------------------------------------------

# Load Libraries
libs <- c("dplyr", "survival", "survminer", "ggplot2","arrow")
pkg_attach(libs)

# ---------------------------------------------------------
# 1. Prepare analysis dataset (ONE RECORD PER SUBJECT)
# ---------------------------------------------------------
# Load base data
adbs <- read_data_catalog(adamdata$adbs)
adbs_1 <- adbs |>
  filter(SAFFL == "Y") 


adtte <- read_data_catalog(adamdata$adtte) |> 
  left_join(adbs_1 |> select(USUBJID, DOSGRP, DOSGRPN, LOTCATN, LOTCAT), by = "USUBJID")


adtte_pfs <- adtte |> 
  filter(PARAMCD == "PFS" & ACAT2 == "INVESTIGATOR" & LOTCATN == 1) |> 
  select(USUBJID, PARAMCD, PARAM, PARAMN, AVAL, ADT, CNSR, DOSGRP, DOSGRPN, LOTCATN, LOTCAT) |>
  distinct(USUBJID, .keep_all = TRUE)

# ---------------------------------------------------------
# 2. Big N and Event counts (for legend & QC)
# ---------------------------------------------------------

pop_summary <- adtte_pfs |>
  group_by(DOSGRP) |>
  summarise(
    N = n(),
    Events = sum(CNSR == 0),
    .groups = "drop"
  )

# Create legend labels
legend_labs <- pop_summary |>
  mutate(
    label = paste0(DOSGRP, " (Events: ", Events, "/", N, ")")
  ) |>
  pull(label)

names(legend_labs) <- pop_summary$DOSGRP

# ---------------------------------------------------------
# 3. Fit Kaplan–Meier model
# ---------------------------------------------------------

km_fit <- survfit(
  Surv(AVAL, CNSR == 0) ~ DOSGRP,
  data = adtte_pfs
)

# ---------------------------------------------------------
# 4. Milestone estimates (6 / 9 / 12 months)
# ---------------------------------------------------------

milestones <- c(0, 3, 6, 9, 12, 15)

km_milestone <- summary(km_fit, times = milestones)

# km_milestone_df <- data.frame(
#   TRTGRP = sub("DOSGRP=", "", km_milestone$strata),
#   Month  = km_milestone$time,
#   Estimate = km_milestone$surv * 100,
#   LowerCI = km_milestone$lower * 100,
#   UpperCI = km_milestone$upper * 100
# )

# ---------------------------------------------------------
# 5. Number at risk table
# ---------------------------------------------------------

risk_times <- seq(0, 39, by = 3)

km_risk <- summary(km_fit, times = risk_times)

# risk_df <- data.frame(
#   TRTGRP = sub("DOSGRP=", "", km_risk$strata),
#   Month  = km_risk$time,
#   N_Risk = km_risk$n.risk
# )

prod <- read_parquet(file.path(g_paths$dddata,"t_ef_pfs_lot_pool_r.parquet")) |> 
  filter (lotcat == "1st-line")


