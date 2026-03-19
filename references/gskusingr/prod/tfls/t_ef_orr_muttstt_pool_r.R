####------------------------------------------------------------------------####
# Program Name: t_ef_orr_muttstt_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Naga Laxmi Chinthala / nc450888
# Purpose: Summary of Best Overall Response and Objective Response Rate by Mutation Status (Phase 1 & 1b pooled)
#          (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adeff]
# Output:
#   - dd [t_ef_orr_muttstt_pool_r]
#   - File: ../prod/output/t_ef_orr_muttstt_pool_r.RTF
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
# Copy from internal 02
#-------------------------------------------------------------------------------

# --- 0. Setup and Library Loading ---

#source("/mnt/code/functions/r_setup.R")

pkg_load("gt","tfrmt","admiral","dplyr","forcats","cards","cardx","stringr","tidyr","arrow","tibble","docorator","purrr")

adbs <-  read_data_catalog(adamdata$adbs) %>%
  filter(EFFL == "Y" & !is.na(TRT01A)) %>%
  select(-starts_with("trt")) %>%
  rename_with(tolower) %>%
  mutate(ARM = dosgrp)

adbsx <- adbs %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adbs)

# --- Create population dataset by mutation status ---
pop <- adbsx %>%
  filter(ctexon9 == "Y" | str_detect(gistmloc, "EXON 9")) %>%
  mutate(mutstt = "Exon 9", mutsttn = 1) %>%
  
  # Exon 11
  bind_rows(
    adbsx %>%
      filter(ctexon11 == "Y" | str_detect(gistmloc, "EXON 11")) %>%
      mutate(mutstt = "Exon 11", mutsttn = 2)
  ) %>%
  
  # Exon 13
  bind_rows(
    adbsx %>%
      filter(ctexon13 == "Y" | str_detect(gistmloc, "EXON 13") ) %>%
      mutate(mutstt = "Exon 13", mutsttn = 3)
  ) %>%
  
  # Exon 14
  bind_rows(
    adbsx %>%
      filter(ctexon14 == "Y" | str_detect(gistmloc, "EXON 14")) %>%
      mutate(mutstt = "Exon 14", mutsttn = 4)
  ) %>%
  
  # Exon 17
  bind_rows(
    adbsx %>%
      filter(ctexon17 == "Y" | str_detect(gistmloc, "EXON 17")) %>%
      mutate(mutstt = "Exon 17", mutsttn = 5)
  )

# --- Read ADEF dataset ---
adf <- read_data_catalog(adamdata$adeff) %>% 
  rename_with(tolower) %>%
  filter(acat2 == "INVESTIGATOR", paramcd == "BOR")

adf <- inner_join(adbs, adf, by = "usubjid")

adf2 <- adf %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adf)

# --- Add mutation flags for each exon ---
adf3 <- adf2 %>%
  filter(ctexon9 == "Y" | str_detect(gistmloc, "EXON 9")) %>%
  mutate(mutstt = "Exon 9", mutsttn = 1) %>%
  
  bind_rows(
    adf2 %>%
      filter(ctexon11 == "Y" | str_detect(gistmloc, "EXON 11")) %>%
      mutate(mutstt = "Exon 11", mutsttn = 2)
  ) %>%
  
  bind_rows(
    adf2 %>%
      filter(ctexon13 == "Y" | str_detect(gistmloc, "EXON 13")) %>%
      mutate(mutstt = "Exon 13", mutsttn = 3)
  ) %>%
  
  bind_rows(
    adf2 %>%
      filter(ctexon14 == "Y" | str_detect(gistmloc, "EXON 14")) %>%
      mutate(mutstt = "Exon 14", mutsttn = 4)
  ) %>%
  
  bind_rows(
    adf2 %>%
      filter(ctexon17 == "Y" | str_detect(gistmloc, "EXON 17")) %>%
      mutate(mutstt = "Exon 17", mutsttn = 5)
  )

