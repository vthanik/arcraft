####------------------------------------------------------------------------####
# Program Name: qc_t_ef_ttr_lot_pool_r
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4 
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: To create Table 14.2.5c  -  Summary of Time to Response  by Line of Therapy (Phase 1 & 1b pooled)  -  Efficacy Analysis Set
# Input: 
#   - adamdata: adbs.sas7dat, adtte.sas7dat
# Output: [N/A]
# External files called: 
#   - /mnt/code/functions/r_setup.R
# Additional Notes: copy from internal_02
#
#-------------------------------------------------------------------------------

# --- Load Libraries ----
pkg_load("dplyr", "forcats", "cards","cardx","stringr","tidyr","arrow","diffdf")

# Creating all rows for treatments and lotcat
dos_grp <- c("C120", "T200/C240", "T300/C400", "T500", "T600/C600", "C800", "C1200", "Total")

lot_cat <- c("1st-line", "2nd-line", "3rd or later-line")

adbs1 <- read_sas_local(adamdata$adbs)  |> 
  filter(EFFL == "Y") |>
  rename_with(tolower) |>
  select(studyid,usubjid,subjid,effl,dosgrp,dosgrpn,lotcat,lotcatn)

adtte1 <- read_sas_local(adamdata$adtte)  |> 
  filter(PARAMCD %in% c("TTR") & ACAT2 == "INVESTIGATOR") %>%  
  rename_with(tolower)

tte_bs <- inner_join(adbs1, adtte1, by = "usubjid")

# adding total 
adbs <- adbs1 %>%
  bind_rows(mutate(adbs1, dosgrp = 'Total', dosgrpn=99)) %>%
  mutate(
    lotcat = factor(lotcat, levels = lot_cat, labels = lot_cat),
    dosgrp = factor(dosgrp, levels = dos_grp, labels = dos_grp)
  )

tte_bs1 <- tte_bs %>%
  bind_rows(mutate(tte_bs, dosgrp = 'Total', dosgrpn=99)) %>%
  mutate(
    lotcat = factor(lotcat, levels = lot_cat, labels = lot_cat),
    dosgrp = factor(dosgrp, levels = dos_grp, labels = dos_grp)
  )

# Calculate big N
ard_n <- ard_tabulate(
  data = adbs,
  variables = "dosgrp",
  by="lotcat",
  statistic = everything() ~ c("n")) %>% 
  unlist_ard_columns() %>%
  select(dosgrp=variable_level,stat,lotcat=group1_level,stat_name,label=stat_label,) %>%
  mutate(
    stat_name = str_replace_all(stat_name, "n", "BigN"),
    stat_variable = "bignn"
  )

#ard_continuous - Time to response
ard_tte <- ard_summary(
  data = tte_bs1,
  by = c('dosgrp','lotcat','paramcd'),
  variable = aval,
  statistic = ~ continuous_summary_fns(c("N", "mean", "sd", "median", "min","max"))) %>%
  unlist_ard_columns() %>%
  mutate(
    stat_variable=
      case_when(
        group3_level == 'TTR' ~ 'Time to Response, month'
      ),
    label = case_when( stat_label == "N" ~ "n", 
                       stat_label == "Min" ~ "Min.",
                       stat_label == "Max" ~ "Max.",
                       TRUE ~ stat_label ),
    dosgrp = group1_level,
    lotcat = group2_level
  )

#---- Prepare data for the output ----
qc <- 
  select(
    ard_tte,
    dosgrp, lotcat, stat_variable, label, stat_name, stat
  ) %>%
  bind_rows(
    select(ard_n, 
           dosgrp, lotcat, stat_variable, label, stat_name, stat))

#Reading prod parquet file 
prod <- read_parquet(file.path(g_paths$dddata, "t_ef_ttr_lot_pool_r.parquet")) %>%
  rename_with(tolower) %>%
  select(-order)

# Compare
qc_result <- diffdf(base = prod ,
                    compare = qc,
                    keys = c('dosgrp','lotcat','stat_name'),
                    file = file.path(g_paths$qc_output, "qc_t_ef_ttr_lot_pool_r.lst")
)

print(qc_result)