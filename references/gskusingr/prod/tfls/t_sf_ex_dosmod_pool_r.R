####------------------------------------------------------------------------####
# Program Name: t_sf_ex_dosmod_pool.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose:
# Input:
#   - sdtmdata: dm.sas7dat, ex.sas7dat
# Output: t_sf_ex_dosmod_pool_r.RTF
# External files called:
#   - /mnt/code/functions/r_setup.R
# Additional Notes: Copied from internal_02
#
#-------------------------------------------------------------------------------

# --- Load Libraries ----
pkg_load( "dplyr", "forcats", "cards", "tfrmt", "gt", "docorator", "stringr", "tidyr", "arrow" )

adbs1 <- read_data_catalog(adamdata$adbs) |>
  filter(SAFFL == "Y") |>
  rename_with(tolower) |>
  select(usubjid, dosgrpn, dosgrp)

# adding total
adbs <- adbs1 %>%
  bind_rows(mutate(adbs1, dosgrp = 'Total', dosgrpn = 99))

adexsum2 <- read_sas_local(adamdata$adexsum) |>
  filter(
    SAFFL == "Y" &
      PARAMCD %in% c("TRTDUR", "NUMCYCLE", "CUMDOSE", "AVGDOSE", "RELDOSE")
  ) |>
  rename_with(tolower) |>
  select(usubjid, param, paramcd, paramn, aval, avalc)

adexsum_ <-
  inner_join(adbs1, adexsum2, by = c("usubjid"))

adexsum <- adexsum_ %>%
  bind_rows(mutate(adexsum_, dosgrp = 'Total', dosgrpn = 99))

# For keeping all treatments
treatment_levels <- c(
  "C120", "T200/C240", "T300/C400", "T500", "T600/C600", "C800", "C1200", "Total")

# Dataset with population count per available treatment
df_big_N <- adbs %>%
  group_by(dosgrp, dosgrpn) %>%
  summarise(N = n(), .groups = 'drop') %>%
  mutate(dummy_trt_n = row_number()) %>%
  ungroup()

# Define the custom functions for formatting and mapping values
reldose_format <- function(aval) {
  case_when(
    aval < 75 ~ "<75%",
    aval >= 75 & aval <= 120 ~ "75-120%",
    aval > 120 ~ ">120%",
    TRUE ~ NA_character_ # Handle NA cases
  )
}

reldose_category <- function(rdicat) {
  case_when(
    rdicat == "<75%" ~ 1,
    rdicat == "75-120%" ~ 2,
    rdicat == ">120%" ~ 3,
    TRUE ~ NA_integer_ # Handle NA cases
  )
}

adexsum1 <- adexsum %>%
  mutate(
    rdicat = ifelse(paramcd == "RELDOSE", reldose_format(aval), NA_character_),
    rdicatn = ifelse(
      paramcd == "RELDOSE",
      reldose_category(rdicat),
      NA_integer_
    )
  )

#---- categorical ----
reldose_levels <- c("<75%", "75-120%", ">120%")

adex_reldose <- adexsum1 %>%
  filter(paramcd == 'RELDOSE') %>%
  mutate(
    dosgrp = factor(
      dosgrp,
      levels = treatment_levels,
      labels = treatment_levels
    ),
    rdicat_dummy = factor(
      rdicat,
      levels = reldose_levels,
      labels = reldose_levels
    )
  )

ard_reldose <- ard_tabulate(
  data = adex_reldose,
  by = c('dosgrp'),
  variable = rdicat_dummy,
  denominator = adbs,
  statistic = ~ c("n", "p")
) %>%
  unlist_ard_columns() %>%
  mutate(
    GROUP = 'Relative Dose Intensity Categories',
    LABEL = variable_level,
    ord_2 = 6,
    column = group1_level
  )

#ard_continuous
adex_cat <- adexsum1 %>%
  mutate(
    dosgrp = factor(
      dosgrp,
      levels = treatment_levels,
      labels = treatment_levels
    )
  )

ard_adex_cat2 <- ard_summary(
  data = adex_cat,
  by = c('dosgrp', 'paramcd'),
  variable = aval,
  statistic = ~ continuous_summary_fns(c(
    "N",
    "mean",
    "sd",
    "median",
    "min",
    "max"
  ))
) %>%
  unlist_ard_columns() %>%
  mutate(
    GROUP = case_when(
      group2_level == 'TRTDUR' ~ 'Duration of Exposure, days',
      group2_level == 'NUMCYCLE' ~ 'Number of Treatment Cycles Started',
      group2_level == 'CUMDOSE' ~ 'Cumulative Dose of IDRX-42 (mg)',
      group2_level == 'AVGDOSE' ~ 'Average Daily Dose (mg)',
      group2_level == 'RELDOSE' ~ 'Relative dose intensity (%)',
      TRUE ~ NA_character_
    ),
    LABEL = stat_label,
    ord_2 = case_when(
      group2_level == 'TRTDUR' ~ 1,
      group2_level == 'NUMCYCLE' ~ 2,
      group2_level == 'CUMDOSE' ~ 3,
      group2_level == 'AVGDOSE' ~ 4,
      group2_level == 'RELDOSE' ~ 5,
      TRUE ~ NA_integer_
    ),
    column = group1_level
  )

