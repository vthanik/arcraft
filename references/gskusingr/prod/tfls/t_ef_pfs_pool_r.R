
####------------------------------------------------------------------------####
# Program Name: t_ef_pfs_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Milon Haque / eh605853
# Purpose: Summary of Progression-free Survival (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adtte]
# Output:
#   - dd [t_ef_pfs_pool_r]
#   - File: ../prod/output/t_ef_pfs_pool_r.RTF
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- 0. Setup and Library Loading ---

pkg_load("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "tfrmt")

library(admiral)
library(dplyr)
library(forcats)
library(cards)
library(tfrmt)
library(purrr)
library(survival)
library(broom)
library(arrow)


#=============================================================================
# 2. Load and Prepare Datasets
#=============================================================================

# --- Load and Prepare ADBS Dataset ---
adbs <-read_data_catalog(adamdata$adbs) %>%
  filter(EFFL == "Y" & !is.na(TRT01A)) %>%
  select(-starts_with("trt")) %>%
  rename_with(tolower) %>%
  mutate(ARM = dosgrp)

pop <- adbs %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adbs)

# --- Read and Prepare ADEF Dataset ---
adf <- read_data_catalog(adamdata$adtte) %>%
  rename_with(tolower) %>%
  filter(paramcd == "PFS" & acat2 == "INVESTIGATOR")

adf <- inner_join(adbs, adf, by = "usubjid")

adf2 <- adf %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adf)


#=============================================================================
# 3. Event and Censor Counts
#=============================================================================

fin1 <- adf2 %>%
  distinct(usubjid, ARM, cnsr) %>%
  mutate(
    cnsrc = case_when(
      cnsr == 0 ~ "Number of Events",
      cnsr == 1 ~ "Number of Censors"
    )
  )

ard1 <- ard_stack_hierarchical(
  data = fin1,
  by = ARM,
  variables = c(cnsrc),
  statistic = ~ c("n", "p"),
  denominator = pop,
  id = usubjid
) %>%
  mutate(variable = "CNSRC", ord = 1) %>%
  filter(!is.na(group1) & stat_name != "N") %>%
  select(group1, group1_level, variable, variable_level, stat_name, stat)

#=============================================================================
# 4. Kaplan–Meier Quartiles (Event)
#=============================================================================

fit <- survfit(Surv(aval, 1 - cnsr) ~ ARM, data = adf2, conf.type = "log-log")
km <- broom::tidy(fit, conf.int = TRUE)

qq <- quantile(fit)
bb <- as.data.frame(qq)
bb$ARM <- rownames(bb)

# --- Reshape Quartiles ---
out <- bb %>%
  select(
    ARM,
    starts_with("quantile."),
    starts_with("lower."),
    starts_with("upper.")
  ) %>%
  pivot_longer(
    cols = -ARM,
    names_to = c("type", "percent"),
    names_sep = "\\."
  ) %>%
  pivot_wider(names_from = type, values_from = value) %>%
  mutate(
    percent = recode(percent, "25" = "p25", "50" = "p50", "75" = "p75"),
    estimate = quantile
  ) %>%
  pivot_longer(
    cols = c(estimate, lower, upper),
    names_to = "type",
    values_to = "value"
  ) %>%
  rename(estimate_type = type) %>%
  select(ARM, percent, estimate_type, value) %>%
  arrange(ARM, percent, estimate_type) %>%
  mutate(ARM = word(ARM, 2, sep = "="))

# --- Prepare ARD2 ---
ard2 <- out %>%
  mutate(
    stat = map(value, ~.x),
    stat_name = str_trim(estimate_type),
    variable_level = map(percent, ~.x),
    variable = "OUER",
    group1 = "ARM",
    group1_level = map(ARM, ~.x)
  ) %>%
  select(group1, group1_level, variable, variable_level, stat_name, stat)

#=============================================================================
# 5. Median Follow-Up
#=============================================================================

fitx <- survfit(Surv(aval, cnsr == 1) ~ ARM, data = adf2, conf.type = "log-log")

qq2 <- quantile(fitx)
bb2 <- as.data.frame(qq2)
bb2$ARM <- rownames(bb2)

