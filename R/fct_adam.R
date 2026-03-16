# ADaM detection — pure R, no Shiny

fct_detect_pop_flags <- function(cols) {
  fl <- grep("FL$", cols, value = TRUE)
  common <- c("SAFFL", "ITTFL", "EFFFL", "FASFL", "PPROTFL")
  c(intersect(common, fl), setdiff(fl, common))
}

fct_detect_trt_vars <- function(cols) {
  intersect(c("TRT01A", "TRT01P", "TRTA", "TRTP", "TRT02A", "TRT02P"), cols)
}

fct_detect_var_type <- function(data, var) {
  if (is.numeric(data[[var]])) "continuous" else "categorical"
}

fct_get_var_label <- function(data, var) {
  lbl <- attr(data[[var]], "label")
  if (!is.null(lbl) && nzchar(lbl)) return(lbl)
  switch(var,
    AGE = "Age (yr)", SEX = "Sex", RACE = "Race", ETHNIC = "Ethnicity",
    BMIBL = "BMI (kg/m2)", HEIGHTBL = "Height (cm)", WEIGHTBL = "Weight (kg)",
    AGEGR1 = "Age Group", ECOGBL = "ECOG Status", DSSTAG = "Disease Stage",
    NPRLINE = "Prior Lines of Therapy", var)
}

fct_detect_demog_vars <- function(data) {
  candidates <- c("AGE", "SEX", "RACE", "ETHNIC", "BMIBL", "HEIGHTBL",
                   "WEIGHTBL", "AGEGR1", "ECOGBL", "DSSTAG", "NPRLINE")
  found <- intersect(candidates, names(data))
  purrr::map_dfr(found, function(v) {
    tibble::tibble(variable = v, label = fct_get_var_label(data, v),
                   type = fct_detect_var_type(data, v))
  })
}