#---- Prepare data for the output ----
df_odmod2 <-
  select(
    ard_adex_cat2, ord_2, GROUP, LABEL, column, stat, stat_name) %>%
  bind_rows(
    select(
      ard_reldose, ord_2, GROUP, LABEL, column, stat, stat_name)) %>%
  right_join(
    rename(select(df_big_N, -dummy_trt_n)),
    by = c('column' = 'dosgrp')) %>%
  mutate(
    stat = case_when(
      is.na(stat) ~ 0,
      .default = stat
    )
  )

df_odmod3 <- df_odmod2 %>%
  mutate(
    column = paste0(column, ' \n(N=', as.character(N), ')'),
    LABEL = case_when(LABEL == "N" ~ "n",  LABEL %in% c("Min", "Max") ~ paste0(LABEL, "."), .default = LABEL),
    stat = if_else(
      stat_name %in% c("p"),
      stat * 100,
      stat
    )
  ) %>%
  select(-N, -dosgrpn)


#---- Creating the `tfrmt` Table ----
table_tfrmt <- tfrmt(
  group = c('GROUP'),
  label = LABEL,
  param = stat_name,
  column = c(column),
  value = stat,
  sorting_cols = c(ord_2),
  
  # formatting rules - combine `n` and `p` in each cell
  body_plan = body_plan(
    frmt_structure(
      group_val = ".default", label_val = ".default", N = frmt("xxxxxx")),
    frmt_structure(
      group_val = ".default", label_val = ".default", mean = frmt("xxxxxx.x", missing = '')),
    frmt_structure(
      group_val = ".default", label_val = ".default", sd = frmt("xxxxxx.xx", missing = '')),
    frmt_structure(
      group_val = ".default", label_val = ".default", median = frmt("xxxxxx.x", missing = '')),
    frmt_structure(
      group_val = ".default", label_val = ".default", min = frmt("xxxxxx", missing = '')),
    frmt_structure(
      group_val = ".default", label_val = ".default", max = frmt("xxxxxx", missing = '')),
    frmt_structure(
      group_val = ".default", label_val = ".default",
      frmt_combine(
        "{n}{p}",
        n = frmt("xxx"),
        p = frmt_when(
          "==0" ~ "",
          "==100" ~ " (100%)",
          "<1" ~ " (<1%)",
          ">99" ~ " (>99%)",
          ">=10" ~ frmt(" (xx%)", missing = ''),
          "TRUE" ~ frmt("  (x%)", missing = '')
        )))),
  
  # remove extra columns and add span
  col_plan = col_plan(
    -starts_with(c('N'))
  ),
  
  # specify row group plan
  row_grp_plan = row_grp_plan(
    row_grp_structure(
      group_val = ".default", element_block(post_space = " ")),
    label_loc = element_row_grp_loc(location = "indented")
  )
) 

# Convert the tfrmt object to a gt object for printing.
gt <- print_to_gt(table_tfrmt, df_odmod3)

# Build the RTF using the flattened gt object.
rtf_dt <-
  rtf_table(
    gt,
    drop_columns = ord_2,
    row_noorphan_col = "ord_2"
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(LABEL = "") |>
  rtf_col_pad(starts_with(c("C", "T")),.n_spaces = 1, .side = "left") |> 
  rtf_paginate_cols(id_columns = LABEL, split_at = 5) |>
  rtf_title(
    "Table 14.1.9.1c",
    "Summary of IDRX-42 Exposure and Dose Modification (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Safety", paste("Data as of",g_config$datadate))
  ) |>
  rtf_footer("Note: Duration of exposure = date of last IDRX-42 dose - the date of first IDRX-42 dose + 1.",
             "Note: Cumulative Dose of IDRX-42 (mg) is calculated as sum of (all individual Total Dose Taken of IDRX-42)",
             "being reported in IDRX-42 Administration CRF and (IDRX-42 Dose* (End Date- Start Date+1- Missed Dose))",
             "being reported in study drug diary.",
             "Note: Average Daily Dose (mg) is calculated by Cumulative Dose of IDRX-42 (mg)/ Duration of Exposure.",
             "Note: Relative dose intensity (%) =Average Daily Dose/ Planned Daily Dose of IDRX-42."
  ) 

rtf_dt |>
  build_rtf(file = file.path(g_paths$output, "t_sf_ex_dosmod_pool_r.rtf"))


# Write out ARD to parquet file
write_parquet(df_odmod3, file.path(g_paths$dddata, "t_sf_ex_dosmod_pool_r.parquet"))

#Reading parquet file
t_sf_ex_dosmod_pool_r <- read_parquet(file.path(g_paths$dddata, "t_sf_ex_dosmod_pool_r.parquet"))