####------------------------------------------------------------------------####
# Program Name: t_ef_pfs_cnt_pct.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Summary of Censored Data
#
# Input:
#   - adam [adbs, adcm]
# Output:
#   - dd []
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------
# --- Load Libraries ---
pkg_load("dplyr", "forcats", "stringr", "purrr", "cards","tfrmt","gt")

adbs <- read_data_catalog(adamdata$adbs) |>
  rename_with(tolower) |> 
  filter(
    effl == "Y"
  ) 

# Dynamically create Treatment Group factor levels from the data.
trt_levels <- distinct(adbs, dosgrpn, dosgrp) |>
  arrange(dosgrpn) |>
  pull(dosgrp)
trt_levels_total <- c(trt_levels, "Total")

# Create the `pop` data frame, defining one row per patient for each analysis stratum.
pop <-
  bind_rows(adbs, adbs |> mutate(dosgrp = "Total")) |> # Add a "Total" group
  select(usubjid, dosgrp) |>
  distinct() |> # Get unique patient-group combinations
  mutate(dosgrp = factor(dosgrp, levels = trt_levels_total))


adtte <- read_data_catalog(adamdata$adtte) |>
  rename_with(tolower) |> 
  filter(
    str_trim(acat2) == "INVESTIGATOR",
    paramcd == "PFS",
    effl == "Y"
  ) |>
  mutate(
    evntdesc_ = paste0(str_trim(evntdesc), " (", str_trim(cnsdtdsc), ")")
  ) |>
  select(usubjid, evntdesc_, cnsr)

adeff <- read_data_catalog(adamdata$adeff) |>
  rename_with(tolower) |> 
  filter(
    str_trim(acat2) == "INVESTIGATOR",
    str_trim(paramcd) == "LSTASSDT"
  ) |>
  mutate(lstassdt = "Y") |>
  distinct(usubjid, .keep_all = TRUE) |>
  select(usubjid, lstassdt)

adtr <- read_data_catalog(adamdata$adtr) |>
  rename_with(tolower) |> 
  filter(
    str_trim(parcat1) == "TARGET",
    str_trim(param) == "Longest Diameter",
    str_trim(ablfl) == "Y"
  ) |>
  distinct(usubjid, .keep_all = TRUE) |>
  select(usubjid, ablfl)

adcm <- read_data_catalog(adamdata$adcm) |>
  rename_with(tolower) |> 
  filter(str_trim(cmcat) == "SUBSEQUENT ANTI-CANCER THERAPY") |>
  mutate(cmcat = "Y") |>
  distinct(usubjid, .keep_all = TRUE) |>
  select(usubjid, cmcat)

adtte_flg <- adtte |>
  left_join(adeff, by = "usubjid") |>
  left_join(adtr, by = "usubjid") |>
  left_join(adcm, by = "usubjid") |>
  left_join(adbs, by = "usubjid") |>
  mutate(
    dcsreas = if_else(dcsreas == "Other", dcsreasp, dcsreas)
  )


  row1 <- adtte_flg |>
    filter(
      ablfl == "Y",
      evntdesc_ == "No progression (or death) (Date of last assessment)",
      is.na(cmcat),
      lstassdt == "Y",
      dcsreas %in% c("", "Study Completion")
    ) |>
    mutate(paramcd = "row1", param = "No progression/ death and is still in the study",chk=1)
  
  row2 <- adtte_flg |>
    filter(
      ablfl == "Y",
      str_trim(evntdesc_) == "No progression (or death) (Date of last assessment)",
      cmcat == "Y" | !dcsreas %in% c("", "Study Completion")
    ) |>
    mutate(paramcd = "row2", param = "Lost to follow up or withdraw consent BEFORE having a documented progression",,chk=2)
  
  row3 <- adtte_flg |>
    filter(
      ablfl == "Y",
      str_trim(evntdesc_) ==
        "Progression or death after two or more missing assessment (Date of last assessment prior to missed assessments)"
    ) |>
    mutate(paramcd = "row3", param = "Progression or death after missing 2 or more tumor assessment",chk=3)
  
  row4 <- adtte_flg |>
    filter(
      ablfl == "Y",
      cnsr == 0,
      cmcat == "Y"
    ) |>
    mutate(paramcd = "row4", param = "Started new anti-cancer therapy or surgical resection BEFORE documented progression",chk=4)
  
  row5 <- adtte_flg |>
    filter(
      ablfl == "Y",
      cnsr == 0,
      is.na(cmcat),
      lstassdt == "Y"
    ) |>
    mutate(paramcd = "row5", param = "Has a PFS event",chk=5)
  
  row6 <- adtte_flg |>
    filter(
      ablfl == "Y",
      evntdesc_ == "No post baseline disease assessment (Date of first IDRX-42 dose)"
    ) |>
    mutate(paramcd = "row6", param = "Censored at Randomisation",chk=6)  
  
  row7 <- adtte_flg |>
    filter(is.na(ablfl)) |>
    mutate(paramcd = "row7", param = "Does not have adequate baseline assessment (missing or not ealuable at baseline)",chk=7)

  all_row <- bind_rows(row1,row2,row3,row4,row5,row6,row7) |>
  select(studyid, siteid, usubjid, paramcd, param, dosgrp)

