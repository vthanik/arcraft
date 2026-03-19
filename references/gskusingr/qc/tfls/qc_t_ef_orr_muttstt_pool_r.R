####------------------------------------------------------------------------####
# Program Name: qc_t_ef_orr_muttstt_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Shilpa Kolli / sk575206
# Purpose: QC of Summary of Best Overall Response and Objective Response Rate
#          by Mutation Status
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

# --- 0. Setup and Central Definitions ---

# Load Libraries

libs <- c("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "binom", "diffdf", "arrow")
pkg_attach(libs)

# Define Factor Levels for Consistent Ordering
gistmut_levels <- c("KIT")
mutstt_levels <- c("Exon 9", "Exon 11", "Exon 13", "Exon 14", "Exon 17")

resp_labels <- c(
  "COMPLETE RESPONSE (CR)",
  "PARTIAL RESPONSE (PR)",
  "STABLE DISEASE (SD)",
  "PROGRESSIVE DISEASE (PD)",
  "NOT EVALUABLE",
  "UNKNOWN"
)
resp_aval_levels <- c("CR", "PR", "SD", "PD", "NE", "UNK")


# --- 1. Load and Filter Raw Data ---

# Load raw ADaM data and apply baseline efficacy population filter.
adbs_raw <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y") 

adeff_raw <- read_data_catalog(adamdata$adeff) |>
  filter(EFFL == "Y", PARAMCD %in% c("BOR", "ORRFL"), ACAT2 == "INVESTIGATOR")

# Define ordered treatment levels from data for table column sorting.
trt_levels <- distinct(adbs_raw, DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)
trt_levels_total <- c(trt_levels, "Total")


# --- 2. Define the Final Analysis Population ---

# Isolate mutation status from wide-format columns.
mutation_data <- adbs_raw |>
  select(USUBJID, starts_with("CTEXON"), GISTMLOC) |>
  pivot_longer(
    cols = starts_with("CTEXON"),
    names_to = "CTEXON_VAR",
    values_to = "CTEXON_FLAG"
  ) |>
    mutate(
    MUTSTT_ = case_when(
      CTEXON_VAR == "CTEXON9" & CTEXON_FLAG == "Y" ~ "Exon 9",
      CTEXON_VAR == "CTEXON11" & CTEXON_FLAG == "Y" ~ "Exon 11",
      CTEXON_VAR == "CTEXON13" & CTEXON_FLAG == "Y" ~ "Exon 13",
      CTEXON_VAR == "CTEXON14" & CTEXON_FLAG == "Y" ~ "Exon 14",
      CTEXON_VAR == "CTEXON17" & CTEXON_FLAG == "Y" ~ "Exon 17"
    ),

    MUTSTT = case_when(
      is.na(MUTSTT_) & str_detect(GISTMLOC, "EXON 9") & CTEXON_VAR == "CTEXON9" ~ "Exon 9",
      is.na(MUTSTT_) & str_detect(GISTMLOC, "EXON 11") & CTEXON_VAR == "CTEXON11" ~ "Exon 11",
      is.na(MUTSTT_) & str_detect(GISTMLOC, "EXON 13") & CTEXON_VAR == "CTEXON13" ~ "Exon 13",
      is.na(MUTSTT_) & str_detect(GISTMLOC, "EXON 14") & CTEXON_VAR == "CTEXON14" ~ "Exon 14",
      is.na(MUTSTT_) & str_detect(GISTMLOC, "EXON 17") & CTEXON_VAR == "CTEXON17" ~ "Exon 17",
      TRUE ~ MUTSTT_
      )
  ) |>
  filter(!is.na(MUTSTT)) |>
  select(USUBJID, MUTSTT) |>
  distinct()

# Create the definitive analysis population dataframe (`anl_pop`).
# This includes all subjects and their relevant subgroups.
anl_pop_base <- adbs_raw |>
  select(USUBJID, DOSGRP, GISTMUT) |>
  inner_join(mutation_data, by = "USUBJID") |>
  filter(
    !is.na(DOSGRP) &
      !is.na(GISTMUT) &
      !is.na(MUTSTT)
  )

# Add a "Total" group for aggregation and apply factor levels for sorting.
anl_pop <- bind_rows(anl_pop_base, anl_pop_base |> mutate(DOSGRP = "Total")) |>
  mutate(
    DOSGRP = factor(DOSGRP, levels = trt_levels_total),
    GISTMUT = factor(GISTMUT, levels = gistmut_levels),
    MUTSTT = factor(MUTSTT, levels = mutstt_levels)
  )


# --- Add Big N ---
Bign <- anl_pop %>%
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total), MUTSTT = factor(MUTSTT, levels = mutstt_levels)) %>% 
  count(DOSGRP, MUTSTT) %>%
  complete(DOSGRP, MUTSTT, fill = list(n = 0)) %>%
  mutate(
    stat_name = "bigN",
    stat = map(n, ~.x),
    group1 = "DOSGRP",
    group1_level = map(DOSGRP, ~.x),
    group3 = "MUTSTT",
    group3_level = map(MUTSTT, ~.x)
  ) %>%
  select(
    group1,
    group1_level,
    group3,
    group3_level,
    stat_name,
    stat
  ) 
