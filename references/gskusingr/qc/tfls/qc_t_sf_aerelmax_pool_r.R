####------------------------------------------------------------------------####
# Program Name: qc_t_sf_aerelmax_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Summary of IDRX-42-related Treatment-Emergent Adverse Events by System Organ Class, 
#          Preferred Term and Maximum CTCAE Grade (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adae]
# Output:
#   - dd []
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------
 # --- Load Libraries ---
  libs <- c("dplyr", "tidyr", "forcats", "stringr", "purrr", "admiral","arrow")
  pkg_attach(libs)
  
  # --- Load base data ---
  adbs <- read_data_catalog(adamdata$adbs)
  adbs <- convert_blanks_to_na(adbs) %>%
    filter(SAFFL == "Y") %>%
    select(USUBJID, DOSGRP)
  
  adbs_t <- adbs |> mutate(DOSGRP="Total")
  
  adbs_1 <- rbind(adbs,adbs_t)
  
  # --- Load AE data ---
  adae <- read_sas_local(adamdata$adae)
  adae <- convert_blanks_to_na(adae) %>%
    filter(SAFFL == "Y", AREL == "Related", TRTEMFL == "Y") %>%
    mutate(
      AESOC = if_else(!is.na(AESOC), AESOC, "Uncoded SOC"),
      AEDECOD = if_else(!is.na(AEDECOD), AEDECOD, "Uncoded PT"),
      ATOXGR = as.numeric(AETOXGR)
    ) %>%
    left_join(adbs, by = "USUBJID")
  
  adae_t <- adae |> mutate(DOSGRP="Total")
  
  adae_1 <- rbind(adae,adae_t)
  
  adae_test <- adae_1 |>  select(USUBJID, DOSGRP, AESOC, AEDECOD, ATOXGR)
  
  # --- Denominator per treatment ---
  denom <- adbs_1 %>%
    group_by(DOSGRP) %>%
    summarise(N_total = n_distinct(USUBJID), .groups = "drop") |> 
    mutate(DOSGRP_N = paste0(DOSGRP, " (N=", N_total, ")"))
  
  adae_first_max <- adae_1 %>%
    filter(
      !is.na(ATOXGR)
    ) %>%
    group_by(USUBJID, DOSGRP) %>%
    filter(ATOXGR == max(ATOXGR, na.rm = TRUE)) %>%  # keep only max ATOXGR
    slice(1) %>%                                    # take first record among max
    ungroup() |> 
    mutate(
      Grade = case_when(
        ATOXGR == 1 ~ "Grade 1",
        ATOXGR == 2 ~ "Grade 2",
        ATOXGR == 3 ~ "Grade 3",
        ATOXGR == 4 ~ "Grade 4",
        ATOXGR == 5 ~ "Grade 5",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!is.na(Grade)) |> 
    select(USUBJID, DOSGRP, AESOC, AEDECOD, Grade)
  
  patient_teae <- adae_first_max %>%
    group_by(DOSGRP, Grade) %>%
    summarise(
      n = n_distinct(USUBJID),
      .groups = "drop"
    ) |> 
    left_join(denom, by = "DOSGRP") %>%
    mutate(
      AESOC = "Patients with Any TEAE",
      AEDECOD = "Patients with Any TEAE",
      p = 100 * n / N_total,
      n_total=n
    )
  
  patient_teae_t <- patient_teae |> 
    select(DOSGRP,Grade,n_total)
    
  adae_first_socmax <- adae_1 %>%
    filter(
      !is.na(ATOXGR)
    ) %>%
    group_by(USUBJID, DOSGRP, AESOC) %>%
    filter(ATOXGR == max(ATOXGR, na.rm = TRUE)) %>%  # keep only max ATOXGR
    slice(1) %>%                                    # take first record among max
    ungroup() |> 
    mutate(
      Grade = case_when(
        ATOXGR == 1 ~ "Grade 1",
        ATOXGR == 2 ~ "Grade 2",
        ATOXGR == 3 ~ "Grade 3",
        ATOXGR == 4 ~ "Grade 4",
        ATOXGR == 5 ~ "Grade 5",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!is.na(Grade)) |> 
    select(USUBJID, DOSGRP, AESOC, AEDECOD, Grade)
  
  # --- Maximum grade per patient per AE ---
  adae_max <- adae_1 %>%
    group_by(USUBJID, DOSGRP, AESOC, AEDECOD) %>%
    slice_max(order_by = ATOXGR, n = 1, with_ties = FALSE) %>%  # keep only one record with max ATOXGR
    ungroup() %>%
    mutate(
      Grade = case_when(
        ATOXGR == 1 ~ "Grade 1",
        ATOXGR == 2 ~ "Grade 2",
        ATOXGR == 3 ~ "Grade 3",
        ATOXGR == 4 ~ "Grade 4",
        ATOXGR == 5 ~ "Grade 5",
        TRUE ~ NA_character_
      )
    ) %>%
    filter(!is.na(Grade)) |> 
    select(USUBJID, DOSGRP, AESOC, AEDECOD, Grade)
  
  # --- Patients with Any TEAE per grade --- 
  # Count each patient once per grade
  teae_any <- adae_first_max %>%
    select(USUBJID, DOSGRP, Grade) %>%
    distinct() %>%
    group_by(DOSGRP, Grade) %>%
    summarise(n = n_distinct(USUBJID), .groups = "drop") %>%
    left_join(denom, by = "DOSGRP") %>%
    mutate(
      AESOC = "Patients with Any TEAE",
      AEDECOD = "Patients with Any TEAE",
      p = 100 * n / N_total,
      n_total=n
    )
  
  teae_any_t <- teae_any |> 
    select(DOSGRP,Grade,n_total)
  
  # --- PT-level counts ---
  pt_counts <- adae_max %>%
    group_by(DOSGRP, AESOC, AEDECOD, Grade) %>%
    summarise(n = n_distinct(USUBJID), .groups = "drop") %>%
    left_join(denom, by = "DOSGRP") %>%
    mutate(p = 100 * n / N_total)
  
  # --- SOC-level Any event counts ---
  soc_any <- adae_first_socmax %>%
    group_by(DOSGRP, AESOC, Grade) %>%
    summarise(n = n_distinct(USUBJID), .groups = "drop") %>%
    left_join(denom, by = "DOSGRP") %>%
    mutate(
      AEDECOD = "Any event",
      p = 100 * n / N_total
    )
  
  # --- Combine all ---
  ae_final <- bind_rows(patient_teae, soc_any, pt_counts) %>%
    arrange(DOSGRP, AESOC, AEDECOD, Grade) %>%
    pivot_longer(cols = c(n, p), names_to = "Measure", values_to = "Value") %>%
    select(DOSGRP, Grade, AESOC, AEDECOD, Measure, Value) |> 
    left_join(denom, select(DOSGRP,DOSGRP_N), by="DOSGRP")
  
  # --- View final table ---
  ae_final 

qc <-  ae_final |>
  mutate(variable=AESOC, variable_level=AEDECOD, col_label=DOSGRP_N, ATOXGR=Grade,
         stat_name=Measure, stat=Value) |> 
         filter(stat != "0") |>
  select(DOSGRP, col_label, ATOXGR, variable, variable_level, stat_name, stat) |>
  arrange(DOSGRP, ATOXGR, variable, variable_level, stat_name)

prod <- read_parquet(file.path(g_paths$dddata,"t_sf_aerelmax_pool_r.parquet")) |>
  filter(stat != "0" & ATOXGR != "Total") |>
  arrange(DOSGRP, ATOXGR, variable, variable_level, stat_name)

diffdf::diffdf(base = prod ,
       compare = qc,
       keys = c('DOSGRP', 'col_label', 'ATOXGR', 'variable','variable_level','stat_name'))
