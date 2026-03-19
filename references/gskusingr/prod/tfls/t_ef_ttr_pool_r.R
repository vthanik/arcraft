
####------------------------------------------------------------------------####
# Program Name: t_ef_ttr_pool_r.R
# Domino Project: 61834_300382_INTERNAL_05
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Mariam ALaverdyan/ ma584118
# Purpose: Summary of Time to Response – Efficacy Analysis Set (Phase 1 & 1b pooled)
# Input: ADSL ADTTE
# Output: [N/A]
# External files called:
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# --- Source Local R Files and Functions ----
source("/mnt/code/functions/r_setup.R")
# --- Load Libraries ----

libs <- c(
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
  "arrow",
  "gt",
  "lubridate",
  "tidyverse",
  "stringr"
)
# --- Load Libraries ----

pkg_attach(libs)

# --- Demo Analysis ----

adtte0 <- read_sas_local(adamdata$adtte) |>
  filter(EFFL == "Y" & PARAMCD == "TTR") |>
  select(USUBJID, AVAL)

adsl <- read_data_catalog(adamdata$adbs)|>
  filter(EFFL == "Y") |>
  select(USUBJID, DOSGRP)

adtte <- merge(adtte0, adsl, by = "USUBJID", all = TRUE)

dm_ard <- ard_stack(
  data = adtte,
  .by = DOSGRP,
  ard_summary(
    variables = c(AVAL),
    statistic = ~ continuous_summary_fns(c(
      "N",
      "mean",
      "sd",
      "median",
      "min",
      "max"
    ))
  ),
  .overall = TRUE,
  .total_n = TRUE
)

ard_tbl <- dm_ard |>
  #reshape the data
  shuffle_card(fill_overall = "Total") |>
  # transform group-level freqs/pcts into a singular "bigN" row
  prep_big_n(vars = "DOSGRP") |>
  # consolidate vars into a single variable column
  prep_combine_vars(vars = c("AVAL")) |>
  # coalesce categorical levels + continuous stats into a "label"
  prep_label() |>
  # filter (context=="summary")|>
  group_by(DOSGRP, stat_variable) |>
  # mutate(across(c(variable_level, label), ~ ifelse(stat_name=="N", "n", .x))) |>
  ungroup() |>
  unique() |>
  
  # relabel the variables
  mutate(
    stat_variable = case_when(
      stat_variable == "AVAL" ~ "Time to Response, month",
      .default = stat_variable
    ),
    label = case_when(
      stat_label == "N" ~ "n",
      .default = stat_label
    ),
    label = case_when(
      #label == "SD" ~ "Standard Deviation",
      label == "Min" ~ "Min.",
      label == "Max" ~ "Max.",
      .default = label
    )
  ) |>
  # drop variables not needed
  select(DOSGRP, stat_variable, label, stat_name, stat) |>
  # remove dups (extra denoms per variable level)
  unique()


DM_T01 <- tfrmt(
  group = stat_variable,
  label = label,
  param = stat_name,
  value = stat,
  column = DOSGRP,
  #sorting_cols = c(ord1, ord2),
  body_plan = body_plan(
    frmt_structure(group_val = ".default", label_val = ".default", frmt("xxxxxxx")),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      mean = frmt_when(">=0 | !is.na(stat)" ~ frmt("xxxxxxx.x"), "TRUE" ~ frmt(""))
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      sd = frmt_when(">=0 | !is.na(stat)" ~ frmt("xxxxxxx.xx"), "TRUE" ~ frmt(""))
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      median = frmt_when(
        ">=0 | !is.na(stat)" ~ frmt("xxxxxxx.x"),
        "TRUE" ~ frmt("")
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine("{min}, {max}", min = frmt("xxxxxx"), max = frmt("xxxxxx"))
    )
  ),
  big_n = big_n_structure(param_val = "bigN", n_frmt = frmt("\n(N=xx)")),
  col_plan = col_plan(
    C120,
    `T200/C240`,
    `T300/C400`,
    T500,
    `T600/C600`,
    C800,
    C1200,
    Total
  ),
  col_style_plan = col_style_plan(
    col_style_structure(col = everything(), align = "left")
  ),
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " "))
  )
) #|>
#   print_to_gt(ard_tbl)


# --- Step 4: Use rtfbuilder to Create Final RTF Output ---
# 2. Create a new, simple gt object from the flattened data.
final_gt_obj <- print_to_gt(DM_T01, ard_tbl) |>
  cols_label(label = "") # Ensure label column header is blank

# 3. Build the RTF using the flattened gt object.
rtf_dt <-
  rtf_table(
    final_gt_obj,
    # drop_columns = "ord1",
    # row_noorphan_col = "ord1",
    # page_group_col = "ord1",
    # page_group_label = paste("Group:", ord1)
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(label = "") |>
  rtf_paginate_cols(id_columns = label, split_at = 5) |>
  rtf_title(
    "Table 14.2.5c",
    "Summary of Time to Response (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(
      paste("Protocol: IDRX-42-001"),
      "Page _PAGEOF_"
    ),
    hfrow(
      paste("Population: Efficacy"),
      paste("Data as of", g_config$datadate)
    )
  )|>
  rtf_footer ("Note: Time to Response (TTR), reported in patients achieving a confirmed CR or confirmed PR, is defined as the time from the date of first IDRX-42 dose to the date of first CR or PR.",
              .align = "left")

rtf_dt |>
  build_rtf(file = file.path(g_paths$output,"t_ef_ttr_pool_r.rtf"))

# DM_T01
# footnote1_1 <- file.path('/mnt', 'code', 'prod', 'tfls', 't_ef_ttr_pool_r.R')
# footnote1_2 <- format(Sys.time(), "%d%b%Y  %H:%M") |> toupper()
# DM_T01 |>
#   as_docorator(
#     display_name = "t_ef_ttr_pool_r",
#     display_loc = output_path,
#     header = fancyhead(
#       fancyrow(
#         left = "Protocol: IDRX-42-001",
#         center = NA,
#         right = doc_pagenum()
#       ),
#       fancyrow(
#         left = "Population: Efficacy",
#         center = NA,
#         right = "Data as of 15SEP2025"
#       ),
#       fancyrow(left = NA, center = "Table 14.2.5c", right = NA),
#       fancyrow(
#         left = NA,
#         center = "Summary of Time to Response (Phase 1 & 1b pooled)",
#         right = NA
#       )
#     ),
#     footer = fancyfoot(
#       fancyrow(
#         left = "Note: Time to Response (TTR), reported in patients achieving a confirmed CR or confirmed PR, is defined as the time from the",
#         center = NA,
#         right = NA
#       ),
#       fancyrow(
#         left = "date of first IDRX-42 dose to the date of first CR or PR.",
#         center = NA,
#         right = NA
#       ),
#       fancyrow(
#         left = footnote1_1,
#         center = footnote1_2,
#         right = NA
#       )
#     )
#   ) |>
#   render_pdf()


#saving final dataset for validation in parquet format
write_parquet(ard_tbl, file.path(file.path(g_paths$dddata, "t_ef_ttr_pool_r.parquet")))
#Getting parquet file
t_ef_ttr_pool_r <- read_parquet(file.path(g_paths$dddata, "t_ef_ttr_pool_r.parquet"))
