####------------------------------ GSK Header R v1.0 ---------------------####
# Program Name:  qc_t_ef_orr_2l_pool_r.R
# Compound/Study/Reporting Effort: 300382_INTERNAL_05_ANALYSIS
#
# OS / R Version: Frozen 4.3.1
#
# Purpose:  Table 14.2.1f Summary of Best Overall Response and Objective Response Rate in 2nd Line of Therapy by Mutation Status (Phase 1 & 1b pooled)
#
# Input: n/a
# Output: qc_t_ef_orr_2l_pool_r.log, qc_t_ef_orr_2l_pool_r.lst
#
# External files called: see source and library statements below


#-----------------------------------------------------------------------------

libs <- c("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "binom", "tfrmt", "arrow", "docorator", 
          "admiral", "haven", "diffdf", "xportr", "metacore", "metatools", "tidyverse")
pkg_attach(libs)
# --- 0. Setup and Central Definitions ---

# Load Libraries
source("/mnt/code/functions/r_setup.R")
libs <- c("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "binom")
pkg_attach(libs)

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
  filter(EFFL == "Y" & LOTCATN == 2)

adeff_raw <- read_data_catalog(adamdata$adeff) |>
  filter(EFFL == "Y", PARAMCD %in% c("BOR", "ORRFL"), ACAT2 == "INVESTIGATOR")

# --- 2. Define the Final Analysis Population ---

# Isolate mutation status from wide-format columns.
mutation_data <- adbs_raw |>
  select(USUBJID, starts_with("CTEXON")) |>
  mutate(
    MUTSTT = case_when(
      CTEXON9 == "Y"  & is.na(CTEXON11) & is.na(CTEXON13) & is.na(CTEXON14) & is.na(CTEXON17) & is.na(CTEXON18) ~ "Exon 9 only",
      CTEXON11 == "Y" & is.na(CTEXON9) & is.na(CTEXON13) & is.na(CTEXON14) & is.na(CTEXON17) & is.na(CTEXON18)  ~ "Exon 11 only",
      CTEXON11 == "Y" & (CTEXON13 == "Y" | CTEXON14 == "Y") ~ "Exon 11 and Exon 13 or 14",
      CTEXON11 == "Y" & (CTEXON17 == "Y" | CTEXON18 == "Y") ~ "Exon 11 and Exon 17 or 18",
      CTEXON9 == "Y"  & (CTEXON11 == "Y" | CTEXON13 == "Y" | CTEXON14 == "Y" | CTEXON17 == "Y" | CTEXON18 == "Y") ~ "Other / Multiple",
      CTEXON13 == "Y" & (CTEXON9 == "Y" | CTEXON14 == "Y" | CTEXON17 == "Y" | CTEXON18 == "Y") ~ "Other / Multiple",
      TRUE ~ NA_character_
    )
  ) |>
  filter(!is.na(MUTSTT)) |>
  select(USUBJID, MUTSTT) |>
  distinct()

# Create the definitive analysis population dataframe (`anl_pop`).
# This includes all subjects and their relevant subgroups.
anl_pop_base <- adbs_raw |>
  select(USUBJID, LOTCAT) |>
  inner_join(mutation_data, by = "USUBJID") |>
  filter(
      !is.na(LOTCAT) &
      !is.na(MUTSTT)
  )

# Add a "Total" group for aggregation and apply factor levels for sorting.
anl_pop <- bind_rows(anl_pop_base, anl_pop_base) 

BigN <- mutation_data %>%
  count(MUTSTT) %>%
  mutate(
    stat_name = "BigN",
    stat = n,
    variable_level = "Y",
    variable = "Y",
  ) %>%
  select(
    MUTSTT,
    variable,
    variable_level,
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

ard_by_vars <- c("MUTSTT")

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
ard_orr <- adeff_orr |>
  filter(ORRFN == 1) |>
  distinct(USUBJID, pick(all_of(ard_by_vars)), .keep_all = TRUE) |>
  ard_hierarchical(
    by = all_of(ard_by_vars),
    variables = ORRFN,
    denominator = anl_pop_distinct,
    id = USUBJID,
  )

# Combine BOR and ORR results.
all_ards <- bind_ard(ard_bor, ard_orr, .update = TRUE)

CI_bigN <- BigN |>
  mutate(group1_level =as.list( MUTSTT),
        N_check = stat,
        group1 = "MUTSTT",
        variable = "ORRFN") |>
  select(group1_level,group1,N_check,variable)
  
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
  mutate( n =as.numeric(unlist(n)))|>
  full_join(CI_bigN, by = c("group1_level","group1","variable"))|>
  mutate( n = case_when ( n>0~n,
                      TRUE ~0),
      N =  N_check) |>
  unnest(c(n, N), keep_empty = TRUE)|>
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
    stat_name = if_else(stat_name == "lower", "CL", "CH"),
    variable_level = "95% exact Confidence Interval", 
    variable = "95% exact Confidence Interval",
    stat = stat * 100
  )


# --- 6. Finalize ARD: Combine, Order, and Clean ---

# Bind CI statistics, unlist columns from `cards`, and filter out empty rows.
final_ard <- bind_rows(
  all_ards |> unlist_ard_columns(),
  ci_data |> unlist_ard_columns()
) |>
  filter(!is.na(variable_level) & stat_name != "N") |>
  mutate(
    # Re-apply factor levels. This is critical for correct sorting after binding and
    # pivoting operations, which can convert factors to characters.
    MUTSTT = group1_level,
    variable_level = factor(variable_level, levels = c(resp_labels, "1")),
    variable = case_when(variable == "ORRFN" ~ "Objective Response Rate",
                         variable == "RESP" ~ "Best Overall Response",
                         TRUE ~ variable), 
    variable_level = case_when(variable == "Objective Response Rate" ~ "Objective Response Rate",
                               variable == "95% exact Confidence Interval" ~ "95% exact Confidence Interval",
                               TRUE ~ variable_level)
  ) |>
  # Arrange rows into the final desired table order.
  arrange(MUTSTT, variable, variable_level) |>
  # Select final columns for a clean output.
  select(
    MUTSTT,
    variable,
    variable_level,
    stat_name,
    stat
  )

qc_t_ef_orr_2l_pool_r <- bind_rows(final_ard,BigN) |>
  rename(MUTCAT = MUTSTT)

dummy <- data.frame(
  MUTCAT = variable <- c(rep("Exon 9 only", 16), rep("Exon 11 only", 16), rep("Exon 11 and Exon 13 or 14", 16), rep("Exon 11 and Exon 17 or 18", 16), rep("Other / Multiple", 16)),
  variable = c(rep("95% exact Confidence Interval", 2), rep("Best Overall Response", 12), rep("Objective Response Rate", 2)),
  variable_level = c(rep("95% exact Confidence Interval", 2),rep("COMPLETE RESPONSE (CR)", 2), rep("PARTIAL RESPONSE (PR)", 2), rep("STABLE DISEASE (SD)", 2), rep("PROGRESSIVE DISEASE (PD)", 2), 
                     rep("NOT EVALUABLE", 2), rep("UNKNOWN", 2), rep("Objective Response Rate", 2)),
  stat_name = c("CH","CL","n","p","n","p","n","p","n","p","n","p","n","p","n","p")
)

qc_t_ef_orr_2l_pool_r <- full_join(qc_t_ef_orr_2l_pool_r, dummy, by = c("MUTCAT","variable","variable_level","stat_name")) %>%
  mutate(
    stat = if_else(is.na(stat),0.0000000,stat),
    order = 1
  ) %>%
  rename(stat_variable = variable)  %>%
  arrange(MUTCAT, stat_variable, variable_level, stat_name)

t_ef_orr_2l_pool_r <- read_parquet(file.path(g_paths$dddata, "t_ef_orr_2l_pool_r.parquet")) %>%
  arrange(MUTCAT, stat_variable, variable_level, stat_name)

diffdf::diffdf(
  base = t_ef_orr_2l_pool_r,
  compare = qc_t_ef_orr_2l_pool_r
)