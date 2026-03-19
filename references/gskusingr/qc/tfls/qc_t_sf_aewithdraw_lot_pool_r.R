####------------------------------------------------------------------------####
# Program Name: qc_t_sf_aewithdraw_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Summary of Treatment-Emergent Adverse Event sLeading to IDRX-42 Withdrawn 
#          by System Organ Class, Preferred Term by line of therapy 
#          (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adae]
# Output:
#   - dd []
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
#-------------------------------------------------------------------------------

# --- Load Libraries ---
pkg_load("dplyr", "forcats", "stringr", "purrr", "cards", "tfrmt", "gt", 
         "admiral","arrow","diffdf")

# --- Load base data ---
adbs <- read_data_catalog(adamdata$adbs)
adbs_1 <- convert_blanks_to_na(adbs) |>
  filter(SAFFL == "Y") |>
  select(SUBJID, USUBJID, SAFFL, DOSGRP, DOSGRPN, LOTCAT) |>
  mutate(LOTCAT = if_else(is.na(LOTCAT), "Unknown LOT", LOTCAT))

bigN_dosgrp_lotcat <- adbs_1 |>
  distinct(USUBJID, DOSGRP, LOTCAT) |>
  count(LOTCAT, DOSGRP, name = "N") |> 
  mutate(
    variable="",
    variable_level="",
    stat=N,
    stat_name="popn"
  ) |> convert_blanks_to_na() |> select(-N)

# --- Load adverse event data ---
adae <- read_sas_local(adamdata$adae)
adae_1 <- convert_blanks_to_na(adae) |>
  filter(SAFFL == "Y", TRTEMFL == "Y" & 
           (AEACN=="DRUG WITHDRAWN" | AEACN2=="DRUG WITHDRAWN" |AEACN3=="DRUG WITHDRAWN")) |>
  select(USUBJID, SUBJID, AEDECOD, AESOC, AEBODSYS, AETERM) |>
  mutate(
    AESOC = if_else(!is.na(AESOC), AESOC, "Uncoded SOC"),
    AEDECOD = if_else(!is.na(AEDECOD), AEDECOD, "Uncoded PT")
  ) |>
  left_join(adbs_1 |> select(USUBJID, DOSGRP, DOSGRPN, LOTCAT), by = "USUBJID")

# --- Create ARD for treatment and overall ---
ae_ard1 <- ard_stack_hierarchical(
  data = adae_1,
  by = c("DOSGRP", "LOTCAT"),
  variables = c("AESOC", "AEDECOD"),
  statistic = ~ c("n", "p"),
  denominator = adbs_1,
  id = USUBJID,
  over_variables = TRUE,
  total_n = TRUE
)

ae_ard_overall1 <- ard_stack_hierarchical(
  data = adae_1,
  by = c("LOTCAT"),
  variables = c("AESOC", "AEDECOD"),
  statistic = ~ c("n", "p"),
  denominator = adbs_1,
  id = USUBJID,
  over_variables = TRUE
)

# --- Create total ARD ---
adae2 <- adae_1 |> mutate(DOSGRP = "Total")
adbs2 <- adbs_1 |> mutate(DOSGRP = "Total")

ae2_ard1 <- ard_stack_hierarchical(
  data = adae2,
  by = c("DOSGRP", "LOTCAT"),
  variables = c("AESOC", "AEDECOD"),
  denominator = adbs2,
  statistic = ~ c("n", "p"),
  id = USUBJID,
  over_variables = TRUE
)

ae2_ard_overall1 <- ard_stack_hierarchical(
  data = adae2,
  by = c("LOTCAT"),
  variables = c("AESOC", "AEDECOD"),
  denominator = adbs2,
  statistic = ~ c("n", "p"),
  id = USUBJID,
  over_variables = TRUE
)

# --- Combine ARDs ---
ae22_ard1 <- ae2_ard1 |>
  bind_ard(ae2_ard_overall1) |>
  filter(group1 != "AESOC")

ae2_ard1 <- ae_ard1 |>
  bind_ard(ae_ard_overall1)

ae3_ard1 <- bind_ard(ae2_ard1, ae22_ard1) |>
  rename_ard_columns() |>
  unlist_ard_columns() |>
  mutate(
    DOSGRP = ifelse(is.na(DOSGRP), "Total", DOSGRP),
    AEDECOD = ifelse(
      !is.na(..ard_hierarchical_overall..) & ..ard_hierarchical_overall.. == TRUE |
        is.na(AEDECOD) & !is.na(AESOC), "ANY EVENT", AEDECOD
    ),
    AESOC = ifelse(AEDECOD == "ANY EVENT" & is.na(AESOC), "ANY EVENT", AESOC),
    stat_name = ifelse(is.na(AEDECOD) & stat_name == "n" | context == "total_n", "bigN", stat_name)
  ) |>
  filter(!(is.na(AEDECOD) & stat_name %in% c("N", "p")))

# --- Ordering ---
ordering_AESOC1 <- ae3_ard1 |>
  filter(DOSGRP == "Total", stat_label == "n", AEDECOD == "ANY EVENT") |>
  distinct(AESOC, .keep_all = TRUE) |>
  arrange(desc(stat)) |>
  mutate(ord1 = row_number()) |>
  select(AESOC, ord1)

ordering_AEDECOD1 <- ae3_ard1 |>
  filter(DOSGRP == "Total", stat_name == "n") |>
  distinct(AESOC, AEDECOD, .keep_all = TRUE) |>
  group_by(AESOC) |>
  arrange(desc(stat)) |>
  mutate(ord2 = row_number()) |>
  select(AESOC, AEDECOD, ord2)

# --- Join with many-to-many relationship ---
ae4_ard1 <- ae3_ard1 |>
  full_join(ordering_AESOC1, by = "AESOC", relationship = "many-to-many") |>
  full_join(ordering_AEDECOD1, by = c("AESOC", "AEDECOD"), relationship = "many-to-many") |>
  select(LOTCAT, AESOC, AEDECOD, ord1, ord2, stat, stat_name, DOSGRP) |> 
  bind_rows(bigN_dosgrp_lotcat)

# --- Final QC dataset ---
qc <- ae4_ard1 |>
  distinct(.keep_all = TRUE) |>
  mutate(
    variable = AESOC,
    variable_level = AEDECOD,
    stat_name = ifelse(stat_name == "bigN", "popn", stat_name),
    variable = ifelse(variable == "ANY EVENT", "Patients with Any TEAE", variable),
    variable_level = ifelse(variable_level == "ANY EVENT", "Any event", variable_level),
    variable_level = ifelse(variable == "Patients with Any TEAE", "Patients with Any TEAE", variable_level),
    stat = if_else(stat_name == "p", stat * 100, stat)
  ) |>
  filter(stat != "0" & !is.nan(stat) & LOTCAT !="Unknown LOT") |>
  select(LOTCAT, DOSGRP, variable, variable_level, stat_name, stat) |>
  arrange(LOTCAT, DOSGRP, variable, variable_level, stat_name)

# --- Load production data and compare ---
prod <- read_parquet(file.path(g_paths$dddata, "t_sf_aewithdraw_lot_pool_r.parquet")) |>
  filter(stat != "0" & !is.nan(stat)) |>
  arrange(LOTCAT, DOSGRP, variable, variable_level, stat_name)

diffdf::diffdf(
  base = prod,
  compare = qc,
  keys = c("LOTCAT", "DOSGRP", "variable", "variable_level", "stat_name"))

