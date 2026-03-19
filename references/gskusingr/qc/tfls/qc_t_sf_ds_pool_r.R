####------------------------------------------------------------------------####
# Program Name: qc_t_sf_ds_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Shilpa Kolli / sk575206
# Purpose: Perform Risk-Based Quality Control (RBQC) checks on the Summary of Disposition 
#(Phase 1 & 1b pooled) Display.
#
# Input:
#   - sdtmdata: [N/A]
#   - adamdata: adbs.parquet
# Output:
#   - adamdata: [N/A]
#   - dddata: [N/A]
#   - file: qc_t_sf_ds_pool_r.lst
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# Remove all objects from workspace
rm(list = ls())

# Load Libraries
source("/mnt/code/functions/r_setup.R")
libs <- c("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "binom", "tfrmt", "arrow", "docorator", "admiral", "haven", "diffdf")
pkg_attach(libs)

adbs <- read_data_catalog(adamdata$adbs)  |> 
  filter(SAFFL == "Y" & !is.na(TRT01A)) |>
  rename_with(tolower) |> convert_na_to_blanks()


adbs <- adbs |>
  mutate(dosgrp = "Total", dosgrpn = 999) |>
  bind_rows(adbs) 


ard1 <- ard_stack(
  data = adbs,
  ard_categorical(variables = c(eotstt)),
  .by = c(dosgrp, dosgrpn),
  .overall = TRUE,
  .total_n = TRUE
) |>
  filter(variable == "eotstt", variable_level != "", stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  )

ard2 <- adbs |>
  ard_stack(
    ard_categorical(variables = c(dctreas)),
    .by = c(dosgrp, dosgrpn),
    .overall = TRUE,
    .total_n = TRUE
  ) |>
  filter(variable == "dctreas", variable_level != "", stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  )

ard3 <- ard_stack(
  data = adbs,
  ard_categorical(variables = c(eosstt)),
  .by = c(dosgrp, dosgrpn),
  .overall = TRUE,
  .total_n = TRUE
) |>
  filter(variable == "eosstt", variable_level != "", stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  )


ard4 <- adbs |>
  ard_stack(
    ard_categorical(variables = c(dcsreas)),
    .by = c(dosgrp, dosgrpn),
    .overall = TRUE,
    .total_n = TRUE
  ) |>
  filter(variable == "dcsreas", variable_level != "", stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  )

# --- Add Big N ---
bign <- adbs |>
  count(dosgrp, dosgrpn) |>
  complete(dosgrp, fill = list(n = 0)) |>
  mutate(
    stat_name = "bigN",
    stat = map(n, ~.x),
    variable_level = map(dosgrp, ~.x),
    dosgrp = map(dosgrp, ~.x),
  ) |>
  mutate(
    stat = as.numeric(stat),
    stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  ) |>
  select(dosgrpn, dosgrp, stat_name, stat) |> arrange(dosgrpn)

final <- bind_rows(ard1, ard2, ard3, ard4) |>
  filter(group1_level != "NULL") |>
  mutate(
    dosgrpn = group2_level,
    dosgrp = group1_level,
    label = variable_level,
    variable = case_when(
      variable == "eotstt" ~ "Treatment Status",
      variable == "dctreas" ~ "Reason for Treatment Discontinuation",
      variable == "eosstt" ~ "Study Status",
      variable == "dcsreas" ~ "Reason for Study Discontinuation",
      TRUE ~ variable
    )
  ) |>
  select(dosgrpn, dosgrp, variable, label, stat_name, stat) 

val <- bind_rows(final |> unlist_ard_columns(), bign |> unlist_ard_columns()) |>
 filter(stat != 0) |> arrange(dosgrpn, dosgrp, variable, label, stat_name) |> select(-dosgrpn)

prod <- read_parquet(file.path(g_paths$dddata, "t_sf_ds_pool_r.parquet")) |>
  rename_with(tolower) |> filter(stat != 0) |> select(-grp) |> 
  arrange(dosgrp, variable, label, stat_name)

prod <- prod |> 
  mutate(
    dosgrp = as.character(dosgrp)
  )
# prod_df <- prod_df_ |> unlist_ard_columns
diff_results <- diffdf(
  prod,
  val,
  # keys = c("dosgrp", "variable", "label", "stat"),
  file = "/mnt/data/61834_300382_INTERNAL_05_ANALYSIS/misc/qc_t_sf_ds_pool_r.lst"
)
print(diff_results)