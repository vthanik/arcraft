####------------------------------------------------------------------------####
# Program Name: t_ef_pfs_lot_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Shilpa Kolli / sk575206
# Purpose: Table 14.2.4e  -  Summary of Progression-free Survival by Line of Therapy
# (Phase 1 & 1b pooled)  -  Efficacy Analysis Set
#
# Input:
#   - ADaM: ADBS, ADEFF
# Output:
#   - DD: t_ef_pfs_lot_pool_r.parquet
#   - File: ../prod/output/t_ef_pfs_lot_pool_r.RTF
#
# External files called: [N/A]
#
# Additional Notes:
#
# 2025-12-24:
#   - Vignesh T. started collaborating with the original programmer.
#
#-------------------------------------------------------------------------------

# --- 0. Setup and Library Loading ---

pkg_load(
  "admiral",
  "dplyr",
  "forcats",
  "stringr",
  "tidyr",
  "purrr",
  "cards",
  "tfrmt",
  "survival",
  "gt"
)

dosgrp_levels <- c(
  "C120",
  "T200/C240",
  "T300/C400",
  "T500",
  "T600/C600",
  "C800",
  "C1200",
  "Total"
)
lot_levels <- c("1st-line", "2nd-line", "3rd or later-line")

# Load Basic Data Structure and filter for the Efficacy population.
adbs <- read_data_catalog(adamdata$adbs) %>%
  filter(EFFL == "Y" & !is.na(DOSGRP) & !is.na(LOTCAT)) %>%
  rename_with(tolower)

# --- Read and Prepare ADEFF Dataset ---
adtte <- read_data_catalog(adamdata$adtte) %>%
  rename_with(tolower) %>%
  filter(paramcd == "PFS" & acat2 == "INVESTIGATOR") %>%
  select(-trt01a)

pop <- adbs %>%
  mutate(dosgrp = "Total", dosgrpn = 999) %>%
  bind_rows(adbs)

adf <- inner_join(adbs, adtte, by = "usubjid")

adf2 <- adf %>%
  mutate(dosgrp = "Total") %>%
  bind_rows(adf)

# Event and Censor counts by ARD creation

fin1 <- adf2 %>%
  distinct(usubjid, lotcat, dosgrp, cnsr) %>%
  mutate(
    cnsrc = case_when(
      cnsr == 0 ~ "Number of Events",
      cnsr == 1 ~ "Number of Censors"
    ),
    dosgrp_levels = factor(dosgrp, levels = dosgrp_levels),
    lotcat = factor(lotcat, levels = lot_levels)
  )

ard1 <- ard_stack_hierarchical(
  data = fin1,
  by = c(lotcat, dosgrp),
  variables = c(cnsrc),
  statistic = ~ c("n", "p"),
  denominator = pop,
  id = usubjid
) %>%
  mutate(variable = "CNSRC", ord = 1) %>%
  filter(!is.na(group1) & stat_name != "N") %>%
  select(
    group1,
    group1_level,
    group2,
    group2_level,
    variable,
    variable_level,
    stat_name,
    stat
  ) %>%
  unlist_ard_columns()

# Kaplan–Meier Quartiles (Event)
fit <- survfit(
  Surv(aval, 1 - cnsr) ~ lotcat + dosgrp,
  data = adf2,
  conf.type = "log-log"
)

# --- Extract quantiles ---
qq <- quantile(fit)

# --- Convert to data frame ---
qq2 <- as.data.frame(qq)

# Get the combined rownames
combined_names <- rownames(qq2)

# Split the names into two parts (dosgrp and lotcat)
split_names <- str_split_fixed(combined_names, ", ", n = 2)

# Extract 'lotcat' by removing the "lotcat=" prefix
qq2$lotcat <- str_remove(split_names[, 1], "lotcat=")

# Extract 'dosgrp' by removing the "dosgrp=" prefix
qq2$dosgrp <- stringr::str_remove(split_names[, 2], "dosgrp=")

