####------------------------------------------------------------------------####
# Program Name: t_ef_ucorr_2l_pool_r.R
# Domino Project: 61834_300382_INTERNAL_05
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Vignesh Thanikachalam / vt704670
# Purpose: Table 14.2.1f Summary of Best Overall Response and Objective Response
# Rate in 2nd Line of Therapy (Phase 1 & 1b pooled)
#
# Input:
#   - ADaM: ADSL, ADEFF
# Output:
#   - DD: t_ef_ucorr_2l_pool_r.parquet
#   - File: ../prod/output/t_ef_ucorr_2l_pool_r.RTF
#
# External files called:
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- Load Libraries ----

pkg_load(
  "dplyr",
  "forcats",
  "cards",
  "tfrmt",
  "purrr",
  "gt",
  "stringr",
  "tidyr"
)

# --- Demo Analysis ----

adtte0 <- read_data_catalog(adamdata$adeff) |>
  filter(EFFL == "Y", PARAMCD == "BORU", ACAT2 == "INVESTIGATOR") |>
  # Select only essential columns.
  select(USUBJID, AVALC)

adtteOOR0 <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y") |> 
  left_join(
    adtte0 |> select(USUBJID, AVALC),
    by = "USUBJID"
  ) |>
  # Derive ORRFN (Objective Response Flag Numerical): 1 for CR/PR, 0 otherwise.
  mutate(AVALC = if_else(AVALC %in% c("CR", "PR"), "Y", "N")) |>
  select(USUBJID, AVALC) |> 
  mutate(
    AVALC = case_when(
      is.na(AVALC) ~ "remove",
      .default = AVALC
    ),
  )

adsl_2l <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y" & LOTCAT == "2nd-line" & DOSGRP == "T300/C400") |>
  select(USUBJID, DOSGRP, LOTCAT, DOSGRPN, GISTMLOC, starts_with("CTEXON"))

# --- Create Mutually Exclusive Mutation Categories ---

adsl <- adsl_2l |>
  rowwise() |>
  mutate(
    # --- Step 1: Create unified boolean flags by combining GISTMLOC and CTEXON data ---
    # A subject has a mutation if it's found in either the local (GISTMLOC) or central (CTEXON) data.
    # The `str_detect` function checks the GISTMLOC string. We use `!is.na()` to be safe.
    final_has_exon9 =  (CTEXON9 == "Y" & !is.na(CTEXON9))   | str_detect(GISTMLOC, "EXON 9"),
    final_has_exon11 = (CTEXON11 == "Y" & !is.na(CTEXON11)) | str_detect(GISTMLOC, "EXON 11"),
    final_has_exon13 = (CTEXON13 == "Y" & !is.na(CTEXON13)) | str_detect(GISTMLOC, "EXON 13"),
    final_has_exon14 = (CTEXON14 == "Y" & !is.na(CTEXON14)) | str_detect(GISTMLOC, "EXON 14"),
    final_has_exon17 = (CTEXON17 == "Y" & !is.na(CTEXON17)) | str_detect(GISTMLOC, "EXON 17"),
    final_has_exon18 = (CTEXON18 == "Y" & !is.na(CTEXON18)) | str_detect(GISTMLOC, "EXON 18"),
    
    # --- Step 2: Count the total number of unique mutations for each subject ---
    # This is crucial for distinguishing "only" cases from multiple mutations.
    total_mutation_count = sum(c_across(starts_with("final_has_"))),
    
    # --- Step 3: Assign the final category using a hierarchical case_when() ---
    # The order of these rules is critical. More specific combinations are checked first.
    mutation_category = case_when(
      # -- Specific Combination Rules --
      final_has_exon11 & (final_has_exon13 | final_has_exon14) ~ "Exon 11 and Exon 13 or 14",
      final_has_exon11 & (final_has_exon17 | final_has_exon18) ~ "Exon 11 and Exon 17 or 18",
      
      # -- "Only" Rules (total mutation count must be 1) --
      final_has_exon9  & total_mutation_count == 1 ~ "Exon 9 only",
      final_has_exon11 & total_mutation_count == 1 ~ "Exon 11 only",
      # final_has_exon13 & total_mutation_count == 1 ~ "Exon 13 only",
      # final_has_exon14 & total_mutation_count == 1 ~ "Exon 14 only",
      # final_has_exon17 & total_mutation_count == 1 ~ "Exon 17 only",
      # final_has_exon18 & total_mutation_count == 1 ~ "Exon 18 only",
      
      # -- Catch-all for any other combination of multiple mutations --
      total_mutation_count >= 1  ~ "Other (including ≥2 resistance mutations)",
      
      # -- Handle cases where "OTHER" is in GISTMLOC but no specific exons are found --
      str_detect(GISTMLOC, "OTHER") & total_mutation_count == 0 ~ "Other (including ≥2 resistance mutations)",
      
      # -- Optional: Handle subjects with no detected mutations --
      total_mutation_count == 0 ~ "No Mutation Detected",
      
      .default = NA_character_
    ),
    
    # --- Step 4: Convert to a factor to control the final display order ---
    mutation_category = factor(mutation_category, levels = c(
      "Exon 9 only",
      "Exon 11 only",
      "Exon 13 only",
      "Exon 14 only",
      "Exon 17 only",
      "Exon 18 only",
      "Exon 11 and Exon 13 or 14",
      "Exon 11 and Exon 17 or 18",
      "Other (including ≥2 resistance mutations)",
      "No Mutation Detected"
    ))
  ) |>
  # Remove the row-wise grouping
  ungroup() |>
  # Select the final columns for the analysis dataset
  select(USUBJID, DOSGRPN, DOSGRP, MUTCAT = mutation_category) |> 
  filter(!is.na(MUTCAT))

