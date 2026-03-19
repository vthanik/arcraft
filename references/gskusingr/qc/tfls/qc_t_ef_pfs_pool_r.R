####------------------------------------------------------------------------####
# Program Name: qc_t_ef_pfs_pool_r.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4 
# Developer: Shilpa Kolli / sk575206
# Purpose: To create Table 14.2.3c  -  Summary of Progression-free Survival (Phase 1 & 1b pooled)  -  Efficacy Analysis Set
# Input: 
#   - adamdata: adbs.sas7dat, adtte.sas7dat
# Output: [N/A]
# External files called: 
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# --- Load Libraries ----

# --- Load Libraries ----
pkg_load("dplyr", "forcats", "cards","cardx","stringr","tidyr","arrow","diffdf","survival","tibble", "admiral", "haven", "purrr")


# Creating all rows for treatments 
dos_grp <- c("C120", "T200/C240", "T300/C400", "T500", "T600/C600", "C800", "C1200", "Total")

adbs1 <- read_data_catalog(adamdata$adbs)  |> 
  filter(EFFL == "Y") |>
  rename_with(tolower) |>
  select(studyid,usubjid,subjid,effl,dosgrp,dosgrpn)

adtte <- read_data_catalog(adamdata$adtte) |> 
  filter(PARAMCD %in% c("PFS") & ACAT2 == "INVESTIGATOR") %>%  
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


#  Big N Counts
bign <- adbs %>%
  count(dosgrp) %>%
  complete(dosgrp, fill = list(n = 0)) %>%
  mutate(
    stat_name = "bigN",
    stat = n,
    trtn = case_when(
      dosgrp == "C120" ~ 1,
      dosgrp == "T200/C240" ~ 2,
      dosgrp == "T300/C400" ~ 3,
      dosgrp == "T500" ~ 4,
      dosgrp == "T600/C600" ~ 5,
      dosgrp == "C800" ~ 6,
      dosgrp == "C1200" ~ 7,
      dosgrp == "Total" ~ 8,
    ),
    label = dosgrp,
    variable = "ARM"
  ) %>%
  arrange( trtn) %>%
  select(dosgrp, variable, stat_name, stat, label) %>% filter(dosgrp != "" )


# Number of Responders, N 
ard_resp <- ard_categorical(data = tte_bs1,
                            variables = c("paramcd"),
                            by   = c( "dosgrp"),
                            statistic = everything() ~ c("n")) %>% 
  shuffle_ard() %>%
  select(variable, dosgrp, stat,stat_name) %>%
  mutate(
    label = "Number of Responders, N",
    stat_name=
      case_when(stat_name == 'n' ~ 'N'),
    variable =
      case_when(variable == 'paramcd' ~ 'Number of Responders, N'),
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat)
  )

# Number of Events, n %   
tte_bs1_e <- tte_bs1 %>%
  filter(cnsr == 0) 

ard_evt <- ard_categorical(
  data = tte_bs1_e,
  by = c('dosgrp'),
  variable = cnsr,
  denominator = tte_bs1,
  statistic = ~ c("n", "p")) %>%
  shuffle_ard() %>%
  select(variable,dosgrp,stat,stat_name) %>%
  mutate(
    label = "Number of Events",
    variable =
      case_when(variable == 'cnsr' ~ 'Number of Events'),
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat)
  )

# Number of Censors, n %   
tte_bs1_c <- tte_bs1 %>%
  filter(cnsr == 1) 

ard_cen <- ard_categorical(
  data = tte_bs1_c,
  by = c('dosgrp'),
  variable = cnsr,
  denominator = tte_bs1,
  statistic = ~ c("n", "p")) %>%
  shuffle_ard() %>%  
  select(variable,dosgrp,stat,stat_name) %>%
  mutate(
    label = "Number of Censors",
    variable =
      case_when(variable == 'cnsr' ~ 'Number of Censors'),
    stat = as.numeric(stat),
    stat = if_else(
      stat_name == "p" & (is.na(stat) | stat == 0),
      0,
      stat)
  )

# Duration of Response, month

# --Survival Fit and Quantiles 
adtte_surv <- tte_bs1 %>%
  mutate(cnsr = ifelse(cnsr >= 1, 0, 1)) # Reverse censoring

fit_surv <- survfit(Surv(aval, cnsr) ~ dosgrp, data = adtte_surv, conf.type='log-log',conf.int = 0.95)
quant <- quantile(fit_surv, probs = c(0.25, 0.5, 0.75))

pfs_mon <- as.data.frame(quant) %>%
  rownames_to_column("strata") %>%
  separate(strata, into = c("dosgrp"), sep = ", ") %>%
  pivot_longer(cols = starts_with(c("quantile", "lower", "upper")),
               names_to = "cat", values_to = "stat") %>%
  mutate(
    variable = "PFS, month",
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
# Median Follow-Up, month

# --Survival Fit and Quantiles 

fit_surv_ <- survfit(Surv(aval, cnsr == 1) ~ dosgrp, data = tte_bs1, conf.type='log-log',conf.int = 0.95)
quant_ <- quantile(fit_surv_, probs = c(0.25, 0.5, 0.75))

med_mon <- as.data.frame(quant_) %>%
  rownames_to_column("strata") %>%
  separate(strata, into = c("dosgrp"), sep = ", ") %>%
  pivot_longer(cols = starts_with(c("quantile", "lower", "upper")),
               names_to = "cat", values_to = "stat") %>%
  mutate(
    variable = "Median Follow-Up, month",
    label =
      case_when(
        cat == "quantile.50" ~ "Median Follow-Up, month",
        cat %in% c("lower.50","upper.50") ~ "95% CI of Median",
        TRUE ~ NA_character_ 
      ),
    stat_name =
      case_when(
        cat %in% c("quantile.50") ~ "estimate",
        cat %in% c("lower.50") ~ "lower",
        cat %in% c("upper.50") ~ "upper",
        TRUE ~ NA_character_ 
      ),
    dosgrp = str_remove_all(dosgrp, "dosgrp=")
    ) %>% 
  filter(cat %in% c("quantile.50", "lower.50", "upper.50"))

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

qc <- 
  
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
      pfs_mon,
      dosgrp,variable, label, stat_name, stat
    )) %>%
  bind_rows(
    select(
      med_mon,
      dosgrp,variable, label, stat_name, stat
    )) %>%
  bind_rows(
    select(
      evt_free,
      dosgrp,variable, label, stat_name, stat
    )) %>% 
  bind_rows(
    select(
      bign,
      dosgrp,variable, stat_name, stat, label
    )) %>%
  mutate(dosgrp = str_trim(dosgrp)) %>%
         # stat = if_else(stat_name == "p", stat * 100, stat)) %>%
  select(dosgrp,variable,stat_name,stat,label) %>% arrange(dosgrp, variable, stat_name, stat)



#Reading prod file
prod <- read_parquet(file.path(g_paths$dddata,"t_ef_pfs_pool_r.parquet")) %>%
  rename_with(tolower) %>% rename(dosgrp = arm) %>% arrange(dosgrp, variable, stat_name, stat)

diffdf::diffdf(base = prod ,
               compare = qc,
               keys = c('dosgrp', 'label', 'stat_name'))
