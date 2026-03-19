# /mnt/code/functions/utils-io.R
# Utility functions for package management and data I/O.


# ── Package Management ───────────────────────────────────────────────────────

#' Attach and/or Install a List of Packages
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' Use [pkg_load()] instead.
#'
#' @param pkgs Character vector of package names.
#' @return Invisible `NULL`.
#' @export
pkg_attach <- function(pkgs) {
  lifecycle::deprecate_warn(
    when = "1.0.0",
    what = "pkg_attach()",
    with = "pkg_load()"
  )
  
  pkgs_to_install <- setdiff(pkgs, rownames(installed.packages()))
  
  if (length(pkgs_to_install) > 0L) {
    cli::cli_inform("Installing missing package{?s}: {.pkg {pkgs_to_install}}")
    utils::install.packages(pkgs_to_install)
  }
  
  cli::cli_inform("Attaching packages: {.pkg {pkgs}}")
  suppressPackageStartupMessages(
    lapply(pkgs, library, character.only = TRUE)
  )
  cli::cli_alert_success("All required packages attached.")
  
  invisible(NULL)
}


#' Flexibly Load Packages with Tidy Evaluation
#'
#' Loads R packages, handling bare symbols, character strings, and
#' unquoting with `!!` / `!!!`.
#'
#' 1. **Errors** if any package is not installed.
#' 2. Informs about already-loaded packages (unless `.quiet = TRUE`).
#' 3. Returns an invisible named logical vector of load statuses.
#'
#' @param ... Package names as symbols (`dplyr`), strings (`"dplyr"`),
#'   or unquoted vectors (`!!!my_pkgs`).
#' @param .quiet If `TRUE`, suppress all informative messages. Default `FALSE`.
#' @return Invisible named logical vector.
#' @export
pkg_load <- function(..., .quiet = FALSE) {
  # --- Resolve package names from quosures ---
  pkgs_quo <- rlang::enquos(...)
  
  resolve_quo <- function(q) {
    expr <- rlang::quo_get_expr(q)
    if (is.symbol(expr)) rlang::as_string(expr) else rlang::eval_tidy(q)
  }
  
  pkgs <- unique(unlist(lapply(pkgs_quo, resolve_quo), use.names = FALSE))
  
  if (length(pkgs) == 0L) {
    return(invisible(logical()))
  }
  
  # --- Check installation status (fast path: .packages(TRUE)) ---
  installed <- pkgs %in% .packages(all.available = TRUE)
  missing   <- pkgs[!installed]
  
  if (length(missing) > 0L) {
    msg <- cli::format_inline(
      "Package{?s} not installed: {.pkg {missing}}"
    )
    if (.quiet) stop(msg, call. = FALSE) else cli::cli_abort(msg)
  }
  
  # --- Partition into already-loaded vs. to-load ---
  on_search   <- paste0("package:", pkgs) %in% search()
  already     <- pkgs[on_search]
  to_load     <- pkgs[!on_search]
  
  status <- stats::setNames(rep(TRUE, length(pkgs)), pkgs)
  
  if (length(already) > 0L && !.quiet) {
    cli::cli_alert_info("Package{?s} already loaded: {.pkg {already}}")
  }
  
  if (length(to_load) > 0L) {
    suppressPackageStartupMessages(
      lapply(to_load, library, character.only = TRUE)
    )
    if (!.quiet) {
      cli::cli_alert_success("Successfully attached: {.pkg {to_load}}")
    }
  }
  
  invisible(status)
}


# ── Data I/O ─────────────────────────────────────────────────────────────────

#' Supported file extensions and their reader functions
#' @noRd
.file_readers <- list(
  sas7bdat = function(path, ...) {
    rlang::check_installed("haven", reason = "to read SAS files.")
    haven::read_sas(path, ...)
  },
  xpt = function(path, ...) {
    rlang::check_installed("haven", reason = "to read XPT files.")
    haven::read_xpt(path, ...)
  },
  parquet = function(path, ...) {
    rlang::check_installed("arrow", reason = "to read Parquet files.")
    arrow::read_parquet(path, ...)
  },
  rds = function(path, ...) readRDS(path)
)


