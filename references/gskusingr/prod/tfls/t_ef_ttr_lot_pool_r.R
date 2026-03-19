####------------------------------------------------------------------------####
# Program Name: t_ef_ttr_lot_pool_r.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Pragya Tripathi/ ps209009
# Purpose: Summary of Time to Response by Line of Therapy (Phase 1 & 1b pooled)
# Input: ADBS ADTTE
# Output: [N/A]
# External files called:
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# --- Load Libraries ----

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
  "arrow",
  "gt",
  "lubridate",
  "tidyverse",
  "stringr"
)

# --- Demo Analysis ----

adtte0 <- read_data_catalog(adamdata$adtte) |>
  filter(EFFL == "Y" & PARAMCD == "TTR") |>
  select(USUBJID, AVAL)

adsl <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y" & !is.na(LOTCAT)) |>
  select(USUBJID, DOSGRP, LOTCAT, EFFL, DOSGRPN)

adslt0 <- adsl |>
  mutate(DOSGRP = "Total", DOSGRPN = 999)

adslt <- bind_rows(adsl, adslt0)|>
  mutate(bignn="Y")

adtte <- merge(adtte0, adslt, by = "USUBJID", all = TRUE)

dm_ard <- ard_stack(
  data = adtte,
  .by = c(DOSGRP, LOTCAT),
  #  ard_tabulate(variables = c(EFFL)),
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
  #.overall = TRUE,
  #.total_n = TRUE
)
# Calculate big N

df_big_N <- ard_stack(
  data = adslt,
  .by = c(DOSGRP, LOTCAT),
  ard_tabulate(variables = c(bignn)),
  #.overall = TRUE,
  #.total_n = TRUE
) |>
  filter((stat_name == "N" & variable=="bignn"))|>
  mutate(stat_name="BigN")

dm_ard2<- bind_rows(dm_ard, df_big_N)

ard_tbl1 <- dm_ard2 |>
  #reshape the data
  shuffle_card(fill_overall = "Total") |>
  # transform group-level freqs/pcts into a singular "bigN" row
  prep_big_n(vars = c("DOSGRP", "LOTCAT")) |>
  # consolidate vars into a single variable column
  prep_combine_vars(vars = c("AVAL")) |>
  # coalesce categorical levels + continuous stats into a "label"
  prep_label() |>
  filter(
    !(DOSGRP %in%
        c("Total.1") |
        LOTCAT == "Total" |
        (stat_name %in% c("p", "N") & stat_variable == "EFFL"))
  ) |>
  group_by(DOSGRP, LOTCAT, stat_variable) |>
  # mutate(across(c(variable_level, label), ~ ifelse(stat_name=="N", "n", .x))) |>
  ungroup() |>
  unique() |>
  
  # relabel the variables
  mutate(
    stat_variable = case_when(
      stat_variable == "AVAL" ~ "Time to Response, month",
      .default = stat_variable
    ),
    #Line_of_Therapy=LOTCAT,
    label = case_when(
      stat_label == "N" ~ "n",
      .default = stat_label
    ),
    label = case_when(
      #label == "SD" ~ "Standard Deviation",
      label == "Min" ~ "Min.",
      label == "Max" ~ "Max.",
      .default = label
    ),
    order=1
  ) |>
  # drop variables not needed
  select(DOSGRP, LOTCAT, stat_variable, label, stat_name, stat,order) |>
  # remove dups (extra denoms per variable level)
  unique()


TTR_LOT <- tfrmt(
  group = c(LOTCAT, stat_variable),
  label = label,
  param = stat_name,
  value = stat,
  column = DOSGRP,
  sorting_cols = order,
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
      min = frmt_when(">=0 | !is.na(stat)" ~ frmt("xxxxxxx"), "TRUE" ~ frmt(""))
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      max = frmt_when(">=0 | !is.na(stat)" ~ frmt("xxxxxxx"), "TRUE" ~ frmt(""))
    )
    # frmt_structure(
    #   group_val = ".default", label_val = ".default",
    #   frmt_combine("{min}, {max}",
    #                min = frmt("xx"),
    #                max = frmt("xx")
    #   )
    # )
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
) #|>
#  print_to_gt(ard_tbl)
# By trt groups
# print_by <- function(df_input, trt) {
#   df_trt <- df_input %>% filter(LOTCAT == trt)
#   print_to_gt(TTR_LOT, df_trt) %>%
#     tab_header(title = md(glue::glue("Line of Therapy: {trt}")))
# }
# sec_01 <- unique(arrange(ard_tbl1, LOTCAT)$LOTCAT) %>%
#   map(~ print_by(ard_tbl1, .x))
# TTR_LOT <- gt_group(.list = sec_01)
# 
# TTR_LOT

# --- Step 4: Use rtfbuilder to Create Final RTF Output ---
# 2. Create a new, simple gt object from the flattened data.
final_gt_obj <- print_to_gt(TTR_LOT, ard_tbl1) 

# 3. Build the RTF using the flattened gt object.
rtf_dt <-final_gt_obj|>
  rtf_table(
    page_group_label = paste("Line of Therapy:", LOTCAT),
    row_noorphan_col = order,
    drop_columns = order
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(label = "") |>
  rtf_paginate_cols(id_columns = label, split_at = 5) |>
  rtf_title(
    "Table 14.2.5e",
    "Summary of Time to Response by Line of Therapy (Phase 1 & 1b pooled)"
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
  build_rtf(file = file.path(g_paths$output,"t_ef_ttr_lot_pool_r.rtf"))

# footnote1_1 <- file.path('/mnt', 'code', 'prod', 'tfls', 't_ef_ttr_lot_pool_r.R')
# footnote1_2 <- format(Sys.time(), "%d%b%Y  %H:%M") |> toupper()
# TTR_LOT |>
#   as_docorator(
#     display_name = "t_ef_ttr_lot_pool_r",
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
#       fancyrow(left = NA, center = "Table 14.2.5e", right = NA),
#       fancyrow(
#         left = NA,
#         center = "Summary of Time to Response by Line of Therapy (Phase 1 & 1b pooled)",
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
write_parquet(ard_tbl1, file.path(file.path(g_paths$dddata, "t_ef_ttr_lot_pool_r.parquet")))
#Getting parquet file
t_ef_ttr_lot_pool_r <- read_parquet(file.path(g_paths$dddata, "t_ef_ttr_lot_pool_r.parquet"))