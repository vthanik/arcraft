####------------------------------------------------------------------------####
# Program Name: t_ef_cbr_lot_pool_r.R
# Domino Project: 61834_300382_INTERNAL_05
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Mariam ALaverdyan/ ma584118
# Purpose: Table 14.2.6e  -  Summary of Clinical Benefit Rate by Line of Therapy (Phase 1 & 1b pooled)  -  Efficacy Analysis Set
# Input: ADSL
# Output: [N/A]
# External files called:
#
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

adtte0 <- read_sas_local(adamdata$adeff) |>
  filter(EFFL == "Y" & PARAMCD == "BOR" & ACAT2 == "INVESTIGATOR") |>
  select(USUBJID, AVALC)


adtteOOR0 <- read_sas_local(adamdata$adeff) |>
  filter(EFFL == "Y" & PARAMCD == "CBRFL" & ACAT2 == "INVESTIGATOR") |>
  select(USUBJID, AVALC) |>
  mutate(
    AVALC = case_when(
      is.na(AVALC) ~ "remove",
      .default = AVALC
    ),
  )
adsl <- read_data_catalog(adamdata$adbs)|>
  filter(EFFL == "Y" & !is.na(LOTCAT)) |>
  select(USUBJID, DOSGRP, LOTCAT, DOSGRPN)

adslt0 <- adsl |>
  mutate(DOSGRP = "Total", DOSGRPN = 999)

adslt <- bind_rows(adsl, adslt0)|>
  mutate(bignn="Y")

adtteBOR <- merge(adtte0, adslt, by = "USUBJID", all = TRUE) |>
  mutate(
    AVALLAB = factor(
      AVALC,
      levels = c(
        "CR",
        "PR",
        "6 <= SD < 16 weeks",
        "SD >= 16 weeks",
        "PD",
        "NE"
      ),
      labels = c(
        "COMPLETE RESPONSE (CR)",
        "PARTIAL RESPONSE (PR)",
        "STABLE DISEASE (SD)",
        "STABLE DISEASE (SD)",
        "PROGRESSIVE DISEASE (PD)",
        "NOT EVALUABLE"
      )
    )
  )


adtteOOR <- merge(adtteOOR0, adslt, by = "USUBJID", all = TRUE) |>
  mutate(
    AVALLAB = factor(
      AVALC,
      levels = c("Y", "N"),
      labels = c("Clinical Benefit Rate", "remove")
    )
  )

dm_ard1 <- ard_stack(
  data = adtteBOR,
  .by = c(DOSGRP, LOTCAT),
  ard_tabulate(variables = c(AVALLAB)),
  #.overall = TRUE,
  #.total_n = TRUE
) |>
  filter(!(stat_name == "N"))

dm_ard2 <- ard_stack(
  data = adtteOOR,
  .by = c(DOSGRP, LOTCAT),
  ard_tabulate(variables = c(AVALLAB)),
  #.overall = TRUE,
  #.total_n = TRUE
) |>
  filter(!(stat_name == "N"))


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


dm_ard <- bind_rows(dm_ard1, dm_ard2,df_big_N)

ard_tbl0 <- dm_ard |>
  #filter (!(context=="tabulate" &stat_name=="N"))|>
  #reshape the data
  shuffle_card(fill_overall = "Total") |>
  # transform group-level freqs/pcts into a singular "bigN" row
  prep_big_n(vars = c("DOSGRP", "LOTCAT")) |>
  # consolidate vars into a single variable column
  prep_combine_vars(vars = c("AVALLAB")) |>
  # coalesce categorical levels + continuous stats into a "label"
  prep_label() |>
  # filter (context=="summary")|>
  group_by(DOSGRP, LOTCAT, stat_variable) |>
  # mutate(across(c(variable_level, label), ~ ifelse(stat_name=="N", "n", .x))) |>
  ungroup() |>
  unique() |>
  
  # relabel the variables
  mutate(
    stat_variable = case_when(
      AVALLAB == "Clinical Benefit Rate" ~ "Clinical Benefit Rate",
      stat_variable == "AVALLAB" ~ "Best Overall Response",
      .default = stat_variable
    ),
    label = case_when(
      stat_label == "N" ~ "n",
      .default = AVALLAB
    )
  ) |>
  # drop variables not needed
  select(DOSGRP, LOTCAT, stat_variable, label, stat_name, stat) |>
  # remove dups (extra denoms per variable level)
  filter(label != "remove" & LOTCAT != "remove") |>
  unique()

###### Confirmed CB Response - INVESTIGATOR (ORR) ######

round_half_up <- function(x, digits = 0) {
  posneg <- sign(x)
  z <- abs(x) * 10^digits
  z <- z + 0.5 + sqrt(.Machine$double.eps)
  z <- trunc(z)
  z <- z / 10^digits
  z * posneg
}
# 95% CI (Clopper-Pearson)
adtteOORt0 <- adtteOOR |>
  mutate(DOSGRP = "Total")

adtteOORt <- bind_rows(adtteOOR, adtteOORt0)

ORRtab <- adtteOOR |>
  group_by(AVALC, DOSGRP, LOTCAT) |>
  summarise(n = n_distinct(USUBJID)) |>
  ungroup()

# Calculate bigN
bigN <- adtteOOR |>
  group_by(DOSGRP, LOTCAT) |>
  summarise(N = n(), .groups = "drop") |>
  ungroup()

