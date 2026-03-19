####------------------------------------------------------------------------####
# Program Name: t_sf_aeser_2n_pool.R
# Domino Project: 61834_300382_INTERNAL_02
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Pragya Tripathi/ ps209009
# Purpose: Table 14.3.2.13c-Summary of Treatment Emergent Serious Adverse Events
#          >= 2 Subjects by Preferred Term, (Phase 1 & 1b pooled)
# Input: ADBS, ADAE
# Output: [N/A]
#
# External files called: [N/A]
#
# Additional Notes:
#
# 2025-12-24:
#   - Vignesh T. started collaborating with the original programmer.
#
#-------------------------------------------------------------------------------

# --- 0. Libraries ---
pkg_load(
  "dplyr",
  "tidyr",
  "stringr",
  "forcats",
  "cards",
  "cardx",
  "tfrmt",
  "gt",
  "admiral",
  "arrow"
)

# --- 1. ADSL / Safety Population ---
adbs <- read_data_catalog(adamdata$adbs) |>
  filter(SAFFL == "Y", !is.na(DOSGRP)) |>
  select(USUBJID, DOSGRP, DOSGRPN)

adbs <- convert_blanks_to_na(adbs)

trt_levels <- adbs |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)

trt_levels_total <- c(trt_levels, "Total")

pop <- bind_rows(adbs, mutate(adbs, DOSGRP = "Total")) |>
  distinct(USUBJID, DOSGRP) |>
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total))

# --- 2. ADAE (Serious TEAEs only, PT only) ---
adae <- read_data_catalog(adamdata$adae) |>
  filter(
    SAFFL == "Y",
    TRTEMFL == "Y",
    AESER == "Y"
  ) |>
  select(USUBJID, AEDECOD) |>
  mutate(AEDECOD = coalesce(AEDECOD, "Not coded")) |>
  inner_join(adbs, by = "USUBJID") |>
  distinct(USUBJID, DOSGRP, AEDECOD)

adae <- bind_rows(adae, mutate(adae, DOSGRP = "Total")) |>
  mutate(DOSGRP = factor(DOSGRP, levels = trt_levels_total))

# --- 3. ARD using ard_stack_hierarchical ---
ard <- adae |>
  ard_stack_hierarchical(
    by = DOSGRP,
    variables = AEDECOD,
    denominator = pop,
    id = USUBJID,
    over_variables = TRUE
  )

# --- 4. Process ARD ---
processed_ard <- ard |>
  unlist_ard_columns() |>
  #filter(stat_name %in% c("n", "p")) |>
  mutate(stat = if_else(stat_name == "p", stat * 100, stat)) |>
  rename_ard_columns(columns = all_ard_groups("names"))

population_counts_ard <- processed_ard |>
  filter(variable == "DOSGRP", stat_name == "n") |>
  mutate(
    DOSGRP = variable_level,
    stat_name = "popn"
  ) |>
  select(-variable, -variable_level)


# --- 5. Apply ≥ 2 Subjects Rule (ANY treatment group) ---
pt_keep <- processed_ard |>
  filter(
    variable == "AEDECOD",
    stat_name == "n",
    DOSGRP == "Total"
  ) |>
  group_by(variable_level) |>
  summarise(max_n = max(stat, na.rm = TRUE), .groups = "drop") |>
  filter(max_n >= 2) |>
  pull(variable_level)

processed_ard <- processed_ard |>
  filter(variable != "AEDECOD" | variable_level %in% pt_keep)

# --- 6. Fix Overall Row and Final Structure ---
final_ard <- processed_ard |>
  filter(variable != "DOSGRP") |>
  mutate(
    variable_level = as.character(variable_level),
    variable_level = ifelse(
      variable == "..ard_hierarchical_overall..",
      "Patients with Any Serious TEAE",
      variable_level
    ),
    variable = ""
  ) |>
  select(DOSGRP, variable, variable_level, stat_name, stat)

final_ard <- bind_rows(processed_ard, population_counts_ard) |>
  mutate(
    variable_level = case_when(
      !is.na(variable_level) &
        variable == "..ard_hierarchical_overall.." ~ "Patients with Any TEAE",
      .default = variable_level
    ),
    variable = if_else(
      variable == "..ard_hierarchical_overall..",
      "Patients with Any TEAE",
      variable
    )
  )

# --- 7. Sort by Total Counts ---
pt_order <- final_ard |>
  filter(DOSGRP == "Total", stat_name == "n") |>
  arrange(desc(stat)) |>
  pull(variable_level)

final_ard <- final_ard |>
  mutate(
    variable_level = factor(variable_level, levels = pt_order),
    DOSGRP = factor(DOSGRP, levels = trt_levels_total)
  ) |>
  arrange(variable_level, DOSGRP) |>
  select(-context, -stat_label, -fmt_fun, -warning, -error) |>
  filter(!is.na(DOSGRP)) |>
  mutate(across(where(is.factor), as.character),
         variable = if_else(variable_level=="Patients with Any TEAE",
                            "Patients with Any TEAE",
                            variable
  )       
  )

final_ard1 <- final_ard |> 
  filter(stat_name %in% c("n","p","popn"))

write_parquet(final_ard, file.path(g_paths$dddata, "t_sf_aeser_2n_pool_r.parquet"))

# --- 8. Create tfrmt Object ---

# Define the table structure using tfrmt.
tfobj <-
  tfrmt(
    group = variable,
    label = variable_level,
    column = DOSGRP,
    value = stat,
    param = stat_name,
    sorting_cols = ,
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
    col_plan = col_plan(-variable),
    big_n = big_n_structure(param_val = "popn", n_frmt = frmt("\n(N=x)")),
    row_grp_plan = row_grp_plan(
      row_grp_structure(
        group_val = ".default",
        element_block(post_space = " ")
      ),
      label_loc = element_row_grp_loc(location = "indented")
    )
  )

# Convert the tfrmt object to a gt object for printing.
gt <- print_to_gt(tfobj, final_ard1)


# --- 7. Create and Save Output in RTF ---

# Build the RTF table object with final formatting.
rtf_obj <- gt |>
  rtf_table() |>
  rtf_col_align(
    variable_level = "left",
    starts_with(c("C", "T")) ~ "center",
    .group = "header"
  ) |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(variable_level = "Preferred Term") |>
  rtf_paginate_cols(id_columns = variable_level, split_at = 5) |>
  rtf_options(page_line_size_landscape = 27) |>
  rtf_title(
    "Table 14.3.2.13c",
    "Summary of Treatment-Emergent Serious Adverse Events >= 2 Subjects by Preferred Term",
    "(Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Safety", paste("Data as of", g_config$datadate))
  ) |>
  rtf_footer(
    "Note: Adverse Events are coded with MedDRA 28.0.",
    "Note: Treatment-emergent adverse events (TEAE) will be recorded from the start of study treatment until 30 days after the last dose of IDRX-42.",
    "Note: Each patient is counted at most once in each category."
  ) |>
  build_rtf(
    file = file.path(g_paths$output, "t_sf_aeser_2n_pool_r.rtf")
  )
