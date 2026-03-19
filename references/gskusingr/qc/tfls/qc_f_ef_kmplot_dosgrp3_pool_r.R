####------------------------------------------------------------------------####
# Program Name: qc_f_ef_kmplot_dosgrp3_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Kaplan-Meier Plot for Progression-free Survival in Dose Group T300/C400 
#          (Phase 1 & 1b pooled).
#
# Input:
#   - sdtmdata: [N/A]
#   - adamdata: adbs
# Output:
#   - adamdata: [N/A]
#   - dddata: [N/A] 
#   - file: qc_f_ef_kmplot_dosgrp3_pool_r.lst
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# ---------------------------------------------------------
# Kaplan–Meier Plot for PFS (Phase 1 & 1b pooled, 2nd line)
# ---------------------------------------------------------

# Load Libraries
libs <- c("dplyr", "survival", "survminer", "ggplot2")
pkg_attach(libs)

# ---------------------------------------------------------
# 1. Prepare analysis dataset (ONE RECORD PER SUBJECT)
# ---------------------------------------------------------
# Load base data
adbs <- read_data_catalog(adamdata$adbs)
adbs_1 <- convert_blanks_to_na(adbs) |>
  filter(EFFL == "Y") 


adtte <- read_data_catalog(adamdata$adtte) |> 
  left_join(adbs_1 |> select(USUBJID, DOSGRP, DOSGRPN), by = "USUBJID")


adtte_pfs <- adtte |> 
  filter(EFFL == "Y" & PARAMCD == "PFS" & ACAT2 == "INVESTIGATOR" & DOSGRPN == 3) |> 
  select(USUBJID, PARAMCD, PARAM, PARAMN, AVAL, ADT, CNSR, DOSGRP, DOSGRPN) |>
  distinct(USUBJID, .keep_all = TRUE)


fit <- survfit(
      Surv(AVAL, CNSR == 0) ~ 1,
      data = adtte_pfs
    )

surv_prob <- data.frame(
  time_months = fit$time,
  surv_prob   = fit$surv,
  n_risk      = fit$n.risk,
  n_event     = fit$n.event,
  n_censor    = fit$n.censor
)

surv_prob

# Plot KM curve
plot(
  fit,
  xlab = "Time (Months)",
  ylab = "Probability of Survival",
  xlim = c(0, 24),
  ylim = c(0, 1),
  mark.time = TRUE,     # censoring marks (+)
  conf.int = FALSE,
  lwd = 2
)


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

milestones <- c(0,3,6, 9, 12,15,18,21,24)

km_milestone <- summary(km_fit, times = milestones)

# ---------------------------------------------------------
# 5. Number at risk table
# ---------------------------------------------------------

risk_times <- seq(0, 39, by = 3)

km_risk <- summary(km_fit, times = risk_times)


prod <- read_parquet(file.path(g_paths$dddata,"t_ef_pfs_lot_pool_r.parquet")) |> 
  filter (dosgrp == "T300/C400")


