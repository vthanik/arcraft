####------------------------------------------------------------------------####
# Program Name: t_sf_dm_pool_r.R
# Domino Project: 61834_300382_INTERNAL_05
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Pragya Tripathi/ ps209009
# Purpose: Summary of Demographic and Baseline Characteristics .
# Input: ADSL
# Output: [N/A]
# External files called:
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

pkg_load(
  "dplyr",
  "forcats",
  "cards",
  "tfrmt",
  "purrr",
  "docorator",
  "haven",
  "diffdf",
  "admiral",
  "xportr",
  "readxl",
  "metacore",
  "metatools",
  "gt",
  "arrow",
  "lubridate",
  "tidyverse",
  "stringr"
)

# --- Demo Analysis ----
adsl0 <- read_data_catalog(adamdata$adbs)

adslt0 <- adsl0 |>
  mutate(DOSGRP = "Total", DOSGRPN = 999)

adsl <- bind_rows(adsl0, adslt0) |>
  filter(SAFFL == "Y" & !is.na(LOTCAT)) |>
  select(
    USUBJID,
    DOSGRP,
    ASEX,
    AGE,
    AGEGR1,
    AETHNIC,
    ARACE,
    WEIGHTBL,
    HEIGHTBL,
    ECOGBL,
    BMIBL,
    LOTCAT,
    STUDYID,
    DOSGRPN
  ) |>
  mutate(
    AGEGR1 = factor(
      AGEGR1,
      levels = c("< 65", ">= 65"),
      labels = c("< 65", ">= 65")
    ),
    SEX = factor(ASEX, levels = c("Male", "Female")),
    ECOGBLC = as.character(ECOGBL),
    #ECOGBLC = factor(ECOGBLC, levels = c("0", "1", "2", "3", "4")),
    ECOGBLC = factor(ECOGBLC, levels = c("0", "1", "2")),
    ETHNIC = factor(
      AETHNIC,
      levels = c(
        "Hispanic or Latino",
        "Not Hispanic or Latino",
        "Not Reported",
        "Unknown"
      ),
      labels = c(
        "HISPANIC OR LATINO",
        "NOT HISPANIC OR LATINO",
        "NOT REPORTED",
        "UNKNOWN"
      )
    ),
    RACE = factor(
      ARACE,
      levels = c(
        "American Indian or Alaskan Native",
        "Asian",
        "Black or African American",
        "Native Hawaiian or Other Pacific Islander",
        "White",
        "Not Reported",
        "Unknown",
        "Multiple"
      ),
      labels = c(
        "AMERICAN INDIAN OR ALASKA NATIVE",
        "ASIAN",
        "BLACK OR AFRICAN AMERICAN",
        "NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER",
        "WHITE",
        "NOT REPORTED",
        "UNKNOWN",
        "MULTIPLE"
      )
    )
  )


dm_ard <- ard_stack(
  data = adsl,
  .by = c(DOSGRP, LOTCAT),
  ard_summary(
    variables = c(AGE),
    statistic = ~ continuous_summary_fns(c(
      "N",
      "mean",
      "sd",
      "median",
      "min",
      "max"
    ))
  ),
  ard_tabulate(variables = c(AGEGR1, SEX, ETHNIC, RACE)),
  ard_summary(
    variables = c(WEIGHTBL, HEIGHTBL, BMIBL),
    statistic = ~ continuous_summary_fns(c(
      "N",
      "mean",
      "sd",
      "median",
      "min",
      "max"
    ))
  ),
  ard_tabulate(variables = c(ECOGBLC)),
  #        .overall = TRUE,
  #        .total_n = TRUE
)

# Calculate big N

df_big_N <- ard_stack(
  data = adsl,
  .by = c(DOSGRP, LOTCAT),
  ard_tabulate(variables = c(STUDYID)),
  #.overall = TRUE,
  #.total_n = TRUE
) |>
  filter((stat_name == "N" & variable=="STUDYID"))|>
  mutate(stat_name="BigN")

dm_ard2<- bind_rows(dm_ard, df_big_N)

ard_tbl <- dm_ard2 |>
  filter(!(context == "tabulate" & stat_name == "N")) |>
  #reshape the data
  shuffle_card(fill_overall = "Total") |>
  # transform group-level freqs/pcts into a singular "bigN" row
  prep_big_n(vars = "DOSGRP") |>
  # consolidate vars into a single variable column
  prep_combine_vars(
    vars = c(
      "AGE",
      "AGEGR1",
      "SEX",
      "ETHNIC",
      "RACE",
      "WEIGHTBL",
      "HEIGHTBL",
      "BMIBL",
      "ECOGBLC"
    )
  ) |>
  # coalesce categorical levels + continuous stats into a "label"
  prep_label() |>
  
  group_by(DOSGRP, stat_variable) |>
  mutate(across(
    c(variable_level, label),
    ~ ifelse(stat_name == "N", "n", .x)
  )) |>
  ungroup() |>
  unique() |>
  # sorting
  mutate(
    ord1 = fct_inorder(stat_variable) |>
      fct_relevel("AGE", after = 0) |>
      as.numeric(),
    ord2 = ifelse(label == "n", 1, 2)
  ) |>
  # relabel the variables
  mutate(
    stat_variable = case_when(
      stat_variable == "AGE" ~ "Age (YEARS)",
      stat_variable == "AGEGR1" ~ "Age Group (YEARS)",
      stat_variable == "SEX" ~ "Sex, n(%)",
      stat_variable == "ETHNIC" ~ "Ethnicity, n(%)",
      stat_variable == "RACE" ~ "Race, n(%)",
      stat_variable == "WEIGHTBL" ~ "Body Weight (kg)",
      stat_variable == "HEIGHTBL" ~ "Height (cm)",
      stat_variable == "BMIBL" ~ "Body Mass Index (kg/m\u00B2)",
      stat_variable == "ECOGBLC" ~ "ECOG Performance Status, n(%)",
      .default = stat_variable
    ),
    label = case_when(
      #label == "SD" ~ "Standard Deviation",
      label == "Min" ~ "Min.",
      label == "Max" ~ "Max.",
      .default = label
    )
  ) |>
  filter(!is.na(label) & LOTCAT != "Total") |>
  # drop variables not needed
  select(DOSGRP, LOTCAT, stat_variable, label, stat_name, stat, ord1, ord2) |>
  # remove dups (extra denoms per variable level)
  unique()

