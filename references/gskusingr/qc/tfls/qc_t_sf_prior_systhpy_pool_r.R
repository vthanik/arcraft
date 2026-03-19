####------------------------------------------------------------------------####
# Program Name: qc_t_sf_prior_systhpy_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: QC of Summary of Prior Systemic Cancer Therapy (Phase 1 & 1b pooled)
#
# Input:
#   - adamdata: [adbs, adcm]
# Output:
#   - dddata: []
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- Load libraries ---
# Added purrr for elegant iteration, though often loaded with dplyr/tidyverse
pkg_load("dplyr", "forcats", "stringr", "purrr", "cards")

# --- 1. Data Loading and Preparation ---

# Load ADaM datasets, filtering for the Safety-Analysable Population
adbs <- read_data_catalog(adamdata$adbs) |> filter(SAFFL == "Y")
adbs_raw <- adbs |> 
  select(USUBJID, DOSGRP) |>
  distinct()
  
adcm_raw <- read_data_catalog(adamdata$adcm) |>
  filter(SAFFL == "Y", CMCAT == "PRIOR CANCER THERAPY")

# Define ordered treatment group levels from ADBS
# This ensures consistency in all tables and plots
trt_levels <- adbs |>
  arrange(DOSGRPN) |>
  distinct(DOSGRP) |>
  pull(DOSGRP)

# Pre-process ADCM data by joining with ADBS and creating analysis variables
adcm <- adcm_raw |>
  # Join with ADBS to get treatment group and other baseline characteristics
  left_join(
    select(adbs, USUBJID, DOSGRP, GISTMUTN, GISTMUT, LOTCATN, LOTCAT),
    by = "USUBJID"
  ) |>
  # Create and re-level factors for analysis
  mutate(
    DOSGRP = fct_relevel(DOSGRP, trt_levels),
    
    # Therapy Type category
    THPY = fct_relevel(
      CMSCAT,
      "CHEMOTHERAPY",
      "TYROSINE KINASE THERAPY",
      "OTHER"
    ),
    
    # Prior Line of Systemic Therapy category
    PRIOR_SYSTRT = fct_relevel(
      CMLINE,
      "FIRST LINE",
      "SECOND LINE",
      "THIRD LINE",
      "FOURTH LINE[JC1]",
      "> FOURTH LINE"
    ),
    
    # Best Response to Prior Therapy
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
    
    # Consolidate less frequent treatments into "OTHER"
    CMTRT = if_else(
      str_detect(CMTRT, "OTHER:|PAZOPANIB|SORAFENIB"),
      "OTHER",
      CMTRT
    ),
    
    # Bin the number of unique prior therapies
    UPRIOR_THPY = case_when(
      CMUPRTH %in% 1:3 ~ as.character(CMUPRTH),
      CMUPRTH >= 4 ~ "4 or more",
      .default = NA_character_
    ),
    
    # Bin the number of unique prior TKI therapies
    UPRIOR_TKI = case_when(
      CMUNTK %in% 1:3 ~ as.character(CMUNTK),
      CMUNTK >= 4 ~ "4 or more",
      .default = NA_character_
    )
  ) |>
  # Filter out any records that couldn't be joined to a treatment group
  filter(!is.na(DOSGRP)) # |> 
  #select(USUBJID,DOSGRP,CMSCAT,CMLINE,CMBSTRSP,CMTRT,CMUPRTH,CMUNTK)


adcm_line <- adbs_raw |> # Start with the defined population for robustness
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
  inner_join(adbs_raw |> select(USUBJID, DOSGRP), by = "USUBJID")

# --- 2. Build Analysis Results Data (ARD) using `cards` ---

# A) Special case: Therapy Type (THPY), which uses ard_stack_hierarchical
ard_thpy <- adcm |>
  slice_tail(n = 1L, by = c(USUBJID, THPY)) |>
  ard_stack_hierarchical(
    by = DOSGRP,
    variables = THPY,
    denominator = adbs,
    id = USUBJID,
    over_variables = TRUE
  )

ard_line <- adcm_line |>
  ard_tabulate(
    by = DOSGRP,
    variables = c(PRIOR_SYSTRT, UPRIOR_THPY, UPRIOR_TKI),
    denominator = adbs
  )


# B) Process all other variables using a functional approach with `purrr::map`
#vars_to_summarize <- c("CMTRT")

ard_trt <-  adcm_trt |>
  ard_hierarchical(
    by = DOSGRP,
    variables = CMTRT,
    denominator = adbs,
    id = USUBJID
  )

# C) Combine all ARD objects into a single one
all_ards <- bind_ard(ard_thpy, ard_trt,ard_line, .update = TRUE)

# --- 3. Finalize and Clean Output ---

final <- all_ards |>
  filter(!is.na(variable_level), !is.na(group1)) |>
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
    DOSGRP=group1_level
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
    stat=if_else(stat_name == "p", stat * 100, stat)
  ) |> 
  select(-group1,-group1_level,-context,-stat_label) |> 
  arrange(order,DOSGRP, variable, variable_level, stat_name) |> 
  filter(stat != "0"
         ) 
  

prod <- read_data_catalog(dddata$t_sf_prior_systhpy_pool) |> 
  arrange(order,DOSGRP, variable, variable_level, stat_name) |> 
  filter(stat != "0" ,
         DOSGRP!="Total"
         ) |> 
  mutate(order = as.numeric(order))

diff_results <- diffdf(base = prod ,
                       compare = qc,
                       keys = c('order','DOSGRP', 'variable','variable_level','stat_name'))

print(diff_results)
