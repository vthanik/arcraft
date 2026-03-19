####------------------------------------------------------------------------####
# Program Name: t_ef_dor_pool_r.R
# Domino Project: 61834_300382_INTERNAL_05
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Mariam ALaverdyan/ ma584118
# Purpose: Summary of Duration of Response – Efficacy Analysis Set (Phase 1 & 1b pooled)
# Input: ADSL, ADTTE
# Output: [N/A]
# External files called:
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#  
#-------------------------------------------------------------------------------
 
# --- Load Libraries ----

libs <- c(
  "dplyr",
  "forcats",
  "cards",
  "tfrmt",
  "purrr",
  "docorator",
  "haven",
  "diffdf",
  "admiral",
  "xportr",
  "readxl",
  "metacore",
  "metatools",
  "survival",
  "broom",
  "arrow",
  "gt",
  "lubridate",
  "tidyverse",
  "stringr"
)
source("/mnt/code/functions/r_setup.R")

# --- Load Libraries ----

pkg_attach(libs)

#=============================================================================
# 2. Load and Prepare Datasets
#=============================================================================

# --- Load and Prepare ADBS Dataset ---
adbs <- read_data_catalog(adamdata$adbs)|>
  convert_blanks_to_na() |>
  filter(EFFL == "Y") |>
  select(-starts_with("trt")) |>
  rename_with(tolower) |>
  mutate(DOSGRP = dosgrp)

pop <- adbs |>
  mutate(DOSGRP = "Total", dosgrpn = 999) |>
  bind_rows(adbs)

# --- Read and Prepare ADEF Dataset ---
adf <- read_sas_local(adamdata$adtte) |>
  convert_blanks_to_na() |>
  rename_with(tolower) |>
  filter(paramcd == "DOR" & acat2 == "INVESTIGATOR")

adf <- inner_join(adbs, adf, by = "usubjid")

adf2 <- adf |>
  mutate(DOSGRP = "Total", dosgrpn = 999) |>
  bind_rows(adf)

NUM <- merge(adbs, adf, by = "usubjid", all.y = TRUE) |>
  mutate(DOSGRP = "Total", dosgrpn = 999) |>
  bind_rows(adf)
#=============================================================================
# 3. Event and Censor Counts
#=============================================================================

fin1 <- adf2 |>
  distinct(usubjid, DOSGRP, cnsr) |>
  mutate(
    cnsrc = case_when(
      cnsr == 0 ~ "Number of Events, n %",
      cnsr == 1 ~ "Number of Censors, n %"
    )
  )

ard1 <- ard_stack_hierarchical(
  data = fin1,
  by = DOSGRP,
  variables = c(cnsrc),
  #statistic = ~ c("n", "p"),
  denominator = NUM,
  id = usubjid
) |>
  mutate(variable = "CNSRC", ord = 1) |>
  filter(
    !is.na(group1) & !(variable_level == "Number of Censors, n %" & stat_name == "N")
  ) |>
  select(group1, group1_level, variable, variable_level, stat_name, stat) |>
  arrange(stat_name, desc(variable_level))

#=============================================================================
# 4. Kaplan–Meier Quartiles (Event)
#=============================================================================

fit <- survfit(
  Surv(aval, 1 - cnsr) ~ DOSGRP,
  data = adf2,
  conf.type = "log-log"
)
km <- broom::tidy(fit, conf.int = TRUE)

qq <- quantile(fit)
bb <- as.data.frame(qq)
bb$DOSGRP <- rownames(bb)

# --- Reshape Quartiles ---
out <- bb |>
  select(
    DOSGRP,
    starts_with("quantile."),
    starts_with("lower."),
    starts_with("upper.")
  ) |>
  pivot_longer(
    cols = -DOSGRP,
    names_to = c("type", "percent"),
    names_sep = "\\."
  ) |>
  pivot_wider(names_from = type, values_from = value) |>
  mutate(
    percent = recode(percent, "25" = "p25", "50" = "p50", "75" = "p75"),
    estimate = quantile
  ) |>
  pivot_longer(
    cols = c(estimate, lower, upper),
    names_to = "type",
    values_to = "value"
  ) |>
  rename(estimate_type = type) |>
  select(DOSGRP, percent, estimate_type, value) |>
  arrange(DOSGRP, percent, estimate_type) |>
  mutate(DOSGRP = word(DOSGRP, 2, sep = "="))

# --- Prepare ARD2 ---
ard2 <- out |>
  mutate(
    stat = map(value, ~.x),
    stat_name = str_trim(estimate_type),
    variable_level = map(percent, ~.x),
    variable = "OUER",
    group1 = "DOSGRP",
    group1_level = map(DOSGRP, ~.x)
  ) |>
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
) |>
  mutate(DOSGRP = word(strata, 2, sep = "=")) |>
  select(DOSGRP, time, surv, low, high)

