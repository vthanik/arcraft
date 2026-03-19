####------------------------------------------------------------------------####
# Program Name: li_ef_os.R
# Domino Environment: Multilingual Frozen R4.5.1_2025-09-09_v1 SASViya4
# Developer: Pragya Tripathi / ps209009
# Purpose: Listing of OS
#
# Input:
#   - adam [adbs, adtte]
# Output:
#   - dd []
#
# External files called:
#   - /mnt/code/functions/r_setup.R
#
# Additional Notes:
#
#-------------------------------------------------------------------------------
library(dplyr)
library(stringr)

adtte <- read_data_catalog(adamdata$adtte) |>
  rename_with(tolower) |> 
  filter(effl=="Y")

adbs <- read_data_catalog(adamdata$adbs) |>
  rename_with(tolower) |> 
  filter(effl=="Y") |> 
  select(usubjid,age, sex, arace,dosgrp,lotcat,dthfl,dcsreas,dcsreasp,eosstt)

adtte_r <- adtte |>
  left_join(adbs, by = "usubjid")|>
  # filter(
  #   paramcd == "OS",
  #   is.na(dthfl),
  #   str_trim(dcsreas) != "Study Completion",
  #   str_trim(eosstt) == "Off Study"
  # ) |>
  mutate(
    dcsreas = if_else(
      dcsreas == "Other",
      dcsreasp,
      dcsreas
    )
  )

adtte_r <- adtte_r |> 
  select(-acat2, -acat2n, -srcseq, -aseq)

final <- adtte_r |>
  select(studyid,siteid, usubjid, subjid, age, sex, arace, dosgrp,lotcat,adt, dcsreas, phase) |>
  distinct()


library(openxlsx)
write.xlsx(final, file = paste0(
  "/mnt/data/",
  Sys.getenv("DOMINO_PROJECT_NAME"),
  "/prod/output/li_raw_tte.xlsx"))