#' Convert Blank Strings to `NA` If admiral Is Available
#'
#' @param data A data frame.
#' @return The data frame with blanks converted to `NA`, or unchanged.
#' @noRd
blanks_to_na <- function(data) {
  if (rlang::is_installed("admiral")) {
    admiral::convert_blanks_to_na(data)
  } else {
    data
  }
}


#' Read a Local SAS File and Convert Blanks to NA
#'
#' @param path Path to a `.sas7bdat` file.
#' @param ... Additional arguments passed to [haven::read_sas()].
#' @return A tibble.
#' @export
read_sas_local <- function(path, ...) {
  rlang::check_installed("haven", reason = "to read SAS files.")
  
  haven::read_sas(path, ...) |>
    blanks_to_na()
}


#' Read Data from a Data Catalog
#'
#' Dispatches to the appropriate reader based on file extension.
#' Supports `.sas7bdat`, `.xpt`, `.parquet`, and `.rds` files.
#' Blank strings are converted to `NA` when the `admiral` package is available.
#'
#' @param path A single file path string.
#' @param ... Additional arguments forwarded to the underlying reader.
#' @param .quiet If `TRUE`, suppress the informative "Reading …" message.
#'   Default `FALSE`.
#' @return A data frame / tibble.
#' @export
read_data_catalog <- function(path, ..., .quiet = FALSE) {
  # --- Validate input ---
  if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
    cli::cli_abort("{.arg path} must be a single non-empty string.")
  }
  if (!fs::file_exists(path)) {
    cli::cli_abort("File not found: {.path {path}}")
  }
  
  ext <- tolower(fs::path_ext(path))
  reader <- .file_readers[[ext]]
  
  if (is.null(reader)) {
    supported <- paste0(".", names(.file_readers))
    cli::cli_abort(c(
      "Unsupported file type: {.val {paste0('.', ext)}}",
      "i" = "Supported extensions: {.val {supported}}"
    ))
  }
  
  if (!.quiet) {
    cli::cli_inform(
      "Reading {.file {basename(path)}} using the {.val {ext}} reader."
    )
  }
  
  reader(path, ...) |>
    blanks_to_na()
}


# ── Dataset Metadata / Contents ──────────────────────────────────────────────

#' Metadata extractors keyed by column name
#'
#' Each element is a function `f(df)` returning a vector of length `ncol(df)`.
#' Extractors are called lazily — only those matching the requested columns are
#' evaluated.
#'
#' @noRd
.metadata_extractors <- list(
  VarNum = function(df) seq_along(df),
  
  Variable = function(df) names(df),
  
  Label = function(df) {
    vapply(df, function(col) attr(col, "label") %||% NA_character_, character(1L))
  },
  
  Type = function(df) {
    vapply(df, function(col) class(col)[[1L]], character(1L))
  },
  
  Format = function(df) {
    vapply(df, function(col) attr(col, "format.sas") %||% NA_character_, character(1L))
  },
  
  Length = function(df) {
    vapply(df, function(col) {
      if (!is.character(col) || all(is.na(col))) return(NA_integer_)
      max(nchar(col), na.rm = TRUE)
    }, integer(1L))
  },
  
  Digits = function(df) {
    vapply(df, function(col) {
      if (!is.numeric(col) || is.integer(col)) return(NA_integer_)
      col <- col[!is.na(col)]
      if (length(col) == 0L) return(NA_integer_)
      
      fractional <- col[col %% 1 != 0]
      if (length(fractional) == 0L) return(0L)
      
      char_vals <- format(fractional, scientific = FALSE, trim = TRUE)
      has_dot   <- grepl(".", char_vals, fixed = TRUE)
      if (!any(has_dot)) return(0L)
      
      decimal_parts <- sub(".*\\.", "", char_vals[has_dot])
      max(nchar(decimal_parts))
    }, integer(1L))
  }
)