ard_tbl1<-ard_tbl|>
  mutate(order = case_when(LOTCAT=="1st-line" & ord1<5~1,
                           LOTCAT=="1st-line" & ord1<8~2,
                           LOTCAT=="1st-line" & ord1<11~3,
                           LOTCAT=="2nd-line" & ord1<5~4,
                           LOTCAT=="2nd-line" & ord1<8~5,
                           LOTCAT=="2nd-line" & ord1<11~6,
                           LOTCAT=="3rd or later-line" & ord1<5~7,
                           LOTCAT=="3rd or later-line" & ord1<8~8,
                           LOTCAT=="3rd or later-line" & ord1<11~9,
  ))

DM_T01 <- tfrmt(
  group = c(LOTCAT, stat_variable),
  label = label,
  param = stat_name,
  value = stat,
  column = DOSGRP,
  sorting_cols = c(ord1, ord2),
  body_plan = body_plan(
    frmt_structure(group_val = ".default", label_val = ".default", frmt("xxx")),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      mean = frmt_when(">=0 | !is.na(stat)" ~ frmt("xxx.x"), "TRUE" ~ frmt(""))
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      sd = frmt_when(">=0 | !is.na(stat)" ~ frmt("xxx.xx"), "TRUE" ~ frmt(""))
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      median = frmt_when(
        ">=0 | !is.na(stat)" ~ frmt("xxx.x"),
        "TRUE" ~ frmt("")
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{n} {p}",
        n = frmt_when(
          ">=0" ~ frmt("xxx"),
          "TRUE" ~ frmt("")
        ),
        p = frmt_when(
          "==1" ~ frmt("(100%)"),
          ">=0.995" ~ frmt("(>99%)"),
          "==0" ~ frmt(""),
          "<=0.01" ~ frmt("(<1%)"),
          ">0" ~ frmt("(xx%)", transform = ~ . * 100),
          "TRUE" ~ frmt("")
        )
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      min = frmt_when(">=0 | !is.na(stat)" ~ frmt("xxx.x"), "TRUE" ~ frmt(""))
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      max = frmt_when(">=0 | !is.na(stat)" ~ frmt("xxx.x"), "TRUE" ~ frmt(""))
    )

  ),
  big_n = big_n_structure(
    param_val = "BigN",
    n_frmt = frmt("\n(N=x)"),
    by_page = TRUE
  ),
  col_plan = col_plan(C120, `T200/C240`, `T300/C400`, T500, `T600/C600`, C800, C1200, Total),
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    label_loc = element_row_grp_loc(location = "spanning")
  ),
  page_plan = page_plan(page_structure(group_val = list(LOTCAT = ".default")))
)

# --- Step 4: Use rtfbuilder to Create Final RTF Output ---
# 2. Create a new, simple gt object from the flattened data.
final_gt_obj <- print_to_gt(DM_T01, ard_tbl1)

# 3. Build the RTF using the flattened gt object.
rtf_dt <-final_gt_obj|>
  rtf_table(
    page_group_label = paste("Line of Therapy:", LOTCAT),
    row_noorphan_col = ord1,
    drop_columns = c(ord1, ord2, order)
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(label = "") |>
  rtf_paginate_cols(id_columns = label, split_at = 5) |>
  rtf_title(
    "Table 14.1.4e",
    "Summary of Demographic and Baseline Characteristics by Line of Therapy (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(
      paste("Protocol: IDRX-42-001"),
      "Page _PAGEOF_"
    ),
    hfrow(
      paste("Population: Safety"),
      paste("Data as of", g_config$datadate)
    )
  )

rtf_dt |>
  build_rtf(file = file.path(g_paths$output,"t_sf_dm_lot_pool_r.rtf"))

#saving final dataset for validation in parquet format
write_parquet(ard_tbl1, file.path(file.path(g_paths$dddata, "t_sf_dm_lot_pool_r.parquet")))
#Getting parquet file
t_sf_dm_lot_pool_r <- read_parquet(file.path(g_paths$dddata, "t_sf_dm_lot_pool_r.parquet"))
