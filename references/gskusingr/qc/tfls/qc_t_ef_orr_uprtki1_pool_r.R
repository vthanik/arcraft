####------------------------------------------------------------------------####
# Program Name: qc_t_ef_orr_uprtki1_pool_r
# Domino Project: 61834_300382_INTERNAL_05
# Domino Environment: Multilingual Frozen R4.5.0_2025-06-03v1 SASViya4
# Developer: Mariam ALaverdyan/ ma584118
# Purpose: QC t_ef_orr_uprtki1_pool_r
# Input: ADSL ADEFF
# Output: [N/A]
# External files called:
#   - /mnt/code/functions/r_setup.R
# Additional Notes: [N/A]
#
#-------------------------------------------------------------------------------

# --- Source Local R Files and Functions ----
source("/mnt/code/functions/r_setup.R")
# --- Load Libraries ----

pkg_load("dplyr", "forcats", "cards", "tfrmt", "purrr", "docorator", "haven", "diffdf", "admiral",
         "xportr", "readxl", "metacore", "metatools", "gt", "arrow", "lubridate", "tidyverse", "stringr")

# --- Load Libraries ----

pkg_attach(libs)

# --- Demo Analysis ----

adtte0 <- read_data_catalog(adamdata$adeff) |>
  filter(EFFL == "Y" & PARAMCD == "BOR" & ACAT2 == "INVESTIGATOR") |>
  select(USUBJID, AVALC)


adtteOOR0C <- read_data_catalog(adamdata$adeff) |>
  filter(EFFL == "Y" & PARAMCD == "ORRFL" & ACAT2 == "INVESTIGATOR") |>
  select(USUBJID, AVALC) |>
  mutate(
    AVALC = case_when(
      is.na(AVALC) ~ "remove",
      .default = AVALC
    ),
  )

adtteOORU0 <- read_data_catalog(adamdata$adeff) |>
  filter(
    EFFL == "Y" &
      PARAMCD == "BORU" &
      ACAT2 == "INVESTIGATOR" &
      AVALC %in% c("PR", "CR")
  ) |>
  mutate(AVALC_U = "Y") |>
  select(USUBJID, AVALC_U)
adtteOORU0 <- unique(adtteOORU0)

adtteOOR0 <- merge(adtteOOR0C, adtteOORU0, by = "USUBJID", all = TRUE) |>
  mutate(AVALC = case_when(AVALC_U == "Y" ~ "Y", TRUE ~ AVALC))

adsl0 <- read_data_catalog(adamdata$adbs) |>
  filter(EFFL == "Y") |>
  select(USUBJID, DOSGRP, DOSGRPN)

#Subjects with Prior Bezuclastinib, NB003, and THE-630
adcm <- read_data_catalog(adamdata$adcm) |>
  filter(
    CMCAT == "PRIOR CANCER THERAPY" &
      str_detect(CMTRT, regex("BEZUCLASTINIB|NB003|THE-630"))
  ) |>
  distinct(USUBJID) |>
  mutate(REMFL = "Y")

adsl <- merge(adsl0, adcm, by = "USUBJID", all.x = TRUE)

adslt0 <- adsl |>
  mutate(DOSGRP = "Total", DOSGRPN = 999)

adslt <- bind_rows(adsl, adslt0)

adtteOOR_dummy <- merge(adtteOOR0, adslt, by = "USUBJID", all.y = TRUE) |>
  mutate(
    AVALC = case_when(is.na(REMFL) ~ "N", TRUE ~ AVALC),
    AVALLAB = factor(
      AVALC,
      levels = c("Y", "N"),
      labels = c("Objective Response Rate", "remove")
    )
  )
dm_ard1 <- ard_stack(
  data = adtteOOR_dummy,
  .by = c(DOSGRP),
  ard_tabulate(variables = c(AVALLAB)),
  #.overall = TRUE,
  #.total_n = TRUE
) |>
  filter(!(stat_name == "N") & stat == 0)

adtteOOR <- merge(adtteOOR0, adslt, by = "USUBJID", all.y = TRUE) |>
  filter(!is.na(REMFL)) |>
  mutate(
    AVALLAB = factor(
      AVALC,
      levels = c("Y", "N"),
      labels = c("Objective Response Rate", "remove")
    )
  )

dm_ard2 <- ard_stack(
  data = adtteOOR,
  .by = c(DOSGRP),
  ard_tabulate(variables = c(AVALLAB)),
  #.overall = TRUE,
  #.total_n = TRUE
) |>
  filter(!(stat_name == "N") & stat != 0)

dm_ard <- bind_rows(dm_ard1, dm_ard2)

adslt <- adslt |>
  filter(!is.na(REMFL))
adtteBOR <- merge(adtteOOR, adslt, by = "USUBJID", all.y = TRUE)