# --- Convert to Long Format ---
tim_long <- timx |>
  pivot_longer(
    cols = c(surv, low, high),
    names_to = "Type",
    values_to = "Value"
  ) |>
  mutate(Type = recode(Type, surv = "estimate2", low = "low", high = "high")) |>
  arrange(DOSGRP, time, match(Type, c("estimate2", "low", "high")))

ard4 <- tim_long |>
  mutate(
    stat = map(Value, ~.x),
    stat_name = str_trim(Type),
    variable_level = map(as.character(time), ~.x),
    variable = "SURV",
    group1 = "DOSGRP",
    group1_level = map(DOSGRP, ~.x)
  ) |>
  select(group1, group1_level, variable, variable_level, stat_name, stat)

#=============================================================================
# 7. Combine ARDs and Prepare Output
#=============================================================================

tot <- bind_rows(ard1, ard2, ard4) |>
  select(group1, variable, stat_name, stat, variable_level, group1_level)

# --- Add Total Counts ---
pop <- adbs |>
  mutate(DOSGRP = "Total", dosgrpn = 999) |>
  bind_rows(adbs)

Bign <- pop |>
  count(DOSGRP) |>
  mutate(
    stat_name = "bigN",
    stat = map(n, ~.x),
    variable_level = map(DOSGRP, ~.x),
    variable = "DOSGRP",
    group1 = "DOSGRP",
    group1_level = map(DOSGRP, ~.x)
  ) |>
  select(group1, variable, stat_name, stat, variable_level, group1_level)

# --- Merge Final ARD ---
ard <- bind_rows(tot, Bign)

#=============================================================================
# 8. Format Final Output Table
#=============================================================================

ard_tbl <- ard |>
  rename_ard_columns(columns = c("group1")) |>
  unlist_ard_columns() |>
  mutate(
    variable_level = case_when(
      stat_name == "N" ~ "Number of Responders, N",
      TRUE ~ as.character(variable_level)
    ),
    label = map_chr(
      variable_level,
      ~ if (length(.x) == 0) NA_character_ else as.character(.x[[1]])
    ),
    variable = case_when(
      variable == "OUER" ~ "Duration of Response, month",
      variable == "SURV" ~ "Event-free Rate at, %",
      variable == "CNSRC" &
        label == "Number of Censors, n %" ~ "Number of Responders, N",
      variable == "CNSRC" &
        label == "Number of Events, n %" ~ "Number of Responders, N",
      variable == "CNSRC" &
        label == "Number of Responders, N" ~ "Number of Responders, N",
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
      label == "6" & stat_name == "estimate2" ~ "6 months",
      label == "6" & stat_name %in% c("low", "high") ~ "95% CI at 6 months",
      label == "9" & stat_name == "estimate2" ~ "9 months",
      label == "9" & stat_name %in% c("low", "high") ~ "95% CI at 9 months",
      label == "12" & stat_name == "estimate2" ~ "12 months",
      label == "12" & stat_name %in% c("low", "high") ~ "95% CI at 12 months",
      TRUE ~ label
    )
  ) |>
  select(DOSGRP, variable, stat_name, stat, label)

# --- Indent CI Rows ---
fin <- ard_tbl |>
  mutate(
    label = if_else(
      variable %in%
        c("Duration of Response, month", "Event-free Rate at, %") &
        str_detect(label, "95%"),
      paste0("  ", str_trim(label)),
      label
    ),
    ord = case_when(
      variable == "Number of Events, n %" ~ 1,
      variable == "Number of Censors, n %" ~ 2,
      TRUE ~ row_number()
    ),
    stat = ifelse(stat_name == "estimate2", stat * 100, stat)
  ) 

final_del<- fin|>
  filter(label == "Number of Events, n %" & stat==0 & stat_name=="n")|>
  mutate(del_fl="Y")|>
  select(DOSGRP, del_fl)

final1 <- merge(
  fin,
  final_del,
  by = c("DOSGRP"),
  all.x = TRUE
)|>
  mutate(delfl1=case_when(variable=="Duration of Response, month" & is.na(stat) & del_fl=="Y"~"Y"))
fin <-final1|>
  filter(is.na(delfl1))|>
  select(-delfl1, -del_fl)|>
  arrange(ord) |>
  select(-ord)


#=============================================================================
# 9. Table Formatting (tfrmt)
#=============================================================================

