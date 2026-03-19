####------------------------------------------------------------------------####
# Program Name: qc_t_sf_prior_systhpy_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: QC of Summary of Prior Systemic Cancer Therapy by Line of Therapy
#          (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adcm]
# Output:
#   - dd []
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------
# --- Load Libraries ---
pkg_load("dplyr", "forcats", "stringr", "purrr", "cards")

# --- 1. Data Loading and Preparation ---

# Load ADBS, which serves as the population denominator (N), and filter for
# the Safety-Analysable Population.
adbs_raw <- read_data_catalog(adamdata$adbs) |>
  filter(SAFFL == "Y") |>
  mutate(
    # Re-level LOTCAT for logical sorting in the final output.
    LOTCAT = fct_relevel(LOTCAT, "1st-line", "2nd-line", "3rd or later-line")
  ) |>
  # Ensure key grouping variables are not missing before analysis.
  filter(!is.na(DOSGRP) & !is.na(LOTCAT))

adbs_base <- adbs_raw |> 
  select(USUBJID, LOTCAT,LOTCATN, DOSGRP,DOSGRPN,GISTMUTN, GISTMUT) |>
  distinct()

# Load raw ADCM data, filtering for the population and category of interest.
adcm_raw <- read_data_catalog(adamdata$adcm) |>
  filter(SAFFL == "Y", CMCAT == "PRIOR CANCER THERAPY")

# Define ordered treatment group levels from ADBS to ensure consistent sorting.
trt_levels <- adbs_base |>
  arrange(DOSGRPN) |>
  distinct(DOSGRP) |>
  pull(DOSGRP)

# Pre-process ADCM data by joining with ADBS and creating analysis variables.
adcm_base <- adcm_raw |>
  # Join with ADBS to get treatment group and other baseline characteristics.
  left_join(
    select(adbs_base, USUBJID, DOSGRP, GISTMUTN, GISTMUT, LOTCAT),
    by = "USUBJID"
  ) |>
  # Create and re-level factors for consistent analysis and reporting.
  mutate(
    DOSGRP = fct_relevel(DOSGRP, trt_levels),
    THPY = fct_relevel(
      CMSCAT,
      "CHEMOTHERAPY",
      "TYROSINE KINASE THERAPY",
      "OTHER"
    ),
    PRIOR_SYSTRT = fct_relevel(
      CMLINE,
      "FIRST LINE",
      "SECOND LINE",
      "THIRD LINE",
      "FOURTH LINE[JC1]",
      "> FOURTH LINE"
    ),
    PRIOR_RSP = factor(
      CMBSTRSP,
      levels = c("CR", "PR", "SD", "PD", "NE", "UNK"),
      labels = c(
        "COMPLETE REMISSION (CR)",
        "PARTIAL REMISSION (PR)",
        "STABLE DISEASE (SD)",
        "PROGRESSIVE DISEASE (PD)",
        "NOT EVALUABLE",
        "UNKNOWN"
      )
    ),
    CMTRT = if_else(
      str_detect(CMTRT, "OTHER:|PAZOPANIB|SORAFENIB"),
      "OTHER",
      CMTRT
    ),
    UPRIOR_THPY = case_when(
      CMUPRTH %in% 1:3 ~ as.character(CMUPRTH),
      CMUPRTH >= 4 ~ "4 or more",
      .default = NA_character_
    ),
    UPRIOR_TKI = case_when(
      CMUNTK %in% 1:3 ~ as.character(CMUNTK),
      CMUNTK >= 4 ~ "4 or more",
      .default = NA_character_
    )
  ) |>
  filter(!is.na(DOSGRP) & !is.na(LOTCAT))

# --- 1.5. Prepare Data for Total Column ---

# To create a "Total" column, we will create a copy of the analysis data,
# assign it a new DOSGRP level called "Total", and then bind it back to the original data.

adbs_total <- adbs_base |> mutate(DOSGRP = "Total")
adcm_total <- adcm_base |> mutate(DOSGRP = "Total")

# Combine original and total dataframes
adbs <- bind_rows(adbs_base, adbs_total)
adcm <- bind_rows(adcm_base, adcm_total) |>
  # Re-level the DOSGRP factor to ensure "Total" appears last in the output table.
  mutate(DOSGRP = fct_relevel(DOSGRP, "Total", after = Inf))

# --- 2. Build Analysis Results Data (ARD) using `cards` ---

# The ARD-building code remains the same; it will now process the "Total"
# group that we added to the input dataframes (adbs and adcm).

