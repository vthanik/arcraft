####------------------------------------------------------------------------####
# Program Name: t_ef_orr_uprtki2_pool_r.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: To create Table 14.2.1.1.2.2c  - Summary of Objective Response Rates in Subjects with Prior Ripretinib
#               (Phase 1 & 1b pooled) (Both confirmed responses and unconfirmed responses awaiting confirmation are included) - Efficacy Analysis Set
# Input:
#   - adamdata: adbs.sas7dat, adeff.sas7dat, adcm.sas7dat
# Output: [N/A]
# External files called:
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

source("/mnt/code/functions/r_setup.R")

# --- Load Libraries ----
pkg_load("dplyr","forcats","cards","cardx","tfrmt","gt","docorator","stringr","tidyr","arrow")

adbs1 <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y") |>
  rename_with(tolower) |>
  select(studyid, usubjid, subjid, effl, dosgrp, dosgrpn)

# subjects with BORU and CR/PR and INVESTIGATOR
adef <- read_data_catalog(adamdata$adeff) |>
  rename_with(tolower)

boru_orr <- adef %>%
  filter(
    paramcd == "BORU",
    avalc %in% c("CR", "PR"),
    acat2 == "INVESTIGATOR"
  ) %>%
  distinct(usubjid)

# left join adbs to boru_orr, create ORRFL and Y/N flag
bor_resp <- adbs1 %>%
  select(usubjid) %>%
  left_join(boru_orr %>% mutate(.drv = TRUE), by = "usubjid") %>%
  mutate(paramcd = "ORRFL", avalc = if_else(!is.na(.drv) & .drv, "Y", "N")) %>%
  select(-.drv)

adcm1 <- read_data_catalog(adamdata$adcm)

# subjects with prior meds matching RIPRETINIB
orr_cm <- adcm1 %>%
  filter(
    CMCAT == "PRIOR CANCER THERAPY",
    str_detect(CMTRT, regex("RIPRETINIB", ignore_case = TRUE))
  ) %>%
  distinct(USUBJID) %>%
  rename_with(tolower)

# subjects in adbs who are in tki
base <- adbs1 %>%
  inner_join(orr_cm, by = "usubjid")

main <- inner_join(base, bor_resp, by = "usubjid")

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

#categories
orr_text <- 'Objective Response Rate'

# adding total
adbs <- base %>%
  bind_rows(mutate(base, dosgrp = 'Total', dosgrpn = 99)) %>%
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
  data = adbs,
  variables = "dosgrp",
  statistic = everything() ~ c("n")
) %>%
  unlist_ard_columns() %>%
  select(column = variable_level, N = stat)

#Objective Response Rate
preorr <- main_both %>%
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
  denominator = adbs,
  statistic = everything() ~ c("n", "p")
) %>%
  unlist_ard_columns() %>%
  mutate(
    GROUP = 'Objective Response Rate',
    LABEL = variable_level,
    ord_2 = 1,
    column = group1_level,
    stat = as.numeric(stat)
  )

#95% exact Confidence Interval
orr_ci <- ard_categorical_ci(
  preorr,
  by = c('dosgrp'),
  variables = "CRPRCI",
  method = "clopper-pearson",
  conf.level = 0.95
) %>%
  unlist_ard_columns() %>%
  filter(stat_label %in% c("conf.low", "conf.high")) %>% #keep only stat we needed
  mutate(
    GROUP = '95% exact Confidence Interval, %',
    LABEL = '95% exact Confidence Interval, %',
    ord_2 = 2,
    column = group1_level,
    stat = as.numeric(stat)
  )

#---- Prepare data for the output ----
df_borci <-
  bind_rows(
    select(
      orr, ord_2, GROUP, LABEL, column, stat, stat_name)) %>%
  bind_rows(
    select(
      orr_ci, ord_2, GROUP, LABEL, column, stat, stat_name)) %>%
  right_join(df_big_N, by = c('column'))

df_borci_ <- df_borci %>%
  mutate(
    stat = case_when( is.na(stat) & !(stat_name %in% c("conf.low", "conf.high")) ~ 0, .default = stat )
  )

df_borci1 <- df_borci_ %>%
  mutate(
    column = paste0(column, ' \n(N=', as.character(N), ')'),
    stat = if_else(
      stat_name %in% c("p", "conf.low", "conf.high"),
      stat * 100,
      stat)) %>%
  filter(!((N == 0) & stat_name %in% c("conf.low", "conf.high"))) %>% #removing zero rows
  select(-N)

t_format <- tfrmt(
  group = c('GROUP'),
  label = LABEL,
  param = stat_name,
  column = c(column),
  value = stat,
  sorting_cols = c(ord_2),
  
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
        conf.low = frmt_when("==0" ~ "0", "TRUE" ~ frmt("x.x"), missing = '-'),
        conf.high = frmt_when("==0" ~ "0", "TRUE" ~ frmt("x.x"), missing = '-')
      )
    )
  ),
  
  # remove extra columns and add span
  col_plan = col_plan(
    -starts_with(c('ord_', 'N'))
  )
) 

#Creation of rtf output
# Create the gt object for previewing
gt <- print_to_gt(t_format, df_borci1)

#Build the RTF using the flattened gt object.
rtf_dt <-
  rtf_table(
    gt,
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.18in") |>
  rtf_col_label(LABEL = "") |>
  rtf_col_pad(starts_with(c("C", "T")),.n_spaces = 2, .side = "left") |> 
  rtf_paginate_cols(id_columns = LABEL, split_at = 5) |>
  rtf_title(
    "Table 14.2.1.1.2.2c",
    "Summary of Objective Response Rate in Subjects with Prior Ripretinib (Phase 1 & 1b pooled)",
    "(Both confirmed responses and unconfirmed responses awaiting confirmation are included)"
  ) |>
  rtf_header(
    hfrow(
      paste("Protocol:", g_config$studyid), "Page _PAGEOF_"
    ),
    hfrow(
      "Population: Efficacy", paste("Data as of",g_config$datadate)
    )
  ) 

rtf_dt |>
  build_rtf(file = file.path(g_paths$output, "t_ef_orr_uprtki2_pool_r.rtf"))


# Write out ARD to parquet file
write_parquet(df_borci,file.path(g_paths$dddata, "t_ef_orr_uprtki2_pool_r.parquet"))

#Reading parquet file
t_ef_orr_uprtki2_pool_r <- read_parquet(file.path(g_paths$dddata,"t_ef_orr_uprtki2_pool_r.parquet"))