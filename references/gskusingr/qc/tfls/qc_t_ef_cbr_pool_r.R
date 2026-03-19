####------------------------------------------------------------------------####
# Program Name: qc_t_ef_cbr_pool_r.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4 
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: To create Table 14.2.5c  -  Summary of Time to Response  by Line of Therapy (Phase 1 & 1b pooled)  -  Efficacy Analysis Set
# Input: 
#   - adamdata: adbs.sas7dat, adtte.sas7dat
# Output: [N/A]
# External files called: 
#   - /mnt/code/functions/r_setup.R
# Additional Notes: Copied from internal_02
#
#-------------------------------------------------------------------------------

# --- Load Libraries ----
pkg_load("dplyr","forcats","cards","cardx","stringr","tidyr","arrow","diffdf")

# Creating all rows for treatments and lotcat
dos_grp <- c("C120", "T200/C240", "T300/C400", "T500", "T600/C600", "C800", "C1200", "Total")

bor_cat <- c("COMPLETE RESPONSE (CR)", "PARTIAL RESPONSE (PR)", "STABLE DISEASE (SD)","PROGRESSIVE DISEASE (PD)","NOT EVALUABLE")

adbs1 <- read_data_catalog(adamdata$adbs)  |> 
  filter(EFFL == "Y") |>
  rename_with(tolower) |>
  select(studyid,usubjid,subjid,effl,dosgrp,dosgrpn)

adeff <- read_data_catalog(adamdata$adeff)  |> 
  filter(PARAMCD %in% c("CBRFL", "BOR") & ACAT2 == "INVESTIGATOR") %>%  
  rename_with(tolower)

eff_bs <- inner_join(adbs1, adeff, by = "usubjid")

# adding total 
adbs <- adbs1 %>%
  bind_rows(mutate(adbs1, dosgrp = 'Total', dosgrpn=99)) %>%
  mutate(
    dosgrp = factor(dosgrp, levels = dos_grp, labels = dos_grp)
  )

eff_bs1 <- eff_bs %>%
  bind_rows(mutate(eff_bs, dosgrp = 'Total', dosgrpn=99)) %>%
  mutate(
    dosgrp = factor(dosgrp, levels = dos_grp, labels = dos_grp)
  )

# Calculate big N
ard_n <- ard_tabulate(data = adbs,
                      variables = "dosgrp",
                      statistic = everything() ~ c("n")) %>% 
  unlist_ard_columns() %>%
  select(dosgrp=variable_level,stat,stat_name,label=stat_label) %>%
  mutate(
    stat_variable = 'Best Overall Response',
    stat_name=
      case_when(stat_name == 'n' ~ 'N')
  )

# Best Overall Response 
bor <- eff_bs1 %>%
  filter(paramcd == 'BOR') %>%
  mutate( 
    avalc=
      case_when(
        avalc == "CR" ~ "COMPLETE RESPONSE (CR)",
        avalc == "PR" ~ "PARTIAL RESPONSE (PR)",
        avalc %in% c("6 <= SD < 16 weeks", "SD >= 16 weeks", "SD") ~ "STABLE DISEASE (SD)",
        avalc == "PD" ~ "PROGRESSIVE DISEASE (PD)",
        avalc == "NE" ~ "NOT EVALUABLE",
        TRUE ~ NA_character_ 
      ),
    avalc = factor(avalc, levels = bor_cat, labels = bor_cat)
  )

ard_bor1 <- ard_tabulate(
  data = bor,
  by = c('dosgrp'),
  variable = avalc,
  denominator = adbs,
  statistic = ~ c("n", "p")
) %>%
  unlist_ard_columns() %>%
  mutate(
    stat_variable = 'Best Overall Response',
    label = variable_level,
    dosgrp = group1_level
  )

#CBR
cbr_cat <- 'Clinical Benefit Rate'

#Clinical Benefit Rate
cbr <- eff_bs1 %>% 
  filter(paramcd == "CBRFL") %>%
  mutate(CBRR = if_else(avalc == 'Y', TRUE, FALSE))

ard_cbr1 <- ard_tabulate(data = cbr %>% filter(avalc == 'Y') %>% 
                           mutate(CBR = cbr_cat, CBR = factor(CBR, levels = cbr_cat, labels = cbr_cat)),
                         by = c('dosgrp'),
                         variables = "CBR",
                         denominator = adbs,
                         statistic = everything() ~ c("n", "p")) %>%
  unlist_ard_columns() %>%
  mutate(
    stat_variable = 'Clinical Benefit Rate',
    label = variable_level,
    dosgrp = group1_level
  )

#95% exact Confidence Interval
ard_ci1 <- ard_categorical_ci(cbr,
                              by = c('dosgrp'),
                              variables = "CBRR",
                              method = "clopper-pearson",
                              conf.level = 0.95) %>%
  filter(stat_label %in% c("conf.low", "conf.high")) %>% 
  unlist_ard_columns() %>%
  mutate(
    stat_variable = '95% exact Confidence Interval, %',
    label = '95% exact Confidence Interval, %',
    stat_name=
      case_when(
        stat_name == "conf.low" ~ "CL",
        stat_name == "conf.high" ~ "CH"
      ),
    stat=round(stat*100,1),
    dosgrp = group1_level
  )

#append all datasets
qc <- 
  bind_rows(
    select(
      ard_bor1,
      dosgrp, stat_variable, label, stat_name, stat
    )) %>%
  bind_rows(
    select(
      ard_cbr1,
      dosgrp, stat_variable, label, stat_name, stat
    )) %>%
  bind_rows(
    select(
      ard_ci1,
      dosgrp, stat_variable, label, stat_name, stat
    )) %>%
  bind_rows(
    select(
      ard_n,
      dosgrp, stat_variable, label, stat_name, stat
    ))

#Reading prod parquet file 
prod <- read_parquet(file.path(g_paths$dddata, "t_ef_cbr_pool_r.parquet")) %>%
  rename_with(tolower)

# Compare
diffdf::diffdf(base = prod ,
                    compare = qc,
                    keys = c('dosgrp', 'label', 'stat_name')
#                    file = file.path(g_paths$qc_output, "qc_t_ef_cbr_pool_r.lst")
)

