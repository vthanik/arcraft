
####------------------------------------------------------------------------####
# Program Name: t_ef_dor_lot_pool_r.R
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
  "gt",
  "survival",
  "broom",
  "arrow",
  "lubridate",
  "tidyverse",
  "stringr"
)

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

# NUM <- merge(adbs, adf, by = "usubjid",  all.y = TRUE)|>
#   mutate(DOSGRP = "Total", dosgrpn = 999) |>
#   bind_rows(adf)
#=============================================================================
# 3. Event and Censor Counts
#=============================================================================

fin1 <- adf2 |>
  distinct(usubjid, DOSGRP, lotcat, cnsr) |>
  mutate(
    cnsrc = case_when(
      cnsr == 0 ~ "Number of Events, n %",
      cnsr == 1 ~ "Number of Censors, n %"
    )
  )
popaa <- pop|>
  select(DOSGRP,usubjid,lotcat)
popch <- merge(fin1, pop, by = c("DOSGRP", "usubjid", "lotcat"),  all.x = TRUE)|>
  select(DOSGRP,usubjid,lotcat)
ard1 <- ard_stack_hierarchical(
  data = fin1,
  by = c(DOSGRP, lotcat),
  variables = c(cnsrc),
  #statistic = ~ c("n", "p"),
  denominator = popch,
  id = usubjid
) |>
  mutate(variable = "CNSRC", ord = 1) |>
  filter(
    !is.na(group1) &
      !(variable_level == "Number of Censors, n %" & stat_name == "N")
  ) |>
  select(
    group1,
    group1_level,
    group2,
    group2_level,
    variable,
    variable_level,
    stat_name,
    stat
  ) |>
  arrange(stat_name, desc(variable_level))

#=============================================================================
# 4. Kaplan–Meier Quartiles (Event)
#=============================================================================

fit <- survfit(
  Surv(aval, 1 - cnsr) ~ DOSGRP + lotcat,
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
  mutate(
    lotcat = word(DOSGRP, 3, sep = "="),
    DOSGRP = word(word(DOSGRP, 2, sep = "="), 1, sep = ","),
  )

# --- Prepare ARD2 ---
ard2 <- out |>
  mutate(
    stat = map(value, ~.x),
    stat_name = str_trim(estimate_type),
    variable_level = map(percent, ~.x),
    variable = "OUER",
    group1 = "DOSGRP",
    group1_level = map(DOSGRP, ~.x),
    group2 = "lotcat",
    group2_level = map(lotcat, ~.x)
  ) |>
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
  mutate(
    lotcat = word(strata, 3, sep = "="),
    DOSGRP = word(word(strata, 2, sep = "="), 1, sep = ","),
  ) |>
  select(DOSGRP, lotcat, time, surv, low, high)

# --- Convert to Long Format ---
tim_long <- timx |>
  pivot_longer(
    cols = c(surv, low, high),
    names_to = "Type",
    values_to = "Value"
  ) |>
  mutate(Type = recode(Type, surv = "estimate2", low = "low", high = "high")) |>
  arrange(DOSGRP, lotcat, time, match(Type, c("estimate2", "low", "high")))

ard4 <- tim_long |>
  mutate(
    stat = map(Value, ~.x),
    stat_name = str_trim(Type),
    variable_level = map(as.character(time), ~.x),
    variable = "SURV",
    group1 = "DOSGRP",
    group1_level = map(DOSGRP, ~.x),
    group2 = "lotcat",
    group2_level = map(lotcat, ~.x)
  ) |>
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

#=============================================================================
# 7. Combine ARDs and Prepare Output
#=============================================================================

ard <- bind_rows(ard1, ard2, ard4) |>
  select(
    group1,
    group2,
    group2_level,
    variable,
    stat_name,
    stat,
    variable_level,
    group1_level
  )

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
  select(DOSGRP, group2_level, variable, stat_name, stat, label)

# Calculate big N
df_big_N <- ard_categorical(
  data = pop,
  variables = "DOSGRP",
  by = "lotcat",
  statistic = everything() ~ c("n")
) |>
  shuffle_ard() |>
  select(DOSGRP = variable_level, N = stat, group2_level = lotcat)


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
  ) |>
  arrange(ord) |>
  select(-ord)

