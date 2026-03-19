####------------------------------------------------------------------------####
# Program Name: qc_t_sf_aeoverall_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Shilpa Kolli / sk575206
# Purpose: Overall Summary of Treatment Emergent Adverse Events by 1st and 
# 2nd Line of Therapy (Phase 1 & 1b pooled)
#
# Input:
#   - ADaM: ADBS, ADAE
# Output:
#   - - qc/output/qc_t_sf_aeoverall_lot_pool_r.lst
#
# External files called:
#
# Additional Notes: 
#
#
#-------------------------------------------------------------------------------

# --- 0. Load Libraries ---
# Ensure all necessary packages are loaded.
pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "tfrmt", "arrow")

# --- 1. Load Data and Define Base Population ---

# Load ADSL/ADBS data and filter for the Safety population.
# This data is primarily used to get the treatment group assignment and the denominator (N).
adbs_raw <- read_data_catalog(adamdata$adbs) |>
  filter(SAFFL == "Y", !is.na(LOTCAT), !is.na(DOSGRP))

# Load Adverse Event data.
# We start with the base TEAE population as defined in the SAS code (SAFFL='Y' and TRTEMFL='Y').
adae_raw <- read_data_catalog(adamdata$adae) |>
  filter(SAFFL == "Y" & TRTEMFL == "Y")

# Join AE data with treatment group info from ADBS.
adae_data <- adbs_raw |>
  select(USUBJID, DOSGRP, DOSGRPN, LOTCATN, LOTCAT) |>
  inner_join(adae_raw, by = "USUBJID")

# Define ordered factor levels for treatment groups for consistent sorting
trt_levels <- adbs_raw |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)
trt_levels_total <- c(trt_levels, "Total")


# --- 2. Prepare Denominator (Big N) ---
# Calculate the total number of patients (N) in the safety population for each treatment group and overall.
df_N <- adbs_raw |>
  distinct(USUBJID, LOTCAT, DOSGRP) |>
  bind_rows(adbs_raw |> distinct(USUBJID, LOTCAT) |> mutate(DOSGRP = "Total")) |>
  count(LOTCAT, DOSGRP, name = "N") |>
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total))

# This can be used later for tfrmt column labels if needed
bign <- df_N |>
  mutate(col_label = if_else(N > 0, paste0(DOSGRP, "\n(N=", N, ")"), DOSGRP))


# --- 3. Generate Numerator Data (n) by Replicating SAS Logic ---

# Define the category labels and their order as specified in the SAS code
category_levels <- c(
  "TEAE",
  "IDRX-42-related TEAE",
  "TEAE with Grade 3 or Higher",
  "IDRX-42-related TEAE with Grade 3 or Higher",
  "TESAE",
  "IDRX-42-related TESAE",
  "TEAE leading to IDRX-42 Withdrawal",
  "TEAE leading to IDRX-42 Drug Interruption",
  "TEAE leading to IDRX-42 Dose Reduction",
  "TEAE leading to death",
  "Dose limiting toxicity"
)