out2 <- bb2 %>%
  select(
    ARM,
    starts_with("quantile."),
    starts_with("lower."),
    starts_with("upper.")
  ) %>%
  pivot_longer(
    cols = -ARM,
    names_to = c("type", "percent"),
    names_sep = "\\."
  ) %>%
  pivot_wider(names_from = type, values_from = value) %>%
  filter(percent == 50) %>%
  mutate(percent = "p50", estimate = quantile) %>%
  pivot_longer(
    cols = c(estimate, lower, upper),
    names_to = "type",
    values_to = "value"
  ) %>%
  rename(estimate_type = type) %>%
  select(ARM, percent, estimate_type, value) %>%
  arrange(ARM, percent, estimate_type) %>%
  mutate(ARM = word(ARM, 2, sep = "="))

ard3 <- out2 %>%
  mutate(
    stat = map(value, ~.x),
    stat_name = str_trim(estimate_type),
    variable_level = map(percent, ~.x),
    variable = "FUP",
    group1 = "ARM",
    group1_level = map(ARM, ~.x)
  ) %>%
  select(group1, group1_level, variable, variable_level, stat_name, stat)

#=============================================================================
# 6. Survival Probability at Specific Times (6, 9, 12 months)
#=============================================================================

tim <- summary(fit, times = c(6, 9, 12))
timx <- data.frame(
  time = tim$time,
  surv = tim$surv,
  low = tim$lower,
  high = tim$upper,
  strata = tim$strata
) %>%
  mutate(ARM = word(strata, 2, sep = "=")) %>%
  select(ARM, time, surv, low, high)

# --- Convert to Long Format ---
tim_long <- timx %>%
  pivot_longer(
    cols = c(surv, low, high),
    names_to = "Type",
    values_to = "Value"
  ) %>%
  mutate(
    Type = recode(Type, surv = "estimate2", low = "low", high = "high")
  ) %>%
  arrange(ARM, time, match(Type, c("estimate2", "low", "high")))

ard4 <- tim_long %>%
  mutate(
    stat = map(Value, ~.x),
    stat_name = str_trim(Type),
    variable_level = map(as.character(time), ~.x),
    variable = "SURV",
    group1 = "ARM",
    group1_level = map(ARM, ~.x)
  ) %>%
  select(group1, group1_level, variable, variable_level, stat_name, stat)

#=============================================================================
# 7. Combine ARDs and Prepare Output
#=============================================================================

tot <- bind_rows(ard1, ard2, ard3, ard4) %>%
  select(group1, variable, stat_name, stat, variable_level, group1_level)

# --- Add Total Counts ---
pop <- adbs %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adbs)

Bign <- pop %>%
  count(ARM) %>%
  mutate(
    stat_name = "bigN",
    stat = map(n, ~.x),
    variable_level = map(ARM, ~.x),
    variable = "ARM",
    group1 = "ARM",
    group1_level = map(ARM, ~.x)
  ) %>%
  select(group1, variable, stat_name, stat, variable_level, group1_level)

# --- Merge Final ARD ---
ard <- bind_rows(tot, Bign)

#=============================================================================
# 8. Format Final Output Table
#=============================================================================

