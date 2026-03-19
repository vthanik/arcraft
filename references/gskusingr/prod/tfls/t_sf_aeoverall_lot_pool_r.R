####------------------------------------------------------------------------####
# Program Name: t_sf_aeoverall_lot_pool_r.R
# Domino Project: 61834_300382_INTERNAL_05
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Naga Laxmi Chinthala/ nc450888
# Purpose: Table 14.3.1.1e-Overall Summary of Treatment Emergent Adverse Events
#          by Line of Therapy, (Phase 1 & 1b pooled)
# Input: ADBS, ADAE
# Output: [N/A]
# External files called:
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# --- Load Libraries ----
pkg_load(
  "gt",
  "tfrmt",
  "admiral",
  "dplyr",
  "forcats",
  "cards",
  "cardx",
  "stringr",
  "tidyr",
  "arrow",
  "survival",
  "tibble",
  "docorator"
)

# Creating all rows for treatments and lotcat
dos_grp <- c(
  "C120",
  "T200/C240",
  "T300/C400",
  "T500",
  "T600/C600",
  "C800",
  "C1200",
  "Total"
)
lot_grp <- c("1st-line", "2nd-line", "3rd or later-line")

# Read input datasets
adbs <- read_data_catalog(adamdata$adbs)

adbs <- adbs |>
  filter(!is.na(DOSGRP) & SAFFL == "Y") |>
  select("STUDYID", "USUBJID", "SUBJID", "LOTCAT", "SAFFL", "DOSGRPN", "DOSGRP")

adbs <- adbs |> convert_blanks_to_na()

adbs1 <- adbs |>
  mutate(DOSGRP = "Total", DOSGRPN = 999)


adbs2 <- adbs |>
  rbind(adbs1) |>
  mutate(
    DOSGRP = factor(DOSGRP, levels = dos_grp, labels = dos_grp),
    LOTCAT = factor(LOTCAT, levels = lot_grp, labels = lot_grp)
  )

adae <- read_data_catalog(adamdata$adae) |>
  convert_blanks_to_na() |>
  filter(TRTEMFL == "Y" & SAFFL == "Y") |>
  mutate(
    AESOC = if_else(!is.na(AESOC), AESOC, "Not Coded"),
    AEDECOD = if_else(!is.na(AEDECOD), AEDECOD, "Not coded")
  ) |>
  left_join(adbs |> select(USUBJID, DOSGRP, DOSGRPN, LOTCAT), by = "USUBJID")

adae1 <- adae |>
  mutate(DOSGRP = "Total", DOSGRPN = 999)

adae2 <- adae |>
  rbind(adae1) |>
  mutate(
    DOSGRP = factor(DOSGRP, levels = dos_grp, labels = dos_grp),
    LOTCAT = factor(LOTCAT, levels = lot_grp, labels = lot_grp)
  )

# Recode variable for ease of use in the table
adae_1 <- adae2 |>
  filter(SAFFL == "Y" & TRTEMFL == "Y" & !is.na(DOSGRP))

adae_2 <- adae_1 |>
  mutate(
    # dummy variable to count the ANY AE
    ANYAE = "TEAE",
    AERELAE = as.factor(if_else(AREL == 'Related', "Y", "N")),
    AETOX = as.factor(if_else(ATOXGRN >= 3, "Y", "N")),
    AERELTOX = as.factor(if_else(ATOXGRN >= 3 & AREL == 'Related', "Y", "N")),
    AEPERDIS = as.factor(if_else(
      (grepl("DRUG WITHDRAWN", AEACN, ignore.case = TRUE) |
         toupper(AEACN2) == "WITHDRAWN FROM STUDY"),
      "Y",
      "N"
    )),
    AEDRED = as.factor(if_else(
      grepl("DOSE REDUCED", AEACN, ignore.case = TRUE),
      "Y",
      "N"
    )),
    AEDI = as.factor(if_else(
      grepl("DRUG INTERRUPTED", AEACN, ignore.case = TRUE),
      "Y",
      "N"
    )),
    #AEMAE = as.factor(if_else(grepl("MEDICALLY ATTENDED", AEACNOTH, ignore.case=TRUE),"Y","N")),
    SAEREL = as.factor(if_else(AESER == "Y" & AREL == "Related", "Y", "N")),
    AEFAT = as.factor(if_else(AESER == "Y" & AESDTH == 'Y', "Y", "N")),
    AEDLT = as.factor(if_else(AEDLT == "Y", "Y", "N"))
  )

