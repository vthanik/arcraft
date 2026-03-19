####------------------------------------------------------------------------####
# Program Name: qc_t_ef_ttr_pool_r.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4 
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: To create Table 14.2.5c  -  Summary of Time to Response (Phase 1 & 1b pooled)  -  Efficacy Analysis Set
# Input: 
#   - adamdata: adbs.sas7dat, adtte.sas7dat
# Output: [N/A]
# External files called: 
#   - /mnt/code/functions/r_setup.R
# Additional Notes: Copied from internal_02
#
#-------------------------------------------------------------------------------

#source("/mnt/code/functions/r_setup.R") 

# --- Load Libraries ----
pkg_load("dplyr","forcats","cards","cardx","stringr","tidyr","arrow","diffdf")

adbs1 <- read_data_catalog(adamdata$adbs)  |> 
  filter(EFFL == "Y") |>
  rename_with(tolower) |>
  select(studyid,usubjid,subjid,effl,dosgrp,dosgrpn)

adtte1 <- read_data_catalog(adamdata$adtte)  |> 
  filter(PARAMCD %in% c("TTR") & ACAT2 == "INVESTIGATOR") %>%  
  rename_with(tolower)

tte_bs <- inner_join(adbs1, adtte1, by = "usubjid")

# adding total 
adbs <- adbs1 %>%
  bind_rows(mutate(adbs1, dosgrp = 'Total', dosgrpn=99))

tte_bs1 <- tte_bs %>%
  bind_rows(mutate(tte_bs, dosgrp = 'Total', dosgrpn=99))

# Calculate big N
ard_n <- ard_tabulate(
  data = adbs,
  variables = "dosgrp",
  statistic = everything() ~ c("n")
) %>%
  unlist_ard_columns() %>%
  mutate(
    dosgrp = variable_level,
    stat_variable = case_when(variable == 'dosgrp' ~ 'DOSGRP'),
    label = stat_label,
    stat_name = str_replace_all(stat_name, "n", "bigN"),
    stat_variable = if_else(variable_level == "Total", "..ard_total_n..",stat_variable)
  ) 

#ard_continuous - Time to response
ard_tte <- ard_summary(
  data = tte_bs1,
  by = c('dosgrp','paramcd'),
  variable = aval,
  statistic = ~ continuous_summary_fns(c("N", "mean", "sd", "median", "min","max"))) %>%
  unlist_ard_columns() %>%
  mutate(
    stat_variable = case_when(
      group2_level == 'TTR' ~ 'Time to Response, month'
    ),
    label = case_when( stat_label == "N" ~ "n", 
                       stat_label == "Min" ~ "Min.",
                       stat_label == "Max" ~ "Max.",
                       TRUE ~ stat_label ),
    dosgrp = group1_level
  )

#---- Prepare data for the output ----
qc <- 
  select(
    ard_tte,
    dosgrp, stat_variable, label, stat_name, stat
  ) %>%
  bind_rows(
    select(
      ard_n,
      dosgrp, stat_variable, label, stat_name, stat
    )
  ) 

#Reading prod parquet file 
prod <- read_parquet(file.path(g_paths$dddata, "t_ef_ttr_pool_r.parquet")) %>%
  rename_with(tolower)


# Compare
diffdf::diffdf(base = prod ,
                    compare = qc,
                    keys = c('dosgrp', 'stat_name')
  #                  file = file.path(g_paths$qc_output, "qc_t_ef_ttr_pool_r.lst")
)

