####------------------------------------------------------------------------####
# Program Name: qc_t_sf_dm_pool_r.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4 
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: To create Table 14.1.4e  -   Summary of Demographic and Baseline Characteristics by Line of Therapy (Phase 1 & 1b pooled)
# Input: 
#   - adamdata: adbs.sas7dat
# Output: [N/A]
# External files called: 
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# --- Load Libraries ----
pkg_load("dplyr","forcats","cards","cardx","stringr","tidyr","arrow","diffdf")

# Creating all rows for treatments and lotcat
dos_grp <- c("C120", "T200/C240", "T300/C400", "T500", "T600/C600", "C800", "C1200", "Total")

#---- categorical ----
age_grp <- c("< 65", ">= 65")

sex_grp <- c("M", "F")

ethin <- c("HISPANIC OR LATINO", "NOT HISPANIC OR LATINO", "NOT REPORTED", "UNKNOWN")

races <- c("AMERICAN INDIAN OR ALASKA NATIVE", "ASIAN", "BLACK OR AFRICAN AMERICAN", "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER",
           "WHITE", "NOT REPORTED", "UNKNOWN", "MULTIPLE")

ecog_n <- c("0","1","2")

adbs1 <- read_data_catalog(adamdata$adbs)  |> 
  filter(SAFFL == "Y") |>
  rename_with(tolower) 

# adding total 
adbs <- adbs1 %>%
  bind_rows(mutate(adbs1, dosgrp = 'Total', dosgrpn=99)) %>%
  mutate(
    dosgrp = factor(dosgrp, levels = dos_grp, labels = dos_grp),
    agegr1 = factor(agegr1, levels = age_grp, labels = age_grp),
    sex = factor(sex, levels = sex_grp, labels = sex_grp),
    ethnic = factor(ethnic, levels = ethin, labels = ethin),
    race = factor(race, levels = races, labels = races),
    ecogbl = factor(ecogbl, levels = ecog_n, labels = ecog_n)    
  )

# Calculate big N
ard_n <- ard_tabulate(data = adbs,
                      variables = "dosgrp",
                      statistic = everything() ~ c("n")) %>% 
  unlist_ard_columns() %>%
  select(dosgrp=variable_level,stat,stat_label,stat_name) %>%
  mutate(
    variable = "DOSGRP",
    variable_level = dosgrp,
    stat_name = str_replace_all(stat_name, "n", "BigN"),
    ord1 = 10
  )

#removing missing values 
adbs_ <- adbs %>% filter(!is.na(dosgrp))

#continuous
ard_cont_ <- ard_summary(
  data = adbs_,
  by = c('dosgrp'),
  variable = c('age','weightbl','heightbl','bmibl'),
  statistic = ~ continuous_summary_fns(c("N", "mean", "sd", "median", "min","max"))) %>%
  unlist_ard_columns() %>%
  mutate(
    ord1 = case_when(
      variable == 'age' ~ 1,
      variable == 'weightbl' ~ 6,
      variable == 'heightbl' ~ 7,
      variable == 'bmibl' ~ 8,
      TRUE ~ NA_integer_ 
    ),
    variable=
      case_when(
        variable == 'age' ~ 'Age (YEARS)',
        variable == 'weightbl' ~ 'Body Weight (kg)',
        variable == 'heightbl' ~ 'Height (cm)',
        variable == 'bmibl' ~ 'Body Mass Index (kg/m²)',
        TRUE ~ NA_character_ 
      ),
    variable_level = case_when( stat_label == "N" ~ "n", 
                       stat_label == "Min" ~ "Min.",
                       stat_label == "Max" ~ "Max.",
                       TRUE ~ stat_label ),
    dosgrp = group1_level
  )

#categorical
ard_cat_ <- ard_tabulate(
  data = adbs,
  by = c('dosgrp'),
  variable = c('agegr1','sex','ethnic','race','ecogbl'),
  denominator = adbs,
  statistic = ~ c("n", "p")) %>%
  unlist_ard_columns() %>%
  mutate(
    ord1 = 
      case_when(
        variable == 'agegr1' ~ 2,
        variable == 'sex' ~ 3,
        variable == 'ethnic' ~ 4,
        variable == 'race' ~ 5,
        variable == 'ecogbl' ~ 9,
        TRUE ~ NA_integer_ 
      ),
    variable=
      case_when(
        variable == 'agegr1' ~ 'Age Group (YEARS)',
        variable == 'sex' ~ 'Sex, n(%)',
        variable == 'ethnic' ~ 'Ethnicity, n(%)',
        variable == 'race' ~ 'Race, n(%)',
        variable == 'ecogbl' ~ 'ECOG Performance Status, n(%)',
        TRUE ~ NA_character_ 
      ),
    variable_level = 
      case_when( variable_level == "M" ~ "Male",
                 variable_level == "F" ~ "Female",
                 TRUE ~ variable_level ),
    dosgrp = group1_level
  )

qc <- 
  select(
    ard_cont_,
    dosgrp, variable, variable_level, stat_name, stat,ord1
  ) %>%
  bind_rows(
    select(
      ard_cat_,
      dosgrp, variable, variable_level, stat_name, stat,ord1
    )
  ) %>%
  bind_rows(
    select(
      ard_n,
      dosgrp, variable, variable_level, stat_name, stat,ord1
    )
  ) 

#Reading prod parquet file 
prod <- read_parquet(file.path(g_paths$dddata, "t_sf_dm_pool_r.parquet")) %>%
  select(-ord2) %>%
  rename_with(tolower) 

# Compare
diffdf::diffdf(base = prod ,
               compare = qc,
               keys = c('dosgrp','variable','stat_name','variable_level','ord1')
#               file = file.path(g_paths$qc_output, "qc_t_sf_dm_pool_r.lst")
)