# Any AE
adae_any <- adae_2 |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

ard_ae <- ard_categorical(
  data = adae_any,
  by = c(LOTCAT, DOSGRP),
  variables = ANYAE,
  statistic = ~ c("n", "p"), # Calculate count and percent only
  denominator = adbs2
) |>
  mutate(label = "TEAE")

# AEs related to study treatment
adae_any_rel <- adae_2 |>
  filter(AERELAE == "Y") |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

ard_rel_ae <- ard_categorical(
  data = adae_any_rel,
  by = c(LOTCAT, DOSGRP),
  variables = AERELAE,
  statistic = ~ c("n", "p"), # Calculate count and percent only
  denominator = adbs2
) |>
  mutate(label = "IDRX-42-related TEAE")

# AEs Grade 3 or Higher
adae_tox <- adae_2 |>
  filter(AETOX == "Y") |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

ard_tox <- ard_categorical(
  data = adae_tox,
  by = c(LOTCAT, DOSGRP),
  variables = AETOX,
  statistic = ~ c("n", "p"), # Calculate count and percent only
  denominator = adbs2
) |>
  mutate(label = "TEAE with Grade 3 or Higher")


# AEs Related Grade 3 or Higher
adae_rel_tox <- adae_2 |>
  filter(AERELTOX == "Y") |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

ard_rel_tox <- ard_categorical(
  data = adae_rel_tox,
  by = c(LOTCAT, DOSGRP),
  variables = AERELTOX,
  statistic = ~ c("n", "p"), # Calculate count and percent only
  denominator = adbs2
) |>
  mutate(label = "IDRX-42-related TEAE with Grade 3 or Higher")

# AEs leading to permanent discontinuation of study treatment
ae_disc <- adae_2 |>
  filter(AEPERDIS == "Y") |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

# Check if there are any non-missing, non-empty values in AEPERDIS
has_valid_data <- ae_disc |>
  filter(!is.na(AEPERDIS), AEPERDIS != "") |>
  nrow() >
  0

if (has_valid_data) {
  # Run ard_categorical only if valid data exists
  ard_ae_disc <- ard_categorical(
    data = ae_disc,
    by = c(LOTCAT, DOSGRP),
    variables = AEPERDIS,
    statistic = ~ c("n", "p"),
    denominator = adbs2
  ) |>
    mutate(
      label = "TEAEs leading to permanent discontinuation of study treatment"
    )
} else {
  # Create an empty or placeholder dataframe with expected structure
  ard_ae_disc <- tibble(
    LOTCAT = character(),
    DOSGRP = character(),
    AEPERDIS = character(),
    n = integer(),
    p = numeric()
    # Add other columns as needed based on ard_categorical output
  ) |>
    mutate(
      label = "TEAE leading to IDRX-42 Withdrawal"
    )
  
  message("No valid AEPERDIS data found; returning empty dataset.")
}

# AE leading to dose reduction
ae_red <- adae_2 |>
  filter(AEDRED == "Y") |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

# Check if there are any non-missing, non-empty values in AEDRED
has_valid_data <- ae_red |>
  filter(!is.na(AEDRED), AEDRED != "") |>
  nrow() >
  0

if (has_valid_data) {
  # Run ard_categorical only if valid data exists
  ard_ae_red <- ard_categorical(
    data = ae_red,
    by = c(LOTCAT, DOSGRP),
    variables = AEDRED,
    statistic = ~ c("n", "p"),
    denominator = adbs2
  ) |>
    mutate(label = "TEAE leading to IDRX-42 Dose Reduction")
} else {
  # Create an empty or placeholder dataframe with expected structure
  ard_ae_red <- tibble(
    LOTCAT = character(),
    DOSGRP = character(),
    AEDRED = character(),
    n = integer(),
    p = numeric()
    # Add other columns as needed based on ard_categorical output
  ) |>
    mutate(label = "TEAE leading to IDRX-42 Dose Reduction")
  message("No valid AEDRED data found; returning empty dataset.")
}

