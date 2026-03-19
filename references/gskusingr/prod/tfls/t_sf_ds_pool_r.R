####------------------------------------------------------------------------####
# Program Name: t_sf_ds_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Vignesh Thanikachalam / vt704670
# Purpose: Summary of Disposition (Phase 1 & 1b pooled)
#
# Input:
#   - ADaM: adbs
# Output:
#   - DD: t_sf_ds_pool_r
#   - File: ../prod/output/t_sf_ds_pool_r.RTF
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- 0. Setup ---

pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "tfrmt")

# --- 1. Load Data and Define Levels ---

adbs_raw <- read_data_catalog(adamdata$adbs) |> 
  filter(SAFFL == "Y", !is.na(DOSGRP))

# Dynamically create ordered treatment group factor levels
# This is more robust than hard-coding the order
trt_levels <- adbs_raw |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)

trt_levels_total <- c(trt_levels, "Total")

# --- 2. Prepare Analysis Data ---

# Create the final ADSL for analysis by filtering and joining
# ARM is defined from DOSGRP for this analysis
adbs <- adbs_raw |>
  select(USUBJID, DOSGRP, EOTSTT, DCTREAS, EOSSTT, DCSREAS)

adsl <- bind_rows(adbs, adbs |> mutate(DOSGRP = "Total")) |>
  mutate(
    DOSGRP = factor(DOSGRP, levels = trt_levels_total),
    DCTREAS = fct_relevel(DCTREAS, "Other", after = Inf),
    DCSREAS = fct_relevel(DCSREAS, "Other", after = Inf),
  )

# --- 3. Build Analysis Results Data (ARD) ---

# Generate summary statistics for disposition variables
ard <- adsl |>
  ard_stack(
    ard_tabulate(
      variables = c(EOTSTT, DCTREAS, EOSSTT, DCSREAS),
      denominator = adsl ,
    ),
    .by = DOSGRP,
    .overall = TRUE
  ) 

# --- 4. Post-process the ARD ---

# Unlist list-columns and rename the grouping column
processed_ard <- ard |>
  unlist_ard_columns() |>
  rename_ard_columns(columns = all_ard_groups("names"))|>
  filter(variable_level != "")


# Isolate the main statistics (n and p)
main_stats_ard <- processed_ard |>
  filter(
    stat_name %in% c("n", "p"),
    !variable %in% c("DOSGRP"), !is.na(DOSGRP)
  ) |>
  mutate(
    stat = case_when(
      stat_name == "p" ~ coalesce(stat * 100, 0),
      .default = stat
    ), 
    label = coalesce(variable_level, stat_label),
    variable = recode(
      variable,
      "EOTSTT" = "Treatment Status",
      "DCTREAS" = "Reason for Treatment Discontinuation",
      "EOSSTT" = "Study Status",
      "DCSREAS" = "Reason for Study Discontinuation"
    ),
    grp = recode(
      variable,
      "Treatment Status" = 1,
      "Reason for Treatment Discontinuation" = 1,
      "Study Status" = 2,
      "Reason for Study Discontinuation" = 2
    )
  )

# Isolate the population counts (Big Ns)
population_counts_ard <- processed_ard |>
  filter(variable == "DOSGRP", stat_name == "n") |>
  mutate(
    ARM = stat_label,
    stat_name = "bigN",
    DOSGRP = variable_level,
    variable = NA_character_,
    variable_level = NA_character_
  )

# Combine main stats and population counts into a final ARD
final_ard <- bind_rows(main_stats_ard, population_counts_ard) |>
  mutate(
    # Convert ARM to a factor to ensure correct column order in the table
    DOSGRP = factor(DOSGRP, levels = trt_levels_total)
  ) |>
  # Select final columns needed for tfrmt
  select(DOSGRP, variable, label, grp, stat_name, stat) 

# Save the final ARD for traceability or reuse
arrow::write_parquet(final_ard, file.path(g_paths$dddata, "t_sf_ds_pool_r.parquet"))

# --- 5. Table Formatting (tfrmt) ---

# Define the table structure using tfrmt
tfobj <- tfrmt(
  group = variable,
  label = label,
  column = DOSGRP,
  value = stat,
  param = stat_name,
  sorting_cols = ,
  body_plan = body_plan(
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{n} {p}",
        n = frmt("xxx"),
        p = frmt_when(
          "==100" ~ frmt("(100%)"),
          ">99" ~ frmt("(>99%)"),
          "==0" ~ frmt(""),
          "<1" ~ frmt("( <1%)"),
          "TRUE" ~ frmt("(xxx%)")
        )
      )
    )
  ),
  big_n = big_n_structure(param_val = "bigN", n_frmt = frmt("\n(N=x)")),
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " "))
  )
)

# Convert the tfrmt object to a gt object
gt <- print_to_gt(tfobj, final_ard)

# --- 6. Create and Save Output in RTF ---

rtf_obj <- gt |>
  rtf_table(
    # Keep groups together to avoid orphaned rows
    row_noorphan_col = grp,
    drop_columns = grp
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(label = "") |>
  # Paginate columns if they exceed the page width
  rtf_paginate_cols(id_columns = label, split_at = 5) |>
  rtf_title(
    "Table 14.1.2c",
    "Summary of Disposition (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Safety", paste("Data as of", g_config$datadate))
  ) |>
  build_rtf(file = file.path(g_paths$output, "t_sf_ds_pool_r.rtf"))