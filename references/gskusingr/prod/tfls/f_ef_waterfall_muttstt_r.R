####------------------------------------------------------------------------####
# Program Name: f_ef_waterfall_muttstt_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Vignesh Thanikachalam / vt704670
# Purpose: Waterfall Plot by KIT (Exon) Mutation Status by Line of Therapy
# (Phase 1 & 1b pooled)
#
# Input:
#   - ADAM: ADBS, ADTR, ADEFF
# Output:
#   - File: ../prod/output/f_ef_waterfall_muttstt_r.rtf
#
# External files called:
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- 0. Library Loading ---

pkg_load(
  "dplyr",
  "forcats",
  "stringr",
  "tidyr",
  "purrr",
  "lubridate",
  "survival",
  "ggplot2",
  "patchwork",
  "glue"
)

# --- 1. Load Data and Define Factor Levels ---
# Loads ADaM dataset (ADBS) and defines ordered factor levels
# for treatment groups (DOSGRP) and line of therapy categories (LOTCAT).
adbs_safety <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y", !is.na(DOSGRP), !is.na(LOTCAT)) |> 
  select(USUBJID, SUBJID, DOSGRP, DOSGRPN, LOTCAT, LOTCATN, EOTSTT, TRTSDT, 
         TRTEDT, DTHDT, starts_with("CTEXON"), GISTMLOC)

# Isolate mutation status from wide-format columns.
mutation_data <- adbs_safety |>
  mutate(
    EXON9 = if_else(CTEXON9 == "Y" | str_detect(GISTMLOC, "EXON 9"), "Y", "N"),
    EXON11 = if_else(CTEXON11 == "Y" | str_detect(GISTMLOC, "EXON 11"), "Y", "N"),
    EXON13 = if_else(CTEXON13 == "Y" | str_detect(GISTMLOC, "EXON 13"), "Y", "N"),
    EXON14 = if_else(CTEXON14 == "Y" | str_detect(GISTMLOC, "EXON 14"), "Y", "N"),
    EXON17 = if_else(CTEXON17 == "Y" | str_detect(GISTMLOC, "EXON 17"), "Y", "N")
  ) |> 
  pivot_longer(
    cols = starts_with("EXON"),
    names_to = "EXON_VAR",
    values_to = "EXON_FLAG"
  ) |>
  filter(EXON_FLAG == "Y") |>
  mutate(
    MUTSTT = case_match(
      EXON_VAR,
      "EXON9" ~ "Exon 9",
      "EXON11" ~ "Exon 11",
      "EXON13" ~ "Exon 13",
      "EXON14" ~ "Exon 14",
      "EXON17" ~ "Exon 17"
    )
  ) |>
  filter(!is.na(MUTSTT)) |>
  mutate(
    MUTSTT = factor(
      MUTSTT, 
      levels = c("Exon 9", "Exon 11", "Exon 13", "Exon 14", "Exon 17"))
  ) |> 
  distinct()

treatment_group_levels <- adbs_safety |>
  distinct(DOSGRPN, DOSGRP) |>
  arrange(DOSGRPN) |>
  pull(DOSGRP)

lot_category_levels <- adbs_safety |>
  distinct(LOTCATN, LOTCAT) |>
  arrange(LOTCATN) |>
  pull(LOTCAT)

# --- 2. Prepare Analysis Dataset ---
# Combines data from ADBS, ADTR (lesion sizes), and ADEFF (BOR)
# to calculate the best percentage change from baseline (`waterfall_analysis_data`)
# for each subject, ready for waterfall plot visualization.
adtr_target_lesions_raw <- read_data_catalog(adamdata$adtr) |>
  filter(PARAMCD == "LDIAM", PARCAT1 == 'TARGET', !is.na(AVALC))

adtr_lesion_summary <- adtr_target_lesions_raw |>
  summarise(SIZE = sum(AVAL), .by = c(USUBJID, AVISITN)) |>
  left_join(
    adtr_target_lesions_raw |>
      distinct(USUBJID, AVISITN, AVISIT, ABLFL, ANL01FL),
    by = c("USUBJID", "AVISITN")
  )

adeff_bor_data <- read_data_catalog(adamdata$adeff) |>
  filter(PARAMCD == "BOR", ACAT2 == "INVESTIGATOR") |>
  mutate(
    AVALC = if_else(
      AVALC %in% c("6 <= SD < 16 weeks", "SD >= 16 weeks"),
      "SD",
      AVALC
    )
  ) |>
  select(USUBJID, BOR = AVALC)

subject_link_data <- left_join(
  adbs_safety |>
    distinct(USUBJID, SUBJID, DOSGRP, LOTCAT, EOTSTT) |>
    mutate(
      DOSGRP = factor(DOSGRP, levels = treatment_group_levels),
      LOTCAT = factor(LOTCAT, levels = lot_category_levels),
      DISCFL = grepl("Discontinued", EOTSTT, ignore.case = TRUE)
    ),
  adeff_bor_data,
  by = "USUBJID"
)

waterfall_analysis_data <-
  left_join(
    subject_link_data,
    full_join(
      adtr_lesion_summary |>
        filter(ANL01FL == "Y") |>
        select(USUBJID, AVISITN, AVISIT, PBL_SIZE = SIZE),
      adtr_lesion_summary |>
        filter(ABLFL == "Y") |>
        select(USUBJID, BL_SIZE = SIZE),
      by = "USUBJID"
    ),
    by = "USUBJID"
  ) |>
  mutate(PCHG = ((PBL_SIZE - BL_SIZE) / BL_SIZE) * 100) |>
  slice_min(order_by = PCHG, n = 1, by = USUBJID, with_ties = FALSE) |> 
  full_join(mutation_data |> select(USUBJID, MUTSTT), by = "USUBJID") |> 
  filter(!is.na(MUTSTT))

# --- 3. Generate Plots by DOSGRP (All LOTs) ---

lot_data <- waterfall_analysis_data |>
  dplyr::group_split(LOTCAT, MUTSTT)

plot_list <- map(lot_data, \(x) {
  lotcat <- as.character(unique(x$LOTCAT))
  mutstt <- as.character(unique(x$MUTSTT))
  colors_by_trt <- which(treatment_group_levels %in% unique(x$DOSGRP))
  fig_waterfall(
    data = x,
    subj_col = SUBJID,
    pchg_col = PCHG,
    group_col = DOSGRP,
    group_levels = treatment_group_levels,
    discont_col = DISCFL,
    include_subj_labels = TRUE,
    subjects_per_page = 50,
    title = glue::glue("Line of Therapy: {lotcat}, KIT Mutation: {mutstt}"),
    colors = g_config$colors
  )
})

# --- 5. Save Outputs ---

rtf_obj <- purrr::flatten(plot_list) |>
  rtf_figure() |>
  rtf_title(
    "Figure 14.2.1f",
    "Waterfall Plot by KIT (Exon) Mutation Status by Line of Therapy (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Efficacy", paste("Data as of", g_config$datadate))
  ) |>
  rtf_footer(
    "X = Discontinued"
  ) |>
  build_rtf(
    file = file.path(g_paths$output, "f_ef_waterfall_muttstt_r.rtf")
  )