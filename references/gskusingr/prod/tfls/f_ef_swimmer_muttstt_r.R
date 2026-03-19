####------------------------------------------------------------------------####
# Program Name: f_ef_swimmer_muttstt_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Vignesh Thanikachalam / vt704670
# Purpose:Swimmer's Plot by KIT (Exon) Mutation Status by Line of Therapy
# (Phase 1 & 1b pooled)
#
# Input:
#   - ADAM: ADBS, ADTR, ADEFF
# Output:
#   - File: ../prod/output/f_ef_swimmer_muttstt_r.rtf
#
# External files called:
#
# Additional Notes:
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
  filter(EFFL == "Y", !is.na(DOSGRP), !is.na(LOTCAT)) |> 
  select(USUBJID, SUBJID, DOSGRP, DOSGRPN, LOTCAT, LOTCATN, EOTSTT, TRTSDT,  
         TRTEDT, DTHDT, starts_with("CTEXON"), GISTMLOC)

# Isolate mutation status from wide-format columns.
mutation_data <- adbs_safety |>
  mutate(
    EXON9 = if_else(CTEXON9 == "Y" | str_detect(GISTMLOC, "EXON 9"), "Y", "N"),
    EXON11 = if_else(CTEXON11 == "Y" | str_detect(GISTMLOC, "EXON 11"), "Y", "N"),
    EXON13 = if_else(CTEXON13 == "Y" | str_detect(GISTMLOC, "EXON 13"), "Y", "N"),
    EXON14 = if_else(CTEXON14 == "Y" | str_detect(GISTMLOC, "EXON 14"), "Y", "N"),
    EXON17 = if_else(CTEXON17 == "Y" | str_detect(GISTMLOC, "EXON 17"), "Y", "N")
  ) |> 
  pivot_longer(
    cols = starts_with("EXON"),
    names_to = "EXON_VAR",
    values_to = "EXON_FLAG"
  ) |>
  filter(EXON_FLAG == "Y") |>
  mutate(
    MUTSTT = case_match(
      EXON_VAR,
      "EXON9" ~ "Exon 9",
      "EXON11" ~ "Exon 11",
      "EXON13" ~ "Exon 13",
      "EXON14" ~ "Exon 14",
      "EXON17" ~ "Exon 17"
    )
  ) |>
  filter(!is.na(MUTSTT)) |>
  mutate(
    MUTSTT = factor(
      MUTSTT, 
      levels = c("Exon 9", "Exon 11", "Exon 13", "Exon 14", "Exon 17"))
  ) |> 
  distinct()

treatment_group_levels <- adbs_safety |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)

lot_levels <- adbs_safety |>
  distinct(LOTCATN, LOTCAT) |>
  arrange(LOTCATN) |>
  pull(LOTCAT)

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

swimmer_analysis_data <- mutation_data |>
  select(USUBJID, SUBJID, DOSGRP, LOTCAT, EOTSTT, TRTSDT, TRTEDT, DTHDT, MUTSTT) |>
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

lot_data <- swimmer_analysis_data |>
  dplyr::group_split(LOTCAT, MUTSTT)

plot_list <- map(lot_data, \(x) {
  lotcat <- as.character(unique(x$LOTCAT))
  mutstt <- as.character(unique(x$MUTSTT))
  fig_swimmer(
    data = x,
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
    title = glue::glue("Line of Therapy: {lotcat}, KIT Mutation: {mutstt}")
  )
})

rtf_obj <- purrr::flatten(plot_list) |>
  rtf_figure() |>
  rtf_title(
    "Figure 14.2.3f",
    "Swimmer's Plot by KIT (Exon) Mutation Status by Line of Therapy (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Efficacy", paste("Data as of", g_config$datadate))
  ) |>
  rtf_footer("") |>
  build_rtf(
    file = file.path(g_paths$output, "f_ef_swimmer_muttstt_r.rtf")
  )