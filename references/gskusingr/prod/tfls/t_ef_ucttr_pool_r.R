####------------------------------------------------------------------------####
# Program Name: t_ef_ucttr_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Vignesh Thanikachalam / vt704670
# Purpose:  Summary of Unconfirmed Time to Response (Phase 1 & 1b pooled)
#
# Input:
#   - ADaM: ADBS, ADEFF 
#   - SDTM: RS
# Output:
#   - DD: t_ef_ucttr_pool_r
#   - File: ../prod/output/t_ef_ucttr_pool_r.RTF
#
# External files called:
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- 0. Setup and Central Definitions ---

# Load required R packages. `pkg_attach` is a helper for attaching packages.
pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "tfrmt")

# --- 1. Load and Prepare Raw Data ---

# Load the ADaM Subject-Level Analysis Dataset (ADBS).
adbs_raw <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y") |>
  select(USUBJID, DOSGRPN, DOSGRP, EFFL, TRTSDT)

rs_raw <- read_data_catalog(sdtmdata$rs) |> 
  filter(RSTESTCD == "OVRLRESP") |> 
  select(USUBJID, RSSEQ, RSDTC, RSSTRESC)

# Load the ADaM Efficacy Analysis Dataset (ADEFF).
adeff_boru_raw <- read_data_catalog(adamdata$adeff) |>
  filter(EFFL == "Y", PARAMCD == "BORU", ACAT2 == "INVESTIGATOR", AVALC %in% c("CR", "PR")) |>
  # Select only essential columns.
  select(USUBJID, PARAMCD, AVALC, ACAT2, SRCSEQ) |> 
  left_join(rs_raw, by = join_by(USUBJID, SRCSEQ == RSSEQ))

# Define ordered treatment levels from ADBS for consistent table columns.
trt_levels <- adbs_raw |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)

trt_levels_total <- c(trt_levels, "Total")

# --- 2. Define the Analysis Population and Denominators ---

# Create the base analysis population dataframe (`anl_pop_base`).
anl_pop_base <- adbs_raw |>
  select(USUBJID, DOSGRP, TRTSDT) |>
  filter(!is.na(DOSGRP))

# Create the final analysis population (`anl_pop`) by adding a "Total" group.
anl_pop <- bind_rows(
  anl_pop_base,
  anl_pop_base |> mutate(DOSGRP = "Total")
) |>
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total)) |>
  distinct(USUBJID, DOSGRP, TRTSDT)


# --- 3. Prepare Analysis-Specific Data for ARD Creation ---
# This section processes the raw response data (BORU and ORR) and links it
# with the analysis population (`anl_pop`) to prepare it for ARD generation.

# Prepare Unconfirmed Best Overall Response (BORU) data.
adeff_ttr_prepared <- adeff_boru_raw |>
  inner_join(anl_pop, by = "USUBJID") |>
  mutate(
    ADT = lubridate::ymd(RSDTC),
    AVAL = as.numeric((ADT - TRTSDT + 1) / 30.4375) 
  ) |> 
  distinct(USUBJID, DOSGRP, .keep_all = TRUE)

# --- 4. Build Analysis Results Data (ARD) using `cards` Package ---

# Define the grouping variables for ARD generation.
ard_by_vars <- c("DOSGRP")

# Create ARD for Unconfirmed Best Overall Response (BORU) counts and percentages.
ard_ttr <- adeff_ttr_prepared |>
  ard_summary(
    by = all_of(ard_by_vars),
    variables = AVAL,
    statistic = ~ continuous_summary_fns(c(
      "N",
      "mean",
      "sd",
      "median",
      "min",
      "max"
    )),
    stat_label = ~ list(N = "n", mean = "Mean", sd = "SD", median = "Median", min = "Min.", max = "Max.")
  ) |> 
  unlist_ard_columns() |> 
  rename_ard_columns(columns = all_ard_groups("names"))

ard_pop <- anl_pop |> 
  ard_tabulate(
    variables = all_of(ard_by_vars),
    statistic = everything() ~ "n"
  ) |> 
  unlist_ard_columns() |> 
  mutate(stat_name = "popn") |> 
  rename_ard_columns(columns = all_ard_variables("names"))

final_ard <- bind_rows(ard_ttr, ard_pop, .id = "id") |> 
  mutate(
    DOSGRP = factor(DOSGRP, levels = trt_levels_total),
    variable = factor(variable, levels = c("AVAL"), labels = c("Time to Response (Unconfirmed), month"))
  ) |> 
  arrange(id, DOSGRP, variable) |>
  select(
    DOSGRP,  
    variable,
    stat_name,
    stat_label,
    stat
  ) |> 
  mutate(across(where(is.factor), as.character))


# --- saving final dataset for validation ---
arrow::write_parquet(
  final_ard,
  file.path(g_paths$dddata, "t_ef_ucttr_pool_r.parquet")
)


# --- 6. Build `tfrmt` structure ---
# Define the table structure using tfrmt.
tfobj <-
  tfrmt(
    group = variable,
    label = stat_label,
    column = DOSGRP,
    value = stat,
    param = stat_name,
    sorting_cols = ,
    body_plan = body_plan(
      frmt_structure(group_val = ".default", label_val = c("n", "Min.", "Max."), frmt("xxx")),
      frmt_structure(
        group_val = ".default", 
        label_val = c("Mean", "Median"), 
        frmt_when(
          "==0" ~ frmt("   0"),
          ">0" ~ frmt("xxx.x"),
          "TRUE" ~ frmt("")
        )
      ),
      frmt_structure(
        group_val = ".default", 
        label_val = "SD", 
        frmt_when(
          "==0" ~ frmt("   0"),
          ">0" ~ frmt("xxx.xx"),
          "TRUE" ~ frmt("")
        )
      )
    ),
    big_n = big_n_structure(param_val = "popn", n_frmt = frmt("\n(N=x)")),
    row_grp_plan = row_grp_plan(
      row_grp_structure(
        group_val = ".default",
        element_block(post_space = " ")
      ),
      label_loc = element_row_grp_loc(location = "indented")
    )
  )

# Convert the tfrmt object to a gt object for printing.
gt <- print_to_gt(tfobj, final_ard)

# --- 7. Create and Save Output in RTF ---

# Build the RTF table object with final formatting.
rtf_dt <- gt |>
  rtf_table() |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(stat_label = "") |>
  rtf_paginate_cols(id_columns = stat_label, split_at = 5) |>
  rtf_title(
    "Table 14.2.5.1c",
    "Summary of Unconfirmed Time to Response (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(
      paste("Protocol: IDRX-42-001"),
      "Page _PAGEOF_"
    ),
    hfrow(
      paste("Population: Efficacy"),
      paste("Data as of", g_config$datadate)
    )
  ) |>
  rtf_footer(
    "Note: Unconfirmed Time to Response (TTR), reported in patients achieving a Complete Response (CR) or Partial",
    "Response (PR) regardless of subsequent confirmation, is defined as the time from the date of first IDRX-42 dose",
    "to the date of the first documented CR or PR.",
    .align = "left"
  ) |> 
  build_rtf(file = file.path(g_paths$output, "t_ef_ucttr_pool_r.rtf"))
