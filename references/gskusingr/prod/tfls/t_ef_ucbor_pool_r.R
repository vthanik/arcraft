####------------------------------------------------------------------------####
# Program Name: t_ef_ucbor_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Vignesh Thanikachalam / vt704670
# Purpose:  Summary of Unconfirmed Best Overall Response and Objective 
# Response Rate (Phase 1 & 1b pooled)
#
# Input:
#   - ADaM: adbs
# Output:
#   - DD: t_ef_ucbor_pool_r
#   - File: ../prod/output/t_ef_ucbor_pool_r.RTF
#
# External files called:
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- 0. Setup and Central Definitions ---

# Load required R packages. `pkg_attach` is a helper for attaching packages.
pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "binom", "tfrmt")

# Define response levels and labels for clarity and consistent ordering.
resp_aval_levels <- c("CR", "PR", "SD", "PD", "NE", "UNK")

resp_labels <- c(
  "COMPLETE RESPONSE (CR)",
  "PARTIAL RESPONSE (PR)",
  "STABLE DISEASE (SD)",
  "PROGRESSIVE DISEASE (PD)",
  "NOT EVALUABLE",
  "UNKNOWN"
)

# --- 1. Load and Prepare Raw Data ---

# Load the ADaM Subject-Level Analysis Dataset (ADBS).
adbs_raw <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y") |>
  select(USUBJID, DOSGRPN, DOSGRP, EFFL)

# Load the ADaM Efficacy Analysis Dataset (ADEFF).
adeff_boru_raw <- read_data_catalog(adamdata$adeff) |>
  filter(EFFL == "Y", PARAMCD == "BORU", ACAT2 == "INVESTIGATOR") |>
  # Select only essential columns.
  select(USUBJID, PARAMCD, AVALC, ACAT2)

# Define ordered treatment levels from ADBS for consistent table columns.
trt_levels <- adbs_raw |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)

trt_levels_total <- c(trt_levels, "Total")

# --- 2. Define the Analysis Population and Denominators ---

# Create the base analysis population dataframe (`anl_pop_base`).
anl_pop_base <- adbs_raw |>
  select(USUBJID, DOSGRP) |>
  filter(!is.na(DOSGRP))

# Create the final analysis population (`anl_pop`) by adding a "Total" group.
anl_pop <- bind_rows(
  anl_pop_base,
  anl_pop_base |> mutate(DOSGRP = "Total")
  ) |>
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total)) |>
  distinct(USUBJID, DOSGRP)


# --- 3. Prepare Analysis-Specific Data for ARD Creation ---
# This section processes the raw response data (BORU and ORR) and links it
# with the analysis population (`anl_pop`) to prepare it for ARD generation.

# Prepare Unconfirmed Best Overall Response (BORU) data.
adeff_bor_prepared <- adeff_boru_raw |>
  # Standardize 'SD' responses.
  mutate(
    AVALC = case_when(
      AVALC %in% c("6 <= SD < 16 weeks", "SD >= 16 weeks") ~ "SD",
      TRUE ~ AVALC
    ),
    RESP = factor(AVALC, levels = resp_aval_levels, labels = resp_labels)
  ) |>
  select(USUBJID, RESP) |>
  inner_join(anl_pop, by = "USUBJID") |>
  distinct(USUBJID, DOSGRP, .keep_all = TRUE)


# Prepare Objective Response Rate (ORR) data.
# ORR is derived from BORU: CR or PR counts as a response.
adeff_orr_prepared <- anl_pop |>
  left_join(
    adeff_boru_raw |> select(USUBJID, AVALC),
    by = "USUBJID"
  ) |>
  # Derive ORRFN (Objective Response Flag Numerical): 1 for CR/PR, 0 otherwise.
  mutate(ORRFN = if_else(AVALC %in% c("CR", "PR"), 1, 0)) |>
  select(USUBJID, DOSGRP, ORRFN) |>
  distinct(USUBJID, DOSGRP, .keep_all = TRUE)

# --- 4. Build Analysis Results Data (ARD) using `cards` Package ---

# Define the grouping variables for ARD generation.
ard_by_vars <- c("DOSGRP")

# Create ARD for Unconfirmed Best Overall Response (BORU) counts and percentages.
ard_bor_overall <- adeff_bor_prepared |>
  ard_stack_hierarchical(
    by = all_of(ard_by_vars),
    variables = RESP,
    denominator = anl_pop, # Use the full analysis population as denominator.
    id = USUBJID
  ) 
  
ard_bor <- ard_bor_overall |> filter(!is.na(group1))

# Create ARD for Objective Response Rate (ORR).
# We filter for ORRFN == 1 (responders) to count them, and use the full `anl_pop`
# to get the correct 'N' (total subjects in analysis population).
ard_orr <- adeff_orr_prepared |>
  filter(ORRFN == 1) |>
  ard_hierarchical(
    by = all_of(ard_by_vars),
    variables = ORRFN,
    denominator = anl_pop, # Use the full analysis population as denominator.
    id = USUBJID
  ) 

# Combine the ARD objects for BORU and ORR into a single ARD.
all_ards <- bind_ard(ard_bor, ard_orr, .update = TRUE) |> 
  unlist_ard_columns() |> 
  mutate(
    variable_level = case_when(
      variable == "ORRFN" ~ "Objective Response Rate",
      .default = variable_level
    ),
    variable = case_when(
      variable == "RESP" ~  "Best Overall Response (Unconfirmed)",
      variable == "ORRFN" ~ "Objective Response Rate",
      .default = variable
    ) 
  )