# --- 3. Prepare Analysis-Specific Data ---

# Prepare Best Overall Response (BOR) data by joining with the analysis population.
adeff_bor <- adeff_raw |>
  filter(PARAMCD == "BOR") |>
  mutate(
    AVALC = ifelse(
      AVALC %in% c("6 <= SD < 16 weeks", "SD >= 16 weeks"),
      "SD",
      AVALC
    ),
    RESP = factor(AVALC, levels = resp_aval_levels, labels = resp_labels)
  ) |>
  select(USUBJID, RESP) |>
  inner_join(anl_pop, by = "USUBJID")

# Prepare Objective Response Rate (ORR) data by joining with the analysis population.
adeff_orr <- adeff_raw |>
  filter(PARAMCD == "ORRFL") |>
  mutate(ORRFN = if_else(AVALC == "Y", 1, 0)) |>
  select(USUBJID, ORRFN) |>
  inner_join(anl_pop, by = "USUBJID")


# --- 4. Build Analysis Results Data (ARD) using `cards` ---

ard_by_vars <- c("DOSGRP", "GISTMUT", "MUTSTT")

# Ensure each subject is counted only once per analysis group.
anl_pop_distinct <- anl_pop |>
  distinct(USUBJID, pick(all_of(ard_by_vars)), .keep_all = TRUE)

# Create ARD for Best Overall Response counts.
ard_bor <- adeff_bor |>
  distinct(USUBJID, pick(all_of(ard_by_vars)), .keep_all = TRUE) |>
  ard_hierarchical(
    by = all_of(ard_by_vars),
    variables = RESP,
    denominator = anl_pop_distinct,
    id = USUBJID
  )

# Create ARD for Objective Response Rate (n/N and percent).
ard_orr_ <- adeff_orr |>
  filter(ORRFN == 1) |>
  distinct(USUBJID, pick(all_of(ard_by_vars)), .keep_all = TRUE) |>
  ard_hierarchical(
    by = all_of(ard_by_vars),
    variables = ORRFN,
    denominator = anl_pop_distinct,
    id = USUBJID
  )

Bign_prepared <- Bign |>
  select(group1_level, group3_level, stat) |> 
  rename(bign = stat)
ard_orr <- ard_orr_ |>
  left_join(Bign_prepared, by = c("group1_level", "group3_level")) |>
  filter(bign != 0)
# Combine BOR and ORR results.
all_ards <- bind_ard(ard_bor, ard_orr, .update = TRUE)


# --- 5. Calculate Confidence Intervals (CIs) for ORR ---

