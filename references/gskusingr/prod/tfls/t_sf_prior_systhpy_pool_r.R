####------------------------------------------------------------------------####
# Program Name: t_sf_prior_systhpy_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: Summary of Prior Systemic Cancer Therapy (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adcm]
# Output:
#   - dd [t_sf_prior_systhpy_pool_r]
#   - File: ../prod/output/t_sf_prior_systhpy_pool_r.RTF
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes: Copy from Internal_02
#
#-------------------------------------------------------------------------------

# --- 0. Setup and Library Loading ---

source("/mnt/code/functions/r_setup.R")

pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "tfrmt")


# --- 1. Load Data and Define Factor Levels ---

# Load Basic Data Structure and filter for Safety population.
adbs_raw <- read_data_catalog(adamdata$adbs) |>
  filter(SAFFL == "Y")

# Load Concomitant Medications and filter for prior cancer therapies in Safety population.
adcm_raw <- read_data_catalog(adamdata$adcm) |>
  filter(SAFFL == "Y", CMCAT == "PRIOR CANCER THERAPY")

# Dynamically create Treatment Group factor levels from the data.
trt_levels <- distinct(adbs_raw, DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)
trt_levels_total <- c(trt_levels, "Total")

# Define static factor levels based on the analysis plan.
thpy_levels <- c("CHEMOTHERAPY", "TYROSINE KINASE THERAPY", "OTHER")
line_levels <- c(
  "FIRST LINE",
  "SECOND LINE",
  "THIRD LINE",
  "FOURTH LINE[JC1]",
  "> FOURTH LINE"
)
resp_levels <- c("CR", "PR", "SD", "PD", "NE", "UNK")
resp_labels <- c(
  "COMPLETE RESPONSE (CR)",
  "PARTIAL RESPONSE (PR)",
  "STABLE DISEASE (SD)",
  "PROGRESSIVE DISEASE (PD)",
  "NOT EVALUABLE",
  "UNKNOWN"
)


# --- 2. Prepare Analysis Population Denominator ---

# Create the `pop` data frame, defining one row per patient for each analysis stratum.
pop <-
  bind_rows(adbs_raw, adbs_raw |> mutate(DOSGRP = "Total")) |> # Add a "Total" group
  select(USUBJID, DOSGRP) |>
  distinct() |> # Get unique patient-group combinations
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total))


# --- 3. Prepare Analysis-Specific Datasets ---

# Create `adcm_base` with derived variables for analysis.
adcm_base <- adcm_raw |>
  mutate(
    THPY = factor(CMSCAT, levels = thpy_levels),
    SYSTRT = factor(CMLINE, levels = line_levels),
    RESP = factor(CMBSTRSP, levels = resp_levels, labels = resp_labels),
    CMTRT = if_else(
      str_detect(CMTRT, "OTHER:|PAZOPANIB|SORAFENIB"),
      "OTHER",
      CMTRT
    ),
    N_THPY = case_when(
      CMUPRTH %in% 1:3 ~ as.character(CMUPRTH),
      CMUPRTH >= 4 ~ "4 or more"
    ),
    N_TKI = case_when(
      CMUNTK %in% 1:3 ~ as.character(CMUNTK),
      CMUNTK >= 4 ~ "4 or more"
    )
  )

# Dynamically set CMTRT factor levels to place "OTHER" last.
cmtrt_levels <- c(sort(setdiff(unique(adcm_base$CMTRT), "OTHER")), "OTHER")

# Create `adcm_thpy` for therapy-level summaries (many-per-patient).
adcm_thpy_trt <- adcm_base |>
  select(USUBJID, THPY, CMTRT) |>
  distinct() |> 
  inner_join(adbs_raw |> select(USUBJID, DOSGRP), by = "USUBJID")

adcm_thpy <-
  bind_rows(adcm_thpy_trt, adcm_thpy_trt |> mutate(DOSGRP = "Total")) |>
  mutate(
    DOSGRP = factor(DOSGRP, levels = trt_levels_total),
    CMTRT = factor(CMTRT, levels = cmtrt_levels)
  )

