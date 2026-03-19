####------------------------------------------------------------------------####
# Program Name: qc_t_sf_dssstt_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Summary of Disease Status by Line of Therapy
#(Phase 1 & 1b pooled) .
#
# Input:
#   - sdtmdata: [N/A]
#   - adamdata: adbs.parquet
# Output:
#   - adamdata: [N/A]
#   - dddata: [N/A]
#   - file: qc_t_sf_dssstt_lot_pool_r.lst
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------
# Load Libraries

pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "binom", "tfrmt", "arrow", "docorator", "admiral", "haven", "diffdf")

# --- 0. Simulate Dummy Data ---
set.seed(123) # for reproducibility

# Define Factor Levels for Consistent Ordering
mutation_levels <- c("KIT", "PDGFRA", "MULTIPLE")
mutloc_levels <- c("Exon 11 (JM)", "Exon 9 (ECD)", "Exon 13 (ATP pocket)", "Exon 14 (ATP pocket)", "Exon 17 (A-loop)", "Other")
mutlocp_levels <- c("Other")

size_levels <- c("<2", "2.1-5", "5.1 - 10", "> 10", "Unknown")
miotcnt_levels <- c("< 5/50", "6 -10/50", "> 10/50", "Unknown")

excluded_values <- c("NULL", "", "NA")
# --- 1. Data Preparation (Mimicking SAS `dc1_` and `proc format`) ---
adbs <- read_data_catalog(adamdata$adbs) |> filter(SAFFL == "Y" & !is.na(TRT01A)) |>
  rename_with(tolower) |> convert_na_to_blanks()

bign <- adbs |>
  mutate(dosgrp = "Total", dosgrpn = 999) |>
  bind_rows(adbs)

adbs_ <- adbs |> 
  filter(saffl == "Y" & !is.na(dosgrp) & !is.na(lotcat)) |> 
  select(usubjid, subjid, saffl, dosgrpn, dosgrp, lotcat, gistmut) |> 
  arrange(usubjid, subjid)

adfa_ <- read_data_catalog(adamdata$adfa) |> rename_with(tolower) |> convert_na_to_blanks() |>
  arrange(usubjid, subjid) 


# 2. Merge (inner join equivalent to SAS `merge ... if a and b;`)
adbs_fa <- inner_join(adfa_, adbs_, by = c("usubjid", "subjid")) |> rename_with(tolower) |> convert_na_to_blanks()

adbs_fa1 <- adbs_fa |>
  filter(grepl("PDGFRA", gistmut, ignore.case = TRUE) & paramcd == "MUTLOC") |>
  mutate(
    PDGRFA1 = "Y",
    paramcd = "MUTLOCP",
    param = "Mutation Location PDGRFA"
  )

adbs_fa2<- bind_rows(adbs_fa, adbs_fa1)


# Add "Total" Group

adbs_fa3 <- adbs_fa2 |>
  mutate(
    dosgrp = "Total",
    dosgrpn = 99
  ) |> 
  bind_rows(adbs_fa2) |>
  arrange(usubjid, subjid, dosgrpn, lotcat, paramcd, avalc) 

# Creating ARDs 
ard1 <- adbs_fa3 |>
  filter(paramcd == "TIMGIST") |>
  ard_summary(
    by = c(dosgrp, lotcat),
    variables = aval,
    statistic = ~ continuous_summary_fns(c(
      "N",
      "mean",
      "sd",
      "median",
      "min",
      "max"
    ))
  ) |>
  filter(!is.na(group1)) |>
  mutate(variable = "TIMGIST", arm = group1_level, label = stat_name,  lotcat = group2_level) |>
  select (arm, variable, lotcat, stat_name, stat, label) |>
  unlist_ard_columns()

ard2 <- adbs_fa3 |>
  filter(paramcd == "TIMCMS") |>
  ard_summary(
    by = c(dosgrp, lotcat),
    variables = aval,
    statistic = ~ continuous_summary_fns(c(
      "N",
      "mean",
      "sd",
      "median",
      "min",
      "max"
    ))
  ) |>
  filter(!is.na(group1)) |>
  mutate(variable = "TIMCMS", arm = group1_level, label = stat_name,  lotcat = group2_level) |>
  select (arm, variable,  lotcat, stat_name, stat, label) |>
  unlist_ard_columns()

ard3 <- adbs_fa3 |>
  distinct(usubjid, paramcd, dosgrp, avalc, .keep_all = TRUE) |> 
  filter(paramcd == "MUTATION") |>
  mutate(avalc = factor(avalc, levels = mutation_levels)) |>
  ard_stack(
    ard_categorical(variables = c(avalc)),
    .by = c(dosgrp, lotcat),
    .overall = TRUE,
    .total_n = TRUE
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  )|>
  mutate(variable = "MUTATION", arm = group1_level, label = variable_level,  lotcat = group2_level) |>
  select (arm, variable,  lotcat, stat_name, stat, label) |>
  unlist_ard_columns()

