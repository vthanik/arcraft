####------------------------------------------------------------------------####
# Program Name: t_sf_dssstt_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Shilpa Kolli / sk575206
# Purpose:  Summary of Disease Status by Line of Therapy (Phase 1 & 1b pooled) 

#
# Input:
#   - adam [adbs, adfa]
# Output:
#   - dd [t_sf_dssstt_lot_pool_r]
#   - File: ../prod/output/t_sf_dssstt_lot_pool_r.RTF
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- 0. Setup and Library Loading ---

pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "tfrmt")

round_half_up <- function(x, digits = 0) {
  posneg <- sign(x)
  z <- abs(x) * 10^digits + 0.5
  z <- trunc(z)
  z <- z / 10^digits
  return(z * posneg)
}

adbs <-  read_data_catalog(adamdata$adbs) %>%
  filter(SAFFL == "Y" & !is.na(LOTCAT) & !is.na(TRT01A)) %>%
  select(-starts_with("trt")) %>%
  rename_with(tolower) %>%
  mutate(ARM = dosgrp)

adfa <-  read_data_catalog(adamdata$adfa) %>%
  rename_with(tolower) %>%
  mutate(
    avalc = if_else(
      paramcd %in% c("SIZE", "MIOTCNT"),
      str_replace_all(avalc, " ", ""), # SAS compress()
      avalc
    )
  )

# Merge by subject
adfa <- inner_join(adbs, adfa, by = "usubjid")

# Add Total arm
adfa2 <- adfa %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adfa)

# ────────────────────────────────
# 2. Continuous Summaries (TIMGIST, TIMCMS)
# ────────────────────────────────

fa1 <- adfa2 %>% filter(paramcd == "TIMGIST")

sum1 <- ard_stack(
  data = fa1,
  .by = c(ARM, lotcat),
  ard_summary(
    variables = aval,
    statistic = ~ continuous_summary_fns(c(
      "N",
      "mean",
      "sd",
      "median",
      "min",
      "max"
    ))
  )
) %>%
  filter(!is.na(group1)) %>%
  mutate(variable = "TIMGIST") %>%
  select(
    group1,
    group2,
    variable,
    stat_name,
    stat,
    variable_level,
    group1_level,
    group2_level
  )

fa2 <- adfa2 %>% filter(paramcd == "TIMCMS")

sum2 <- ard_stack(
  data = fa2,
  .by = c(ARM, lotcat),
  ard_summary(
    variables = aval,
    statistic = ~ continuous_summary_fns(c(
      "N",
      "mean",
      "sd",
      "median",
      "min",
      "max"
    ))
  )
) %>%
  filter(!is.na(group1)) %>%
  mutate(variable = "TIMCMS") %>%
  select(
    group1,
    group2,
    variable,
    stat_name,
    stat,
    variable_level,
    group1_level,
    group2_level
  )

# ────────────────────────────────
# 3. ARM mapping
# ────────────────────────────────

BPTRTN <- c(
  "C120" = "C120",
  "T200/C240" = "T200/C240",
  "T300/C400" = "T300/C400",
  "T500" = "T500",
  "T600/C600" = "T600/C600",
  "C800" = "C800",
  "C1200" = "C1200"
)

# ────────────────────────────────
# 4. Mutation Variables
# ────────────────────────────────

# Mutation type
fin3 <- adfa2 %>%
  filter(paramcd == "MUTATION") %>%
  mutate(
    MUT = factor(avalc, c("KIT", "PDGFRA", "MULTIPLE"))
  ) %>%
  distinct(usubjid, lotcat, ARM, MUT)

ard3 <- ard_stack(
  data = fin3,
  .by = c(ARM, lotcat),
  ard_categorical(variables = c(MUT)),
  .overall = TRUE,
  .total_n = TRUE
) %>%
  mutate(variable = "MUT") %>%
  filter(!is.na(group1), stat_name != "N")

# KIT mutation location
fin4 <- adfa2 %>%
  filter(paramcd == "MUTLOC", gistmut == "KIT") %>%
  mutate(
    GSMUT = factor(
      avalc,
      c(
        "Exon 11 (JM)",
        "Exon 9 (ECD)",
        "Exon 13 (ATP pocket)",
        "Exon 14 (ATP pocket)",
        "Exon 17 (A-loop)",
        "Other"
      )
    )
  ) %>%
  distinct(usubjid, lotcat, ARM, GSMUT)