# (Optional) Reorder columns for better readability, placing the grouping variables first
qq2 <- qq2 %>%
  select(lotcat, dosgrp, everything())


# --- Reshape Quartiles ---
ard2 <- qq2 %>%
  select(
    lotcat,
    dosgrp,
    starts_with("quantile."),
    starts_with("lower."),
    starts_with("upper.")
  ) %>%
  pivot_longer(
    cols = -c(lotcat, dosgrp),
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
  select(lotcat, dosgrp, percent, estimate_type, value) %>%
  arrange(lotcat, dosgrp, percent, estimate_type) %>%
  mutate(
    stat = value,
    stat_name = str_trim(estimate_type),
    variable_level = percent,
    variable = "OUER",
    group1 = "lotcat",
    group1_level = lotcat,
    group2 = "dosgrp",
    group2_level = dosgrp,
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


# Median Follow-Up

fitx <- survfit(
  Surv(aval, cnsr == 1) ~ lotcat + dosgrp,
  data = adf2,
  conf.type = "log-log"
)

med <- quantile(fitx)
med2 <- as.data.frame(med)

# Get the combined rownames
combined_names <- rownames(med2)

# Split the names into two parts (dosgrp and lotcat)
split_names <- str_split_fixed(combined_names, ", ", n = 2)

# Extract 'lotcat' by removing the "lotcat=" prefix
med2$lotcat <- str_remove(split_names[, 1], "lotcat=")

# Extract 'dosgrp' by removing the "dosgrp=" prefix
med2$dosgrp <- stringr::str_remove(split_names[, 2], "dosgrp=")

# (Optional) Reorder columns for better readability, placing the grouping variables first
med2 <- med2 %>%
  select(lotcat, dosgrp, everything())

# --- Reshape Quartiles ---
ard3 <- med2 %>%
  select(
    lotcat,
    dosgrp,
    starts_with("quantile."),
    starts_with("lower."),
    starts_with("upper.")
  ) %>%
  pivot_longer(
    cols = -c(lotcat, dosgrp),
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
  select(lotcat, dosgrp, percent, estimate_type, value) %>%
  arrange(lotcat, dosgrp, percent, estimate_type) %>%
  mutate(
    stat = value,
    stat_name = str_trim(estimate_type),
    variable_level = percent,
    variable = "FUP",
    group2 = "dosgrp",
    group2_level = dosgrp,
    group1 = "lotcat",
    group1_level = lotcat,
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


# Survival Probability at Specific Times (6, 9, 12 months)
tim <- summary(fit, times = c(6, 9, 12))
timx <- data.frame(
  time = tim$time,
  surv = tim$surv,
  low = tim$lower,
  high = tim$upper,
  strata = tim$strata
) %>%
  mutate(
    lotcat = str_extract(strata, "lotcat=[^,]+") %>%
      stringr::str_remove("lotcat="),

    dosgrp = str_extract(strata, "dosgrp=[^,]+") %>%
      str_remove("dosgrp=")
  ) %>%
  select(lotcat, dosgrp, time, surv, low, high)

# --- Convert to Long Format ---
ard4 <- timx %>%
  pivot_longer(
    cols = c(surv, low, high),
    names_to = "Type",
    values_to = "Value"
  ) %>%
  mutate(
    Type = recode(Type, surv = "estimate2", low = "low", high = "high")
  ) %>%
  arrange(lotcat, dosgrp, time, match(Type, c("estimate2", "low", "high"))) %>%
  mutate(
    stat = Value,
    stat_name = str_trim(Type),
    variable_level = as.character(time),
    variable = "SURV",
    group2 = "dosgrp",
    group2_level = dosgrp,
    group1 = "lotcat",
    group1_level = lotcat,
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


#  Big N Counts
Bign <- pop %>%
  count(lotcat, dosgrp) %>%
  complete(lotcat, dosgrp, fill = list(n = 0)) %>%
  mutate(
    stat_name = "bigN",
    stat = n,
    trtn = case_when(
      dosgrp == "C120" ~ 1,
      dosgrp == "T200/C240" ~ 2,
      dosgrp == "T300/C400" ~ 3,
      dosgrp == "T500" ~ 4,
      dosgrp == "T600/C600" ~ 5,
      dosgrp == "C800" ~ 6,
      dosgrp == "C1200" ~ 7,
      dosgrp == "Total" ~ 8,
    )
  ) %>%
  arrange(lotcat, trtn) %>%
  select(lotcat, dosgrp, stat_name, stat)


# Combine ARDs and Prepare Output
ard <- bind_rows(ard1, ard2, ard3, ard4) %>%
  mutate(
    group2_level = str_trim(group2_level)
  ) %>%
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


ard_tbl <- ard %>%
  rename_ard_columns(columns = c("group1", "group2")) %>%
  unlist_ard_columns() %>%
  mutate(
    label = map_chr(
      variable_level,
      ~ if (length(.x) == 0) NA_character_ else as.character(.x[[1]])
    ),
    stat = case_when(
      stat_name == "p" & is.nan(stat) ~ 0,
      stat_name == "p" ~ stat * 100,
      .default = stat
    ),

    variable = case_when(
      variable == "OUER" ~ "PFS, month",
      variable == "FUP" ~ "Median Follow-Up, month",
      variable == "SURV" ~ "Event-free Rate at, %",
      variable == "CNSRC" & label == "Number of Censors" ~ "Number of Censors",
      variable == "CNSRC" & label == "Number of Events" ~ "Number of Events",
      .default = variable
    ),

    grp = case_when(
      variable == "Number of Events" ~ 1,
      variable == "Number of Censors" ~ 2,
      variable == "PFS, month" ~ 3,
      variable == "Median Follow-Up, month" ~ 4,
      variable == "Event-free Rate at, %" ~ 5,
      TRUE ~ NA_real_
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
  select(lotcat, dosgrp, variable, stat_name, stat, label, grp)

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
      dosgrp == "C120" ~ 1,
      dosgrp == "T200/C240" ~ 2,
      dosgrp == "T300/C400" ~ 3,
      dosgrp == "T500" ~ 4,
      dosgrp == "T600/C600" ~ 5,
      dosgrp == "C800" ~ 6,
      dosgrp == "C1200" ~ 7,
      dosgrp == "Total" ~ 8,
    ),

    stat = ifelse(stat_name == "estimate2", stat * 100, stat)
  ) %>%
  arrange(lotcat, trtn, ord) %>%
  select(-c(trtn, ord))

fin0 <- bind_rows(fin, Bign) %>% arrange(grp)

high <- fin0 %>%
  filter(stat_name %in% c("high", "upper")) %>%
  select(lotcat, dosgrp, variable, label, grp, h_stat = stat)

low <- fin0 %>%
  filter(stat_name %in% c("low", "lower")) %>%
  select(lotcat, dosgrp, variable, label, grp, l_stat = stat)

fin <- fin0 |>
  left_join(
    high,
    by = c("lotcat", "dosgrp", "variable", "label", "grp")
  ) |>
  left_join(
    low,
    by = c("lotcat", "dosgrp", "variable", "label", "grp")
  ) |>
  mutate(
    del_fl = case_when(
      stat_name %in% c("high", "upper") & is.na(l_stat) & is.na(stat) ~ "Y",
      stat_name %in% c("low", "lower") & is.na(h_stat) & is.na(stat) ~ "Y"
    ),
    stat_name = case_when(
      del_fl == "Y" ~ paste0(stat_name, "_bl"),
      TRUE ~ stat_name
    )
  ) |>
  #filter(is.na(del_fl))|>
  select(-l_stat, -h_stat, -del_fl)


arrow::write_parquet(
  fin,
  file.path(g_paths$dddata, "t_ef_pfs_lot_pool_r.parquet")
)

#  Table formatting

thl <- tfrmt(
  group = c(lotcat, variable),
  label = label,
  param = stat_name,
  value = stat,
  column = dosgrp,
  sorting_cols = grp,
  body_plan = body_plan(
    frmt_structure(group_val = ".default", label_val = ".default", frmt("xxx")),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      estimate = frmt_when(
        "==100" ~ frmt("  100"),
        ">=0" ~ frmt("   xx.x"),
        "TRUE" ~ frmt(""),
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      estimate2 = frmt_when(
        "==100" ~ frmt("  100"),
        ">=0" ~ frmt("   xx.x"),
        "TRUE" ~ frmt("")
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{n} {p}",
        n = frmt("xxx"),
        p = frmt_when(
          "==100" ~ frmt("(100%)"),
          ">=99" ~ frmt("(>99%)"),
          "==0" ~ frmt(""),
          "<1" ~ frmt("( <1%)"),
          "TRUE" ~ frmt("(xxx%)")
        )
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{lower}{upper}",
        lower = frmt_when(
          "==100" ~ frmt("100"),
          ">=-100000" ~ frmt("(xx.x, "),
          "TRUE" ~ frmt("(-, ")
        ),
        upper = frmt_when(
          "==100" ~ frmt("100"),
          ">=-100000" ~ frmt("xx.x)"),
          "TRUE" ~ frmt("-)")
        )
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{lower_bl}{upper_bl}",
        lower_bl = frmt(""),
        upper_bl = frmt("")
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{low_bl}{high_bl}",
        low_bl = frmt(""),
        high_bl = frmt("")
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{low}{high}",
        low = frmt_when(
          "==1" ~ frmt(""),
          ">=-100000" ~ frmt("(xx.x, ", transform = ~ . * 100),
          "TRUE" ~ frmt("(-, ")
        ),
        high = frmt_when(
          "==1" ~ frmt(""),
          ">=-100000" ~ frmt("xx.x)", transform = ~ . * 100),
          "TRUE" ~ frmt("-)")
        )
      )
    )
  ),
  big_n = big_n_structure(
    param_val = "bigN",
    n_frmt = frmt("\n(N=x)"),
    by_page = TRUE
  ),

  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    row_grp_structure(
      group_val = list(variable = "Number of Events"),
      element_block(post_space = NULL)
    ),
    row_grp_structure(
      group_val = list(variable = "Number of Censors "),
      element_block(post_space = NULL)
    ),
    label_loc = element_row_grp_loc(location = "spanning")
  ),
  page_plan = page_plan(page_structure(group_val = list(lotcat = ".default")))
)

gts <- print_to_gt(thl, fin)

# --- 7. Create and Save Output in RTF ---

rtf_obj <- gts |>
  rtf_table(
    page_group_label = paste("Line of Therapy:", lotcat),
    row_noorphan_col = grp,
    drop_columns = grp
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.15in") |>
  rtf_col_label(label = "") |>
  rtf_paginate_cols(id_columns = label, split_at = 5) |>
  rtf_title(
    "Table 14.2.4e",
    " Summary of Progression-free Survival by Line of Therapy (Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Efficacy", paste("Data as of", g_config$datadate))
  ) |>
  rtf_footer(
    "Note: Progression-free survival (PFS) is calculated from the date of first IDRX-42 dose to the date of disease",
    "progression or death, whichever occurs first.",
    "Note: Estimated with the Kaplan-Meier method."
  ) |>
  rtf_options(
    page_line_size_landscape = 33,
    page_margin_top = "0.95in",
    page_margin_bottom = "0.95in"
  ) |>
  build_rtf(file = file.path(g_paths$output, "t_ef_pfs_lot_pool_r.rtf"))
