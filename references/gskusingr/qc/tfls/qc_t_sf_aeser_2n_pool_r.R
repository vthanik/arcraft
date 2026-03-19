####------------------------------------------------------------------------####
# Program Name: qc_t_sf_aeser_2n_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Shilpa Kolli / sk575206
# Purpose: Summary of Treatment-Emergent Serious Adverse Events >=2 Subjects by System Organ Class 
#          and Preferred Term (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adae]
# Output:
#   - qc/output/qc_t_sf_aeser_2n_pool_r.Rout
#
# External files called:
#
# Additional Notes: 
#
# 2026-01-02:
#   - Vignesh started as collaborator due to unavailability of programmer.
#
#-------------------------------------------------------------------------------

# --- Load Libraries ---
pkg_load("dplyr", "forcats", "stringr", "purrr", "cards", "tfrmt", "gt", "admiral","arrow","diffdf")

# Load base data
adbs <- read_data_catalog(adamdata$adbs) %>%
  filter(SAFFL == "Y") %>%
  select(SUBJID,USUBJID,SAFFL,DOSGRP,DOSGRPN)

# Dynamically create ordered Treatment Group factor levels.
trt_levels <- adbs |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)

trt_levels_total <- c(trt_levels, "Total")

# Load adverse event data
adae <- read_data_catalog(adamdata$adae) 

adae_ <- adae %>%
  filter(SAFFL == "Y", TRTEMFL == "Y", AESER == "Y") %>%
  select(USUBJID, SUBJID, AEDECOD, AESOC, AEBODSYS, AETERM) %>%
  mutate(
    AESOC = if_else(!is.na(AESOC), AESOC, "Uncoded SOC"),
    AEDECOD = if_else(!is.na(AEDECOD), AEDECOD, "Uncoded PT")
  ) %>%
  left_join(adbs %>% select(USUBJID, DOSGRP, DOSGRPN), by = "USUBJID") 

adae_total <- bind_rows(adae_, adae_ |> mutate(DOSGRP = "Total")) |> 
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total))

adbs_total <- bind_rows(adbs, adbs |> mutate(DOSGRP = "Total")) |> 
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total))

# Create an ARD that stacks hierarchical data of adverse events
# Grouping by treatment, system organ class, and preferred term
ae_ard1 <- ard_stack_hierarchical(
  data = adae_total,
  by = c(DOSGRP),
  variables = AEDECOD,
  statistic = ~ c("n", "p", "N"),
  denominator = adbs_total,
  id = USUBJID,
  over_variables = TRUE
) 

# Process and finalize the ARD (this part is also common logic)

# Create `processed_ard` by unlisting columns, converting proportions to
# percentages, and standardizing column names.
processed_ard <- ae_ard1 |>
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

filter_ard <- processed_ard |> 
  filter(DOSGRP == "Total", variable == "AEDECOD", stat_name == "n", stat >= 2) 

processed_ard_2 <- semi_join(processed_ard, filter_ard, by = c("variable_level")) |> 
  bind_rows(processed_ard |> filter(variable %in% c("DOSGRP", "..ard_hierarchical_overall..")))

# --- 5. Finalize and Format the Output Data ---

reshaped_ard <- processed_ard_2 |>
  filter(variable != "DOSGRP") |>
  mutate(
    new_variable = case_when(
      variable == "..ard_hierarchical_overall.." ~ "Patients with Any TEAE",
      .default = variable
    ),
    new_variable_level = case_when(
      variable == "..ard_hierarchical_overall.." ~ "Patients with Any TEAE",
      .default = variable_level
    )
  ) |>
  select(
    DOSGRP,
    variable = new_variable,
    variable_level = new_variable_level,
    stat_name,
    stat
  )

# Create sorting keys based on total counts for each PT.
pt_total_counts <- reshaped_ard |>
  filter(DOSGRP == "Total", stat_name == "n") |>
  select(variable_level, pt_count = stat)

# Create final main statistics ARD with sorting applied.
main_stats_ard <- reshaped_ard |>
  left_join(pt_total_counts, by = "variable_level") |>
  mutate(
    is_overall = (variable_level == "Patients with Any TEAE"),
    DOSGRP = factor(DOSGRP, levels = trt_levels_total)
  ) |>
  arrange(desc(is_overall), desc(pt_count), variable_level, DOSGRP) |>
  select(-pt_count, -is_overall)

# Create `population_counts_ard` containing the population 'N' for each group.
population_counts_ard <- processed_ard |>
  filter(variable == "DOSGRP", stat_name == "n") |>
  mutate(
    DOSGRP = variable_level,
    stat_name = "bigN"
  ) |>
  select(-variable, -variable_level)

# Create `final_ard` by combining main statistics with population counts.
final_ard <- bind_rows(main_stats_ard, population_counts_ard) |>
  mutate(across(where(is.factor), as.character)) |>
  select(DOSGRP, variable_level, stat_name, stat) |> 
  arrange(DOSGRP, variable_level) |> 
  filter(stat_name != "bigN")

# --- 6. Perform QC Comparison ---

# Read the production dataset.
prod_raw <- read_data_catalog(dddata$t_sf_aeser_2n_pool_r) |> 
  filter(stat_name != "bigN", stat_name %in% c("n", "p")) 

remove_zeros <- prod_raw |> filter(DOSGRP == "Total", stat_name == "n", stat == 0) |> 
  select(!c(DOSGRP, stat_name, stat))

prod <- anti_join(prod_raw, remove_zeros, by = join_by(variable, variable_level)) |> 
  arrange(DOSGRP, variable_level) |> 
  select(!variable)

# Compare the QC-generated data with the production data.
diffdf::diffdf(prod, final_ard)