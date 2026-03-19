####------------------------------------------------------------------------####
# Program Name: qc_t_ef_dor_lot_pool_r.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4 
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: To create Table 14.2.3e  -  Summary of Duration of Response by Line of Therapy (Phase 1 & 1b pooled)
# Input: 
#   - adamdata: adbs.sas7dat, adtte.sas7dat
# Output: [N/A]
# External files called: 
#   - /mnt/code/functions/r_setup.R
# Additional Notes: Copied from internal_02
#
#-------------------------------------------------------------------------------

pkg_load("dplyr", "forcats", "cards","cardx","stringr","tidyr","arrow","diffdf","survival","tibble")


# Creating all rows for treatments and lotcat
dos_grp <- c("C120", "T200/C240", "T300/C400", "T500", "T600/C600", "C800", "C1200", "Total")

lot_cat <- c("1st-line", "2nd-line", "3rd or later-line")

adbs1 <- read_data_catalog(adamdata$adbs)  |> 
  filter(EFFL == "Y") |>
  rename_with(tolower) |>
  select(studyid,usubjid,subjid,effl,dosgrp,dosgrpn,lotcat,lotcatn)

adtte <- read_data_catalog(adamdata$adtte)  |> 
  filter(PARAMCD %in% c("DOR") & ACAT2 == "INVESTIGATOR") %>%  
  rename_with(tolower)

tte_bs <- inner_join(adbs1, adtte, by = "usubjid")

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
ard_n <- ard_tabulate(data = adbs,
                      variables = "dosgrp",
                      by="lotcat",
                      statistic = everything() ~ c("n")) %>% 
  unlist_ard_columns() %>%
  mutate(
    dosgrp = variable_level,
    group2_level = group1_level,
    variable = "studyid",
    stat_name = str_replace_all(stat_name, "n", "BigN"),
    label = if_else(stat_label == "n", NA_character_, stat_label)
  )

# Number of Responders, N 
ard_resp <- ard_tabulate(data = tte_bs1,
                         variables = "dosgrp",
                         by = "lotcat",
                         statistic = everything() ~ c("n")) %>% 
  unlist_ard_columns() %>%
  mutate(
    label = "Number of Responders, N",
    stat_name=
      case_when(stat_name == 'n' ~ 'N'),
    variable =
      case_when(variable == 'dosgrp' ~ 'Number of Responders, N'),
    group2_level = group1_level,
    dosgrp = variable_level
  )

# Number of Events, n %   
tte_bs1_e <- tte_bs1 %>%
  filter(cnsr == 0) 

ard_evt <- ard_tabulate(
  data = tte_bs1_e,
  by = c('dosgrp','lotcat'),
  variable = cnsr,
  denominator = tte_bs1,
  statistic = ~ c("n", "p")) %>%
  unlist_ard_columns() %>%
  mutate(
    label = "Number of Events, n %",
    dosgrp = group1_level,
    variable =
      case_when(variable == 'cnsr' ~ 'Number of Responders, N')
  )

# Number of Censors, n %   
tte_bs1_c <- tte_bs1 %>%
  filter(cnsr == 1) 

ard_cen <- ard_tabulate(
  data = tte_bs1_c,
  by = c('dosgrp','lotcat'),
  variable = cnsr,
  denominator = tte_bs1,
  statistic = ~ c("n", "p")) %>%
  unlist_ard_columns() %>%
  mutate(
    label = "Number of Censors, n %",
    dosgrp = group1_level,
    variable =
      case_when(variable == 'cnsr' ~ 'Number of Responders, N')
  )

# Duration of Response, month

# --Survival Fit and Quantiles 
adtte_surv <- tte_bs1 

fit_surv <- survfit(Surv(aval, cnsr==0) ~ dosgrp + lotcat, data = adtte_surv, conf.type='log-log',conf.int = 0.95)
quant_res <- quantile(fit_surv, probs = c(0.25, 0.5, 0.75))