ORRtab_per <- ORRtab |>
  filter(AVALC == "Y") |> # select only CR+PR (same as AVALC=Y)
  full_join(bigN, by = c("DOSGRP", "LOTCAT")) |>
  filter(LOTCAT != "remove")

# Add 95% CI Clopper-Pearson
ORRtab_CIL <- ORRtab_per |>
  mutate(n=case_when (is.na(n) &  N>0~0,
                      TRUE~n),
         stat = qbeta(0.025, shape1 = n, shape2 = N - n + 1) * 100,
         stat_name = "CL"
  )

ORRtab_CIH <- ORRtab_per |>
  mutate(n=case_when (is.na(n) &  N>0~0,
                      TRUE~n),
         stat = qbeta(1 - 0.025, shape1 = n + 1, shape2 = N - n) * 100,
         1,
         stat_name = "CH"
  )

ORRtab_CI_0 <- bind_rows(ORRtab_CIL, ORRtab_CIH) |>
  mutate(
    stat_variable = "95% exact Confidence Interval, %",
    label = "95% exact Confidence Interval, %"
  )
DUMMY <-
  crossing(
    DOSGRP = unique(adslt$DOSGRP),
    LOTCAT = unique(adslt$LOTCAT), # Assuming group2_level refers to LOTCAT
    stat_name = c("CL", "CH")
  ) |>
  mutate(
    stat_variable = "95% exact Confidence Interval, %",
    label = "95% exact Confidence Interval, %"
  )


ORRtab_CI <- merge(
  DUMMY,
  ORRtab_CI_0,
  by = c("DOSGRP", "LOTCAT", "stat_variable", "stat_name", "label"),
  all = TRUE
)

#Combine all stat-s in final dataset

ard_tbl1 <- bind_rows(ard_tbl0, ORRtab_CI) |>
  # drop variables not needed
  select(DOSGRP, stat_variable, label, stat_name, stat, LOTCAT) |>
  mutate(order=1)



# adsln <- adslt |>
#   arrange(DOSGRPN) |>
#   distinct(DOSGRPN, .keep_all = TRUE) |>
#   select(DOSGRPN, DOSGRP)
# 
# df_big_Nn <- merge(df_big_N, adsln, by = c("DOSGRP"), all = TRUE)
# 
# 
# ard_tbl1 <- merge(ard_tbl, df_big_Nn, by = c("DOSGRP", "LOTCAT"), all = TRUE) |>
#   arrange(DOSGRPN, LOTCAT, stat_variable) |>
#   select(-N,  -DOSGRPN, )


ORR_LOT <- tfrmt(
  group = c(LOTCAT, stat_variable),
  label = label,
  param = stat_name,
  value = stat,
  column = DOSGRP,
  sorting_cols = order,
  body_plan = body_plan(
    frmt_structure(group_val = ".default", label_val = ".default", frmt("xxx")),
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
      frmt_combine("({CL},{CH})", 
                   CL = frmt_when("==0" ~ "0", "TRUE" ~ frmt("x.x")), 
                   CH = frmt_when("==0" ~ "0", "TRUE" ~ frmt("x.x")))
    )
  ),
  
  # col_plan = col_plan(
  #   -starts_with(c('ord', 'N'))
  # ),
  
  col_plan = col_plan(C120, `T200/C240`, `T300/C400`, T500, `T600/C600`, C800, C1200, Total),
  # col_style_plan = col_style_plan(col_style_structure(
  #   width = 80,
  #   type = 'char',
  #   align = c(')'),
  #   col = vars(contains('C'), contains('T'), starts_with('Total'))
  # )),
  big_n = big_n_structure(
    param_val = "BigN",
    n_frmt = frmt("\n(N=x)"),
    by_page = TRUE
  ),
  # row_grp_plan = row_grp_plan(
  #   row_grp_structure(group_val = ".default", element_block(post_space = " "))
  # ),
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    row_grp_structure(
      group_val = list(stat_variable = "Clinical Benefit Rate"),
      element_block(post_space = NULL)
    ),
    row_grp_structure(
      group_val = list(stat_variable = "95% exact Confidence Interval, %"),
      element_block(post_space = NULL)
    ),
    label_loc = element_row_grp_loc(location = "spanning")
  ),
  page_plan = page_plan(page_structure(group_val = list(LOTCAT = ".default")))
) 


# --- Step 4: Use rtfbuilder to Create Final RTF Output ---
# 2. Create a new, simple gt object from the flattened data.
final_gt_obj <- print_to_gt(ORR_LOT, ard_tbl1) 
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
    "Table 14.2.6e",
    "Summary of Clinical Benefit Rate by Line of Therapy (Phase 1 & 1b pooled)"
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
  rtf_footer ("Note: Clinical Benefit Rate (CBR) is defined as the percentage of participants with a confirmed CR/PR or SD lasting at least 16 weeks from the start of treatment according to mRECIST v1.1 per Investigator assessment. Participants who have not had a tumor assessment at ≥16 weeks will be excluded from the analysis unless they have experienced PR or PD or have discontinued treatment due to any reason.",
              .align = "left")

rtf_dt |>
  build_rtf(file = file.path(g_paths$output,"t_ef_cbr_lot_pool_r.rtf"))

#saving final dataset for validation in parquet format
write_parquet(ard_tbl1, file.path(file.path(g_paths$dddata, "t_ef_cbr_lot_pool_r.parquet")))

#Getting parquet file 
t_ef_cbr_pool <- read_parquet(file.path(file.path(g_paths$dddata, "t_ef_cbr_lot_pool_r.parquet")))