ard4 <- adbs_fa3 |>
  distinct(usubjid, paramcd, dosgrp, avalc, .keep_all = TRUE) |> 
  filter(paramcd == "MUTLOC", gistmut == "KIT") |>
  mutate(avalc = factor(avalc, levels = mutloc_levels)) |>
  ard_stack(
    ard_categorical(variables = c(avalc)),
    .by = c(dosgrp, lotcat),
    .overall = TRUE,
    .total_n = TRUE
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  )|>
  mutate(variable = "MUTLOC", arm = group1_level, label = variable_level,  lotcat = group2_level) |>
  select (arm, variable,  lotcat, stat_name, stat, label) |>
  unlist_ard_columns()

ard5 <- adbs_fa3 |>
  distinct(usubjid, paramcd, dosgrp, avalc, .keep_all = TRUE) |> 
  filter(paramcd == "MUTLOCP") |>
  mutate(avalc = factor(avalc, levels = mutlocp_levels)) |>
  ard_stack(
    ard_categorical(variables = c(avalc)),
    .by = c(dosgrp, lotcat),
    .overall = TRUE,
    .total_n = TRUE
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  )|>
  mutate(variable = "MUTLOCP", arm = group1_level, label = variable_level,  lotcat = group2_level) |>
  select (arm, variable,  lotcat, stat_name, stat, label) |>
  unlist_ard_columns()

ard6 <- adbs_fa3 |>
  distinct(usubjid, paramcd, dosgrp, .keep_all = TRUE) |> 
  filter(paramcd == "SIZE") |>
  mutate(avalc = factor(avalc, levels = size_levels)) |>
  ard_stack(
    ard_categorical(variables = c(avalc)),
    .by = c(dosgrp, lotcat),
    .overall = TRUE,
    .total_n = TRUE
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  )|>
  mutate(variable = "SIZE", arm = group1_level, label = variable_level, lotcat = group2_level) |>
  select (arm, variable,  lotcat, stat_name, stat, label) |>
  unlist_ard_columns()

ard7 <- adbs_fa3 |>
  distinct(usubjid, paramcd, dosgrp, avalc, .keep_all = TRUE) |> 
  filter(paramcd == "MIOTCNT") |>
  mutate(avalc = factor(avalc, levels = miotcnt_levels)) |>
  ard_stack(
    ard_categorical(variables = c(avalc)),
    .by = c(dosgrp, lotcat),
    .overall = TRUE,
    .total_n = TRUE
  ) |>
  filter(!is.na(group1), stat_name != "N") |>
  mutate(
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat
    ) 
  )|>
  mutate(variable = "MIOTCNT", arm = group1_level, label = variable_level,  lotcat = group2_level) |>
  select (arm, variable,  lotcat, stat_name, stat, label) |>
  unlist_ard_columns()

final <- bind_rows(ard1, ard2, ard3, ard4, ard5, ard6, ard7) |>
  mutate(
    variable = case_when(
      variable == "TIMGIST" ~ "Time Since Date of Initial GIST Diagnosis (months)",
      variable == "TIMCMS" ~ "Time Since Date of Confirmed Metastatic and/or Surgically Unresectable GIST Diagnosis (months)",
      variable == "MUTATION" ~ "Mutation",
      variable == "MUTLOC" ~ "Location of KIT Mutation",
      variable == "MUTLOCP" ~ "Location of PDGFRA Mutation Other",
      variable == "SIZE" ~ "Size of the Primary Tumor (cm)",
      variable == "MIOTCNT" ~ "Mitotic Count of Primary Tumor",
      TRUE ~ variable
    ),
    label = case_when(
      label == "5.1 - 10" ~ "5.1-10",
      label == "> 10" ~ ">10",
      TRUE ~ label
    ),
    label = case_when(
      label == "< 5/50" ~ "<5/50",
      label == "6 -10/50" ~ "6-10/50",
      label == "> 10/50" ~ ">10/50",
      TRUE ~ label
    )
  ) |>
  filter(
    !(arm %in% excluded_values) &
      !(lotcat %in% excluded_values)
  )


# --- Add Big N ---
bign_ <- adbs %>%
  mutate(dosgrp = "Total", dosgrpn = 999) |>
  bind_rows(adbs)
bign <- bign_ |>
  count(dosgrp, lotcat) |>
  complete(dosgrp, lotcat, fill = list(n = 0)) |>
  mutate(
    stat_name = "bigN",
    stat = map(n, ~.x),
    variable_level = map(dosgrp, ~.x),
   # variable = NA,
    lotcat = map(lotcat, ~.x),
    arm = map(dosgrp, ~.x),
    label = "bigN",
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
  select(arm, label, lotcat, stat_name, stat)

prod_df <- read_parquet(file.path(g_paths$dddata, "t_sf_dssstt_lot_pool_r.parquet")) |>
  rename_with(tolower) |>
  filter(stat!=0) |> 
  select(-grp)

val_df <- bind_rows(final |> unlist_ard_columns(), bign |> unlist_ard_columns()) |>
  filter(stat!=0)

diff_results <- diffdf::diffdf(base = prod_df ,
                               compare = val_df,
                               keys = c('lotcat','arm', 'variable','stat_name','label'),
                               file = file.path(g_paths$qc_output, "chk.lst")
)
                               
print(diff_results)