# AE leading to dose interruption/delay
ae_dint <- adae_2 |>
  filter(AEDI == "Y") |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

# Check if there are any non-missing, non-empty values in AEDI
has_valid_data <- ae_dint |>
  filter(!is.na(AEDI), AEDI != "") |>
  nrow() >
  0

if (has_valid_data) {
  # Run ard_categorical only if valid data exists
  ard_ae_dint <- ard_categorical(
    data = ae_dint,
    by = c(LOTCAT, DOSGRP),
    variables = AEDI,
    statistic = ~ c("n", "p"),
    denominator = adbs2
  ) |>
    mutate(label = "TEAE leading to IDRX-42 Drug Interruption")
} else {
  # Create an empty or placeholder dataframe with expected structure
  ard_ae_dint <- tibble(
    LOTCAT = character(),
    DOSGRP = character(),
    AEDI = character(),
    n = integer(),
    p = numeric()
    # Add other columns as needed based on ard_categorical output
  ) |>
    mutate(label = "TEAE leading to IDRX-42 Drug Interruption")
  message("No valid AEDI data found; returning empty dataset.")
}

# Any SAE
adae_any_sae <- adae_2 |>
  filter(AESER == "Y") |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

ard_sae <- ard_categorical(
  data = adae_any_sae,
  by = c(LOTCAT, DOSGRP),
  variables = AESER,
  statistic = ~ c("n", "p"), # Calculate count and percent only
  denominator = adbs2
) |>
  mutate(label = "TESAE")

# SAEs related to study treatment
sae_rel <- adae_2 |>
  filter(SAEREL == "Y") |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

# Check if there are any non-missing, non-empty values in AEDRED
has_valid_data <- sae_rel |>
  filter(!is.na(SAEREL), SAEREL != "") |>
  nrow() >
  0

if (has_valid_data) {
  # Run ard_categorical only if valid data exists
  ard_rel_sae <- ard_categorical(
    data = sae_rel,
    by = c(LOTCAT, DOSGRP),
    variables = SAEREL,
    statistic = ~ c("n", "p"),
    denominator = adbs2
  ) |>
    mutate(label = "IDRX-42-related TESAE")
} else {
  # Create an empty or placeholder dataframe with expected structure
  ard_rel_sae <- tibble(
    LOTCAT = character(),
    DOSGRP = character(),
    SAEREL = character(),
    n = integer(),
    p = numeric()
    # Add other columns as needed based on ard_categorical output
  ) |>
    mutate(label = "IDRX-42-related TESAE")
  message("No valid SAE related to study data found; returning empty dataset.")
}

# Fatal SAE
sae_fat <- adae_2 |>
  filter(AEFAT == "Y") |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

# Check if there are any non-missing, non-empty values in AEDRED
has_valid_data <- sae_fat |>
  filter(!is.na(AEFAT), AEFAT != "") |>
  nrow() >
  0

if (has_valid_data) {
  # Run ard_categorical only if valid data exists
  ard_sae_fat <- ard_categorical(
    data = sae_fat,
    by = c(LOTCAT, DOSGRP),
    variables = AEFAT,
    statistic = ~ c("n", "p"),
    denominator = adbs2
  ) |>
    mutate(label = "TEAE leading to death")
} else {
  # Create an empty or placeholder dataframe with expected structure
  ard_sae_fat <- tibble(
    LOTCAT = character(),
    DOSGRP = character(),
    AEFAT = character(),
    n = integer(),
    p = numeric()
    # Add other columns as needed based on ard_categorical output
  ) |>
    mutate(label = "TEAE leading to death")
  message("No valid fatal data found; returning empty dataset.")
}

# Dose Limiting Toxicity
tae_dlt <- adae_2 |>
  filter(AEDLT == "Y") |>
  group_by(USUBJID, DOSGRP) |>
  slice(1) |>
  ungroup()

