####------------------------------------------------------------------------####
# Program Name: qc_t_sf_ex_dosmod_pool_r.R
# Domino Project: 61834_300382_INTERNAL_05
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Mariam ALaverdyan/ ma584118
# Purpose: Summary of IDRX-42 Exposure and Dose Modification (Phase 1 & 1b pooled)
# Input: ADSL ADEXSUM
# Output: [N/A]
# External files called:
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# --- Source Local R Files and Functions ----
source("/mnt/code/functions/r_setup.R")
# --- Load Libraries ----
# --- 0. Load Libraries ---
# Ensure all necessary packages are loaded.
pkg_load("dplyr", "forcats", "cards", "tfrmt", "purrr", "docorator", "haven", "diffdf", "admiral",
         "xportr", "readxl", "metacore", "metatools", "gt", "arrow", "lubridate", "tidyverse", "stringr")

# --- Load Libraries ----

pkg_attach(libs)

# --- EX Analysis ----
adsl00 <- read_data_catalog(adamdata$adbs) |>
  select(USUBJID, DOSGRP, DOSGRPN, SAFFL) |>
  filter(SAFFL == "Y")
adexsum0 <- read_data_catalog(adamdata$adexsum)

#add all subjects for Relative dose intensity
rel <- adexsum0 |>
  filter(PARAM == "Relative dose intensity (%)")
rel_ALL <- merge(adsl00, rel, by = "USUBJID", all = TRUE) |>
  mutate(
    PARAM = case_when(
      is.na(PARAM) ~ "Relative dose intensity (%)",
      .default = PARAM
    )
  ) |>
  select(USUBJID, PARAM, PARAMCD, AVAL, AVALCAT1)

adexsum <- adexsum0 |>
  filter(PARAM != "Relative dose intensity (%)") |>
  bind_rows(rel_ALL)

adsl0 <- merge(adsl00, adexsum, by = "USUBJID", all = TRUE)

adslt0 <- adsl0 |>
  mutate(DOSGRP = "Total", DOSGRPN = 999)


adsl <- bind_rows(adsl0, adslt0) |>
  select(USUBJID, DOSGRP, PARAM, PARAMCD, AVAL, AVALCAT1, DOSGRPN) |>
  mutate(
    AVALCAT1 = case_when(
      AVAL > 120 ~ ">120%",
      AVAL >= 75 ~ "75-120%",
      AVAL < 75 ~ "<75%",
      is.na(AVAL) ~ "remove"
    ),
    AVALCAT1 = factor(
      AVALCAT1,
      levels = c("<75%", "75-120%", ">120%", "remove"),
      labels = c("<75%", "75-120%", ">120%", "remove"),
    )
  )


dm_ard <- ard_stack(
  data = adsl,
  .by = c(DOSGRP, PARAM),
  ard_summary(
    variables = c(AVAL),
    statistic = ~ continuous_summary_fns(c(
      "N",
      "mean",
      "sd",
      "median",
      "min",
      "max"
    ))
  ),
  ard_tabulate(variables = c(AVALCAT1)),
  #        .overall = TRUE,
  #        .total_n = TRUE
)

ard_tbl <- dm_ard |>
  filter(
    !(group2_level %in% c("Total Planned Dose", "Number of Doses Received")) &
      !(context == "tabulate" & group2_level != "Relative dose intensity (%)") &
      group2 == "PARAM" &
      !(context == "tabulate" & stat_name == "N")
  ) |>
  #reshape the data
  shuffle_card(fill_overall = "Total") |>
  # transform group-level freqs/pcts into a singular "bigN" row
  prep_big_n(vars = "DOSGRP") |>
  # consolidate vars into a single variable column
  prep_combine_vars(vars = c("AVAL", "AVALCAT1")) |>
  # coalesce categorical levels + continuous stats into a "label"
  prep_label() |>
  
  group_by(DOSGRP, stat_variable) |>
  mutate(across(
    c(variable_level, label),
    ~ ifelse(stat_name == "N", "n", .x)
  )) |>
  ungroup() |>
  unique() |>
  # sorting
  mutate(
    ord1 = fct_inorder(stat_variable) |>
      fct_relevel("AGE", after = 0) |>
      as.numeric(),
    ord2 = ifelse(label == "n", 1, 2)
  ) |>
  # relabel the variables
  mutate(
    ord_2 = case_when(
      PARAM == "Duration of Exposure, days" ~ 1,
      PARAM == "Number of Treatment Cycles Started" ~ 2,
      PARAM == "Cumulative Dose of IDRX-42 (mg)" ~ 3,
      PARAM == "Average Daily Dose (mg)" ~ 4,
      PARAM == "Relative dose intensity (%)" & stat_variable == "AVAL" ~ 5,
      PARAM == "Relative dose intensity (%)" ~ 6
    ),
    PARAM = case_when(
      ord_2 == 6 ~ "Relative Dose Intensity Categories",
      .default = PARAM
    ),
    stat = case_when(
      ord_2 == 6 & stat_name=="p"~ stat*100,
      .default = stat
    )
    # label = case_when(
    #   label == "SD" ~ "Standard Deviation",
    #   label == "Min" ~ "Min, Max",
    #   label == "Max" ~ "Min, Max",
    #   .default = label)
  ) |>
  filter(!is.na(label) & PARAM != "Total" & label != "remove") |>
  # drop variables not needed
  select(
    DOSGRP,
    PARAM,
    stat_variable,
    label,
    stat_name,
    stat,
    ord1,
    ord2,
    ord_2
  ) |>
  # remove dups (extra denoms per variable level)
  unique()

# Calculate big N
adslt0 <- adsl00 |>
  mutate(DOSGRP = "Total", DOSGRPN = 999)

adslbign <- bind_rows(adsl00, adslt0)

df_big_N <- ard_categorical(
  data = adslbign,
  variables = "DOSGRP",
  statistic = everything() ~ c("n")
) |>
  shuffle_ard() |>
  select(DOSGRP = variable_level, N = stat)

adsln <- adsl |>
  arrange(DOSGRPN) |>
  distinct(DOSGRPN, .keep_all = TRUE) |>
  select(DOSGRPN, DOSGRP)

df_big_Nn <- merge(df_big_N, adsln, by = c("DOSGRP"), all = TRUE)

qc_t_sf_ex_dosmod_pool_r <- merge(
  ard_tbl,
  df_big_Nn,
  by = c("DOSGRP"),
  all = TRUE
) |>
  mutate(column = paste0(DOSGRP, ' \n(N=', as.character(N), ')'), ) |>
  arrange(DOSGRPN, ord_2) |>
  select(-N, -DOSGRP, -DOSGRPN, LABEL = label, GROUP = PARAM)


#Getting parquet file
t_sf_ex_dosmod_pool_r <- read_parquet(file.path(g_paths$dddata, "t_sf_ex_dosmod_pool_r.parquet"))

qc_t_sf_ex_dosmod_pool_r <- qc_t_sf_ex_dosmod_pool_r |>
  arrange(ord_2, column, stat_name, LABEL) |>
  select(-ord1, -ord2, -stat_variable)
t_sf_ex_dosmod_pool_r <- t_sf_ex_dosmod_pool_r |>
  arrange(ord_2, column, stat_name, LABEL)

# Compare PRODUCTION vs QC datasets ----
# Compare the QC-generated data with the production data.
diffdf::diffdf(
  base = t_sf_ex_dosmod_pool_r,
  compare = qc_t_sf_ex_dosmod_pool_r
)
