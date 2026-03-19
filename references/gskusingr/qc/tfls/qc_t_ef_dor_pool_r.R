####------------------------------------------------------------------------####
# Program Name: qc_t_ef_dor_pool_r.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4 
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: To create Table 14.2.3c  -  Summary of Duration of Response (Phase 1 & 1b pooled)  -  Efficacy Analysis Set
# Input: 
#   - adamdata: adbs.sas7dat, adtte.sas7dat
# Output: [N/A]
# External files called: 
#   - /mnt/code/functions/r_setup.R
# Additional Notes: Copied from internal_02
#
#-------------------------------------------------------------------------------

# --- Load Libraries ----
pkg_load("dplyr","forcats","cards","cardx","stringr","tidyr","arrow","diffdf","survival","tibble")

# Creating all rows for treatments and lotcat
dos_grp <- c("C120", "T200/C240", "T300/C400", "T500", "T600/C600", "C800", "C1200", "Total")

adbs1 <- read_data_catalog(adamdata$adbs)  |> 
  filter(EFFL == "Y") |>
  rename_with(tolower) |>
  select(studyid,usubjid,subjid,effl,dosgrp,dosgrpn)

adtte <- read_data_catalog(adamdata$adtte)  |> 
  filter(PARAMCD %in% c("DOR") & ACAT2 == "INVESTIGATOR") %>%  
  rename_with(tolower)

tte_bs <- inner_join(adbs1, adtte, by = "usubjid")

# adding total 
adbs <- adbs1 %>%
  bind_rows(mutate(adbs1, dosgrp = 'Total', dosgrpn=99)) %>%
  mutate(
    dosgrp = factor(dosgrp, levels = dos_grp, labels = dos_grp)
  )

tte_bs1 <- tte_bs %>%
  bind_rows(mutate(tte_bs, dosgrp = 'Total', dosgrpn=99)) %>%
  mutate(
    dosgrp = factor(dosgrp, levels = dos_grp, labels = dos_grp)
  )

# Calculate big N
ard_n <- ard_tabulate(data = adbs,
                      variables = "dosgrp",
                      statistic = everything() ~ c("n")) %>% 
  unlist_ard_columns() %>%
  select(variable,dosgrp=variable_level,stat,stat_name) %>%
  mutate(
    label = dosgrp,
    stat_name=
      case_when(stat_name == 'n' ~ 'bigN'),
    variable=
      case_when(variable == 'dosgrp' ~ 'DOSGRP')    
  )


# Number of Responders, N 
ard_resp <- ard_tabulate(data = tte_bs1,
                         variables = "dosgrp",
                         statistic = everything() ~ c("n")) %>% 
  unlist_ard_columns() %>%
  select(variable,dosgrp=variable_level,stat,stat_name) %>%
  mutate(
    label = "Number of Responders, N",
    stat_name=
      case_when(stat_name == 'n' ~ 'N'),
    variable =
      case_when(variable == 'dosgrp' ~ 'Number of Responders, N')
  )

# Number of Events, n %   
tte_bs1_e <- tte_bs1 %>%
  filter(cnsr == 0) 

ard_evt <- ard_tabulate(
  data = tte_bs1_e,
  by = c('dosgrp'),
  variable = cnsr,
  denominator = tte_bs1,
  statistic = ~ c("n", "p")) %>%
  unlist_ard_columns() %>%
  select(variable,dosgrp=group1_level,stat,stat_name) %>%
  mutate(
    label = "Number of Events, n %",
    variable =
      case_when(variable == 'cnsr' ~ 'Number of Responders, N')
  )

# Number of Censors, n %   
tte_bs1_c <- tte_bs1 %>%
  filter(cnsr == 1) 

ard_cen <- ard_tabulate(
  data = tte_bs1_c,
  by = c('dosgrp'),
  variable = cnsr,
  denominator = tte_bs1,
  statistic = ~ c("n", "p")) %>%
  unlist_ard_columns() %>%
  select(variable,dosgrp=group1_level,stat,stat_name) %>%
  mutate(
    label = "Number of Censors, n %",
    variable =
      case_when(variable == 'cnsr' ~ 'Number of Responders, N')
  )

# Duration of Response, month

# --Survival Fit and Quantiles 
adtte_surv <- tte_bs1 %>%
  mutate(cnsr = ifelse(cnsr >= 1, 0, 1)) # Reverse censoring

fit_surv <- survfit(Surv(aval, cnsr) ~ dosgrp, data = adtte_surv, conf.type='log-log',conf.int = 0.95)
quant <- quantile(fit_surv, probs = c(0.25, 0.5, 0.75))

dor_mon <- as.data.frame(quant) %>%
  rownames_to_column("strata") %>%
  separate(strata, into = c("dosgrp"), sep = ", ") %>%
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
    dosgrp = str_remove_all(dosgrp, "dosgrp=") 
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
  separate(strata, into = c("dosgrp"), sep = ", ") %>%
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
    dosgrp = str_remove_all(dosgrp, "dosgrp="),
    stat = if_else(stat_name == "estimate2", stat * 100, stat)
  )

qc1 <- 
  bind_rows(
    select(
      ard_n,
      dosgrp,variable, label, stat_name, stat
    )) %>%
  bind_rows(
    select(
      ard_resp,
      dosgrp,variable, label, stat_name, stat
    )) %>%
  bind_rows(
    select(
      ard_evt,
      dosgrp,variable, label, stat_name, stat
    )) %>%
  bind_rows(
    select(
      ard_cen,
      dosgrp,variable, label, stat_name, stat
    )) %>%
  bind_rows(
    select(
      dor_mon,
      dosgrp,variable, label, stat_name, stat
    )) %>%
  bind_rows(
    select(
      evt_free,
      dosgrp,variable, label, stat_name, stat
    )) 

qc <- qc1 %>%
  filter(!(variable %in% c('Duration of Response, month') & is.na(stat)))


#Reading prod file
prod <- read_parquet(file.path(g_paths$dddata,"t_ef_dor_pool_r.parquet")) %>%
  rename_with(tolower) %>%
  filter(!(variable %in% c('Duration of Response, month') & is.na(stat)))


# Compare
diffdf::diffdf(base = prod ,
                    compare = qc,
                    keys = c('dosgrp', 'label', 'stat_name')
#                    file = file.path(g_paths$qc_output, "qc_t_ef_dor_pool_r.lst")
)
