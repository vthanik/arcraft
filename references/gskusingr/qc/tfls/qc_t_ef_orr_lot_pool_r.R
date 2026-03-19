####------------------------------ GSK Header R v1.0 ---------------------####
# Program Name:  qc_t_ef_orr_lot_pool_r.R
# Compound/Study/Reporting Effort: 300382_INTERNAL_05_ANALYSIS
#
# OS / R Version: Frozen 4.3.1
#
# Purpose:  QC Summary of Best Overall Response and Objective Response Rate by line of therapy subgroup (Phase 1 & 1b pooled)
#
# Input: n/a
# Output: qc_t_ef_orr_lot_pool_r.log, qc_t_ef_orr_lot_pool_r.lst
#
# External files called: see source and library statements below
#
#-----------------------------------------------------------------------------
# ~Change Log~
# Version | Developer | Date        | Description
# 1       | sk575206  | 22-DEC-2025 | Initial commit

#-----------------------------------------------------------------------------

libs <- c("dplyr", "forcats", "stringr", "tidyr", "purrr", "cards", "binom", "tfrmt", "arrow", "docorator", 
          "admiral", "haven", "diffdf", "xportr", "metacore", "metatools", "tidyverse")
pkg_attach(libs)

# --- Load and prepare ADBS dataset ---
adbs <- read_data_catalog(adamdata$adbs) %>%
  convert_blanks_to_na() %>%
  filter(EFFL == "Y" & !is.na(TRT01A)) %>%
  select(-starts_with("trt")) %>%
  rename_with(tolower) %>%
  mutate(ARM = dosgrp) %>%
  filter(!is.na(lotcat))

adbsx <- adbs %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adbs)

# --- Create population dataset by mutation status ---
pop <- adbsx
# --- Read ADEF dataset ---
adf <- read_data_catalog(adamdata$adeff) %>%
  convert_blanks_to_na() %>%
  rename_with(tolower) %>%
  filter(acat2 == "INVESTIGATOR", paramcd == "BOR")

adf <- inner_join(adbs, adf, by = "usubjid")

adf2 <- adf %>%
  mutate(ARM = "Total", dosgrpn = 999) %>%
  bind_rows(adf)

# --- Add mutation flags for each exon ---
adf3 <- adf2

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
  .by = c(ARM, lotcat),
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
  group_by(lotcat, paramcd, ARM) %>%
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
  select(lotcat, paramcd, ARM, X, proportion, lowerCL, upperCL) %>%
  pivot_longer(
    cols = c(X, proportion, lowerCL, upperCL),
    names_to = "stat_name",
    values_to = "stat"
  ) %>%
  mutate(ARM = ARM) %>%
  arrange(lotcat, paramcd, ARM, stat_name)

# --- Prepare ARD2 for ORR ---
ard2 <- rr1_long %>%
  mutate(
    stat = map(stat, ~.x),
    variable_level = map(paramcd, ~.x),
    variable = "ORR",
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
  count(ARM, lotcat) %>%
  complete(ARM, lotcat, fill = list(n = 0)) %>%
  mutate(
    stat_name = "BigN",
    stat = map(n, ~.x),
    variable_level = map("n", ~.x),
    variable = "bignn",
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
    variable,
    variable_level,
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
    label = ifelse(is.na(label), stat_name, label)
  ) %>%
  select(ARM, variable, lotcat, stat_name, stat, label)


# --- Final dataset formatting ---
fin <- ard_tbl %>%
  mutate(
    variable = ifelse(
      variable == "Objective Response" &
        stat_name %in% c("X", "proportion", "lowerCL", "upperCL"),
      label,
      variable
    ),
    
    ARM = factor(
      ARM,
      c(
        "C120",
        "T200/C240",
        "T300/C400",
        "T500",
        "T600/C600",
        "C800",
        "C1200",
        "Total"
      ),
      c(
        "C120",
        "T200/C240",
        "T300/C400",
        "T500",
        "T600/C600",
        "C800",
        "C1200",
        "Total"
      )
    )
  )

prod <- read_parquet(file.path(g_paths$dddata, "t_ef_orr_lot_pool_r.parquet")) %>%
  rename_with(tolower) %>%
  filter(stat_name != 'N') %>%
  filter(label != 'UNKNOWN') %>%
  mutate(
    variable = str_trim(stat_variable),
    variable = ifelse(
      label == "95% exact Confidence Interval",
      "95% exact Confidence Interval",
      variable
    ),
    
    stat_name = ifelse(stat_name == "CH", "upperCL", stat_name),
    stat_name = ifelse(stat_name == "CL", "lowerCL", stat_name),
    stat_name = ifelse(
      label == "Objective Response Rate" & stat_name == "n",
      "X",
      stat_name
    ),
    stat_name = ifelse(
      label == "Objective Response Rate" & stat_name == "p",
      "proportion",
      stat_name
    )
  ) %>%
  select(dosgrp, lotcat, variable, stat_name, stat, label)


qc <- fin %>%
  unlist_ard_columns() %>%
  filter(!is.na(stat)) %>%
  filter(stat != 0) %>%
  mutate(
    dosgrp = as.character(ARM),
    stat = ifelse(
      stat_name %in% c("lowerCL", "upperCL"),
      stat * 100,
      stat
    )
  ) %>% 
  select(-ARM) %>%
  arrange(lotcat, variable, label, stat_name)

prod <- prod %>%
  filter(!is.na(stat)) %>%
  filter(stat != 0) %>%
  arrange(lotcat, variable, label, stat_name)

diff_results <- diffdf(
  prod,
  qc,
  file = "/mnt/data/61834_300382_INTERNAL_05_ANALYSIS/misc/qc_t_ef_orr_lot_pool_r.lst"
)
print(diff_results)