# This pipe calculates the 95% CI for the ORR using the "exact" method.
# 1. Isolate the n/N statistics for the ORR analysis.
# 2. Pivot to get `n` and `N` into separate columns for calculation.
# 3. Apply `binom.confint` to each row's `n` and `N` to get lower/upper bounds.
# 4. Unnest the CI results and pivot back to the long ARD format.
ci_data <- all_ards |>
  filter(
    variable == "ORRFN" &
      stat_name %in% c("n", "N") &
      !is.na(stat)
  ) |>
  pivot_wider(
    id_cols = c(starts_with("group"), variable),
    names_from = stat_name,
    values_from = stat
  ) |>
  unnest(c(n, N), keep_empty = TRUE) |>
  mutate(
    ci = map2(
      n,
      N,
      ~ binom.confint(.x, .y, methods = "exact") |> select(lower, upper)
    )
  ) |>
  unnest(ci) |>
  pivot_longer(
    cols = c(lower, upper),
    names_to = "stat_name",
    values_to = "stat"
  ) |>
  mutate(
    stat_label = if_else(stat_name == "lower", "Lower CI", "Upper CI"),
    variable_level = "1" # Set level to match ORRFN
  )


# --- 6. Finalize ARD: Combine, Order, and Clean ---

# Bind CI statistics, unlist columns from `cards`, and filter out empty rows.
final_ard <- bind_rows(
  all_ards |> unlist_ard_columns(),
  ci_data |> unlist_ard_columns()
) |>
  filter(!is.na(variable_level)) |>
  mutate(
    # Re-apply factor levels. This is critical for correct sorting after binding and
    # pivoting operations, which can convert factors to characters.
    group1_level = factor(group1_level, levels = trt_levels_total),
    group2_level = factor(group2_level, levels = gistmut_levels),
    group3_level = factor(group3_level, levels = mutstt_levels),
    variable_level = factor(variable_level, levels = c(resp_labels, "1")),
  ) |>
  # Arrange rows into the final desired table order.
  arrange(group1_level, group2_level, group3_level, variable, variable_level) |>
  # Select final columns for a clean output.
  select(
    starts_with("group"),
    variable,
    variable_level,
    stat_name,
    stat,
    stat_label
  ) |> unlist_ard_columns()

qc <-  bind_rows(final_ard, Bign |> unlist_ard_columns()) |> filter(stat_name != "N") |>
  mutate(
    ARM = as.character(group1_level),
    mutstt = as.character(group3_level),
    label = variable_level,
    variable = case_when(
      variable == "ORRFN" ~ "Objective Response",
      variable == "RESP" ~ "Best Overall Response",
      .default = variable
    ),
    stat_name = ifelse(
      variable == "Objective Response" & stat_name == "n",
      "X",
      stat_name
    ),
    stat_name = ifelse(
      variable == "Objective Response" & stat_name == "p",
      "proportion",
      stat_name
    ),
    stat_name = ifelse(stat_name == "upper", "upperCL", stat_name),
    stat_name = ifelse(stat_name == "lower", "lowerCL", stat_name),
    label = case_when(
      variable == "Objective Response" &
        stat_name %in% c("X", "proportion") ~ "Objective Response Rate",
      variable == "Objective Response" &
        stat_name %in%
        c("lowerCL", "upperCL") ~ "95% exact Confidence Interval",
      TRUE ~ label
    ),
    stat = if_else(stat == "NaN",0,stat)
    ) |> select(ARM, variable, mutstt, stat_name, stat, label) |>
  arrange(ARM, variable, mutstt, label, stat_name)

# --- 7. Production ---

# --- Load production data and compare ---

prod <- read_parquet(file.path(g_paths$dddata,"t_ef_orr_muttstt_pool_r.parquet")) |>
  arrange(ARM, variable, mutstt, label, stat_name) 

# Compare
diff_results <- diffdf(
  prod,
  qc,
  keys = c("ARM", "variable", "mutstt", "label", "stat_name")
)
print(diff_results)