####------------------------------------------------------------------------####
# Program Name: t_ef_median_fup_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Vignesh Thanikachalam / vt704670
# Purpose: Median Follow-up Time (Months) for the Efficacy Analysis Set 
# (Phase 1 & 1b Pooled)
#
# Input:
#   - ADaM: ADBS, ADTTE
# Output:
#   - DD: t_ef_median_fup_r
#   - File: ../prod/output/t_ef_median_fup_r.RTF
#
# External files called:
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- Load Libraries and Data (from your original script) ----
library(dplyr)
library(survival)

# Assuming adbs.sas7dat and adtte.sas7dat are in a list called adamdata
# This part is directly from your script to create the Efficacy Analysis Set
adbs <- read_data_catalog(adamdata$adbs)  |> 
  filter(EFFL == "Y") |>
  rename_with(tolower) |>
  select(studyid, usubjid, subjid, effl, dosgrp, dosgrpn)

adtte <- read_data_catalog(adamdata$adtte)  |> 
  filter(PARAMCD %in% c("PFS") & ACAT2 == "INVESTIGATOR") %>%  
  rename_with(tolower)

# This is your Efficacy Analysis Set for time-to-event
tte_bs <- inner_join(adbs, adtte, by = "usubjid")


# --- NEW CODE: Calculate Median Follow-up for ALL Patients ----

# 1. Reverse the censoring indicator for the follow-up calculation.
#    Assuming original `cnsr` is 0=event, 1=censored.
#    For follow-up, we flip this: event becomes censored, censored becomes event.
tte_followup <- tte_bs %>%
  mutate(event_rev = 1 - cnsr)

# 2. Fit the Kaplan-Meier model on the reversed data for the entire cohort (~ 1)
#    The result is the follow-up time distribution.
fit_followup <- survfit(Surv(aval, event_rev) ~ 1, data = tte_followup) 
summary_table <- summary(fit_followup)$table

final <- as.list(summary_table) |> 
  as_tibble() |>  
  mutate(
    txt = "Median Follow-Up, month", 
    across(c(median, starts_with("0.95")), ~ sprintf("%5.1f", .))) |> 
  select(txt, n.max, events, median, starts_with("0.95"))

# Save the final ARD for traceability or reuse
arrow::write_parquet(final, file.path(g_paths$dddata, "t_ef_median_fup_r.parquet"))

gt <- gt::gt(final)
  
# --- 6. Create and Save Output in RTF ---

rtf_obj <- gt |>
  rtf_table() |>
  rtf_col_label(txt = "", n.max = "N", events = "Events", median = "Median", `0.95LCL` = "95% LCL", `0.95UCL` = "95% UCL") |>
  rtf_col_align(everything() ~ "center", .group = "header") |>
  rtf_col_align(txt ~ "left", everything() ~ "center", .group = "column") |>
  rtf_col_widths( c(n.max, events, median) ~ "1.05in", starts_with("0.95") ~ "1.05in") |>
  rtf_title(
    "Table 14.2.4f",
    "Median Follow-up Time (Months) for the Efficacy Analysis Set (Phase 1 & 1b Pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Efficacy", paste("Data as of", g_config$datadate))
  ) |>
  build_rtf(file = file.path(g_paths$output, "t_ef_median_fup_r.rtf"))