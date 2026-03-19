####------------------------------------------------------------------------####
# Program Name: t_ef_orr_4l_excl_pool_r.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: To create Table 14.2.1.1e  -  Table 14.2.1h Summary of Best Overall Response and Objective Response Rate in 
#                Subjects with 4th Line or Later Therapy Excluding Prior Ripretinib and Ph1b Cohort 4 (Phase 1 & 1b pooled)
# Input:
#   - adamdata: adbs.sas7dat, adeff.sas7dat
# Output: [N/A]
# External files called:
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

source("/mnt/code/functions/r_setup.R")

# --- Load Libraries ----
pkg_load("dplyr","forcats","cards","cardx","tfrmt","gt","docorator","stringr","tidyr","tidyverse","arrow")

response <- function(avalc) {
  case_when(
    avalc == "CR" ~ "COMPLETE RESPONSE (CR)",
    avalc == "PR" ~ "PARTIAL RESPONSE (PR)",
    avalc %in% c("6 <= SD < 16 weeks", "SD >= 16 weeks", "SD") ~ "STABLE DISEASE (SD)",
    avalc == "PD" ~ "PROGRESSIVE DISEASE (PD)",
    avalc == "NE" ~ "NOT EVALUABLE",
    avalc == "UNK" ~ "UNKNOWN",
    TRUE ~ NA_character_ # Default case for unmatched values
  )
}

responsen <- function(avalc) {
  case_when(
    avalc == "CR" ~ 1,
    avalc == "PR" ~ 2,
    avalc %in% c("6 <= SD < 16 weeks", "SD >= 16 weeks", "SD") ~ 3,
    avalc == "PD" ~ 4,
    avalc == "NE" ~ 5,
    avalc == "UNK" ~ 6,
    TRUE ~ NA_integer_ # Handle NA cases
  )
}

adbs1 <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y", LINETHPY >= 4, COHORT == "COHORT 4", PHASE == "PHASE 1B EXPLORATORY COHORTS") |>
  rename_with(tolower) |>
  select(studyid, usubjid, subjid, effl, dosgrp, dosgrpn)

adcm1 <- read_sas_local(adamdata$adcm) |>
  filter(
    CMCAT == "PRIOR CANCER THERAPY" &
      str_detect(CMTRT, regex("RIPRETINIB", ignore_case = TRUE))
  ) |>
  rename_with(tolower) |>
  select(usubjid)

adeff1 <- read_sas_local(adamdata$adeff) |>
  filter(PARAMCD %in% c("BOR", "ORRFL") & ACAT2 == "INVESTIGATOR") %>%
  rename_with(tolower)

adcm <- unique(adcm1[('usubjid')]) #unique records

ads1 <- adbs1 %>%
  anti_join(adcm, by = "usubjid") 

# Filter data based on conditions
adeff <- adeff1 %>%
  mutate(
    resp = ifelse(paramcd == "BOR", response(avalc), NA_character_),
    respn = ifelse(paramcd == "BOR", responsen(avalc), NA_integer_)
  )

main <- ads1 %>%
  left_join(adeff, by = "usubjid")

# For keeping all treatments
treatment_levels <- c(
  "C120",
  "T200/C240",
  "T300/C400",
  "T500",
  "T600/C600",
  "C800",
  "C1200",
  "Total"
)

# adding total
ads2 <- ads1 %>%
  bind_rows(mutate(ads1, dosgrp = 'Total', dosgrpn = 99)) %>%
  mutate(
    dosgrp = factor(
      dosgrp,
      levels = treatment_levels,
      labels = treatment_levels
    )
  )

main_both <- main %>%
  bind_rows(mutate(main, dosgrp = 'Total', dosgrpn = 99)) %>%
  mutate(
    dosgrp = factor(
      dosgrp,
      levels = treatment_levels,
      labels = treatment_levels
    )
  )

# Calculate big N
df_big_N <- ard_tabulate(
  data = ads2,
  variables = "dosgrp",
  statistic = everything() ~ c("n")) %>%
  unlist_ard_columns() %>%
  mutate(
    stat_name = "bigN"
  ) %>%
  select(dosgrp = variable_level, stat, stat_name)

#----BOR categorical ----
bor_levels <- c(
  "COMPLETE RESPONSE (CR)",
  "PARTIAL RESPONSE (PR)",
  "STABLE DISEASE (SD)",
  "PROGRESSIVE DISEASE (PD)",
  "NOT EVALUABLE",
  "UNKNOWN"
)
orr_text <- 'Objective Response Rate'

adeff_bor <- main_both %>%
  filter(paramcd == 'BOR') %>%
  mutate(
    bor_dummy = factor(resp, levels = bor_levels, labels = bor_levels)
  )

ard_bor <- ard_tabulate(
  data = adeff_bor,
  by = c('dosgrp'),
  variable = bor_dummy,
  denominator = ads2,
  statistic = ~ c("n", "p")
) %>%
  unlist_ard_columns() %>%
  mutate(
    GROUP = 'Best Overall Response',
    LABEL = variable_level,
    ord_2 = 1,
    dosgrp = group1_level
  )

# End of BOR

