####------------------------------------------------------------------------####
# Program Name: t_sf_aemax_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Shilpa Kolli / sk575206
# Purpose: Table 14.3.2.8e Summary of IDRX-42-related Treatment-Emergent Adverse Events by System 
# Organ Class, Preferred Term and Maximum CTCAE Grade by Line of Therapy (Phase 1 & 1b pooled)
#
# Input:
#   - ADaM: [adbs, adae]
# Output:
#   - DD: t_sf_aemax_lot_pool_r.parquet
#   - File: ../prod/output/t_sf_aemax_lot_pool_r.RTF
#
# External files called: [N/A]
#
# Additional Notes:
#
#
#-------------------------------------------------------------------------------

# --- 0.Load Libraries ---

pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "tfrmt", "arrow")

# --- 1. Load Data and Define Factor Levels ---

# Load Basic Data Structure and filter for the Safety population.
adbs_raw <- read_data_catalog(adamdata$adbs) |>
  filter(SAFFL == "Y", !is.na(LOTCAT))

# Load Adverse Event data for the Safety population.
adae_raw1 <- read_data_catalog(adamdata$adae) |>
  filter(SAFFL == "Y" & AREL == "Related" & TRTEMFL == "Y") 

# Join AE data with treatment group info
adae_raw2 <- adbs_raw |>
  select(USUBJID, LOTCAT) |>
  inner_join(adae_raw1, by = "USUBJID")

# Define ordered factor levels for consistent sorting
tox_levels <- c("Grade 1", "Grade 2", "Grade 3", "Grade 4", "Grade 5")
tox_levels_total <- c(tox_levels, "Total")

trt_levels <- adbs_raw |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)
trt_levels_total <- c(trt_levels, "Total")
# Dynamically create ordered LOT Group factor levels.
lot_levels <- adbs_raw |>
  distinct(LOTCAT) |>
  arrange(LOTCAT) |>
  pull(LOTCAT)

# --- 2. Prepare Denominator (Big N) ---
# Calculate the total number of patients (N) for each treatment group and the overall total.
df_N <- adbs_raw |>
  distinct(USUBJID, LOTCAT) |>
  # bind_rows(adbs_raw |> distinct(USUBJID)) |>
  count(LOTCAT, name = "N")

# Create the 'bign' object for tfrmt column labels
bign <- df_N|>
  mutate(col_label = if_else(N > 0, paste0(LOTCAT, " (N=", N, ")"), LOTCAT))


# --- 3. Prepare Numerator Data (n) with All Hierarchical Levels ---

# Base AE data with coalesced terms and ordered grade factor
adae_base <- adae_raw2 |>
  mutate(
    AESOC = coalesce(AESOC, "Uncoded SOC"),
    AEDECOD = coalesce(AEDECOD, "Uncoded PT"),
    ATOXGR = factor(ATOXGR, levels = tox_levels, ordered = TRUE)
  )

# *** NEW: HELPER FUNCTION TO REDUCE REPETITION ***
# This function encapsulates the repeated logic of finding the max grade per patient
# within specified groups, and adding a 'Total' grade level.
calculate_max_grade_by <- function(.data, ...) {
  # Group by patient, treatment, and any other specified variables (...)
  df_max_grade <- .data |>
    group_by(USUBJID, LOTCAT, ...) |>
    slice_max(order_by = ATOXGR, n = 1, with_ties = FALSE) |>
    ungroup()
  
  # Add a "Total" grade row for each unique patient combination
  bind_rows(
    df_max_grade,
    df_max_grade |> distinct(USUBJID, LOTCAT, ...) |> mutate(ATOXGR = "Total")
  )
}

# A) Prepare "Patients with Any Event" data using the helper function
n_any_event_data <- calculate_max_grade_by(adae_base) |>
  mutate(
    variable = "Patients with Any Event",
    variable_level = "Patients with Any Event",
    AESOC = NA_character_, AEDECOD = NA_character_
  )

