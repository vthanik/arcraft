# Variable suggestions — demographics only (Phase 1)
# Other template suggestions backed up in _backup_templates/

fct_suggest_vars <- function(template, data) {
  cols <- names(data)
  candidates <- switch(template,
    demog = c("AGE", "AGEGR1", "SEX", "RACE", "ETHNIC",
              "HEIGHTBL", "WEIGHTBL", "BMIBL", "BMIGR1",
              "ECOGBL", "COUNTRY"),
    character(0)
  )
  intersect(candidates, cols)
}