# --- Create BOR response table ---
bor <- adf3 %>%
  mutate(
    avalc = as.character(avalc),
    resn = case_when(
      toupper(avalc) == "CR" ~ 1L,
      toupper(avalc) == "PR" ~ 2L,
      toupper(avalc) == "SD" ~ 3L,
      toupper(avalc) == "PD" ~ 4L,
      toupper(avalc) == "NE" ~ 5L,
      TRUE ~ 6L
    ),
    typ = ifelse(resn %in% c(1L, 2L), 1L, 2L),
    avalc = ifelse(str_detect(avalc, "SD"), "SD", avalc)
  )

# --- Prepare Best Overall Response dataset ---
fin1 <- bor %>%
  filter(acat2 == "INVESTIGATOR", paramcd == "BOR") %>%
  mutate(
    BOR = factor(
      avalc,
      c("CR", "PR", "SD", "PD", "NE"),
      c(
        "COMPLETE RESPONSE (CR)",
        "PARTIAL RESPONSE (PR)",
        "STABLE DISEASE (SD)",
        "PROGRESSIVE DISEASE (PD)",
        "NOT EVALUABLE"
      )
    )
  )

# --- Stack categorical data for BOR ---
ard1 <- ard_stack(
  data = fin1,
  .by = c(ARM, mutstt),
  ard_categorical(variables = c(BOR)),
  .overall = TRUE,
  .total_n = TRUE
) %>%
  mutate(variable = "BOR") %>%
  filter(!is.na(group1) & stat_name != "N") %>%
  select(
    group1,
    group1_level,
    group2,
    group2_level,
    variable,
    variable_level,
    stat_name,
    stat_label,
    stat
  )