# B) Prepare SOC-level numerator data using the helper function
soc_max_grade_data <- calculate_max_grade_by(adae_base, AESOC) |>
  mutate(variable = "AESOC", variable_level = AESOC, AEDECOD = NA_character_)

# C) Prepare PT-level numerator data using the helper function
pt_max_grade_data <- calculate_max_grade_by(adae_base, AESOC, AEDECOD) |>
  mutate(variable = "AEDECOD", variable_level = AEDECOD)

# D) Combine all hierarchical levels into one dataset
adae_hierarchical_n <- bind_rows(n_any_event_data, soc_max_grade_data, pt_max_grade_data)

# E) Summarize to get sparse counts of actual events for each level and its total.
df_counts <- adae_hierarchical_n |>
  bind_rows(mutate(adae_hierarchical_n)) |>
  group_by(LOTCAT, ATOXGR, variable, AESOC, AEDECOD, variable_level) |>
  summarise(n = n_distinct(USUBJID), .groups = "drop")

# 1. Create a scaffold of the column structure for EACH treatment group
df_scaffold <- expand_grid(
  LOTCAT = factor(lot_levels, levels = lot_levels),
  ATOXGR = factor(tox_levels_total, levels = tox_levels_total)
)

# 2. Get the unique hierarchical items that occurred within each treatment group
hier_items <- df_counts |>
  distinct(LOTCAT, variable, AESOC, AEDECOD, variable_level)

# 3. *** THE IMPROVED STEP ***
# Build the full grid by using a left_join. This is far more efficient
# than the original cross_join() %>% filter().
df_n_grid <- hier_items |>
  left_join(df_scaffold, by = "LOTCAT", relationship = "many-to-many")

# 4. Now, join the actual counts to this correctly-built grid
df_n <- df_n_grid |>
  left_join(df_counts, by = c("variable", "AESOC", "AEDECOD", "variable_level", "LOTCAT", "ATOXGR")) |>
  # Coalesce the NA counts to 0 for the combinations that were just created
  mutate(n = coalesce(n, 0L))

# --- 4. Combine and Pivot to Final ARD-like Format ---
final_ard <- df_n |>
  left_join(df_N, by = "LOTCAT") |>
  fill(N, .direction = "downup") |>
  mutate(p = if_else(N > 0, n / N, 0)) |>
  pivot_longer(
    cols = c(n, N, p),
    names_to = "stat_name",
    values_to = "stat"
  )

# --- 5. Reshape and Format Data for `tfrmt` ---

# Scale percentages and filter to n and p stats
processed_ard <- final_ard |>
  filter(stat_name %in% c("n", "p")) |>
  mutate(
    stat = case_when(
      stat_name == "p" ~ coalesce(stat * 100, 0),
      .default = stat
    )
  )

# Reshape data to create the row group and label structure
reshaped_ard <- processed_ard |>
  mutate(
    .row_type = case_when(
      variable == "Patients with Any Event" ~ "overall",
      variable == "AESOC" ~ "soc",
      variable == "AEDECOD" ~ "pt"
    ),
    # Redefine the 'variable' column to be the SOC for grouping
    variable = case_when(
      .row_type == "overall" ~ "Patients with Any TEAE",
      .row_type == "soc" ~ variable_level,
      .row_type == "pt" ~ AESOC
    ),
    # Redefine 'variable_level' to be the table label
    variable_level = case_when(
      .row_type == "overall" ~ "Patients with Any TEAE",
      .row_type == "soc" ~ "Any event",
      .row_type == "pt" ~ variable_level
    )
  ) |>
  select(-AESOC, -.row_type) # Clean up temporary columns

# Create sorting keys based on total counts for each PT.
pt_total_counts <- reshaped_ard |>
  filter(ATOXGR == "Total", stat_name == "n", !is.na(AEDECOD)) |>
  select(LOTCAT, AEDECOD, pt_count = stat) |> arrange(AEDECOD)