adcm_line <- adbs |> # Start with the defined population for robustness
  left_join(
    adcm |>
      select(USUBJID, PRIOR_SYSTRT, PRIOR_RSP, UPRIOR_THPY) |>
      slice_max(order_by = PRIOR_SYSTRT, n = 1, by = USUBJID, with_ties = FALSE), # Get latest line per patient
    by = "USUBJID"
  ) |>
  left_join(
    adcm |>
      filter(THPY == "TYROSINE KINASE THERAPY") |>
      select(USUBJID, UPRIOR_TKI) |>
      slice_max(order_by = UPRIOR_TKI, n = 1, by = USUBJID, with_ties = FALSE), # Get max TKI count per patient
    by = "USUBJID"
  )

adcm_trt <- adcm |>
  select(USUBJID, THPY, CMTRT) |>
  distinct() |> 
  inner_join(adbs |> select(USUBJID, LOTCAT, DOSGRP), by = "USUBJID")

ard_thpy <- adcm |>
  slice_tail(n = 1L, by = c(USUBJID, THPY, DOSGRP)) |>
  ard_stack_hierarchical(
    by = c(LOTCAT, DOSGRP),
    variables = THPY,
    denominator = adbs,
    id = USUBJID,
    over_variables = TRUE
  )

ard_line <- adcm_line |>
  ard_tabulate(
    by = c(LOTCAT, DOSGRP),
    variables = c(PRIOR_SYSTRT, UPRIOR_THPY, UPRIOR_TKI),
    denominator = adbs
  )

ard_trt <-  adcm_trt |>
  ard_hierarchical(
    by = c(LOTCAT, DOSGRP),
    variables = CMTRT,
    denominator = adbs,
    id = USUBJID
  )

# C) Combine all ARD objects into a single one
all_ards <- bind_ard(ard_thpy, ard_trt,ard_line, .update = TRUE)

# --- 3. Finalize and Clean Output ---

final <- all_ards |>
  filter(!is.na(variable_level)) |>
  unlist_ard_columns() |>
  select(-any_of(c("warning", "error", "fmt_fun"))) |> 
  filter(
    !(variable != "..ard_hierarchical_overall.." & stat_name == "N")
  ) |> 
  mutate(
    variable=case_when(
      variable=="..ard_hierarchical_overall.." & stat_name %in% c("n","p") ~ "Patients with Prior Systemic Cancer Therapy",
      variable=="..ard_hierarchical_overall.." & stat_name=="N" ~ NA_character_,
      TRUE ~ variable
    ),
    variable_level=case_when(
      variable_level=="TRUE" & stat_name %in% c("n","p") ~ "Patients with Prior Systemic Cancer Therapy",
      variable_level=="TRUE" & stat_name=="N" ~ NA_character_,
      TRUE ~ variable_level
    ),
    stat_name=case_when(
      stat_name == "N" & is.na(variable) & is.na(variable_level) ~ "popn",
      TRUE ~ stat_name
    ),
    DOSGRP=group2_level,
    LOTCAT=group1_level
  ) 

qc <- final |>
  mutate(
    variable=case_when(
      variable=="CMTRT" ~ "Prior TKI Therapy",
      variable=="PRIOR_SYSTRT" ~ "Prior Lines of Systemic Treatment [2]",
      variable=="THPY" ~ "Type of Therapy [1]",
      variable=="UPRIOR_THPY" ~ "Number of Unique Prior Therapies",
      variable=="UPRIOR_TKI" ~ "Number of Unique Tyrosine Kinase Inhibitor Therapies",
      TRUE ~ variable
    ),
    order=case_when(
      variable == "Patients with Prior Systemic Cancer Therapy" ~ 1,
      variable=="Prior TKI Therapy" ~ 4,
      variable=="Prior Lines of Systemic Treatment [2]" ~ 3,
      variable=="Type of Therapy [1]" ~ 2,
      variable=="Number of Unique Prior Therapies" ~ 5,
      variable=="Number of Unique Tyrosine Kinase Inhibitor Therapies" ~ 6
    ),
    stat=if_else(stat_name == "p", stat * 100, stat),
    stat = if_else(is.nan(stat), 0, stat)
  ) |> 
  select(-group1,-group1_level,-group2,-group2_level,-context,-stat_label) |> 
  arrange(order,LOTCAT,DOSGRP, variable, variable_level, stat_name) |> 
  filter(stat != "0",!is.na(DOSGRP),!is.na(LOTCAT)
  ) 


prod <- read_data_catalog(dddata$t_sf_prior_systhpy_lot_pool) |> 
  arrange(order,LOTCAT,DOSGRP, variable, variable_level, stat_name) |> 
  filter(stat != "0") |> 
  mutate(order = as.numeric(order))

diff_results <- diffdf::diffdf(base = prod ,
                       compare = qc,
                       keys = c('order','LOTCAT','DOSGRP', 'variable','variable_level','stat_name'))

print(diff_results)