# --- Calculate Objective Response Rate (ORR) ---
rr1 <- bor %>%
  filter(acat2 == "INVESTIGATOR", paramcd == "BOR") %>%
  group_by(mutstt, paramcd, ARM) %>%
  summarise(
    n = n(),
    X = sum(typ == 1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  rowwise() %>%
  mutate(
    binom = list(binom.test(X, n, conf.level = 0.95)),
    lowerCL = binom$conf.int[1],
    upperCL = binom$conf.int[2],
    proportion = ifelse(n > 0, X / n, NA_real_)
  ) %>%
  ungroup()

# --- Reshape ORR to long format ---
rr1_long <- rr1 %>%
  select(mutstt, paramcd, ARM, X, proportion, lowerCL, upperCL) %>%
  pivot_longer(
    cols = c(X, proportion, lowerCL, upperCL),
    names_to = "stat_name",
    values_to = "stat"
  ) %>%
  mutate(ARM = ARM) %>%
  arrange(mutstt, paramcd, ARM, stat_name)

# --- Prepare ARD2 for ORR ---
ard2 <- rr1_long %>%
  mutate(
    stat = map(stat, ~.x),
    variable_level = map(paramcd, ~.x),
    variable = "ORR",
    group1 = "ARM",
    group1_level = map(ARM, ~.x),
    group2 = "mutstt",
    group2_level = map(mutstt, ~.x)
  ) %>%
  select(
    group1,
    group1_level,
    group2,
    group2_level,
    variable,
    variable_level,
    stat_name,
    stat
  )

# --- Combine BOR and ORR datasets ---
tot <- bind_rows(ard1, ard2) %>%
  select(
    group1,
    group1_level,
    group2,
    group2_level,
    variable,
    variable_level,
    stat_name,
    stat
  )

# --- Add Big N ---
Bign <- pop %>%
  count(ARM, mutstt) %>%
  complete(ARM, mutstt, fill = list(n = 0)) %>%
  mutate(
    stat_name = "bigN",
    stat = map(n, ~.x),
    #variable_level = map(ARM, ~.x),
    #variable = "ARM",
    group1 = "ARM",
    group1_level = map(ARM, ~.x),
    group2 = "mutstt",
    group2_level = map(mutstt, ~.x)
  ) %>%
  select(
    group1,
    group1_level,
    group2,
    group2_level,
    stat_name,
    stat
  )

# --- Final ARD table ---
ard <- bind_rows(tot, Bign)

ard_tbl <- ard %>%
  rename_ard_columns(columns = c("group1", "group2")) %>%
  unlist_ard_columns() %>%
  mutate(
    label = map_chr(
      variable_level,
      ~ {
        if (length(.x) == 0) {
          return(NA_character_)
        }
        as.character(.x[[1]])
      }
    ),
    stat = ifelse(variable %in% c("BOR") & is.na(stat), 0, stat),
    
    variable = case_when(
      variable == "BOR" ~ "Best Overall Response",
      variable == "ORR" ~ "Objective Response",
      .default = variable
    ),
    label = case_when(
      variable == "Objective Response" &
        stat_name %in% c("X", "proportion") ~ "Objective Response Rate",
      variable == "Objective Response" &
        stat_name %in%
        c("lowerCL", "upperCL") ~ "95% exact Confidence Interval",
      TRUE ~ label
    ),
    label = ifelse(is.na(label), stat_name, label),
    label = ifelse(is.na(variable), NA_character_, label)
  ) %>%
  select(ARM, variable, mutstt, stat_name, stat, label) 

# --- Final dataset formatting ---
fin <- ard_tbl %>%
  mutate(
    variable = ifelse(
      variable == "Objective Response" &
        stat_name %in% c("X", "proportion", "lowerCL", "upperCL"),
      label,
      variable
    ),
    
    ord = case_when(
      mutstt =="Exon 9"~ 1,
      mutstt=="Exon 11"~ 2,
      mutstt == "Exon 13"~3,
      mutstt=="Exon 14"~ 4,
      mutstt == "Exon 17"~5,
      TRUE ~ NA_real_
    ),
    
    
    trtn = case_when(
      ARM == "C120" ~ 1,
      ARM == "T200/C240" ~ 2,
      ARM == "T300/C400" ~ 3,
      ARM == "T500" ~ 4,
      ARM == "T600/C600" ~ 5,
      ARM == "C800" ~ 6,
      ARM == "C1200" ~ 7,
      ARM == "Total" ~ 8,
    ),
    
  ) %>% arrange(ord, trtn) %>%  select(ARM, variable, mutstt, stat_name, stat, label) 

arrow::write_parquet(ard_tbl, file.path(g_paths$dddata, "t_ef_orr_muttstt_pool_r.parquet"))



THL <- tfrmt(
  group = c(mutstt, variable),
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
          "<=0.01" ~ frmt("(<1%)"),
          "TRUE" ~ frmt("(xxx%)", transform = ~ . * 100)
        )
      )
    ),
    
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{X} {proportion}",
        X = frmt("xxx"),
        proportion = frmt_when(
          "==0" ~ frmt(""),
          "TRUE" ~ frmt("(xxx%)", transform = ~ . * 100)
        )
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "({lowerCL}, {upperCL})",
        low = frmt("xx.x", transform = ~ . * 100),
        high = frmt("xx.x", transform = ~ . * 100)
      )
    )
  ),
  
  big_n = big_n_structure(param_val = "bigN", n_frmt = frmt("\n(N=x)"), by_page = TRUE),
  
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    
    row_grp_structure(
      group_val = list(variable = "Objective Response Rate"),
      element_block(post_space = NULL)
    ),
    row_grp_structure(
      group_val = list(variable = "95% exact Confidence Interval"),
      element_block(post_space = NULL)
    ),
    label_loc = element_row_grp_loc(location = "spanning")
  ),
  page_plan = page_plan(
    page_structure(group_val = list(mutstt = ".default"))
  )
)



gt <- print_to_gt(THL, fin)

# --- 7. Create and Save Output in RTF ---

rtf_obj <- gt |> 
  rtf_table(
    page_group_label = paste("KIT Mutation:", mutstt),
    #row_noorphan_col = grp,
    #drop_columns = grp
  ) |> 
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(label = "") |> 
  rtf_paginate_cols(id_columns =label, split_at = 5) |> 
  rtf_title(
    "Table 14.2.1.1f",
    "Summary of Best Overall Response and Objective Response Rate by Mutation Status (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Efficacy", paste("Data as of", g_config$datadate)) 
  ) |> 
  rtf_footer(
    "Note: Objective response rate (ORR) is defined as the proportion of patients achieving confirmed CR or confirmed PR.",
  ) |> 
  build_rtf(file = file.path(g_paths$output, "t_ef_orr_muttstt_pool_r.rtf"))