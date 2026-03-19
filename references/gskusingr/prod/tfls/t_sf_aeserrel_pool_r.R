####------------------------------------------------------------------------####
# Program Name: t_sf_aeserrel_pool_r.R
# Domino Environment: Multilingual Semi-Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Summary of IDRX-42-related Treatment-Emergent Serios Adverse Events by System Organ Class
#          and Preferred Term (Phase 1 & 1b pooled)
#
# Input:
#   - adam: adbs, adae
# Output:
#   - dd: t_sf_aeserrel_pool_r.parquet
#   - File: ../prod/output/t_sf_aeserrel_pool_r.RTF
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

pkg_load(
  "dplyr",
  "forcats",
  "stringr",
  "tidyr",
  "purrr",
  "cards",
  "cardx",
  "tfrmt",
  "gt",
  "admiral",
  "arrow"
)

# --- 1. Load Data and Define Factor Levels ---

# Load Basic Data Structure and filter for the Safety population.
adbs <- read_data_catalog(adamdata$adbs) |>
  filter(SAFFL == "Y", !is.na(DOSGRP)) %>%
  select(
    SUBJID,
    USUBJID,
    SAFFL,
    TRT01P,
    TRT01PN,
    TRT01A,
    TRT01AN,
    DOSGRP,
    DOSGRPN
  )

adbs_1 <- convert_blanks_to_na(adbs)

# Load Adverse Event data for the Safety population.
adae <- read_data_catalog(adamdata$adae) |>
  filter(SAFFL == "Y", AESER == "Y", AREL == "Related", TRTEMFL == "Y") %>%
  select(USUBJID, SUBJID, AEDECOD, AESOC, AEBODSYS, AETERM) %>%
  mutate(
    AESOC = if_else(!is.na(AESOC), AESOC, "Not Coded"),
    AEDECOD = if_else(!is.na(AEDECOD), AEDECOD, "Not coded")
  ) %>%
  left_join(adbs_1 %>% select(USUBJID, DOSGRP, DOSGRPN), by = "USUBJID")

adae_1 <- convert_blanks_to_na(adae)

# Dynamically create ordered Treatment Group factor levels.
trt_levels <- adbs_1 |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)
trt_levels_total <- c(trt_levels, "Total")

# --- 2. Prepare Analysis Population Denominator ---

# Create `pop` with one row per patient per analysis group (incl. "Total").
pop <-
  bind_rows(adbs_1, adbs_1 |> mutate(DOSGRP = "Total")) |>
  distinct(USUBJID, DOSGRP) |>
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total))

# --- 3. Prepare Analysis-Specific Dataset ---

# Create `adae_by_trt`, containing clean data for each actual treatment group.
adae_by_trt <- adae_1 |>
  mutate(
    AESOC = coalesce(AESOC, "Uncoded SOC"),
    AEDECOD = coalesce(AEDECOD, "Uncoded PT")
  ) |>
  distinct(USUBJID, AESOC, AEDECOD) |>
  inner_join(select(adbs_1, USUBJID, DOSGRP), by = "USUBJID")

# Create the final `adae` dataset by adding the "Total" group to `adae_by_trt`
# and setting the final factor levels.
adae <- adae_by_trt |>
  bind_rows(mutate(adae_by_trt, DOSGRP = "Total")) |>
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total))


# --- 4. Build Analysis Results Data (ARD) using `cards` ---

# Calculate n/N for SOC and PT levels using `ard_stack_hierarchical`.
ard_socpt <- adae |>
  ard_stack_hierarchical(
    by = DOSGRP,
    variables = c(AESOC, AEDECOD),
    denominator = pop,
    id = USUBJID,
    over_variables = TRUE
  )

# Create `processed_ard` by unlisting columns, converting proportions to
# percentages, and standardizing column names.
processed_ard <- ard_socpt |>
  unlist_ard_columns() |>
  filter(stat_name %in% c("n", "p")) |>
  mutate(
    stat = case_when(
      stat_name == "p" ~ coalesce(stat * 100, 0),
      .default = stat
    )
  ) |>
  select(-any_of(c("warning", "error", "fmt_fun"))) |>
  rename_ard_columns(columns = all_ard_groups("names"))


# --- 5. Finalize and Format the Output Data ---

# Create `reshaped_ard` by constructing the final `variable` and
# `variable_level` columns from the hierarchical results.
reshaped_ard <- processed_ard |>
  filter(variable != "DOSGRP") |>
  mutate(
    .row_type = case_when(
      variable == "..ard_hierarchical_overall.." ~ "overall",
      variable == "AESOC" ~ "soc",
      variable == "AEDECOD" ~ "pt"
    ),
    variable = case_when(
      .row_type == "overall" ~ "Patients with Any TEAE",
      .row_type == "soc" ~ variable_level,
      .row_type == "pt" ~ AESOC
    ),
    variable_level = case_when(
      .row_type == "overall" ~ variable,
      .row_type == "soc" ~ "Any event",
      .row_type == "pt" ~ variable_level
    )
  ) |>
  select(-AESOC, -.row_type)

# Create `total_counts` and `soc_total_counts` containing event counts
# from the "Total" group to be used as sorting keys.
total_counts <- reshaped_ard |>
  filter(DOSGRP == "Total", stat_name == "n") |>
  select(variable, variable_level, all_count = stat)

soc_total_counts <- total_counts |>
  filter(variable_level == "Any event") |>
  select(variable, soc_count = all_count)

# Create `main_stats_ard` by joining sorting keys, arranging the data,
# and removing the key columns.
main_stats_ard <- reshaped_ard |>
  left_join(total_counts, by = c("variable", "variable_level")) |>
  left_join(soc_total_counts, by = "variable") |>
  mutate(
    soc_count = coalesce(soc_count, all_count),
    DOSGRP = factor(DOSGRP, levels = trt_levels_total)
  ) |>
  arrange(desc(soc_count), desc(all_count), variable, DOSGRP) |>
  select(-all_count, -soc_count)

# Create `population_counts_ard` containing the population 'N' for each group.
population_counts_ard <- processed_ard |>
  filter(variable == "DOSGRP", stat_name == "n") |>
  mutate(
    DOSGRP = variable_level,
    stat_name = "popn"
  ) |>
  select(-variable, -variable_level)

# Create `final_ard` by combining main statistics with population counts.
final_ard <- bind_rows(main_stats_ard, population_counts_ard) |>
  mutate(across(where(is.factor), as.character)) |>
  select(DOSGRP, variable, variable_level, stat_name, stat)

write_parquet(
  final_ard,
  file.path(g_paths$dddata, "t_sf_aeserrel_pool_r.parquet")
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
            "==100" ~ frmt("(100%)"),
            ">99" ~ frmt("(>99%)"),
            "==0" ~ frmt(""),
            "<1" ~ frmt("( <1%)"),
            "TRUE" ~ frmt("(xxx%)")
          )
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
rtf_obj <- gt |>
  rtf_table() |>
  rtf_col_align(
    variable_level = "left",
    starts_with(c("C", "T")) ~ "center",
    .group = "header"
  ) |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(variable_level = "System Organ Class\n  Preferred Term") |>
  rtf_paginate_cols(id_columns = variable_level, split_at = 5) |>
  rtf_options(page_line_size_landscape = 28) |>
  rtf_title(
    "Table 14.3.3.2c",
    "Summary of IDRX-42-related Serious Treatment-Emergent Adverse Events by System Organ Class and Preferred Term",
    "(Phase 1 & 1b pooled)"
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
  build_rtf(
    file = file.path(g_paths$output, "t_sf_aeserrel_pool_r.rtf")
  )