# Check if there are any non-missing, non-empty values in AEDRED
has_valid_data <- tae_dlt |>
  filter(!is.na(AEDLT), AEDLT != "") |>
  nrow() >
  0

if (has_valid_data) {
  # Run ard_categorical only if valid data exists
  ard_tae_dlt <- ard_categorical(
    data = tae_dlt,
    by = c(LOTCAT, DOSGRP),
    variables = AEDLT,
    statistic = ~ c("n", "p"),
    denominator = adbs2
  ) |>
    mutate(label = "Dose limiting toxicity")
} else {
  # Create an empty or placeholder dataframe with expected structure
  ard_tae_dlt <- tibble(
    LOTCAT = character(),
    DOSGRP = character(),
    AEDLT = character(),
    n = integer(),
    p = numeric()
    # Add other columns as needed based on ard_categorical output
  ) |>
    mutate(label = "Dose limiting toxicity")
  message("No valid SAE related to study data found; returning empty dataset.")
}

# Combining all data ----
adae_comb <- bind_rows(
  ard_ae,
  ard_rel_ae,
  ard_tox,
  ard_rel_tox,
  ard_ae_disc,
  ard_ae_red,
  ard_ae_dint,
  ard_sae,
  ard_rel_sae,
  ard_sae_fat,
  ard_tae_dlt
) |>
  filter(!is.na(label))

adae_comb2 <- adae_comb |>
  #convert columns to character
  mutate(
    across(
      c(
        all_ard_groups("levels"),
        all_ard_variables("levels")
      ),
      ~ lapply(., \(x) if (!is.null(x)) as.character(x))
    )
  ) |>
  #select(-DOSGRP) |>
  rename_ard_columns() |>
  unlist_ard_columns() |>
  mutate(
    label = case_when(
      !is.na(ANYAE) ~ "TEAE",
      AERELAE == "Y" ~ "IDRX-42-related TEAE",
      AETOX == "Y" ~ "TEAE with Grade 3 or Higher",
      AERELTOX == "Y" ~ "IDRX-42-related TEAE with Grade 3 or Higher",
      AEPERDIS == "Y" ~ "TEAE leading to IDRX-42 Withdrawal",
      AEDRED == "Y" ~ "TEAE leading to IDRX-42 Dose Reduction",
      AEDI == "Y" ~ "TEAE leading to IDRX-42 Drug Interruption",
      AESER == "Y" ~ "TESAE",
      SAEREL == "Y" ~ "IDRX-42-related TESAE",
      AEFAT == "Y" ~ "TEAE leading to death",
      AEDLT == "Y" ~ "Dose limiting toxicity"
    ),
    stat_name = if_else(
      stat_name == "N" &
        is.na(label),
      "bigN",
      stat_name
    )
  )

all_labels <- c(
  "TEAE",
  "IDRX-42-related TEAE",
  "TEAE with Grade 3 or Higher",
  "IDRX-42-related TEAE with Grade 3 or Higher",
  "TEAE leading to IDRX-42 Withdrawal",
  "TEAE leading to IDRX-42 Dose Reduction",
  "TEAE leading to IDRX-42 Drug Interruption",
  "TESAE",
  "IDRX-42-related TESAE",
  "TEAE leading to death",
  "Dose limiting toxicity"
)

all_labels_df <- tibble(label = all_labels)
adae_comb3 <- adae_comb2 |>
  full_join(all_labels_df, by = "label") |>
  filter(!is.na(label) & !is.na(DOSGRP))

all_treatments <- unique(adbs2$DOSGRP)
all_trt_df <- tibble(DOSGRP = all_treatments)

adae_comb4 <- adae_comb2 |>
  complete(
    label = all_labels,
    DOSGRP = all_treatments,
    fill = list(stat = 0)
  ) |>
  mutate(
    DOSGRPN = case_when(
      DOSGRP == "C120" ~ 1,
      DOSGRP == "T200/C240" ~ 2,
      DOSGRP == "T300/C400" ~ 3,
      DOSGRP == "T500" ~ 4,
      DOSGRP == "T600/C600" ~ 5,
      DOSGRP == "C800" ~ 6,
      DOSGRP == "C1200" ~ 7,
      DOSGRP == "Total" ~ 999,
      TRUE ~ NA_real_
    )
  )