THL <- tfrmt(
  group = variable,
  label = label,
  param = stat_name,
  value = stat,
  column = DOSGRP,
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
        n = frmt_when(
          ">=0" ~ frmt("xxx"),
          "TRUE" ~ frmt("")
        ),
        p = frmt_when(
          "==1" ~ frmt("(100%)"),
          ">=0.99" ~ frmt("(>99%)"),
          "==0" ~ frmt(""),
          "<=0.01" ~ frmt("( <1%)"),
          "TRUE" ~ frmt("(xxx%)", , transform = ~ . * 100)
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
          ">0" ~ frmt("(xx.x, "),
          "TRUE" ~ frmt("(-, ")
        ),
        upper = frmt_when(
          "==100" ~ frmt("100"),
          ">0" ~ frmt("xx.x)"),
          "TRUE" ~ frmt("-)")
        )
      )
    ),
    frmt_structure(
      group_val = ".default",
      label_val = ".default",
      frmt_combine(
        "{low}{high}",
        low = frmt_when(
          "==1" ~ frmt(""),
          ">0" ~ frmt("(xx.x, ", transform = ~ . * 100),
          "TRUE" ~ frmt("(-, ")
        ),
        high = frmt_when(
          "==1" ~ frmt(""),
          ">0" ~ frmt("xx.x)", transform = ~ . * 100),
          "TRUE" ~ frmt("-)")
        )
      )
    )
  ),
  big_n = big_n_structure(param_val = "bigN", n_frmt = frmt("\n(N=xx)")),
  col_plan = col_plan(label, C120, `T200/C240`, `T300/C400`, T500, `T600/C600`, C800, C1200, Total),
  col_style_plan = col_style_plan(
    col_style_structure(col = everything(), align = "left")
  ),
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    row_grp_structure(
      group_val = list(variable = "Number of Events, n %"),
      element_block(post_space = NULL)
    ),
    row_grp_structure(
      group_val = list(variable = "Number of Censors, n % "),
      element_block(post_space = NULL)
    )
  )
) #|>
#print_to_gt(fin)


# --- Step 4: Use rtfbuilder to Create Final RTF Output ---
# 2. Create a new, simple gt object from the flattened data.
final_gt_obj <- print_to_gt(THL, fin) |>
  cols_label(label = "") # Ensure label column header is blank

# 3. Build the RTF using the flattened gt object.
rtf_dt <-
  rtf_table(
    final_gt_obj,
    # drop_columns = "ord1",
    # row_noorphan_col = "ord1",
    # page_group_col = "ord1",
    # page_group_label = paste("Group:", ord1)
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.35in") |>
  rtf_col_label(label = "") |>
  rtf_paginate_cols(id_columns = label, split_at = 5) |>
  rtf_title(
    "Table 14.2.3c",
    "Summary of Duration of Response (Phase 1 & 1b pooled)"
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
  )|>
  rtf_footer ("Note: Analysis is based on the number of responder (N).",
              "Note: Duration of response, reported in patients achieving a confirmed CR of PR, is calculated from the date of first observation of CR or PR to the date of disease progression or death, whichever occurs first.",
              "Note: Estimated with the Kaplan-Meier method.",
              .align = "left")

rtf_dt |>
  build_rtf(file = file.path(g_paths$output,"t_ef_dor_pool_r.rtf"))


# THL
# 
# footnote1_1 <- file.path('/mnt', 'code', 'prod', 'tfls', 't_ef_dor_pool_r.R')
# footnote1_2 <- format(Sys.time(), "%d%b%Y  %H:%M") |> toupper()
# 
# THL |>
#   as_docorator(
#     display_name = "t_ef_dor_pool_r",
#     display_loc = output_path,
#     header = fancyhead(
#       fancyrow(
#         left = "Protocol: IDRX-42-001",
#         center = NA,
#         right = doc_pagenum()
#       ),
#       fancyrow(
#         left = "Population: Efficacy",
#         center = NA,
#         right = "Data as of 15SEP2025"
#       ),
#       fancyrow(left = NA, center = "Table 14.2.3c", right = NA),
#       fancyrow(
#         left = NA,
#         center = "Summary of Duration of Response (Phase 1 & 1b pooled)",
#         right = NA
#       )
#     ),
#     footer = fancyfoot(
#       fancyrow(
#         left = "Note: Analysis is based on the number of responder (N).",
#         center = NA,
#         right = NA
#       ),
#       fancyrow(
#         left = "Note: Duration of response, reported in patients acheiving a confirmed CR of PR, is calculated from the date of first",
#         center = NA,
#         right = NA
#       ),
#       fancyrow(
#         left = "observation of CR or PR to the date of disease progression or death, whichever occurs first.",
#         center = NA,
#         right = NA
#       ),
#       fancyrow(
#         left = "Note: Estimated with the Kaplan-Meier method.",
#         center = NA,
#         right = NA
#       ),
#       fancyrow(
#         left = footnote1_1,
#         center = footnote1_2,
#         right = NA
#       )
#     )
#   ) |>
#   render_pdf()

#saving final dataset for validation in parquet format
write_parquet(fin, file.path(g_paths$dddata, "t_ef_dor_pool_r.parquet"))

#Getting parquet file
# t_ef_dor_pool_r <- read_parquet(file.path(dddata, "t_ef_dor_pool_r.parquet"))
t_ef_dor_pool_r <- read_parquet(file.path(g_paths$dddata, "t_ef_dor_pool_r.parquet"))