# For each subject, determine if they had at least one AE meeting each criterion.
# This approach avoids recounting subjects who have multiple AEs in the same category.
subject_summary <- adae_data |>
  # Use toupper() for case-insensitive matching, which is robust and mimics SAS behavior.
  group_by(USUBJID, LOTCAT, DOSGRP) |>
  summarize(
    # catgroup1: TEAE (Any event in the source data is a TEAE)
    cat1 = TRUE,
    # catgroup2: Related TEAE
    cat2 = any(toupper(AEREL) %in% c("RELATED", "POSSIBLY RELATED")),
    # catgroup3: Grade 3+ TEAE
    cat3 = any(ATOXGRN >= 3, na.rm = TRUE),
    # catgroup4: Related Grade 3+ TEAE
    cat4 = any(ATOXGRN >= 3 & toupper(AEREL) %in% c("RELATED", "POSSIBLY RELATED"), na.rm = TRUE),
    # catgroup5: Serious AE
    cat5 = any(AESER == "Y"),
    # catgroup6: Related Serious AE
    cat6 = any(AESER == "Y" & toupper(AEREL) %in% c("RELATED", "POSSIBLY RELATED")),
    # catgroup7: Led to Drug Withdrawal
    cat7 = any(toupper(AEACN) == "DRUG WITHDRAWN"),
    # catgroup8: Led to Drug Interruption
    cat8 = any(toupper(AEACN) == "DRUG INTERRUPTED"),
    # catgroup9: Led to Dose Reduction
    cat9 = any(toupper(AEACN) == "DOSE REDUCED"),
    # catgroup10: Led to Death
    cat10 = any(AESDTH == "Y"),
    # catgroup11: Dose Limiting Toxicity
    cat11 = any(AEDLT == "Y"),
    .groups = "drop"
  ) |>
  # Pivot from a wide format (one column per category) to a long format
  pivot_longer(
    cols = starts_with("cat"),
    names_to = "category_id",
    values_to = "has_event"
  ) |>
  # We only care about the subjects who had the event
  filter(has_event == TRUE) |>
  # Map the temporary category ID to the final label
  mutate(
    row_label = case_when(
      category_id == "cat1" ~ category_levels[1],
      category_id == "cat2" ~ category_levels[2],
      category_id == "cat3" ~ category_levels[3],
      category_id == "cat4" ~ category_levels[4],
      category_id == "cat5" ~ category_levels[5],
      category_id == "cat6" ~ category_levels[6],
      category_id == "cat7" ~ category_levels[7],
      category_id == "cat8" ~ category_levels[8],
      category_id == "cat9" ~ category_levels[9],
      category_id == "cat10" ~ category_levels[10],
      category_id == "cat11" ~ category_levels[11],
    ),
    row_label = factor(row_label, levels = category_levels)
  )

# --- 4. Calculate Counts (n) and Percentages (%) ---

# Calculate counts for each treatment group
n_counts_by_group <- subject_summary |>
  group_by(LOTCAT, DOSGRP, row_label) |>
  summarise(n = n(), .groups = "drop")

# Calculate total counts across all treatment groups
n_counts_total <- subject_summary |>
  group_by(row_label, LOTCAT) |>
  summarise(n = n(), .groups = "drop") |>
  mutate(DOSGRP = "Total")

# Combine group and total counts
df_numer <- bind_rows(n_counts_by_group, n_counts_total) |>
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total))

# Join numerators (n) with denominators (N) to create the final summary data frame
# A right join ensures all categories and treatment groups are present, even with zero counts.
qc_summary_data <- df_numer |>
  right_join(
    # Create a complete grid of all possible combinations of labels and groups
    tidyr::expand(df_numer, row_label, LOTCAT, DOSGRP),
    by = c("LOTCAT", "DOSGRP", "row_label")
  ) |>
  left_join(df_N, by = c("LOTCAT", "DOSGRP")) |>
  # If a count is NA after the join, it means it was 0
  mutate(
    n = if_else(is.na(n), 0L, n),
    p = (n / N) * 100
  ) |>
  arrange(row_label, LOTCAT, DOSGRP) |> 
  tidyr::pivot_longer(
    cols = c("n", "p"),
    names_to = "stat_name",
    values_to = "stat"
  ) |> 
  rename("label" = "row_label") |> 
  mutate(
    across(where(is.factor), as.character),
    stat = if_else(is.na(stat), 0, stat)
  ) |> 
  select(!N) |> 
  arrange(LOTCAT, DOSGRP, label)

prod <- read_parquet(file.path(g_paths$dddata,"t_sf_aeoverall_lot_pool_r.parquet")) |> 
  filter(stat_name %in% c("n", "p")) |>
  select(!c(group, starts_with("ord"))) |> 
  arrange(LOTCAT, DOSGRP, label)

# Compare the QC-generated data with the production data.
diffdf::diffdf(
  base = prod,
  compare = qc_summary_data,
  file = file.path(g_paths$qc_output, "qc_t_sf_aeoverall_lot_pool_r.lst")
)