ard_tbl0 <- dm_ard |>
  #filter (!(context=="tabulate" &stat_name=="N"))|>
  #reshape the data
  shuffle_card(fill_overall = "Total") |>
  # transform group-level freqs/pcts into a singular "bigN" row
  prep_big_n(vars = c("DOSGRP")) |>
  # consolidate vars into a single variable column
  prep_combine_vars(vars = c("AVALLAB")) |>
  # coalesce categorical levels + continuous stats into a "label"
  prep_label() |>
  # filter (context=="summary")|>
  group_by(DOSGRP, stat_variable) |>
  # mutate(across(c(variable_level, label), ~ ifelse(stat_name=="N", "n", .x))) |>
  ungroup() |>
  unique() |>
  
  # relabel the variables
  mutate(
    stat_variable = case_when(
      AVALLAB == "Objective Response Rate" ~ "Objective Response Rate",
      stat_variable == "AVALLAB" ~ "Best Overall Response",
      .default = stat_variable
    ),
    label = case_when(
      stat_label == "N" ~ "n",
      .default = AVALLAB
    )
  ) |>
  # drop variables not needed
  select(DOSGRP, stat_variable, label, stat_name, stat) |>
  # remove dups (extra denoms per variable level)
  filter(label != "remove") |>
  unique()

###### Confirmed Objective Response - INVESTIGATOR (ORR) ######

round_half_up <- function(x, digits = 0) {
  posneg <- sign(x)
  z <- abs(x) * 10^digits
  z <- z + 0.5 + sqrt(.Machine$double.eps)
  z <- trunc(z)
  z <- z / 10^digits
  z * posneg
}
# 95% CI (Clopper-Pearson)
adtteOORt0 <- adtteOOR |>
  mutate(DOSGRP = "Total")

adtteOORt <- bind_rows(adtteOOR, adtteOORt0)

ORRtab <- adtteOOR |>
  group_by(AVALC, DOSGRP) |>
  summarise(n = n_distinct(USUBJID)) |>
  ungroup()

# Calculate bigN
bigN <- adtteOOR |>
  group_by(DOSGRP) |>
  summarise(N = n(), .groups = "drop") |>
  ungroup()

bigN_dummy <- adsl |>
  group_by(DOSGRP) |>
  summarise(N = n(), .groups = "drop") |>
  ungroup() |>
  select(DOSGRP)

bigN <- merge(bigN, bigN_dummy, by = "DOSGRP", all = TRUE) |>
  mutate(N = case_when(is.na(N) ~ 0, TRUE ~ N))

ORRtab_per <- ORRtab |>
  filter(AVALC == "Y") |> # select only CR+PR (same as AVALC=Y)
  full_join(bigN, by = c("DOSGRP"))

# Add 95% CI Clopper-Pearson
ORRtab_CIL <- ORRtab_per |>
  mutate(
    stat = qbeta(0.025, shape1 = n, shape2 = N - n + 1), #*100
    stat_name = "conf.low"
  )

ORRtab_CIH <- ORRtab_per |>
  mutate(
    stat = qbeta(1 - 0.025, shape1 = n + 1, shape2 = N - n), #*100
    stat_name = "conf.high"
  )

ORRtab_CI <- bind_rows(ORRtab_CIL, ORRtab_CIH) |>
  mutate(
    stat_variable = "95% exact Confidence Interval, %",
    label = "95% exact Confidence Interval, %"
  )

#Combine all stat-s in final dataset

ard_tbl <- bind_rows(ard_tbl0, ORRtab_CI) |>
  # drop variables not needed
  select(DOSGRP, stat_variable, label, stat_name, stat)


# Calculate big N
df_big_N <- ard_categorical(
  data = adslt,
  variables = "DOSGRP",
  #by="LOTCAT",
  statistic = everything() ~ c("n")
) |>
  shuffle_ard() |>
  mutate(N = as.integer(stat)) |>
  select(DOSGRP = variable_level, N)

adsln <- adslt |>
  arrange(DOSGRPN) |>
  distinct(DOSGRPN, .keep_all = TRUE) |>
  select(DOSGRPN, DOSGRP)

df_big_Nn <- merge(df_big_N, adsln, by = c("DOSGRP"), all = TRUE)

ard_tbl1 <- merge(ard_tbl, df_big_Nn, by = c("DOSGRP"), all = TRUE) |>
  mutate(
    stat = case_when(is.na(N) & stat_name == "p" ~ NaN, TRUE ~ stat),
    N = case_when(is.na(N) ~ as.integer(0), TRUE ~ as.integer(N)),
    # TRUE~N),
    # column = paste0(DOSGRP, ' (N=', as.character(N), ')'),
    column = DOSGRP
  ) |>
  arrange(DOSGRPN) |>
  select(-DOSGRPN, LABEL = label, GROUP = stat_variable, -DOSGRP )


#saving final dataset for validation in parquet format
#write_parquet(ard_tbl1, file.path(dddata_path, "t_ef_orr_lot_pool.parquet"))


#Getting parquet file
t_ef_orr_uprtki1_pool_r <- read_parquet(file.path(g_paths$dddata, "t_ef_orr_uprtki1_pool_r.parquet"))
#


qc_t_ef_orr_uprtki1_pool_r <- ard_tbl1 |>
  arrange(column, stat_name, LABEL, GROUP) #|>
# mutate(stat = case_when(stat_name!="p" ~stat,
#                         stat>=0 & stat_name=="p" ~stat*100,
#                         TRUE ~  0
# ))
#select(-stat_variable)
t_ef_orr_uprtki1_pool_r <- t_ef_orr_uprtki1_pool_r |>
  arrange(column, stat_name, LABEL, GROUP) |>
  select(-ord_2)

# Compare PRODUCTION vs QC datasets ----
# Compare the QC-generated data with the production data.
diffdf::diffdf(
  base = t_ef_orr_uprtki1_pool_r,
  compare = qc_t_ef_orr_uprtki1_pool_r
)