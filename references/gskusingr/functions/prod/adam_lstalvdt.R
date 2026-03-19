#' Read and Validate the LSTALVDT Date Specification File (Internal Helper)
#'
#' Reads a specific sheet from the Excel file, safely selects required columns,
#' and validates the content.
#'
#' @param path Path to the Excel specification file.
#' @param sheet The name of the sheet to read from the Excel file.
#' @return A validated and cleaned tibble of date specifications.
#' @noRd
read_lstalvdt_spec <- function(path, sheet) {
  if (!fs::file_exists(path)) {
    cli::cli_abort("LSTALVDT spec file not found at: {.file {path}}")
  }
  
  spec_df <- tryCatch(
    readxl::read_excel(path, sheet = sheet, col_types = "text"),
    error = function(e) {
      cli::cli_abort("Failed to read sheet {.val {sheet}} from file {.file {path}}. Error: {e$message}")
    }
  )
  
  required_excel_cols <- c("SDTM Dataset", "SDTM Datetime Variable")
  if (!all(required_excel_cols %in% names(spec_df))) {
    cli::cli_abort("Spec sheet {.val {sheet}} is missing required columns: {.val {setdiff(required_excel_cols, names(spec_df))}}")
  }
  
  spec_clean <- spec_df %>%
    select(
      sdtm_dataset = "SDTM Dataset",
      sdtm_variable = "SDTM Datetime Variable",
      any_of(c(r_filter_condition = "R Filter Condition"))
    )
  
  # Filter out rows where essential info is missing
  spec_validated <- spec_clean %>%
    filter(
      !is.na(sdtm_dataset) & sdtm_dataset != "",
      !is.na(sdtm_variable) & sdtm_variable != ""
    )
  
  if (nrow(spec_validated) < nrow(spec_clean)) {
    cli::cli_warn("Ignoring {nrow(spec_clean) - nrow(spec_validated)} row(s) from spec file due to missing values.")
  }
  
  if (!"r_filter_condition" %in% names(spec_validated)) {
    spec_validated$r_filter_condition <- ""
  }
  
  spec_validated %>%
    mutate(r_filter_condition = if_else(is.na(r_filter_condition), "", r_filter_condition))
}