final <-
  bind_rows(all_row, all_row |> mutate(dosgrp = "Total")) |>
  mutate(
    dosgrp = factor(dosgrp, levels = trt_levels_total),
  )


# Calculate n/N for the hierarchical variable THPY.
ard_final <- final |>
  ard_stack_hierarchical(
    by = dosgrp,
    variables = param,
    denominator = pop,
    id = usubjid,
    over_variables = TRUE
  )

# --- Post-process the ARD ---

# Unlist list-columns and rename the grouping column
processed_ard <- ard_final |>
  unlist_ard_columns() |>
  rename_ard_columns(columns = all_ard_groups("names"))|>
  filter(variable_level != "")


# Isolate the main statistics (n and p)
main_stats_ard <- processed_ard |>
  filter(
    stat_name %in% c("n", "p"),
    !variable %in% c("dosgrp"), !is.na(dosgrp),variable_level != "TRUE"
  ) |>
  mutate(
    stat = case_when(
      stat_name == "p" ~ coalesce(stat * 100, 0),
      .default = stat
    ), 
    label = coalesce(variable_level, stat_label),
    grp = recode(
      variable_level,
      "No progression/ death and is still in the study" = 1,
      "Lost to follow up or withdraw consent BEFORE having a documented progression" = 2,
      "Progression or death after missing 2 or more tumor assessment" =3,
      "Started new anti-cancer therapy or surgical resection BEFORE documented progression" = 4,
      "Has a PFS event" = 5,
      "Censored at Randomisation" = 6,
      "Does not have adequate baseline assessment (missing or not ealuable at baseline)" = 7,
      .default = NA_real_
  )
  )

# Isolate the population counts (Big Ns)
population_counts_ard <- processed_ard |>
  filter(variable == "dosgrp", stat_name == "n") |>
  mutate(
    ARM = stat_label,
    stat_name = "bigN",
    dosgrp = variable_level,
    variable = NA_character_,
    variable_level = NA_character_
  )

# Combine main stats and population counts into a final ARD
final_ard <- bind_rows(main_stats_ard, population_counts_ard) |>
  mutate(
    # Convert ARM to a factor to ensure correct column order in the table
    dosgrp = factor(dosgrp, levels = trt_levels_total),
    variable=""
  ) |>
  # Select final columns needed for tfrmt
  select(dosgrp, variable, label, grp, stat_name, stat) 


# --- Table Formatting (tfrmt) ---

# Define the table structure using tfrmt
tfobj <- tfrmt(
  group = variable,
  label = label,
  column = dosgrp,
  value = stat,
  param = stat_name,
  sorting_cols = grp ,
  body_plan = body_plan(
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{n} {p}",
        n = frmt("xxx"),
        p = frmt_when(
          "==100" ~ frmt("(100%)"),
          ">99" ~ frmt("(>99%)"),
          "==0" ~ frmt(""),
          "<1" ~ frmt("( <1%)"),
          "TRUE" ~ frmt("(xxx%)")
        )
      )
    )
  ),
  big_n = big_n_structure(param_val = "bigN", n_frmt = frmt("\n(N=x)")),
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " "))
  )
)

# Convert the tfrmt object to a gt object
gt <- print_to_gt(tfobj, final_ard)

# --- 6. Create and Save Output in RTF ---

rtf_obj <- gt |>
  rtf_table(
    # Keep groups together to avoid orphaned rows
    row_noorphan_col = grp,
    drop_columns = grp,
    row_height=0.35
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(label = "") |>
  # Paginate columns if they exceed the page width
  rtf_paginate_cols(id_columns = label, split_at = 5) |>
  rtf_title(
    "Table 1",
    "Summary of Censored Subjects"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Efficay", paste("Data as of", g_config$datadate))
  ) |>
  build_rtf(file = file.path(g_paths$output, "t_ef_pfs_cnt_pct.rtf"))