adslt0 <- adsl 

adslt <- adsl |>
  mutate(bignn = "Y")

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
        "NE",
        "UNK"
      ),
      labels = c(
        "COMPLETE RESPONSE (CR)",
        "PARTIAL RESPONSE (PR)",
        "STABLE DISEASE (SD)",
        "STABLE DISEASE (SD)",
        "PROGRESSIVE DISEASE (PD)",
        "NOT EVALUABLE",
        "UNKNOWN"
      )
    )
  )


adtteOOR <- merge(adtteOOR0, adslt, by = "USUBJID", all = TRUE) |>
  mutate(
    AVALLAB = factor(
      AVALC,
      levels = c("Y", "N"),
      labels = c("Objective Response Rate", "remove")
    )
  )

dm_ard1 <- ard_stack(
  data = adtteBOR,
  .by = MUTCAT,
  ard_tabulate(variables = c(AVALLAB)),
  #.overall = TRUE,
  #.total_n = TRUE
) |>
  filter(!(stat_name == "N"))

dm_ard2 <- ard_stack(
  data = adtteOOR,
  .by = MUTCAT,
  ard_tabulate(variables = c(AVALLAB)),
  #.overall = TRUE,
  #.total_n = TRUE
) |>
  filter(!(stat_name == "N"))


# Calculate big N

df_big_N <- ard_stack(
  data = adslt,
  .by = MUTCAT,
  ard_tabulate(variables = c(bignn)),
  #.overall = TRUE,
  #.total_n = TRUE
) |>
  filter((stat_name == "N" & variable == "bignn")) |>
  mutate(stat_name = "BigN")


dm_ard <- bind_rows(dm_ard1, dm_ard2, df_big_N)

ard_tbl0 <- dm_ard |>
  unlist_ard_columns() |> 
  rename_ard_columns(columns = all_ard_groups("names")) |> 
  # relabel the variables
  mutate(
    stat_variable = case_when(
      variable == "AVALLAB" & variable_level== "Objective Response Rate" ~ "Objective Response Rate",
      variable == "AVALLAB" ~ "Best Overall Response",
      .default = variable_level
    )
  ) |>
  # remove dups (extra denoms per variable level)
  filter(variable_level != "remove" & variable != "MUTCAT") |> 
  # drop variables not needed
  select(MUTCAT, stat_variable, variable_level, stat_name, stat)


###### Confirmed Objective Response - INVESTIGATOR (ORR) ######

# 95% CI (Clopper-Pearson)
adtteOOR <- adtteOOR |> filter(!is.na(MUTCAT))

ORRtab <- adtteOOR |>
  group_by(AVALC, MUTCAT) |>
  summarise(n = n_distinct(USUBJID)) |>
  ungroup()

# Calculate bigN
bigN <- adtteOOR |>
  group_by(MUTCAT) |>
  summarise(N = n(), .groups = "drop") |>
  ungroup()

ORRtab_per <- ORRtab |>
  filter(AVALC == "Y") |> # select only CR+PR (same as AVALC=Y)
  full_join(bigN, by = "MUTCAT") |>
  filter(MUTCAT != "remove")

# Add 95% CI Clopper-Pearson
ORRtab_CIL <- ORRtab_per |>
  mutate(
    n = case_when(is.na(n) & N > 0 ~ 0, TRUE ~ n),
    stat = qbeta(0.025, shape1 = n, shape2 = N - n + 1) * 100,
    stat_name = "CL"
  )