#' Compute Last Alive Date (LSTALVDT)
#'
#' Computes the last known alive date by dynamically reading and scanning SDTM
#' domains based on an external specification file.
#'
#' @param adsl The input ADSL dataset.
#' @param spec_path Path to the Excel file specifying the date variables to scan.
#' @param cutoffdt A Date object representing the data cutoff date.
#' @param idvar The name of the subject identifier variable. Defaults to "USUBJID".
#' @param sheet The name of the sheet in the `spec_path` file to use. Defaults
#'   to "Date Last Known Alive".
#'
#' @return The input `adsl` dataset with `LSTALVDT`, `LALVDOM`, `LALVVAR`, and
#'   `LALVSEQ` added.
#'
compute_lstalvdt <- function(adsl, spec_path, cutoffdt, idvar = "USUBJID", sheet = "Date Last Known Alive") {
  # --- 1. Setup and Validation ---
  pkg_load(c("dplyr", "purrr", "lubridate", "readxl", "rlang"), .quiet = TRUE)
  
  if (!exists("sdtmdata")) cli::cli_abort("`sdtmdata` object not found.")
  if (!idvar %in% names(adsl)) cli::cli_abort("`adsl` must contain the ID variable: {.val {idvar}}")
  if (!inherits(cutoffdt, "Date")) cli::cli_abort("`cutoffdt` must be a Date object.")
  
  spec_df <- read_lstalvdt_spec(spec_path, sheet = sheet)
  
  # --- 2. Collect all possible 'alive' dates from specified domains ---
  all_dates_long <- purrr::map_dfr(seq_len(nrow(spec_df)), function(i) {
    spec_row <- spec_df[i, ]
    domain_code <- tolower(spec_row$sdtm_dataset)
    domain_name <- toupper(domain_code)
    var_name <- toupper(spec_row$sdtm_variable)
    filter_cond <- spec_row$r_filter_condition
    
    domain_path <- sdtmdata[[domain_code]]
    if (is.null(domain_path)) {
      cli::cli_warn("Skipping: Dataset {.val {domain_name}} not found in `sdtmdata`.")
      return(NULL)
    }
    
    domain_data <- read_data_catalog(domain_path)
    
    required_vars <- c(idvar, var_name)
    if (!all(required_vars %in% names(domain_data))) {
      cli::cli_warn("Skipping: {.val {domain_name}} is missing vars: {.val {setdiff(required_vars, names(domain_data))}}")
      return(NULL)
    }
    
    if (nzchar(filter_cond)) {
      domain_data <- tryCatch(dplyr::filter(domain_data, !!rlang::parse_expr(filter_cond)),
                              error = function(e) {
                                cli::cli_warn("Filter failed on {.val {domain_name}} with ` {filter_cond} `. Skipping.")
                                return(NULL)
                              })
      if (is.null(domain_data) || nrow(domain_data) == 0) return(NULL)
    }
    
    seq_var_name <- paste0(domain_name, "SEQ")
    
    domain_data %>%
      select(all_of(idvar), DTC = all_of(var_name), SEQ = any_of(seq_var_name)) %>%
      mutate(
        SEQ = if ("SEQ" %in% names(.)) SEQ else NA_integer_,
        LALVDOM = domain_name,
        LALVVAR = var_name
      )
  })
  
  # --- 3. Impute dates and find the maximum valid date per subject ---
  max_alive_dates <- all_dates_long %>%
    filter(!is.na(DTC) & DTC != "") %>%
    admiral::derive_vars_dt(
      new_vars_prefix = "ALIVE", dtc = DTC,
      highest_imputation = "M", date_imputation = "last"
    ) %>%
    filter(!is.na(ALIVEDT) & ALIVEDT <= cutoffdt) %>%
    group_by(!!sym(idvar)) %>%
    arrange(desc(ALIVEDT), desc(LALVDOM), desc(LALVVAR)) %>%
    slice_head(n = 1) %>%
    ungroup() %>%
    rename(LSTALVDT_MAX = ALIVEDT, LALVSEQ = SEQ)
  
  # --- 4. Process death dates from DM ---
  dm <- read_data_catalog(sdtmdata$dm)
  dm_dth <- dm %>%
    filter(DTHFL == "Y") %>%
    select(all_of(idvar), DTHDTC) %>%
    mutate(LSTALVDT_DTH = admiral::convert_dtc_to_dt(DTHDTC)) %>%
    filter(!is.na(LSTALVDT_DTH))
  
  # --- 5. Combine results and create final ADSL variables ---
  
  # Conditionally join DTHFL from DM only if it's not already in ADSL
  if (!"DTHFL" %in% names(adsl)) {
    adsl_to_process <- adsl %>%
      left_join(select(dm, all_of(idvar), DTHFL), by = idvar)
  } else {
    adsl_to_process <- adsl
  }
  
  final_adsl <- adsl_to_process %>%
    left_join(select(dm_dth, all_of(idvar), LSTALVDT_DTH), by = idvar) %>%
    left_join(max_alive_dates, by = idvar) %>%
    mutate(
      LSTALVDT = if_else(DTHFL == "Y" & !is.na(LSTALVDT_DTH), LSTALVDT_DTH, LSTALVDT_MAX),
      LALVDOM = if_else(DTHFL == "Y" & !is.na(LSTALVDT_DTH), "DM", LALVDOM),
      LALVVAR = if_else(DTHFL == "Y" & !is.na(LSTALVDT_DTH), "DTHDTC", LALVVAR),
      LALVSEQ = if_else(DTHFL == "Y" & !is.na(LSTALVDT_DTH), NA_integer_, LALVSEQ)
    ) %>%
    # Remove only the intermediate calculation columns
    select(-any_of(c("LSTALVDT_DTH", "LSTALVDT_MAX")))
  
  return(final_adsl)
}