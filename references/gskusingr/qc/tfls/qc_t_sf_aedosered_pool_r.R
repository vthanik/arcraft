####------------------------------------------------------------------------####
# Program Name: qc_t_sf_aedosered_pool_r.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Summary of Treatment-Emergent Adverse Events Leading to IDRX-42 Dose 
# Reduced by System Organ Class and Preferred Term (Phase 1 & 1b pooled)
#
# Input:
#   - adam [adbs, adae]
# Output:
#   - t_sf_aedosered_pool_r.lst
#
# External files called:
#
#
# Additional Notes:
#
#-------------------------------------------------------------------------------

# --- Load Libraries ---
libs <- c("dplyr", "forcats", "stringr", "purrr", "cards", "tfrmt", "gt", "admiral","arrow")
pkg_attach(libs)

# Load base data
adbs <- adbs <- read_data_catalog(adamdata$adbs) 
adbs_1 <- convert_blanks_to_na(adbs) %>%
  filter(SAFFL == "Y") %>%
  select(SUBJID,USUBJID,SAFFL,DOSGRP,DOSGRPN)

# Load adverse event data
adae <- adbs <- read_data_catalog(adamdata$adae) 
adae_1 <- convert_blanks_to_na(adae)%>%
  filter(SAFFL == "Y" & (AEACNN == 3 | AEACN2N == 3 | AEACN3N == 3) & TRTEMFL == "Y") %>%
  select(USUBJID, SUBJID, AEDECOD, AESOC, AEBODSYS, AETERM) %>%
  mutate(
    AESOC = if_else(!is.na(AESOC), AESOC, "Not Coded"),
    AEDECOD = if_else(!is.na(AEDECOD), AEDECOD, "Not coded")
  ) %>%
  left_join(adbs_1 %>% select(USUBJID, DOSGRP, DOSGRPN), by = "USUBJID")


# Create an ARD that stacks hierarchical data of adverse events
# Grouping by treatment, system organ class, and preferred term
ae_ard1 <- ard_stack_hierarchical(
  data = adae_1,
  by = c(DOSGRP),
  variables = c(AESOC, AEDECOD),
  statistic = ~ c("n", "p"), # Calculate count and percentage
  denominator = adbs_1,
  id = USUBJID,
  over_variables = TRUE,
  total_n = TRUE
)

#ae_ard1 <- ae_ard1 |>
#filter(context != "categorical")

ae_ard_overall1 <- ard_stack_hierarchical(
  data = adae_1,
  by = NULL,
  variables = c(AESOC, AEDECOD),
  statistic = ~ c("n", "p"), # Calculate count and percentage
  denominator = adbs_1,
  id = USUBJID,
  over_variables = TRUE
)

# Filter adae and adsl with trt01a set to "Total" and create a new ARD for the total column
adae2 <- adae_1 |>
  mutate(DOSGRP = "Total")
adbs2 <- adbs_1 |>
  mutate(DOSGRP = "Total")

ae2_ard1 <- ard_stack_hierarchical(
  data = adae2,
  by = c(DOSGRP),
  variables = c(AESOC, AEDECOD),
  denominator = adbs2,
  statistic = ~ c("n", "p"),
  id = USUBJID,
  over_variables = TRUE
)

ae2_ard_overall1 <- ard_stack_hierarchical(
  data = adae2,
  by = NULL,
  variables = c(AESOC, AEDECOD),
  denominator = adbs2,
  statistic = ~ c("n", "p"),
  id = USUBJID,
  over_variables = TRUE
)

# Keep required DOSGRP "TOTAL" rows
ae22_ard1 <- ae2_ard1 |>
  bind_ard(ae2_ard_overall1) |>
  #filter(variable!="STUDYPRT" &
  filter(group1 != "AESOC")

ae2_ard1 <- ae_ard1 |>
  bind_ard(ae_ard_overall1)

ae3_ard1 <-
  #combine the ards and then convert to be in the format required for tfrmt
  bind_ard(ae2_ard1, ae22_ard1) |>
  rename_ard_columns() |>
  unlist_ard_columns() |>
  #add labels for total treatment and STUDYPRT we will use the total STUDYPRT for sorting
  mutate(
    DOSGRP = ifelse(is.na(DOSGRP), "Total", DOSGRP),
    # label any event rows for top level any event and each aesoc any event rows
    AEDECOD = ifelse(
      !is.na(..ard_hierarchical_overall..) &
        ..ard_hierarchical_overall.. == TRUE |
        is.na(AEDECOD) & !is.na(AESOC),
      "ANY EVENT",
      AEDECOD
    ),
    # update na rows in AESOC to be ANY EVENT so labels appear correctly in tfrmt
    AESOC = ifelse(
      AEDECOD == "ANY EVENT" &
        is.na(AESOC),
      "ANY EVENT",
      AESOC
    ),
    # create bigN values
    stat_name = ifelse(
      is.na(AEDECOD) & stat_name == "n" | context == "total_n",
      "bigN",
      stat_name
    )
  ) |>
  # filter to just the needed stats
  filter(!(is.na(AEDECOD) & stat_name %in% c("N", "p")))

# create ordering columns, sort by AESOC
ordering_AESOC1 <- ae3_ard1 |>
  filter(DOSGRP == "Total", stat_label == "n", AEDECOD == "ANY EVENT")

d_ordering_AESOC1 <- ordering_AESOC1 %>%
  distinct(.keep_all = TRUE) |>
  arrange(desc(stat)) |>
  mutate(ord1 = row_number()) |>
  select(AESOC, ord1)

# sort by AEDECOD after AESOC order
ordering_AEDECOD1 <- ae3_ard1 |>
  filter(DOSGRP == "Total", stat_name == "n")

d_ordering_AEDECOD1 <- ordering_AEDECOD1 %>%
  distinct(.keep_all = TRUE) |>
  group_by(AESOC) |>
  arrange(desc(stat)) |>
  mutate(ord2 = row_number()) |>
  select(AESOC, AEDECOD, ord2)

# join on our ordering columns and keep required columns
ae4_ard1 <- ae3_ard1 |>
  full_join(d_ordering_AESOC1, by = "AESOC") |>
  full_join(d_ordering_AEDECOD1, by = c("AESOC", "AEDECOD")) |>
  select(AESOC, AEDECOD, ord1, ord2, stat, stat_name, DOSGRP)

d_ae4_ard1 <- ae4_ard1 |> distinct(.keep_all = TRUE)

qc <-  d_ae4_ard1 |>
  mutate(variable=AESOC, variable_level=AEDECOD,
         stat_name = ifelse(stat_name=="bigN","popn",stat_name),
         variable = ifelse(variable=="ANY EVENT","Patients with Any TEAE",variable),
         variable_level = ifelse(variable_level=="ANY EVENT","Any event",variable_level),
         variable_level = ifelse(variable=="Patients with Any TEAE", "Patients with Any TEAE", variable_level),
         stat=if_else(stat_name == "p", stat * 100, stat)
  ) |> filter(stat != "0") |>
  select(DOSGRP, variable, variable_level, stat_name, stat) |>
  arrange(DOSGRP, variable, variable_level, stat_name)

prod <- read_parquet(file.path(g_paths$dddata,"t_sf_aedosered_pool_r.parquet")) |>
  filter(stat != "0") |>
  arrange(DOSGRP, variable, variable_level, stat_name)

# Compare
diffdf::diffdf(
  prod,
  qc
)



