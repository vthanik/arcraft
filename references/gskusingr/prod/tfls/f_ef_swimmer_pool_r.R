####------------------------------------------------------------------------####
# Program Name: f_ef_swimmerplot_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / pt209009
# Purpose: Swimmer Plot for Subject's Response to IDRX-42 Over Time (Phase 1 & 1b pooled)
#
# Input:
#   - adam:
# Output:
#   - File: ../prod/output/f_ef_swimmer_pool_r.rtf
#
# External files called: [N/A]
#
# Additional Notes:
#
# 2025-12-24:
#   - Vignesh T. started collaborating with the original programmer.
#
#-------------------------------------------------------------------------------

# --- 0. Setup and Library Loading ---
# Loads global setup, custom plotting function, and required R packages.

pkg_load(
  "dplyr",
  "forcats",
  "stringr",
  "tidyr",
  "purrr",
  "lubridate",
  "survival",
  "ggplot2",
  "patchwork",
  "glue"
)

# --- 1. Load Data and Define Factor Levels ---
# Loads ADaM dataset (ADBS) and defines ordered factor levels
# for treatment groups (DOSGRP) and line of therapy categories (LOTCAT).
adbs_safety <- read_data_catalog(adamdata$adbs) |>
  filter(SAFFL == "Y", !is.na(DOSGRP))

treatment_group_levels <- adbs_safety |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)

# --- 2. Prepare Analysis Dataset ---
# Combines data from ADBS, ADEFF (PD dates), and ADRS (first response dates)
# to create `swimmer_analysis_data` with calculated durations and event times
# for swimmer plot visualization.
DAYS_PER_MONTH <- 30.4375

pd_dates <- read_data_catalog(adamdata$adeff) |>
  filter(PARAMCD == "PDDT", ACAT2 == "INVESTIGATOR", !is.na(AVALC)) |>
  mutate(PDDT = parse_date_time(AVALC, "d%b%y") |> as_date()) |>
  select(USUBJID, PDDT)

first_response_dates <- read_data_catalog(adamdata$adrs) |>
  filter(AVALC %in% c("CR", "PR"), PARAMCD == "OVRLRESP") |>
  select(USUBJID, ADT, AVISITN, AVISIT, AVALC, AVAL) |>
  slice_min(order_by = ADT, by = c(USUBJID, AVALC)) |>
  pivot_wider(
    id_cols = USUBJID,
    names_from = AVALC,
    values_from = ADT,
    names_glue = "{AVALC}DT"
  )

swimmer_analysis_data <- adbs_safety |>
  select(USUBJID, SUBJID, DOSGRP, EOTSTT, TRTSDT, TRTEDT, DTHDT) |>
  left_join(pd_dates, by = "USUBJID") |>
  left_join(first_response_dates, by = "USUBJID") |>
  rowwise() |>
  mutate(MAXDT = max(TRTEDT, PRDT, CRDT, PDDT, DTHDT, na.rm = TRUE)) |>
  ungroup() |>
  mutate(
    END = (as.numeric(MAXDT - TRTSDT) + 1) / DAYS_PER_MONTH,
    LAST_DOSE = (as.numeric(TRTEDT - TRTSDT) + 1) / DAYS_PER_MONTH,
    PR = (as.numeric(PRDT - TRTSDT) + 1) / DAYS_PER_MONTH,
    CR = (as.numeric(CRDT - TRTSDT) + 1) / DAYS_PER_MONTH,
    PD = (as.numeric(PDDT - TRTSDT) + 1) / DAYS_PER_MONTH,
    DTH = (as.numeric(DTHDT - TRTSDT) + 1) / DAYS_PER_MONTH,
    ONGO_FL = grepl("Ongoing", EOTSTT, ignore.case = TRUE)
  ) |>
  select(-ends_with("DT"))

# --- 3. Generate Plots by DOSGRP (All LOTs) ---
# Generates a list of paginated swimmer plots, stratified by treatment group
# across all lines of therapy.
plots_by_treatment_group <- fig_swimmer(
  data = swimmer_analysis_data,
  subj_col = "SUBJID",
  bar_col = "LAST_DOSE",
  group_col = "DOSGRP",
  group_levels = treatment_group_levels,
  ongoing_col = "ONGO_FL",
  pr_col = "PR",
  cr_col = "CR",
  pd_col = "PD",
  dth_col = "DTH",
  subjects_per_page = 40,
  title = NULL
)

rtf_obj <- plots_by_treatment_group |>
  rtf_figure() |>
  rtf_title(
    "Figure 14.2.3c",
    "Swimmer Plot for Subject's Response to IDRX-42 Overtime (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Efficacy", paste("Data as of", g_config$datadate))
  ) |>
  rtf_footer("") |>
  build_rtf(
    file = file.path(g_paths$output, "f_ef_swimmer_pool_r.rtf")
  )
