
####------------------------------------------------------------------------####
# Program Name: t_sf_dth_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Milon Haque / eh605853
# Purpose:  Summary of Death by Line of Therapy (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs]
# Output:
#   - dd [t_sf_dth_lot_pool_r]
#   - File: ../prod/output/t_sf_dth_lot_pool_r.RTF 
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------


pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "tfrmt")

adbs <-  read_data_catalog(adamdata$adbs) %>%
  filter(SAFFL == "Y" & !is.na(TRT01A)) %>%
  select(-starts_with("trt")) %>%
  rename_with(tolower) %>%
  mutate(ARM = dosgrp)

adbs2 <- adbs %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adbs)


pop <- adbs2 %>% select(usubjid, lotcat, ARM)


fin <- adbs2 %>%
  mutate(
    dthcaus30 = ifelse(!is.na(dthcaus) & dth30tfl == "Y", dthcaus, ""),
    dthcaus30a = ifelse(!is.na(dthcaus) & dtha30fl == "Y", dthcaus, "")
  ) %>%
  filter(!is.na(lotcat)) %>%
  mutate(
    lotcat = factor(
      lotcat,
      levels = c("1st-line", "2nd-line", "3rd or later-line")
    ),
    lotcatx = factor(
      lotcat,
      c("1st-line", "2nd-line", "3rd or later-line"),
      c("1st-line", "2nd-line", "3rd or later-line")
    ),
    ARM = factor(
      ARM,
      levels = c(
        "C120",
        "T200/C240",
        "T300/C400",
        "T500",
        "T600/C600",
        "C800",
        "C1200",
        "Total"
      )
    ),
  )


ard1 <- ard_stack_hierarchical(
  data = fin,
  by = c(ARM, lotcat),
  variables = c(dthfl),
  statistic = ~ c("n", "p"), # Calculate count and percentage
  denominator = pop,
  id = usubjid
) %>%
  mutate(variable = "DTHFL", ord = 1) %>%
  filter(!is.na(group1) & stat_name != 'N')


ard2 <- ard_stack_hierarchical(
  data = fin,
  by = c(ARM, lotcat),
  variables = c(dthcaus),
  statistic = ~ c("n", "p"), # Calculate count and percentage
  denominator = pop,
  id = usubjid
) %>%
  mutate(variable = "DTHCAUS", ord = 2) %>%
  filter(!is.na(group1) & stat_name != 'N')


fin2 <- fin %>% filter(!is.na(dthcaus) & dth30tfl == "Y")

ard3 <- ard_stack_hierarchical(
  data = fin2,
  by = c(ARM, lotcat),
  variables = c(dth30tfl),
  statistic = ~ c("n", "p"), # Calculate count and percentage
  denominator = pop,
  id = usubjid
) %>%
  mutate(variable = "DTH30TFL", ord = 3) %>%
  filter(!is.na(group1) & stat_name != 'N')


ard4 <- ard_stack_hierarchical(
  data = fin2,
  by = c(ARM, lotcat),
  variables = c(dthcaus30),
  statistic = ~ c("n", "p"), # Calculate count and percentage
  denominator = pop,
  id = usubjid
) %>%
  mutate(variable = "DTH30", ord = 4) %>%
  filter(!is.na(group1) & stat_name != 'N')


fin3 <- fin %>% filter(!is.na(dthcaus) & dtha30fl == "Y")

ard5 <- ard_stack_hierarchical(
  data = fin3,
  by = c(ARM, lotcat),
  variables = c(dtha30fl),
  statistic = ~ c("n", "p"), # Calculate count and percentage
  denominator = pop,
  id = usubjid
) %>%
  mutate(variable = "DTHA30FL", ord = 5) %>%
  filter(!is.na(group1) & stat_name != 'N')


ard6 <- ard_stack_hierarchical(
  data = fin3,
  by = c(ARM, lotcat),
  variables = c(dthcaus30a),
  statistic = ~ c("n", "p"), # Calculate count and percentage
  denominator = pop,
  id = usubjid
) %>%
  mutate(variable = "DTH30A", ord = 6) %>%
  filter(!is.na(group1) & stat_name != 'N')


tot <- bind_rows(ard1, ard2, ard3, ard4, ard5, ard6) %>%
  select(
    group1,
    group2,
    variable,
    stat_name,
    stat,
    variable_level,
    group1_level,
    group2_level,
    ord
  )

pop <- adbs %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adbs) %>%
  filter(!is.na(lotcat))

# --- Add Big N ---