soc_total_counts <- reshaped_ard |>
  filter(ATOXGR == "Total", stat_name == "n", variable_level == "Any event") |>
  select(LOTCAT, variable, soc_count = stat)

# Create final main statistics ARD with sorting applied.
main_stats_ard <- reshaped_ard |>
  left_join(pt_total_counts, by = c("LOTCAT", "AEDECOD")) |>
  left_join(soc_total_counts, by = c("LOTCAT", "variable")) |>
  mutate(
    is_any_teae = (variable == "Patients with Any TEAE"),
    is_any_event = (variable_level == "Any event"),
    LOTCAT = factor(LOTCAT, levels = lot_levels),
  ) |>
  arrange(desc(is_any_teae), desc(is_any_event), desc(soc_count), desc(pt_count), variable, variable_level, LOTCAT) |> 
  left_join(select(bign, LOTCAT, col_label), by="LOTCAT") |>
  select(LOTCAT, col_label, variable, variable_level, ATOXGR, stat_name, stat) |>
  mutate(across(where(is.factor), as.character))

final_ard1 <- pivot_wider(
  data = final_ard,         
  names_from = ATOXGR,    
  values_from = stat,   
) %>% filter(Total != 0)

final_ard <- pivot_longer(
  data = final_ard1,
  cols = starts_with(c("G", "T")),
  names_to = "ATOXGR",
  # names_prefix = "Sales_", # Removes "Sales_" from the beginning of the `Year` column values
  values_to = "stat"
)
arrow::write_parquet(
  main_stats_ard,
  file.path(g_paths$dddata, "t_sf_aemax_lot_pool_r.parquet")
)

# --- 6. Build `tfrmt` structure ---
# Define the table structure using tfrmt.
tfobj <-
  tfrmt(
    group = c(col_label, variable),
    label = variable_level,
    column = ATOXGR,
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
    # big_n = big_n_structure(param_val = "popn", n_frmt = frmt("\n(N=x)"), by_page = TRUE),
    row_grp_plan = row_grp_plan(
      row_grp_structure(
        group_val = ".default",
        element_block(post_space = " ")
      ),
      label_loc = element_row_grp_loc(location = "spanning")
    ),
    
    page_plan = page_plan(page_structure(group_val = list(col_label = ".default")))
  )

# Convert the tfrmt object to a gt object for printing.
gt <- print_to_gt(tfobj, main_stats_ard)


# --- 7. Create and Save Output in RTF ---

# Build the RTF table object with final formatting.
rtf_obj <- gt |>
  rtf_table(
    page_group_label = paste("Line of Therapy:", col_label),
    drop_columns = LOTCAT
  ) |>
  rtf_col_align(
    variable_level = "left",
    starts_with(c("G", "T")) ~ "center",
    .group = "header"
  ) |>
  rtf_col_widths(starts_with(c("G", "T")) ~ "1.05in") |>
  rtf_col_label(variable_level = "System Organ Class\n  Preferred Term") |>
  rtf_title(
    "Table 14.3.2.8e",
    "Summary of IDRX-42-related Treatment-Emergent Adverse Events by System Organ Class, Preferred Term and",
    "Maximum CTCAE Grade by Line of Therapy (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Safety", paste("Data as of", g_config$datadate))
  ) |>
  rtf_footer(
    "Note: Adverse Events are coded with MedDRA 28.0.",
    "Note: Treatment-emergent adverse events (TEAE) will be recorded from the start of study treatment until 30 days after the last dose of IDRX-42.",
    "Note: Each patient is counted at most once in each category."
  ) |>
  rtf_options(page_margin_top = "0.95in", page_margin_bottom = "0.95in", page_line_size_landscape = 31) |> 
  build_rtf(
    file = file.path(g_paths$output, "t_sf_aemax_lot_pool_r.rtf")
  )
