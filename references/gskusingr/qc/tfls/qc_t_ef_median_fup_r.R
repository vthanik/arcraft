####------------------------------------------------------------------------####
# Program Name: qc_t_ef_median_fup_r_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Median Follow-up Time (Months) for the Efficacy Analysis Set
#          (Phase 1 & 1b pooled).
#
# Input:
#   - sdtmdata: [N/A]
#   - adamdata: adbs
# Output:
#   - adamdata: [N/A]
#   - dddata: [N/A]
#   - file: qc_t_ef_median_fup_r_r.lst
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# Load Libraries
libs <- c("dplyr", "survival","broom")
pkg_attach(libs)

# Reverse the censoring: 1 -> censored, 0 -> event
adtte_eff <- read_data_catalog(adamdata$adtte) %>%
  filter(EFFL == "Y" & ACAT2N == 1 & PARAMCD=="PFS") %>%   # Efficacy Analysis Set
  mutate(reverse_cnsr = ifelse(CNSR == 0, 1, 0)) # Reverse censoring

# Fit Kaplan-Meier for follow-up
km_fit <- survfit(Surv(AVAL, reverse_cnsr) ~ 1, data = adtte_eff)

# Extract median follow-up
median_fu_months <- summary(km_fit)$table["median"]

km_summary <- summary(km_fit)
median_fu <- km_summary$table["median"]
lower_ci <- km_summary$table["0.95LCL"]
upper_ci <- km_summary$table["0.95UCL"]


cat("Median Follow-up (months):", round(median_fu,1), 
    " (95% CI:", round(lower_ci,1), "-", round(upper_ci,1), ")\n")


prod <- read_parquet(file.path(g_paths$dddata, "t_ef_median_fup_r.parquet")) 