#' Extract Variable Metadata from a Single Data File
#'
#' Reads a dataset via [read_data_catalog()] and returns a tibble of
#' per-variable metadata for the requested columns.
#'
#' @param file_path Path to the data file.
#' @param dataset_name Dataset identifier (e.g., `"AE"`).
#' @param columns_to_keep Character vector of metadata column names to include.
#'   Must be a subset of `"Dataset"`, `"VarNum"`, `"Variable"`, `"Label"`,
#'   `"Type"`, `"Length"`, `"Digits"`, `"Format"`.
#' @return A tibble, or `NULL` on read failure.
#' @noRd
get_variable_metadata <- function(file_path, dataset_name, columns_to_keep) {
  df <- tryCatch(
    read_data_catalog(file_path, .quiet = TRUE),
    error = function(e) {
      cli::cli_warn(
        "Could not read {.file {basename(file_path)}}: {e$message}"
      )
      NULL
    }
  )
  
  if (is.null(df)) return(NULL)
  
  # Build only the requested columns; "Dataset" is a scalar recycled by tibble
  result <- list()
  
  if ("Dataset" %in% columns_to_keep) {
    result[["Dataset"]] <- toupper(dataset_name)
  }
  
  extractors_needed <- intersect(columns_to_keep, names(.metadata_extractors))
  for (col_name in extractors_needed) {
    result[[col_name]] <- .metadata_extractors[[col_name]](df)
  }
  
  tibble::as_tibble(result)
}


#' Get a SAS-Like Contents Data Frame for a Data Catalog
#'
#' Scans every dataset in a named catalog list and returns a single tibble of
#' variable-level metadata, similar to `SASHELP.VCOLUMN`.
#'
#' @param catalog A named list mapping dataset identifiers (e.g., `"ae"`) to
#'   file paths, as produced by the project setup script.
#' @param ignore_attr Optional character vector of metadata columns to exclude.
#'   Accepts any of `"Label"`, `"Type"`, `"Length"`, `"Format"`, `"Digits"`
#'   (case-insensitive).
#' @return A tibble of variable metadata across all datasets.
#' @export
get_contents <- function(catalog, ignore_attr = NULL) {
  catalog_label <- rlang::as_label(rlang::enquo(catalog))
  
  # --- Validate catalog ---
  if (!is.list(catalog) || length(catalog) == 0L) {
    cli::cli_abort(
      "{.arg {catalog_label}} must be a non-empty named list."
    )
  }
  if (is.null(names(catalog)) || any(!nzchar(names(catalog)))) {
    cli::cli_abort(
      "Every element of {.arg {catalog_label}} must be named."
    )
  }
  
  # --- Resolve which metadata columns to produce ---
  all_cols <- c("Dataset", "VarNum", "Variable", "Label",
                "Type", "Length", "Digits", "Format")
  
  cols_to_drop <- character(0L)
  if (!is.null(ignore_attr)) {
    if (!is.character(ignore_attr)) {
      cli::cli_warn("{.arg ignore_attr} must be a character vector; ignoring.")
    } else {
      cols_to_drop <- all_cols[tolower(all_cols) %in% tolower(ignore_attr)]
    }
  }
  columns_to_keep <- setdiff(all_cols, cols_to_drop)
  
  # --- Iterate with progress ---
  n_datasets <- length(catalog)
  cli::cli_progress_bar(
    name  = "Processing datasets",
    total = n_datasets,
    clear = FALSE
  )
  
  results <- vector("list", n_datasets)
  
  for (i in seq_along(catalog)) {
    results[[i]] <- get_variable_metadata(
      file_path       = catalog[[i]],
      dataset_name    = names(catalog)[[i]],
      columns_to_keep = columns_to_keep
    )
    cli::cli_progress_update()
  }
  
  cli::cli_progress_done()
  
  purrr::list_rbind(results)
}