# Create `adcm_line` for patient-level summaries (one-per-patient).
adcm_line <- pop |> # Start with the defined population for robustness
  left_join(
    adcm_base |>
      select(USUBJID, SYSTRT, RESP, N_THPY) |>
      slice_max(order_by = SYSTRT, n = 1, by = USUBJID, with_ties = FALSE), # Get latest line per patient
    by = "USUBJID"
  ) |>
  left_join(
    adcm_base |>
      filter(THPY == "TYROSINE KINASE THERAPY") |>
      select(USUBJID, N_TKI) |>
      slice_max(order_by = N_TKI, n = 1, by = USUBJID, with_ties = FALSE), # Get max TKI count per patient
    by = "USUBJID"
  )


# --- 4. Build Analysis Results Data (ARD) using `cards` ---

# Calculate n/N for the hierarchical variable THPY.
ard_thpy <- adcm_thpy |>
  ard_stack_hierarchical(
    by = DOSGRP,
    variables = THPY,
    denominator = pop,
    id = USUBJID,
    over_variables = TRUE
  )

# Calculate n/N for each treatment type, counting each patient once per type.
ard_trt <- adcm_thpy |>
  ard_hierarchical(
    by = DOSGRP,
    variables = CMTRT,
    denominator = pop,
    id = USUBJID
  )

# Calculate n/N for patient-level statistics.
ard_stats <- adcm_line |>
  ard_tabulate(
    by = DOSGRP,
    variables = c(SYSTRT, N_THPY, N_TKI),
    denominator = pop
  )

# Combine all ARD objects and perform final formatting.
all_ards <- bind_ard(ard_thpy, ard_trt, ard_stats, .update = TRUE) |>
  unlist_ard_columns() |>
  filter(stat_name %in% c("n", "p")) |>
  mutate(
    stat = case_when(
      stat_name == "p" & is.nan(stat) ~ 0, # Convert NaN percentages to 0
      stat_name == "p" ~ stat * 100, # Convert proportion to percentage
      .default = stat
    )
  ) |>
  select(-any_of(c("warning", "error", "fmt_fun"))) |>
  rename_ard_columns(columns = all_ard_groups("names"))


# --- 5. Finalize and Format the Output Data ---

# Create a named vector to map programming variable names to display labels.
variable_label_map <- c(
  "..ard_hierarchical_overall.." = "Patients with Prior Systemic Cancer Therapy",
  "THPY" = "Type of Therapy [1]",
  "SYSTRT" = "Prior Lines of Systemic Treatment [2]",
  "CMTRT" = "Prior TKI Therapy",
  "N_THPY" = "Number of Unique Prior Therapies",
  "N_TKI" = "Number of Unique Tyrosine Kinase Inhibitor Therapies"
)

# Prepare the main body of the table statistics, including recoding and sorting keys.
main_stats_ard <- all_ards |>
  filter(variable != "DOSGRP") |>
  mutate(
    sort_key1 = if_else(
      variable == "THPY",
      match(variable_level, thpy_levels),
      NA_integer_
    ),
    variable = recode(variable, !!!variable_label_map),
    variable_level = if_else(variable_level == "TRUE", variable, variable_level)
  )

# Prepare the population counts for column headers.
population_counts_ard <- all_ards |>
  filter(variable == "DOSGRP", stat_name == "n") |>
  mutate(
    DOSGRP = if_else(variable == "DOSGRP", variable_level, DOSGRP),
    stat_name = "popn"
  ) |>
  select(-c(variable, variable_level))

# Combine stats and population counts into the final ARD.
final_ard <- bind_rows(main_stats_ard, population_counts_ard) |>
  mutate(
    across(where(is.factor), as.character),
    order = match(variable, unname(variable_label_map))
  ) |>
  arrange(order, sort_key1) |>
  select(DOSGRP, variable, variable_level, stat_name, stat, order)

arrow::write_parquet(
  final_ard,
  file.path(g_paths$dddata, "t_sf_prior_systhpy_pool_r.parquet")
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
    sorting_cols = order,
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
  rtf_table(drop_columns = "order") |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(variable_level = "") |>
  rtf_paginate_cols(id_columns = variable_level, split_at = 5) |>
  rtf_title(
    "Table 14.1.6.1c",
    "Summary of Prior Systemic Cancer Therapy (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Safety", paste("Data as of", g_config$datadate))
  ) |>
  rtf_footer(
    "[1] The patients may report multiple categories.",
    "[2] Latest line of prior therapy, patients counted only once."
  ) |>
  build_rtf(
    file = file.path(g_paths$output, "t_sf_prior_systhpy_pool_r.rtf")
  )