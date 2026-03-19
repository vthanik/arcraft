####------------------------------------------------------------------------####
# Program Name: qc_t_sf_dth_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Shilpa Kolli / sk575206
# Purpose: Perform Risk-Based Quality Control (RBQC) checks on Summary of Death (Phase 1 & 1b pooled) Display.
#
# Input:
#   - sdtmdata: [N/A]
#   - adamdata: adbs.parquet
# Output:
#   - adamdata: [N/A]
#   - dddata: [N/A]
#   - file: qc_t_sf_dth_pool.lst
#
# External files called:
#
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# Load Libraries

pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "binom", "tfrmt", "arrow", "docorator", "admiral", "haven", "diffdf")


# Define Factor Levels for Consistent Ordering
dosgrp_levels <- c("C120", "T200/C240", "T300/C400", "T500", "T600/C600", "C800", "C1200", "Total")
lot_levels <- c("1st-line", "2nd-line", "3rd or later-line")
dthcaus_levels <- c("Primary Disease Progression", "Adverse Event", "Other", "Unknown")

excluded_values <- c("NULL", "", "NA")

adbs <- read_data_catalog(adamdata$adbs) |> filter(SAFFL == "Y" & !is.na(TRT01A)) |>
  rename_with(tolower) |> convert_na_to_blanks()


adbs <- adbs |>
  mutate(dosgrp = "Total", dosgrpn = 999) |>
  bind_rows(adbs)

ard1 <- adbs |>
  filter(dthfl == "Y" ) |>
  mutate(dosgrp = factor(dosgrp, levels = dosgrp_levels)) |>
  ard_categorical(
    by = c(dosgrp),
    variables = dthfl,
    denominator = adbs,
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  ) |>
  mutate(variable = "Patient Deaths on Study, n(%)", variable_level = "Patient Deaths on Study, n(%)") |> 
  unlist_ard_columns()

ard2 <- adbs |>
  filter(dthfl == "Y" & !is.na(dthcaus)) |>
  ard_categorical(
    by = c(dosgrp),
    variables = dthcaus,
    denominator = adbs,
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  ) |>
  mutate(variable = "Primary Cause of Death") |>
  unlist_ard_columns()

ard3 <- adbs |>
  filter(dthfl == "Y", dth30tfl == "Y" ) |>
  mutate(dosgrp = factor(dosgrp, levels = dosgrp_levels)) |>
  ard_categorical(
    by = c(dosgrp),
    variables = dth30tfl,
    denominator = adbs,
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  ) |>
  mutate(variable = "Patient Deaths within 30 Days of Last IDRX-42 Dose, n(%)", variable_level = "Patient Deaths within 30 Days of Last IDRX-42 Dose, n(%)") |>
  unlist_ard_columns()

ard4 <- adbs |>
  filter(dthfl == "Y", dth30tfl == "Y", !is.na(dthcaus) ) |>
  ard_categorical(
    by = c(dosgrp),
    variables = dthcaus,
    denominator = adbs,
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  ) |>
  mutate(variable = "Primary Cause of Death within 30 Days") |> 
  unlist_ard_columns()

ard5 <- adbs |>
  filter(dthfl == "Y", dtha30fl == "Y" ) |>
  mutate(dosgrp = factor(dosgrp, levels = dosgrp_levels)) |>
  ard_categorical(
    by = c(dosgrp),
    variables = dtha30fl,
    denominator = adbs,
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  ) |>
  mutate(variable = "Patient Deaths after 30 Days of Last IDRX-42 Dose, n(%)", variable_level = "Patient Deaths after 30 Days of Last IDRX-42 Dose, n(%)") |> 
  unlist_ard_columns()


ard6 <- adbs |>
  filter(dthfl == "Y", dtha30fl == "Y", !is.na(dthcaus) ) |>
  ard_categorical(
    by = c(dosgrp),
    variables = dthcaus,
    denominator = adbs,
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  ) |>
  mutate(variable = "Primary Cause of Death after 30 Days") |> 
  unlist_ard_columns()


final <- bind_rows(ard1, ard2, ard3, ard4, ard5, ard6) |>
  filter(group1_level != "NULL") |>
  mutate(
    arm = group1_level,
    label = variable_level,
  ) |>
  filter( !(variable %in% c("Primary Cause of Death", "Primary Cause of Death within 30 Days", "Primary Cause of Death after 30 Days") & stat == 0)) |>
  filter(
    !(arm %in% excluded_values)
  ) |>
  select(arm, variable, label, stat_name, stat)

# --- Add Big N ---

bign <- adbs |>
  count(dosgrp) |>
  complete(dosgrp, fill = list(n = 0)) |>
  mutate(
    stat_name = "bigN",
    stat = map(n, ~.x),
    variable_level = map(dosgrp, ~.x),
    arm = map(dosgrp, ~.x),
  ) |>
  mutate(
    stat = as.numeric(stat),
    # stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  ) |>
  filter(
    !(arm %in% excluded_values)
    ) |>
  select(arm, stat_name, stat)


val_df <- bind_rows(final |> unlist_ard_columns(), bign |> unlist_ard_columns()) |>
  arrange(arm, label)

prod_df <- read_parquet(file.path(g_paths$dddata, "t_sf_dth_pool_r.parquet")) |> 
  rename_with(tolower) |> mutate(variable = trimws(variable)) |>  
  arrange(arm, label)


diffdf(
  base = prod_df,
  compare = val_df)