# DUMMY
DUMMY <-
  crossing(
    crossing(
      tibble(
        #tt_avid=rep(1, 6),
        ord = c(
          0,
          1,
          1,
          2,
          2,
          3,
          4,
          4,
          5,
          6,
          6,
          7,
          8,
          8,
          9,
          10,
          10,
          11,
          12,
          12,
          13,
          14,
          14
        ),
        label = c(
          "Number of Responders, N",
          "Number of Events, n %",
          "Number of Events, n %",
          "Number of Censors, n %",
          "Number of Censors, n %",
          "25% Quartile",
          "  95% CI of 25% Quartile",
          "  95% CI of 25% Quartile",
          "Median",
          "  95% CI of Median",
          "  95% CI of Median",
          "75% Quartile",
          "  95% CI of 75% Quartile",
          "  95% CI of 75% Quartile",
          "6 months",
          "  95% CI at 6 months",
          "  95% CI at 6 months",
          "9 months",
          "  95% CI at 9 months",
          "  95% CI at 9 months",
          "12 months",
          "  95% CI at 12 months",
          "  95% CI at 12 months"
        ),
        variable = c(
          "Number of Responders, N",
          "Number of Responders, N",
          "Number of Responders, N",
          "Number of Responders, N",
          "Number of Responders, N",
          "Duration of Response, month",
          "Duration of Response, month",
          "Duration of Response, month",
          "Duration of Response, month",
          "Duration of Response, month",
          "Duration of Response, month",
          "Duration of Response, month",
          "Duration of Response, month",
          "Duration of Response, month",
          "Event-free Rate at, %",
          "Event-free Rate at, %",
          "Event-free Rate at, %",
          "Event-free Rate at, %",
          "Event-free Rate at, %",
          "Event-free Rate at, %",
          "Event-free Rate at, %",
          "Event-free Rate at, %",
          "Event-free Rate at, %"
        ),
        stat_name = c(
          "N",
          "n",
          "p",
          "n",
          "p",
          "estimate",
          "lower",
          "upper",
          "estimate",
          "lower",
          "upper",
          "estimate",
          "lower",
          "upper",
          "estimate2",
          "low",
          "high",
          "estimate2",
          "low",
          "high",
          "estimate2",
          "low",
          "high"
        ),
      ),
      DOSGRP = unique(df_big_N$DOSGRP)
    ),
    group2_level = unique(df_big_N$group2_level)
  )

fin <- fin |>
  #filter(stat_name %in% c("estimate") & DOSGRP=="Total")|>
  mutate(
    #label=str_trim(label),
    group2_level = str_trim(group2_level)
  )


fin1 <- merge(
  fin,
  DUMMY,
  by = c("DOSGRP", "group2_level", "stat_name", "variable", "label"),
  all.x = TRUE
)

df_big_N <- ard_stack(
  data = pop,
  .by = c(DOSGRP, lotcat),
  ard_tabulate(variables = c(studyid)),
  #.overall = TRUE,
  #.total_n = TRUE
) |>
  filter((stat_name == "N" & variable=="studyid"))|>
  mutate(stat_name="BigN",
         group2_level = unlist(group2_level),
         stat = unlist(stat),
         DOSGRP = unlist(group1_level))|>
  select(DOSGRP, group2_level, variable, stat_name, stat)

final0<- bind_rows(fin1, df_big_N)

final_del<- final0|>
  filter(label == "Number of Events, n %" & stat==0 & stat_name=="n")|>
  mutate(del_fl="Y")|>
  select(DOSGRP, group2_level, del_fl)

final1 <- merge(
  final0,
  final_del,
  by = c("DOSGRP", "group2_level"),
  all.x = TRUE
)|>
  mutate(delfl1=case_when(variable=="Duration of Response, month" & is.na(stat) & del_fl=="Y"~"Y"))