# --- 5. Calculate Confidence Intervals (CIs) for ORR ---
# This section calculates 95% exact binomial confidence intervals for the ORR
# for each treatment group and the total.

ci_data <- all_ards |>
  # Filter for the ORRFN variable and 'n' (number of responders) and 'N' (total subjects).
  filter(
    variable == "Objective Response Rate" &
      stat_name %in% c("n", "N") &
      !is.na(stat)
  ) |>
  # Reshape data to have 'n' and 'N' in separate columns for `binom.confint`.
  pivot_wider(
    id_cols = c(starts_with("group"), variable),
    names_from = stat_name,
    values_from = stat
  ) |>
  # Unnest if n or N were list-columns (though usually not for `stat` in ARD).
  unnest(c(n, N), keep_empty = TRUE) |>
  # Calculate binomial exact CIs for each row (each DOSGRP group).
  mutate(
    ci = map2(
      n,
      N,
      ~ binom.confint(.x, .y, methods = "exact") |> select(lower, upper)
    )
  ) |>
  # Expand the CI list-column into separate 'lower' and 'upper' columns.
  unnest(ci) |>
  # Reshape back to long format for binding with the main ARD.
  pivot_longer(
    cols = c(lower, upper),
    names_to = "stat_name",
    values_to = "stat"
  ) |>
  # Assign descriptive labels for the CI bounds.
  mutate(
    stat_label = if_else(stat_name == "lower", "Lower 95% CI", "Upper 95% CI"),
    # Assign the defined ORR_VARIABLE_LEVEL for consistent labeling.
    variable = "95% exact Confidence Interval",
    variable_level = "95% exact Confidence Interval"
  ) |> 
  unlist_ard_columns()
  

# --- 6. Finalize ARD: Combine, Order, and Clean ---
# This section combines all results (BORU counts, ORR counts, ORR CIs),
# applies final ordering, and selects the desired output columns.

final_ard <- bind_rows(all_ards, ci_data) |>
  rename_ard_columns(columns = all_ard_groups("names")) |> 
  # Filter out rows where variable_level is NA (e.g., intermediate 'N' rows not needed in final output).
  filter(!is.na(variable_level)) |>
  # Re-apply factor levels for correct ordering after binding and unlisting.
  mutate(
    DOSGRP = factor(DOSGRP, levels = trt_levels_total),
    variable = factor(variable, levels = c("Best Overall Response (Unconfirmed)", "Objective Response Rate", "95% exact Confidence Interval")),
    variable_level = factor(variable_level, levels = c(resp_labels, "Objective Response Rate", "95% exact Confidence Interval"))
  ) |>
  # Arrange rows into the final desired table order: by treatment group, then by response/ORR.
  arrange(DOSGRP, variable, variable_level) |>
  # Select final columns for a clean and standardized output.
  select(
    DOSGRP,  
    variable,
    variable_level,
    stat_name,
    stat
  ) 
  
ard_pop <- ard_bor_overall |> filter(is.na(group1)) |> 
  unlist_ard_columns() |> 
  rename_ard_columns(columns = all_ard_variables("names")) |> 
  filter(stat_name == "n") |> 
  mutate(stat_name = "popn") |> 
  select(all_of(ard_by_vars), stat_name, stat)

final <- bind_rows(final_ard, ard_pop) |> 
  filter(stat_name %in% c("n", "p", "lower", "upper", "popn")) |> 
  mutate(across(where(is.factor), as.character))

arrow::write_parquet(
  final, 
  file.path(g_paths$dddata, "t_ef_ucbor_pool_r.parquet")
)

# --- 6. Build `tfrmt` structure ---
# Define the table structure using tfrmt.
tfobj <-
  tfrmt(
    group = variable,
    label = variable_level,
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
            "==1" ~ frmt("(100%)"),
            ">0.99" ~ frmt("(>99%)"),
            "==0" ~ frmt(""),
            "<0.01" ~ frmt("( <1%)"),
            ">0" ~ frmt("(xxx%)", transform = ~ . * 100),
            "TRUE" ~ frmt("")
          )
        )
      ),
      frmt_structure(
        group_val = ".default",
        label_val = ".default",
        frmt_combine(
          "({lower}, {upper})",
          CL = frmt_when("==0" ~ "0", "==1" ~ "100", "TRUE" ~ frmt("x.x", transform = ~ . * 100)),
          CH = frmt_when("==0" ~ "0", "==1" ~ "100", "TRUE" ~ frmt("x.x", transform = ~ . * 100))
        )
      )
    ),
    big_n = big_n_structure(param_val = "popn", n_frmt = frmt("\n(N=x)")),
    row_grp_plan = row_grp_plan(
      row_grp_structure(
        group_val = "Best Overall Response (Unconfirmed)",
        element_block(post_space = " ")
      ),
      label_loc = element_row_grp_loc(location = "indented")
    )
  )

# Convert the tfrmt object to a gt object for printing.
gt <- print_to_gt(tfobj, final)


# --- 7. Create and Save Output in RTF ---

# Build the RTF table object with final formatting.
rtf_dt <- gt |>
  rtf_table() |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.2in") |>
  rtf_col_label(variable_level = "") |>
  rtf_paginate_cols(id_columns = variable_level, split_at = 5) |>
  rtf_title(
    "Table 14.2.1.2c",
    "Summary of Unconfirmed Best Overall Response and Objective Response Rate (Phase 1 & 1b pooled)"
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
    "Note: Objective response rate (ORR) is defined as the proportion of patients achieving confirmed/unconfirmed CR or PR.",
    .align = "left"
  ) |> 
  build_rtf(file = file.path(g_paths$output, "t_ef_ucbor_pool_r.rtf"))