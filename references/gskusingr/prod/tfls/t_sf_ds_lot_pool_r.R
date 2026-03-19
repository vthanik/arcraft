####------------------------------------------------------------------------####
# Program Name: t_sf_ds_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Naga laxmi Chinthala / nc450888
# Purpose:  Summary of Disposition by Line of Therapy (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adcm]
# Output:
#   - dd [t_sf_ds_lot_pool_r]
#   - File: ../prod/output/t_sf_ds_lot_pool_r.RTF
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes: Copied from Internal 02
#
#-------------------------------------------------------------------------------

# --- 0. Setup and Library Loading ---

#source("/mnt/code/functions/r_setup.R")

libs <- c("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "tfrmt")
pkg_attach(libs)

adbs <-  read_data_catalog(adamdata$adbs) %>%
  select(-ARM) %>%
  filter(SAFFL == "Y" & !is.na(DOSGRP)) %>%
  mutate(arm = DOSGRP) 

pop <- adbs %>%
  mutate(arm = "Total", DOSGRPN = 999) %>%
  bind_rows(adbs) %>%
  rename_with(tolower)

fin <- pop %>% select(usubjid, lotcat, arm, eotstt, dctreas, eosstt, dcsreas)

ard1 <- ard_tabulate(
  data = fin,
  by = c('arm', 'lotcat'),
  variable = c(eotstt, dctreas, eosstt, dcsreas),
  denominator = fin,
  statistic = ~ c("n", "p")
) %>%
 # unlist_ard_columns() %>%
  filter(!is.na(group1) & stat_name != 'N') %>%
  filter(variable_level != "")

Bign <- pop %>%
  filter(!is.na(lotcat)) %>%
  count(arm, lotcat) %>% # counts existing combinations
  complete(arm, lotcat, fill = list(n = 0)) %>% # add missing with n=0
  mutate(
    stat_name = "bigN",
    stat = map(n, ~.x),
    #variable_level = map(arm, ~.x),
    #variable = "arm",
    group1 = "arm",
    group1_level = map(arm, ~.x),
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


ard <- bind_rows(ard1, Bign)

ard_tbl <-
  ard |>
  # rename cols, coalesce variable levels/stat_labels, unnest
  rename_ard_columns(columns = c("group1", "group2")) |>
  unlist_ard_columns() |>
  mutate(
    label = map_chr(
      variable_level,
      ~ {
        if (length(.x) == 0) {
          return(NA_character_) # Assign NA if the element is empty
        }
        as.character(.x[[1]]) # Convert to character
      }
    )
  ) %>%
  mutate(
    grp = case_when(
      variable %in% c("eotstt", "dctreas")~ 1,
      variable %in% c("eosstt","dcsreas" )~ 2,
      TRUE ~ NA_real_
    ),
    
    trtn = case_when(
      arm == "C120" ~ 1,
      arm == "T200/C240" ~ 2,
      arm == "T300/C400" ~ 3,
      arm == "T500" ~ 4,
      arm == "T600/C600" ~ 5,
      arm == "C800" ~ 6,
      arm == "C1200" ~ 7,
      arm == "Total" ~ 8,
    ),
    
    variable = case_when(
      variable == "eotstt" ~ "Treatment Status",
      variable == "dctreas" ~ "Reason for Treatment Discontinuation",
      variable == "eosstt" ~ "Study Status",
      variable == "dcsreas" ~ "Reason for Study Discontinuation",
      .default = variable
    ),
    stat = ifelse(is.na(stat), 0, stat),
    
    #variable = ifelse(stat_name == "bigN", "NA", variable),
    #label = ifelse(stat_name == "bigN", "NA", label),
    
    
  )%>%  arrange(lotcat, trtn) %>%
  select(arm, variable, lotcat, stat_name, stat, label, grp) 


arrow::write_parquet(ard_tbl, file.path(g_paths$dddata, "t_sf_ds_lot_pool_r.parquet"))




# ────────────────────────────────
# 9. Table Formatting (tfrmt)
# ────────────────────────────────

THL <- tfrmt(
  group   = c(lotcat, variable),
  label   = label,
  param   = stat_name,
  value   = stat,
  column  = arm,
  
  body_plan = body_plan(
    # Default display
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt("xxx")
    ),
    
    # Percent display for n and p
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{n} {p}",
        n = frmt("xxx"),
        p = frmt_when(
          "==1"     ~ frmt("(100%)"),
          ">=0.995" ~ frmt("(>99%)"),
          "==0"     ~ frmt(""),
          "<=0.01"  ~ frmt("(<1%)"),
          "TRUE"    ~ frmt("(xxx%)", transform = ~ . * 100)
        )
      )
    )
  ),
  
  big_n = big_n_structure(
    param_val = "bigN",
    n_frmt    = frmt("\n(N=x)"),
    by_page   = TRUE
  ),
  
  row_grp_plan = row_grp_plan(
    row_grp_structure(
      group_val = ".default",
      element_block(post_space = " ")
    ),
    label_loc = element_row_grp_loc(location = "spanning")
  ),
  
  page_plan = page_plan(
    page_structure(
      group_val = list(lotcat = ".default")
    )
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
    "Table 14.1.2e",
    "Summary of Disposition by Line of Therapy (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Safety", paste("Data as of", g_config$datadate)) 
  ) |> 
  
  build_rtf(file = file.path(g_paths$output, "t_sf_ds_lot_pool_r.rtf"))