final <-final1|>
  # filter(is.na(delfl1))|>
  select(-delfl1, -del_fl)



#=============================================================================
# 9. Table Formatting (tfrmt)
#=============================================================================

THL <- tfrmt(
  group = c(group2_level, variable),
  label = label,
  param = stat_name,
  value = stat,
  column = DOSGRP,
  sorting_cols = ord,
  #sorting_cols = c("group2_level", "ord"),
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
          ">0" ~ frmt("(xxx%)", , transform = ~ . * 100),
          "TRUE" ~ frmt("")
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
  big_n = big_n_structure(
    param_val = "BigN",
    n_frmt = frmt("\n(N=x)"),
    by_page = TRUE
  ),
  col_plan = col_plan(label, C120, `T200/C240`, `T300/C400`, T500, `T600/C600`, C800, C1200, Total),
  row_grp_plan = row_grp_plan(
    row_grp_structure(group_val = ".default", element_block(post_space = " ")),
    row_grp_structure(
      group_val = list(variable = "Number of Events, n %"),
      element_block(post_space = NULL)
    ),
    row_grp_structure(
      group_val = list(variable = "Number of Censors, n %"),
      element_block(post_space = NULL)
    ),
    label_loc = element_row_grp_loc(location = "spanning")
  ),
  page_plan = page_plan(page_structure(group_val = list(group2_level = ".default")))
) 

final_gt_obj <- print_to_gt(THL, final) 

# 3. Build the RTF using the flattened gt object.
rtf_dt <- final_gt_obj|>
  rtf_table(
    page_group_label = paste("Line of Therapy:", group2_level),
    row_noorphan_col = group2_level,
    drop_columns = ord
  ) |>
  rtf_col_align(starts_with(c("C", "T")) ~ "center", .group = "header") |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.35in") |>
  rtf_col_label(label = "") |>
  rtf_paginate_cols(id_columns = label, split_at = 5) |>
  rtf_title(
    "Table 14.2.3e",
    "Summary of Duration of Response by Line of Therapy (Phase 1 & 1b pooled)"
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
  build_rtf(file = file.path(g_paths$output,"t_ef_dor_lot_pool_r.rtf"))




#|>
#  print_to_gt(ard_tbl)
# By trt groups
# print_by <- function(df_input, trt) {
#   df_trt <- df_input |> filter(group2_level == trt)
#   print_to_gt(THL, df_trt) |>
#     tab_header(title = md(glue::glue("Line of Therapy: {trt}")))
# }
# sec_01 <- unique(arrange(final, group2_level)$group2_level) |>
#   map(~ print_by(final, .x))
# THL <- gt_group(.list = sec_01)
# 
# THL
# footnote1_1 <- file.path('/mnt', 'code', 'prod', 'tfls', 't_ef_dor_lot_pool_r.R')
# footnote1_2 <- format(Sys.time(), "%d%b%Y  %H:%M") |> toupper()
# # additional steps with docorator
# THL |>
#   as_docorator(
#     filename = paste0('t_ef_dor_lot_pool_r', '.pdf'),
#     path = output_path,
#     tbl_stub_pct = c(0.3),
#     header = fancyhead(
#       fancyrow(left = "IDRX-42-001 ", center = NA, right = doc_pagenum()),
#       fancyrow(
#         left = "Population: Efficacy",
#         center = NA,
#         right = "Data as of 15SEP2025"
#       ),
#       fancyrow(left = NA, center = "Table 14.2.3e", right = NA),
#       fancyrow(
#         left = NA,
#         center = "Summary of Duration of Response by Line of Therapy (Phase 1 & 1b pooled)",
#         right = NA
#       ),
#       fancyrow(left = NA, center = NA, right = NA)
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
#   )


#saving final dataset for validation in parquet format
write_parquet(final, file.path(g_paths$dddata, "t_ef_dor_lot_pool_r.parquet"))

#Getting parquet file
t_ef_dor_lot_pool_r.parquet <- read_parquet(file.path(g_paths$dddata, "t_ef_dor_lot_pool_r.parquet"))