dor_mon <- as.data.frame(quant_res) %>%
  rownames_to_column("strata") %>%
  separate(strata, into = c("dosgrp","lotcat"), sep = ", ") %>%
  pivot_longer(cols = starts_with(c("quantile", "lower", "upper")),
               names_to = "cat", values_to = "stat") %>%
  mutate(
    variable = "Duration of Response, month",
    label =
      case_when(
        cat == "quantile.25" ~ "25% Quartile",
        cat == "quantile.50" ~ "Median",
        cat == "quantile.75" ~ "75% Quartile",
        cat %in% c("lower.25","upper.25") ~ "  95% CI of 25% Quartile",
        cat %in% c("lower.50","upper.50") ~ "  95% CI of Median",
        cat %in% c("lower.75","upper.75") ~ "  95% CI of 75% Quartile",
        TRUE ~ NA_character_ 
      ),
    stat_name =
      case_when(
        cat %in% c("quantile.25","quantile.50","quantile.75") ~ "estimate",
        cat %in% c("lower.25","lower.50","lower.75") ~ "lower",
        cat %in% c("upper.25","upper.50","upper.75") ~ "upper",
        TRUE ~ NA_character_ 
      ),
    dosgrp = sub("dosgrp=", "", dosgrp),
    lotcat = sub("lotcat=", "", lotcat),
  ) %>%
  filter(!(is.na(stat)))

dor_mon <- dor_mon %>%
  mutate( 
    dosgrp = str_trim(dosgrp),
    group2_level = str_trim(lotcat)
  )


# --Event-free Rate at, % --
surv_times <- c(6, 9, 12)
surv_summary <- summary(fit_surv, times = surv_times)

# Check that summary contains data
evt_free <- data.frame(
  strata = surv_summary$strata,
  time = surv_summary$time,
  surv = surv_summary$surv,
  lower = surv_summary$lower,
  upper = surv_summary$upper
) %>%
  separate(strata, into = c("dosgrp","lotcat"), sep = ", ") %>%
  group_by(time) %>%
  pivot_longer(cols = c("surv", "lower", "upper"),
               names_to = "cat", values_to = "stat") %>%
  ungroup(time) %>%
  mutate(
    variable = "Event-free Rate at, %",
    stat_name = case_when(
      cat == "surv" ~ "estimate2",
      cat == "lower" ~ "low",
      cat == "upper" ~ "high"
    ),
    label = case_when(
      cat == "surv" ~ paste0(time,' months'),
      cat %in% c("lower","upper") ~ paste0('  95% CI at ',time,' months')
    ),
    dosgrp = sub("dosgrp=", "", dosgrp),
    lotcat = sub("lotcat=", "", lotcat),
    stat = if_else(stat_name == "estimate2", stat * 100, stat)
  ) %>%
  filter(!(is.na(stat)))

evt_free <- evt_free %>%
  mutate( 
    dosgrp = str_trim(dosgrp),
    group2_level = str_trim(lotcat)
  )

qc <- 
  bind_rows(
    select(
      ard_resp,
      dosgrp,variable, label, stat_name, stat,group2_level
    )) %>%
  bind_rows(
    select(
      ard_evt,
      dosgrp,variable, label, stat_name, stat,group2_level
    )) %>%
  bind_rows(
    select(
      ard_cen,
      dosgrp,variable, label, stat_name, stat,group2_level
    )) %>%
  bind_rows(
    select(
      dor_mon,
      dosgrp,variable, label, stat_name, stat,group2_level
    )) %>%
  bind_rows(
    select(
      evt_free,
      dosgrp,variable, label, stat_name, stat,group2_level
    )) %>%
  bind_rows(
    select(
      ard_n,
      dosgrp,variable, label, stat_name, stat,group2_level
    )) 


#Reading prod parquet file 
prod <- read_parquet(file.path(g_paths$dddata,"t_ef_dor_lot_pool_r.parquet")) %>%
  rename_with(tolower) %>%
  select(-ord) %>%
  filter(!(variable %in% c('Event-free Rate at, %', 'Duration of Response, month') & is.na(stat)))

# Compare
diffdf::diffdf(base = prod ,
                    compare = qc,
                    keys = c('dosgrp', 'group2_level', 'label', 'stat_name','stat')
#                    file = file.path(g_paths$qc_output, "qc_t_ef_dor_lot_pool_r.lst")
)