# Define all desired ARM and Exon levels
all_arms <- c(
  "C120",
  "T200/C240",
  "T300/C400",
  "T500",
  "T600/C600",
  "C800",
  "C1200",
  "Total"
)
all_lot <- c("1st-line", "2nd-line", "3rd or later-line")

Bign <- pop %>%
  count(ARM, lotcat) %>%
  complete(
    ARM = all_arms,
    lotcat = all_lot,
    fill = list(n = 0)
  ) %>%
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
    group1_level,
    group2,
    group2_level,
    
    stat_name,
    stat
  )


ard <- bind_rows(tot, Bign)

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
    variable = case_when(
      variable == "DTHFL" ~ "Patient Deaths on Study, n(%)",
      variable == "DTHCAUS" ~ "Primary Cause of Death",
      variable ==
        "DTH30TFL" ~ "Patient Deaths within 30 Days of Last IDRX-42 Dose, n(%)",
      variable == "DTH30" ~ "Primary Cause of Death within 30 Days",
      variable ==
        "DTHA30FL" ~ "Patient Deaths after 30 Days of Last IDRX-42 Dose, n(%)",
      variable == "DTH30A" ~ "Primary Cause of Death after 30 Days",
      .default = variable
    ),
    label = ifelse(label == "Y", variable, label),
    stat = ifelse(is.na(stat), 0, stat)
  ) %>%
  select(ARM, variable, lotcat, stat_name, stat, label, ord) %>%
  mutate(
    ord2 = case_when(
      # For CMLINE
      variable == "Primary Cause of Death" &
        str_trim(label) == "Primary Disease Progression" ~ 1,
      variable == "Primary Cause of Death" &
        str_trim(label) == "Adverse Event" ~ 2,
      variable == "Primary Cause of Death" & str_trim(label) == "Unknown" ~ 3,
      
      variable == "Primary Cause of Death within 30 Days" &
        str_trim(label) == "Primary Disease Progression" ~ 1,
      variable == "Primary Cause of Death within 30 Days" &
        str_trim(label) == "Adverse Event" ~ 2,
      variable == "Primary Cause of Death within 30 Days" &
        str_trim(label) == "Unknown" ~ 3,
      
      variable == "Primary Cause of Death after 30 Days" &
        str_trim(label) == "Primary Disease Progression" ~ 1,
      variable == "Primary Cause of Death after 30 Days" &
        str_trim(label) == "Adverse Event" ~ 2,
      variable == "Primary Cause of Death after 30 Days" &
        str_trim(label) == "Unknown" ~ 3,
      TRUE ~ NA_real_
    ),
    
    variable = ifelse(
      variable %in%
        c(
          "Primary Cause of Death",
          "Primary Cause of Death within 30 Days",
          "Primary Cause of Death after 30 Days"
        ),
      paste0(" ", variable),
      variable
    )
  ) %>%
  arrange(lotcat, ord, ord2, variable, label) %>%
  select(-c(ord, ord2))

ard_tbl <- ard_tbl %>%
  filter(
    !(variable %in%
        c(
          " Primary Cause of Death",
          " Primary Cause of Death within 30 Days",
          " Primary Cause of Death after 30 Days"
        ) &
        stat == 0)
  ) %>% mutate(
    
    lotcat=case_when(
      lotcat=="1"~"1st-line",
      lotcat=="2"~"2nd-line",
      lotcat=="3"~"3rd or later-line",
      TRUE          ~ lotcat
    )
    
  )

arrow::write_parquet(ard_tbl, file.path(g_paths$dddata, "t_sf_dth_lot_pool_r.parquet"))


# ────────────────────────────────
# 9. Table Formatting (tfrmt)
# ────────────────────────────────

THL <- tfrmt(
  group   = c(lotcat, variable),
  label   = label,
  param   = stat_name,
  value   = stat,
  column  = ARM,
  
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
        "  {n} {p}",
        n = frmt("xxx"),
        p = frmt_when(
          "==1"     ~ frmt("(100%)"),
          ">=0.995" ~ frmt("(>99%)"),
          "==0"     ~ frmt(""),
          "<=0.01"  ~ frmt("( <1%)"),
          "TRUE"    ~ frmt("( xx%)", transform = ~ . * 100)
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
    #row_noorphan_col = grp,
    #drop_columns = grp
  ) |> 
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.08in") |>
  rtf_col_label(label = "") |> 
  rtf_paginate_cols(id_columns =label, split_at = 5) |> 
  rtf_title(
    "Table 14.3.3.6c",
    "Summary of Death by Line of Therapy (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Safety", paste("Data as of", g_config$datadate)) 
  ) |> 
  
  build_rtf(file = file.path(g_paths$output, "t_sf_dth_lot_pool_r.rtf"))