adae_comb_grp <- adae_comb4 |>
  filter(!is.na(DOSGRP)) |>
  # create grouping so column is indented correctly
  mutate(
    ord = case_when(
      LOTCAT %in%
        c("1st-line") ~ 1,
      LOTCAT %in%
        c("2nd-line") ~ 2,
      LOTCAT %in%
        c("3rd or later-line") ~ 3
    ),
    ord1 = case_when(
      label %in%
        c(
          "TEAE",
          "IDRX-42-related TEAE",
          "TEAE with Grade 3 or Higher",
          "IDRX-42-related TEAE with Grade 3 or Higher"
        ) ~ 1,
      label %in%
        c(
          "TESAE",
          "IDRX-42-related TESAE"
        ) ~ 2,
      label %in%
        c(
          "TEAE leading to IDRX-42 Withdrawal",
          "TEAE leading to IDRX-42 Dose Reduction",
          "TEAE leading to IDRX-42 Drug Interruption"
        ) ~ 3,
      label %in%
        c(
          "TEAE leading to death"
        ) ~ 4,
      label %in%
        c(
          "Dose limiting toxicity"
        ) ~ 5
    ),
    ord2 = case_when(
      label == "TEAE" ~ 1,
      label == "IDRX-42-related TEAE" ~ 2,
      label == "TEAE with Grade 3 or Higher" ~ 3,
      label == "IDRX-42-related TEAE with Grade 3 or Higher" ~ 4,
      label == "TESAE" ~ 5,
      label == "IDRX-42-related TESAE" ~ 6,
      label == "TEAE leading to IDRX-42 Withdrawal" ~ 7,
      label == "TEAE leading to IDRX-42 Drug Interruption" ~ 8,
      label == "TEAE leading to IDRX-42 Dose Reduction" ~ 9,
      label == "TEAE leading to death" ~ 10,
      label == "Dose limiting toxicity" ~ 11
    ),
    group = case_when(
      label %in%
        c(
          "TEAE",
          "IDRX-42-related TEAE",
          "TEAE with Grade 3 or Higher",
          "IDRX-42-related TEAE with Grade 3 or Higher"
        ) ~ "TEAE1",
      label %in%
        c(
          "TESAE",
          "IDRX-42-related TESAE"
        ) ~ "TEAE2",
      label %in%
        c(
          "TEAE leading to IDRX-42 Withdrawal",
          "TEAE leading to IDRX-42 Dose Reduction",
          "TEAE leading to IDRX-42 Drug Interruption"
        ) ~ "TEAE3",
      label %in%
        c(
          "TEAE leading to death"
        ) ~ "TEAE4",
      label %in%
        c(
          "Dose limiting toxicity"
        ) ~ "TEAE5",
      TRUE ~ NA
    )
  ) |>
  
  arrange(ord, DOSGRPN, ord1, ord2) |>
  
  filter(!(is.na(label) & stat_name != "bigN")) |>
  # stat_name != "N")  remove rows with stat_name blank (where n p not derived)
  select(
    LOTCAT,
    DOSGRP,
    group,
    label,
    stat_name,
    stat_label,
    stat,
    ord,
    ord1,
    ord2
  ) |>
  mutate(stat = ifelse((is.na(stat) | stat == ''), 0, stat))

#bigN

bigN_df <- ard_tabulate(
  adbs2,
  by = LOTCAT,
  variables = DOSGRP
) |>
  filter(stat_name == "n") |>
  mutate(
    label = NA_character_,
    group = NA_character_,
    ord = NA_real_,
    ord1 = NA_real_,
    ord2 = NA_real_,
    stat_name = "bigN",
    stat_label = NA_character_
  ) |>
  select(
    LOTCAT = group1_level,
    DOSGRP = variable_level,
    group,
    label,
    stat_name,
    stat_label,
    stat,
    ord,
    ord1,
    ord2
  ) |>
  unlist_ard_columns()