ard4 <- ard_stack(
  data = fin4,
  .by = c(ARM, lotcat),
  ard_categorical(variables = c(GSMUT)),
  .overall = TRUE,
  .total_n = TRUE
) %>%
  mutate(variable = "GSMUT") %>%
  filter(!is.na(group1), stat_name != "N")

# PDGFRA mutation location
fin5 <- adfa2 %>%
  filter(paramcd == "MUTLOC", gistmut == "PDGFRA") %>%
  mutate(
    GSMUTX = factor(
      avalc,
      c(
        "Exon 11 (JM)",
        "Exon 9 (ECD)",
        "Exon 13 (ATP pocket)",
        "Exon 14 (ATP pocket)",
        "Exon 17 (A-loop)",
        "Other"
      )
    )
  ) %>%
  distinct(usubjid, lotcat, ARM, GSMUTX)

ard5 <- ard_stack(
  data = fin5,
  .by = c(ARM, lotcat),
  ard_categorical(variables = c(GSMUTX)),
  .overall = TRUE,
  .total_n = TRUE
) %>%
  mutate(variable = "GSMUTX") %>%
  filter(!is.na(group1), stat_name != "N")

# ────────────────────────────────
# 5. Size and Mitotic Count
# ────────────────────────────────

# Tumor size
fin6 <- adfa2 %>%
  filter(paramcd == "SIZE") %>%
  mutate(
    SIZE = factor(avalc, c("<2", "2.1-5", "5.1-10", ">10", "Unknown"))
  ) %>%
  distinct(usubjid, lotcat, ARM, SIZE)

ard6 <- ard_stack(
  data = fin6,
  .by = c(ARM, lotcat),
  ard_categorical(variables = c(SIZE)),
  .overall = TRUE,
  .total_n = TRUE
) %>%
  mutate(variable = "SIZE") %>%
  filter(!is.na(group1), stat_name != "N")

# Mitotic count
fin7 <- adfa2 %>%
  filter(paramcd == "MIOTCNT") %>%
  mutate(
    MIOTCNT = factor(avalc, c("<5/50", "6-10/50", ">10/50", "Unknown"))
  ) %>%
  distinct(usubjid, lotcat, ARM, MIOTCNT)

ard7 <- ard_stack(
  data = fin7,
  .by = c(ARM, lotcat),
  ard_categorical(variables = c(MIOTCNT)),
  .overall = TRUE,
  .total_n = TRUE
) %>%
  mutate(variable = "MIOTCNT") %>%
  filter(!is.na(group1), stat_name != "N")

# ────────────────────────────────
# 6. Combine all ARDs
# ────────────────────────────────

tot <- bind_rows(sum1, sum2, ard3, ard4, ard5, ard6, ard7) %>%
  select(
    group1,
    group2,
    variable,
    stat_name,
    stat,
    variable_level,
    group1_level,
    group2_level
  )

# ────────────────────────────────
# 7. Population and Big N
# ────────────────────────────────

pop <- adbs %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adbs)


Bign <- pop %>%
  count(ARM, lotcat) %>% # counts existing combinations
  complete(ARM, lotcat, fill = list(n = 0)) %>% # add missing with n=0
  mutate(
    stat_name = "bigN",
    stat = map(n, ~.x),
    #variable_level = map(ARM, ~.x),
    #variable = "ARM",
    group1 = "ARM",
    group1_level = map(ARM, ~.x),
    group2 = "lotcat",
    group2_level = map(lotcat, ~.x)
  ) %>%
  select(
    group1,
    group2,
    
    stat_name,
    stat,
    
    group1_level,
    group2_level
  )


ard <- bind_rows(tot, Bign)
# ────────────────────────────────
# 8. Final ARD Table Assembly
# ────────────────────────────────