ORRtab_CIH <- ORRtab_per |>
  mutate(
    n = case_when(is.na(n) & N > 0 ~ 0, TRUE ~ n),
    stat = qbeta(1 - 0.025, shape1 = n + 1, shape2 = N - n) * 100,
    1,
    stat_name = "CH"
  )

ORRtab_CI_0 <- bind_rows(ORRtab_CIL, ORRtab_CIH) |>
  mutate(
    stat_variable = "95% exact Confidence Interval",
    variable_level = "95% exact Confidence Interval"
  )

DUMMY <-
  crossing(
    MUTCAT = unique(adslt$MUTCAT), # Assuming group2_level refers to MUTCAT
    stat_name = c("CL", "CH")
  ) |>
  mutate(
    stat_variable = "95% exact Confidence Interval",
    variable_level = "95% exact Confidence Interval"
  )


ORRtab_CI <- merge(
  DUMMY,
  ORRtab_CI_0,
  by = c("MUTCAT", "stat_variable", "stat_name", "variable_level"),
  all = TRUE
)
#Combine all stat-s in final dataset
ard_tbl1 <- bind_rows(ard_tbl0, ORRtab_CI) |>
  # drop variables not needed
  select(stat_variable, variable_level, stat_name, stat, MUTCAT) |>
  mutate(order = 1) |> 
  filter(!MUTCAT %in% c("Exon 13 only", "Exon 14 only", "Exon 17 only", "Exon 18 only", "No Mutation Detected"))

ORR_LOT <- tfrmt(
  group = stat_variable,
  label = variable_level,
  param = stat_name,
  value = stat,
  column = MUTCAT,
  sorting_cols = ,
  body_plan = body_plan(
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
          ">0.99" ~ frmt("(>99%)"),
          "==0" ~ frmt(""),
          "<0.01" ~ frmt("( <1%)"),
          ">0" ~ frmt("(xxx%)", transform = ~ . * 100),
          "TRUE" ~ frmt("")
        )
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "({CL}, {CH})",
        CL = frmt_when("==0" ~ "0", "==100" ~ "100", "TRUE" ~ frmt("x.x")),
        CH = frmt_when("==0" ~ "0", "==100" ~ "100", "TRUE" ~ frmt("x.x"))
      )
    )
  ),
  
  col_plan = col_plan(
    `Exon 9 only`,
    `Exon 11 only`,
    `Exon 11 and Exon 13 or 14`,
    `Exon 11 and Exon 17 or 18`,
    `Other (including ≥2 resistance mutations)`
  ),
  big_n = big_n_structure(
    param_val = "BigN",
    n_frmt = frmt("\n(N=x)"),
    by_page = FALSE
  ),
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    row_grp_structure(
      group_val = list(stat_variable = "Objective Response Rate"),
      element_block(post_space = NULL)
    ),
    row_grp_structure(
      group_val = list(stat_variable = "95% exact Confidence Interval"),
      element_block(post_space = NULL)
    ),
    label_loc = element_row_grp_loc(location = "indented")
  )
)

# --- Step 4: Use rtfbuilder to Create Final RTF Output ---
# 2. Create a new, simple gt object from the flattened data.
final_gt_obj <- print_to_gt(ORR_LOT, ard_tbl1)
# 3. Build the RTF using the flattened gt object.
rtf_dt <- final_gt_obj |>
  rtf_table(
    drop_columns = order
  ) |>
  rtf_col_align(starts_with(c("Exon", "Other", "No")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("Exon", "Other", "No"))  ~ "1.20in") |>
  rtf_col_label(variable_level = "") |>
  rtf_col_spanner(label = "KIT Mutation", columns = starts_with(c("Exon", "Other", "No"))) |> 
  # rtf_paginate_cols(id_columns = variable_level, split_at = 5) |> 
  rtf_title(
    "Table 14.2.1f",
    "Summary of Unconfirmed Best Overall Response and Objective Response Rate in Dose Group T300/C400, 2nd Line of Therapy",
    "by Mutation Status (Phase 1 & 1b pooled)"
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
  ) |> 
  build_rtf(file = file.path(g_paths$output, "t_ef_ucorr_2l_pool_r.rtf"))

#saving final dataset for validation in parquet format
arrow::write_parquet(
  ard_tbl1,
  file.path(g_paths$dddata, "t_ef_ucorr_2l_pool_r.parquet")
)
