####------------------------------------------------------------------------####
# Program Name: t_ef_orr_2l_pool_r.R
# Domino Project: 61834_300382_INTERNAL_05
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Vignesh Thanikachalam / vt704670
# Purpose: Table 14.2.1f Summary of Best Overall Response and Objective Response
# Rate in 2nd Line of Therapy (Phase 1 & 1b pooled)
#
# Input:
#   - ADaM: ADSL, ADEFF
# Output:
#   - DD: t_ef_orr_2l_pool_r.parquet
#   - File: ../prod/output/t_ef_orr_2l_pool_r.RTF
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
  filter(EFFL == "Y" & PARAMCD == "BOR" & ACAT2 == "INVESTIGATOR") |>
  select(USUBJID, AVALC)


adtteOOR0 <- read_data_catalog(adamdata$adeff) |>
  filter(EFFL == "Y" & PARAMCD == "ORRFL" & ACAT2 == "INVESTIGATOR") |>
  select(USUBJID, AVALC) |>
  mutate(
    AVALC = case_when(
      is.na(AVALC) ~ "remove",
      .default = AVALC
    ),
  )

adsl_2l <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y" & LOTCAT == "2nd-line") |>
  select(USUBJID, DOSGRP, LOTCAT, DOSGRPN, starts_with("CTEXON"))

# --- Create Mutually Exclusive Mutation Categories ---

adsl <- adsl_2l |>
  rowwise() |>
  mutate(
    # Step 1: Securely count the number of "Y" mutations, ignoring NAs.
    mutation_count = sum(c_across(starts_with("CTEXON")) == "Y", na.rm = TRUE)
  ) |> 
  ungroup() |> 
  mutate(
    # --- Step 1: Create NA-safe boolean flags for clarity and robustness ---
    # This prevents logical errors from NA values. A mutation is only TRUE if it's "Y".
    has_exon9 = (CTEXON9 == "Y" & !is.na(CTEXON9)),
    has_exon11 = (CTEXON11 == "Y" & !is.na(CTEXON11)),
    has_exon13 = (CTEXON13 == "Y" & !is.na(CTEXON13)),
    has_exon14 = (CTEXON14 == "Y" & !is.na(CTEXON14)),
    has_exon17 = (CTEXON17 == "Y" & !is.na(CTEXON17)),
    has_exon18 = (CTEXON18 == "Y" & !is.na(CTEXON18)),
    
    # --- Step 2: Assign the final category using a hierarchical case_when() ---
    # The order of these rules is critical and follows your specification.
    mutation_category = case_when(
      
      # Category 3: Exon 13 AND (Exon 9 OR Exon 11)
      # This complex rule is checked first as it is the most specific.
      has_exon11 & (has_exon13 | has_exon14) ~ "Exon 11 and Exon 13 or 14",
      
      # Category 4: Exon 17 AND (Exon 9 OR Exon 11)
      # The second-most specific rule.
      has_exon11 & (has_exon17 | has_exon18) ~ "Exon 11 and Exon 17 or 18",
      
      # Category 1: Exon 9 ONLY (relative to Exon 11)
      # This is only evaluated if the rules above are FALSE.
      # This means we only need to check that Exon 11 is not also present.
      has_exon9 & mutation_count == 1 ~ "Exon 9 only",
      
      # Category 2: Exon 11 ONLY (relative to Exon 9)
      # Checked after the rule for "Exon 9 only".
      has_exon11 & mutation_count == 1  ~ "Exon 11 only",
      
      # Category 5: Other / Multiple
      # It catches any patient who did not fit the specific
      # patterns above. This includes:
      # - Patients with no mutations.
      # - Patients with both Exon 9 and Exon 11.
      # - Patients with other mutations not in the rules (e.g., Exon 14 only).
      # - Any other combination.
      mutation_count > 1 ~ "Other / Multiple",
      .default = NA_character_
    ),
    
    # --- Step 3: Convert to a factor to control display order ---
    mutation_category = factor(mutation_category, levels = c(
      "Exon 9 only",
      "Exon 11 only",
      "Exon 11 and Exon 13 or 14",
      "Exon 11 and Exon 17 or 18",
      "Other / Multiple"
    ))
  ) |>
  # Optional: Clean up the temporary flag columns
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
  mutate(order = 1)

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
    `Other / Multiple`
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
  rtf_col_align(starts_with(c("Exon", "Other")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("Exon", "Other"))  ~ "1.20in") |>
  rtf_col_label(variable_level = "") |>
  rtf_title(
    "Table 14.2.1f",
    "Summary of Best Overall Response and Objective Response Rate in 2nd Line of Therapy",
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
  build_rtf(file = file.path(g_paths$output, "t_ef_orr_2l_pool_r.rtf"))

#saving final dataset for validation in parquet format
arrow::write_parquet(
  ard_tbl1,
  file.path(g_paths$dddata, "t_ef_orr_2l_pool_r.parquet")
)