adbs_distinct_lot <- adbs2 |>
  distinct(DOSGRP, LOTCAT)


all_ard <- bind_rows(adae_comb_grp, bigN_df)

all_ard$label <- factor(all_ard$label, levels = all_labels)

all_ard_2 <- all_ard |>
  mutate(
    stat_name = if_else(
      (is.na(stat_name) &
         is.na(stat_label) &
         stat == 0 &
         !is.na(label) &
         !is.na(DOSGRP)),
      "n",
      stat_name
    )
  ) |>
  select(-stat_label, ) |>
  mutate(
    stat = if_else(stat_name == "p" & stat != 0, stat * 100, stat)
  ) |>
  left_join(adbs_distinct_lot, by = c("DOSGRP", "LOTCAT")) |>
  mutate(across(where(is.factor), as.character))
#  filter(LOTCAT != "3rd or later-line")

#Copy the data to xpt for QC comparison

write_parquet(
  all_ard_2,
  file.path(g_paths$dddata, "t_sf_aeoverall_lot_pool_r.parquet")
)

# Define the table structure using tfrmt.
tfobj <-
  tfrmt(
    group = c(LOTCAT, group),
    label = label,
    column = DOSGRP,
    value = stat,
    param = stat_name,
    sorting_cols = ,
    body_plan = body_plan(
      frmt_structure(
        group_val = ".default",
        label_val = ".default",
        frmt_combine(
          "{n} {p}",
          n = frmt("xxx"),
          p = frmt_when(
            "==100" ~ frmt("(100%)"),
            ">99" ~ frmt("(>99%)"),
            "==0" ~ frmt(""),
            "<1" ~ frmt("( <1%)"),
            "TRUE" ~ frmt("(xxx%)")
          )
        )
      )
    ),
    col_plan = col_plan(-group),
    big_n = big_n_structure(
      param_val = "bigN",
      n_frmt = frmt("\n(N=x)"),
      by_page = TRUE
    ),
    row_grp_plan = row_grp_plan(
      row_grp_structure(
        group_val = ".default",
        element_block(post_space = " ")
      ),
      label_loc = element_row_grp_loc(location = "spanning")
    ),
    page_plan = page_plan(page_structure(group_val = list(LOTCAT = ".default")))
  )

# Convert the tfrmt object to a gt object for printing.
gt <- print_to_gt(tfobj, all_ard_2)

# --- 7. Create and Save Output in RTF ---

# Build the RTF table object with final formatting.
rtf_obj <- gt |>
  rtf_table(
    page_group_label = paste("Line of Therapy:", LOTCAT),
    drop_columns = c(ord, ord1, ord2)
  ) |>
  rtf_col_align(
    label = "left",
    starts_with(c("C", "T")) ~ "center",
    .group = "header"
  ) |>
  rtf_col_widths(starts_with(c("C", "T")) ~ "1.05in") |>
  rtf_col_label(label = "Patients Who Had Any, n(%)") |>
  rtf_paginate_cols(id_columns = label, split_at = 5) |>
  rtf_title(
    "Table 14.3.1.1e",
    "Overall Summary of Treatment Emergent Adverse Events by Line of Therapy",
    "(Phase 1 & 1b pooled)"
  ) |>
  rtf_header(
    hfrow(paste("Protocol:", g_config$studyid), "Page _PAGEOF_"),
    hfrow("Population: Safety", paste("Data as of", g_config$datadate))
  )  |>
  rtf_footer(
    "Note: Treatment-emergent adverse events (TEAE) will be recorded from the start of study treatment until",
    "30 days after the last dose of IDRX-42.",
    "Note: Adverse Events are graded with CTCAE Grade 5.0. ",
    "Note: Each patient is counted at most once in each category. TEAEs related to study drug are events reported",
    "with 'Related' and 'Possibly Related' in the relationship to study drug. Missing relatedness will be",
    "considered as 'Related'.",
    .align = "left"
  )

rtf_obj |>
  build_rtf(file = file.path(g_paths$output, "t_sf_aeoverall_lot_pool_r.rtf"))