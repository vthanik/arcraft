#' Finalize and Save an ADaM Dataset for Production
#'
#' Validates that output directories exist, applies final metadata-driven
#' formatting, and saves the dataset in two required formats:
#'
#' 1. A RAPIDO-compliant `.parquet` file for internal analysis.
#' 2. A `.xpt` transport file for P21 validation and regulatory submission.
#'
#' The function will stop with an informative error if target directories do not
#' exist or if required inputs are invalid.
#'
#' @param data The finalized ADaM data frame (e.g., `adsl`, `adae`).
#' @param metacore The metacore object containing the specifications.
#' @param dataset_name A string for the dataset name (e.g., `"ADSL"`, `"ADAE"`).
#'
#' @return The final, formatted data frame, invisibly.
#'
#' @export
save_adam <- function(data, metacore, dataset_name) {
  
  # --- 1. Input Validation ----------------------------------------------------
  
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame, not {.cls {class(data)}}.")
  }
  if (nrow(data) == 0L) {
    cli::cli_warn("{.arg data} has zero rows — output files will be empty.")
  }
  if (!is.character(dataset_name) || length(dataset_name) != 1L || !nzchar(dataset_name)) {
    cli::cli_abort("{.arg dataset_name} must be a single non-empty string.")
  }
  
  dataset_name <- toupper(dataset_name)
  file_name_base <- tolower(dataset_name)
  
  # --- 2. Directory Validation (fail fast) ------------------------------------
  
  required_dirs <- c(
    adamdata        = g_paths$adamdata,
    submission_data = g_paths$submission_data
  )
  
  missing_dirs <- required_dirs[!vapply(required_dirs, fs::dir_exists, logical(1L))]
  
  if (length(missing_dirs) > 0L) {
    cli::cli_abort(c(
      "x" = "Required output director{?y/ies} not found:",
      set_names(
        paste0("{.path ", missing_dirs, "}"),
        rep("*", length(missing_dirs))
      ),
      "i" = "Please create {?it/them} before saving."
    ))
  }
  
  # --- 3. Prepare the Final Data Frame ----------------------------------------
  
  metacore_spec <- metacore |>
    select_dataset(dataset_name) |>
    suppressWarnings()
  
  final_df <- data |>
    drop_unspec_vars(metacore) |>
    check_variables(metacore_spec, strict = FALSE) |>
    check_ct_data(metacore_spec, na_acceptable = TRUE) |>
    order_cols(metacore_spec) |>
    sort_by_key(metacore_spec) |>
    xportr::xportr_type(metadata = metacore_spec) |>
    xportr::xportr_length(metadata = metacore_spec) |>
    xportr::xportr_format(metadata = metacore_spec) |>
    xportr::xportr_label(metadata = metacore_spec) |>
    xportr::xportr_df_label(metadata = metacore_spec, domain = dataset_name)
  
  # --- 4. Save Both Formats ---------------------------------------------------
  
  parquet_path <- fs::path(g_paths$adamdata, file_name_base, ext = "parquet")
  xpt_path     <- fs::path(g_paths$submission_data, file_name_base, ext = "xpt")
  
  # Parquet (RAPIDO-compliant for TFLs / QC)
  cli::cli_inform(
    "Saving {.strong RAPIDO-compliant parquet} for {.val {dataset_name}} to {.path {parquet_path}}"
  )
  
  md_for_pq <- build_json_md(
    .df    = final_df,
    dfname = metacore_spec$dataset,
    pretty = TRUE
  )
  
  tryCatch(
    arrow::write_parquet(final_df, parquet_path),
    error = function(e) {
      cli::cli_abort(
        "Failed to write parquet file for {.val {dataset_name}}.",
        parent = e
      )
    }
  )
  
  # XPT (P21 validation / regulatory submission)
  cli::cli_inform(
    "Saving {.strong XPT} for {.val {dataset_name}} to {.path {xpt_path}}"
  )
  
  tryCatch(
    xportr::xportr_write(
      .df      = final_df,
      path     = xpt_path,
      metadata = metacore_spec,
      domain   = dataset_name
    ),
    error = function(e) {
      cli::cli_abort(
        "Failed to write XPT file for {.val {dataset_name}}.",
        parent = e
      )
    }
  )
  
  cli::cli_alert_success(
    "{.val {dataset_name}} saved successfully ({nrow(final_df)} row{?s})."
  )
  
  invisible(final_df)
}