ard_tbl <- ard %>%
  rename_ard_columns(columns = c("group1", "group2")) |>
  unlist_ard_columns() %>%
  mutate(
    label = map_chr(
      variable_level,
      ~ if (length(.x) == 0) NA_character_ else as.character(.x[[1]])
    ),
    
    grp = case_when(
      variable %in% c("TIMGIST", "TIMCMS")~ 1,
      variable %in% c("MUT", "GSMUT", "GSMUTX")~ 2,
      variable %in% c("SIZE", "MIOTCNT" )~ 3,
      TRUE ~ NA_real_
    ),
    
    
    ord = case_when(
      variable =="TIMGIST"~ 1,
      variable=="TIMCMS"~ 2,
      variable == "MUT"~3,
      variable=="GSMUT"~ 4,
      variable == "GSMUTX"~5,
      variable=="SIZE"~ 6,
      variable == "MIOTCNT"~7,
      TRUE ~ NA_real_
    ),
    
    
    trtn = case_when(
      ARM == "C120" ~ 1,
      ARM == "T200/C240" ~ 2,
      ARM == "T300/C400" ~ 3,
      ARM == "T500" ~ 4,
      ARM == "T600/C600" ~ 2,
      ARM == "C800" ~ 5,
      ARM == "C1200" ~ 6,
      ARM == "Total" ~ 7,
    ),
    
    
    label = if_else(is.na(label), stat_name, label),
    stat = ifelse(variable %in% c("TIMGIST", "TIMCMS") & is.na(stat), NA, stat),
    stat = ifelse(
      variable %in%
        c("MUT", "GSMUT", "GSMUTX", "SIZE", "MIOTCNT") &
        is.na(stat),
      0,
      stat
    ),
    
    variable = case_when(
      variable ==
        "TIMGIST" ~ "Time Since Date of Initial GIST Diagnosis (months)",
      variable ==
        "TIMCMS" ~ "Time Since Date of Confirmed Metastatic and/or Surgically Unresectable GIST Diagnosis (months)",
      variable == "MUT" ~ "Mutation",
      variable == "GSMUT" ~ "Location of KIT Mutation",
      variable == "GSMUTX" ~ "Location of PDGFRA Mutation Other",
      variable == "SIZE" ~ "Size of the Primary Tumor (cm)",
      variable == "MIOTCNT" ~ "Mitotic Count of Primary Tumor",
      .default = variable
    ),
  ) %>% arrange(lotcat, trtn, ord) %>%
  select(ARM, variable, lotcat, stat_name, stat, label, grp) |> 
  mutate(label = case_when(
    stat_name == "N" ~ "n",
    stat_name == "mean" ~ "Mean",
    stat_name == "sd" ~ "SD",
    stat_name == "median" ~ "Median",
    stat_name == "min" ~ "Min.",
    stat_name == "max" ~ "Max.",
    .default = label 
  ))


arrow::write_parquet(ard_tbl, file.path(g_paths$dddata, "t_sf_dssstt_lot_pool_r.parquet"))


# ────────────────────────────────
# 9. Table Formatting (tfrmt)
# ────────────────────────────────

THL <- tfrmt(
  group = c(lotcat, variable),
  label = label,
  param = stat_name,
  value = stat,
  column = ARM,
  
  body_plan = body_plan(
    # Default display
    frmt_structure(group_val = ".default", label_val = ".default", frmt("xxx")),
    
    # Percent display for n and p
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{n} {p}",
        n = frmt("xxx"),
        p = frmt_when(
          "==1" ~ frmt("(100%)"),
          ">=0.995" ~ frmt("(>99%)"),
          "==0" ~ frmt(""),
          "<=0.01" ~ frmt("( <1%)"),
          "TRUE" ~ frmt("( xx%)", transform = ~ . * 100)
        )
      )
    ),
    
    # mean, median, min, max → 1 decimal
    frmt_structure(
      group_val = ".default",
      label_val = c("Mean", "Median", "Min.", "Max."),
      frmt("xxx.x", missing = "")
    ),
    
    # sd → 2 decimals
    frmt_structure(
      group_val = ".default",
      label_val = "SD",
      frmt("xxx.x", missing = "")
    )
  ),
  
  big_n = big_n_structure(param_val = "bigN", n_frmt = frmt("\n(N=x)"), by_page = TRUE),
  
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    label_loc = element_row_grp_loc(location = "spanning")
  ),
  page_plan = page_plan(
    page_structure(group_val = list(lotcat = ".default"))
  )
)

gt <- print_to_gt(THL, ard_tbl)

# --- 7. Create and Save Output in RTF ---

rtf_obj <- gt |> 
  rtf_table(
    page_group_label = paste("Line of Therapy:", lotcat),
    row_noorphan_col = grp,
    drop_columns = grp
  ) |> 
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(label = "") |> 
  rtf_paginate_cols(id_columns =label, split_at = 5) |> 
  rtf_title(
    "Table 14.1.5e",
    "Summary of Disease Status by Line of Therapy (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Safety", paste("Data as of", g_config$datadate)) 
  ) |> 
  rtf_footer(
    "Note: Time since date of diagnosis is the difference in months between the date of first IDRX-42 dose and date of initial diagnosis.",
    "Note: KIT mutation status is based on local testing results and not derived from ctDNA."
  ) |> 
  build_rtf(file = file.path(g_paths$output, "t_sf_dssstt_lot_pool_r.rtf"))