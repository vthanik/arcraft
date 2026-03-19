####------------------------------------------------------------------------####
# Program Name: f_ef_kmplot_dosgrp3_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Vignesh Thanikachalam / vt704670
# Purpose: Kaplan-Meier Plot for Progression-free Survival in Dose Group T300/C400 
#
# Input:
#   - ADAM: ADBS, ADTR, ADEFF
# Output:
#   - File: ../prod/output/f_ef_kmplot_dosgrp3_pool_r.rtf
#
# External files called:
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- 0. Load Libraries ---

pkg_load(
  "dplyr",
  "forcats",
  "stringr",
  "tidyr",
  "purrr",
  "survival",
  "ggplot2",
  "patchwork",
  "glue"
)

# --- 1. Load Data and Define Factor Levels ---
adbs_raw <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y", DOSGRP == "T300/C400")

adtte_raw <- read_data_catalog(adamdata$adtte) |>
  filter(EFFL == "Y", PARAMCD == "PFS", ACAT2 == "INVESTIGATOR")

trt_levels <- adbs_raw |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)

lot_levels <- adbs_raw |>
  distinct(LOTCATN, LOTCAT) |>
  arrange(LOTCATN) |>
  pull(LOTCAT)

# --- 2. Prepare Data for Plotting ---
pop <- adbs_raw |>
  distinct(USUBJID, DOSGRP, LOTCAT) |>
  mutate(
    DOSGRP = factor(DOSGRP, levels = trt_levels),
    LOTCAT = factor(LOTCAT, levels = lot_levels)
  )

adtte <- adtte_raw |>
  distinct(USUBJID, PARAMCD, PARAM, AVAL, CNSR, CNSDTDSC) |>
  inner_join(pop, by = "USUBJID") |>
  arrange(LOTCAT, DOSGRP)

colors_by_trt <- adbs_raw |> distinct(DOSGRPN, DOSGRP) |> pull(DOSGRPN)

survplot <- fig_kmplot(
  data = adtte,
  time_col = AVAL,
  censor_col = CNSR,
  trt_col = DOSGRP,
  trt_levels = trt_levels,
  colors = g_config$colors[colors_by_trt],
)

rtf_obj <- survplot |>
  rtf_figure(width = 7.1) |>
  rtf_title(
    "Figure 14.2.2f",
    "Kaplan-Meier Plot for Progression-free Survival in Dose Group T300/C400"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Efficacy", paste("Data as of", g_config$datadate))
  ) |>
  rtf_footer(
    "Note: Progression-free survival (PFS) is calculated from the date of first IDRX-42 dose to the date of disease progression or death, whichever occurs first. The patients without disease progression or death will be censored on the date of last disease assessment.",
  ) |>
  build_rtf(
    file = file.path(g_paths$output, "f_ef_kmplot_dosgrp3_pool_r.rtf")
  )
