####------------------------------------------------------------------------####
# Program Name: qc_t_sf_ds_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Shilpa Kolli / sk575206
# Purpose: QC of Summary of Disposition by Line of Therapy
#(Phase 1 & 1b pooled) Display.
#
# Input:
#   - sdtmdata: [N/A]
#   - adamdata: adbs.parquet
# Output:
#   - adamdata: [N/A]
#   - dddata: [N/A]
#   - file: qc_t_sf_ds_lot_pool.lst
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

# adsl <- read_parquet(file.path(adamdata, "adds.parquet"))

adbs <- read_data_catalog(adamdata$adbs) |>
  filter(SAFFL == "Y" & !is.na(TRT01A) & !is.na(LOTCAT)) |>
  rename_with(tolower) |> convert_na_to_blanks()


adbs <- adbs |>
  mutate(dosgrp = "Total", dosgrpn = 999) |>
  bind_rows(adbs)

excluded_values <- c("NULL", "", "NA")
ard1 <- ard_stack(
  data = adbs,
  ard_categorical(variables = c(eotstt)),
  .by = c(dosgrp, lotcat),
  .overall = TRUE,
  .total_n = TRUE
) |>
  filter(variable == "eotstt", variable_level != "", stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    )
    # stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  )

ard2 <- adbs |>
  ard_stack(
    ard_categorical(variables = c(dctreas)),
    .by = c(dosgrp, lotcat),
    .overall = TRUE,
    .total_n = TRUE
  ) |>
  filter(variable == "dctreas", variable_level != "", stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    )
    # stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  )

ard3 <- ard_stack(
  data = adbs,
  ard_categorical(variables = c(eosstt)),
  .by = c(dosgrp, lotcat),
  .overall = TRUE,
  .total_n = TRUE
) |>
  filter(variable == "eosstt", variable_level != "", stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    )
    # stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  )


ard4 <- adbs |>
  ard_stack(
    ard_categorical(variables = c(dcsreas)),
    .by = c(dosgrp, lotcat),
    .overall = TRUE,
    .total_n = TRUE
  ) |>
  filter(variable == "dcsreas", variable_level != "", stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    )
    # stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  )

# --- Add Big N ---
bign <- adbs |>
  count(dosgrp, lotcat) |>
  complete(dosgrp, lotcat, fill = list(n = 0)) |>
  mutate(
    stat_name = "bigN",
    stat = map(n, ~.x),
    variable_level = map(dosgrp, ~.x),
    lotcat = map(lotcat, ~.x),
    arm = map(dosgrp, ~.x),
  ) |>
  mutate(
    stat = as.numeric(stat),
    # stat = ifelse(stat_name == "p", stat * 100, stat),
    # stat_label = ifelse(stat_name == "p", paste0(round(stat, 1), "%"), stat_label)
  ) |>
  filter(
    !(arm %in% excluded_values) &
      !(lotcat %in% excluded_values)
  ) |>
  select(arm, lotcat, stat_name, stat)

final <- bind_rows(ard1, ard2, ard3, ard4) |>
  filter(group1_level != "NULL") |>
  mutate(
    arm = group1_level,
    lotcat = group2_level,
    label = variable_level,
    variable = case_when(
      variable == "eotstt" ~ "Treatment Status",
      variable == "dctreas" ~ "Reason for Treatment Discontinuation",
      variable == "eosstt" ~ "Study Status",
      variable == "dcsreas" ~ "Reason for Study Discontinuation",
      TRUE ~ variable
    )
  ) |>
  filter(
    !(arm %in% excluded_values) &
      !(lotcat %in% excluded_values)
  ) |>
  select(arm, variable, lotcat, label, stat_name, stat) |>
  arrange(arm, lotcat)


val_df <- bind_rows(final |> unlist_ard_columns(), bign |> unlist_ard_columns()) |>
  arrange(arm, lotcat)
# val_df <- val_df |>
#   mutate(
#     stat = if_else(stat == "NaN", 0, variable),
#   )

prod_df <- read_parquet(file.path(g_paths$dddata, "t_sf_ds_lot_pool_r.parquet")) |>
  rename_with(tolower) |> select(-grp) |>
  arrange(arm, lotcat)
# prod_df <- prod_df_ |> unlist_ard_columns
diff_results <- diffdf(
  base = prod_df,
  compare = val_df,
  keys = c('arm', 'variable','lotcat','label', 'stat_name'),
  file = paste0(g_paths$qc_output,"/qc_t_sf_ds_lot_pool.lst")
)
print(diff_results)