#Objective Response Rate
preorr <- main_both %>%
  filter(paramcd == "ORRFL") %>%
  mutate(CRPRCI = if_else(avalc == 'Y', TRUE, FALSE))

orr <- ard_tabulate(
  data = preorr %>%
    filter(avalc == 'Y') %>%
    mutate(
      ORR = orr_text,
      ORR = factor(ORR, levels = orr_text, labels = orr_text)
    ),
  by = c('dosgrp'),
  variables = "ORR",
  denominator = ads2,
  statistic = everything() ~ c("n", "p")
) %>%
  unlist_ard_columns() %>%
  mutate(
    GROUP = 'Objective Response Rate',
    LABEL = variable_level,
    ord_2 = 2,
    dosgrp = group1_level
  )

#95% exact Confidence Interval
orr_ci <- ard_categorical_ci(
  preorr,
  by = c('dosgrp'),
  variables = "CRPRCI",
  method = "clopper-pearson",
  conf.level = 0.95
) %>%
  filter(stat_label %in% c("conf.low", "conf.high")) %>% #keep only stat we needed
  unlist_ard_columns() %>%
  mutate(
    GROUP = '95% exact Confidence Interval, %',
    LABEL = '95% exact Confidence Interval, %',
    ord_2 = 3,
    dosgrp = group1_level
  )

#---- Prepare data for the output ----
df_borci <-
  select(
    ard_bor, ord_2, dosgrp, GROUP, LABEL, stat, stat_name) %>%
  bind_rows(
    select(
      orr, ord_2, dosgrp, GROUP, LABEL, stat, stat_name)) %>%
  bind_rows(
    select(
      orr_ci, ord_2, dosgrp, GROUP, LABEL, stat, stat_name)) %>%
  bind_rows(
    select(
      df_big_N, dosgrp, stat, stat_name))

df_borci_ <- df_borci %>%
  mutate(
    stat = case_when(
      is.na(stat) ~ 0,
      .default = stat
    )
  )

df_borci1 <- df_borci_ %>%
  mutate(
    stat = if_else(
      stat_name %in% c("p", "conf.low", "conf.high"),
      stat * 100,
      stat
    )
  ) %>%
  filter(
    !((stat == 0.0) & stat_name %in% c("conf.low", "conf.high"))
  ) 

t_format <- tfrmt(
  group = GROUP,
  label = LABEL,
  param = stat_name,
  column = dosgrp,
  value = stat,
#  sorting_cols = ord_2,
  
  #Specify value formatting
  body_plan = body_plan(
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{n}{p}",
        n = frmt("xxx"),
        p = frmt_when(
          "==0" ~ "",
          "==100" ~ " (100%)",
          "<1" ~ " (<1%)",
          ">99" ~ " (>99%)",
          TRUE ~ frmt(" (x%)", missing = '')
        )
      )
    ),
    
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "({conf.low},{conf.high})",
        conf.low = frmt_when("==100" ~ "100", "==0" ~ "", "TRUE" ~ frmt("x.x")),
        conf.high = frmt_when("==100" ~ "100", "==0" ~ "", "TRUE" ~ frmt("x.x"))
      )
    )
  ),
  
  big_n = big_n_structure(
    param_val = "bigN",
    n_frmt = frmt("\n(N=x)")
  ),
  
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    row_grp_structure(
      group_val = list(GROUP = "Objective Response Rate"),
      element_block(post_space = NULL)
    ),
    row_grp_structure(
      group_val = list(GROUP = "95% exact Confidence Interval"),
      element_block(post_space = NULL)
    )
  ),
  
  # remove extra columns and add span
  col_plan = col_plan(
    -starts_with(c('N'))
  )
) 

gt <- print_to_gt(t_format, df_borci1)

#Build the RTF using the flattened gt object.
rtf_dt <-
  rtf_table(
    gt,
    row_noorphan_col = ord_2,
    drop_columns = ord_2
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.15in") |>
  rtf_col_label(LABEL = "") |>
  rtf_col_pad(starts_with(c("C", "T")),.n_spaces = 2, .side = "left") |> 
  rtf_paginate_cols(id_columns = LABEL, split_at = 5) |>
  rtf_title(
    "Table 14.2.1h",
    "Summary of Best Overall Response and Objective Response Rate in Subjects with 4th Line or Later Therapy",
    "Excluding Prior Ripretinib and Ph1b Cohort 4 (Phase 1b pooled)"
  ) |>
  rtf_header(
    hfrow(
      paste("Protocol:", g_config$studyid), "Page _PAGEOF_"
    ),
    hfrow(
      "Population: Efficacy", paste("Data as of",g_config$datadate)
    )
  ) |>
  rtf_footer("Note: Objective response rate (ORR) is defined as the proportion of patients achieving",
             "confirmed CR or confirmed PR."
  ) 

rtf_dt |>
  build_rtf(file = file.path(g_paths$output, "t_ef_orr_4l_excl_pool_r.rtf"))


# Write out ARD to parquet file
write_parquet(df_borci,file.path(g_paths$dddata, "t_ef_orr_4l_excl_pool_r.parquet"))

#Reading parquet file
t_ef_orr_4l_excl_pool_r <- read_parquet(file.path(g_paths$dddata,"t_ef_orr_4l_excl_pool_r.parquet"))