ard_tbl <- ard %>%
  rename_ard_columns(columns = c("group1")) %>%
  unlist_ard_columns() %>%
  mutate(
    label = map_chr(
      variable_level,
      ~ if (length(.x) == 0) NA_character_ else as.character(.x[[1]])
    ),
    variable = case_when(
      variable == "OUER" ~ "PFS, month",
      variable == "FUP" ~ "Median Follow-Up, month",
      variable == "SURV" ~ "Event-free Rate at, %",
      variable == "CNSRC" & label == "Number of Censors" ~ "Number of Censors",
      variable == "CNSRC" & label == "Number of Events" ~ "Number of Events",
      .default = variable
    ),
    label = case_when(
      label == "p25" & stat_name == "estimate" ~ "25% Quartile",
      label == "p25" &
        stat_name %in% c("lower", "upper") ~ "95% CI of 25% Quartile",
      label == "p50" & stat_name == "estimate" ~ "Median",
      label == "p50" & stat_name %in% c("lower", "upper") ~ "95% CI of Median",
      label == "p75" & stat_name == "estimate" ~ "75% Quartile",
      label == "p75" &
        stat_name %in% c("lower", "upper") ~ "95% CI of 75% Quartile",
      label == "p50" &
        variable == "Median Follow-Up, month" &
        stat_name == "quantile" ~ "Median Follow-Up, month",
      label == "p50" & stat_name %in% c("lower", "upper") ~ "95% CI of Median",
      label == "6" & stat_name == "estimate2" ~ "6 months",
      label == "6" & stat_name %in% c("low", "high") ~ "95% CI at 6 months",
      label == "9" & stat_name == "estimate2" ~ "9 months",
      label == "9" & stat_name %in% c("low", "high") ~ "95% CI at 9 months",
      label == "12" & stat_name == "estimate2" ~ "12 months",
      label == "12" & stat_name %in% c("low", "high") ~ "95% CI at 12 months",
      TRUE ~ label
    ),
    label = ifelse(
      variable == "Median Follow-Up, month" & stat_name == "estimate",
      "Median Follow-Up, month",
      label
    )
  ) %>%
  select(ARM, variable, stat_name, stat, label)

# --- Indent CI Rows ---
fin <- ard_tbl %>%
  mutate(
    label = if_else(
      variable %in%
        c("PFS, month", "Event-free Rate at, %") &
        str_detect(label, "95%"),
      paste0("  ", str_trim(label)),
      label
    ),
    ord = case_when(
      variable == "Number of Events" ~ 1,
      variable == "Number of Censors" ~ 2,
      TRUE ~ row_number()
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
    
    
    stat = ifelse(stat_name == "estimate2", stat * 100, stat)
  ) %>%
  arrange(trtn, ord) %>%
  select(-c(trtn, ord))

# Save the final ARD for traceability or reuse
arrow::write_parquet(fin, file.path(g_paths$dddata, "t_ef_pfs_pool_r.parquet"))

#=============================================================================
# 9. Table Formatting (tfrmt)
#=============================================================================

THL <- tfrmt(
  group = variable,
  label = label,
  param = stat_name,
  value = stat,
  column = ARM,
  body_plan = body_plan(
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt("xxx.x")
    ),
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
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "({lower}, {upper})",
        lower = frmt_when(
          ">0" ~ frmt("xx.x"),
          "TRUE" ~ frmt("-")
        ),
        upper = frmt_when(
          ">0" ~ frmt("xx.x"),
          "TRUE" ~ frmt("-")
        )
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "({low}, {high})",
        low = frmt_when(
          ">0" ~ frmt("xx.x", transform = ~ . * 100),
          "TRUE" ~ frmt("-")
        ),
        high = frmt_when(
          ">0" ~ frmt("xx.x", transform = ~ . * 100),
          "TRUE" ~ frmt("-")
        )
      )
    )
  ),
  big_n = big_n_structure(param_val = "bigN", frmt("\n(N=xx)")),
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    row_grp_structure(
      group_val = list(variable = "Number of Events"),
      element_block(post_space = NULL)
    ),
    row_grp_structure(
      group_val = list(variable = "Number of Censors "),
      element_block(post_space = NULL)
    )
  )
) |>
  print_to_gt(fin)

THL





# --- 7. Create and Save Output in RTF ---

rtf_obj <- THL |> 
  rtf_table(
    #page_group_label = paste("Line of Therapy:", LOTCAT),
    #row_noorphan_col = grp,
    #drop_columns = grp
  )|> 
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.20in") |>
  rtf_col_label(label = "") |> 
  rtf_paginate_cols(id_columns = label, split_at = 5) |>
  rtf_title(
    "Table 14.2.4c",
    "Summary of Progression-free Survival (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Safety", paste("Data as of", g_config$datadate)) 
  ) |> 
  rtf_footer(
    "Note: Progression-free survival (PFS) is calculated from the date of first IDRX-42 dose to the date of disease progression or death, whichever occurs first.",
    "Note: Estimated with the Kaplan-Meier method."
  ) |> 
  build_rtf(file = file.path(g_paths$output, "t_ef_pfs_pool_r.rtf"))
