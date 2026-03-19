# /mnt/code/functions/r_setup.R
# ─────────────────────────────────────────────────────────────────────────────
# Silent, one-time study environment setup engine.
#
# Called exactly once from .Rprofile. Populates the global environment with
# `g_config`, `g_paths`, and per-domain data catalogs, then removes itself.
# ─────────────────────────────────────────────────────────────────────────────

if (!requireNamespace("fs", quietly = TRUE)) {
  stop("Package 'fs' is required for study setup.", call. = FALSE)
}


# ── Internal helpers (scoped to this file) ───────────────────────────────────

#' Build Study Configuration
#' @return A named list of study-level constants.
#' @noRd
.build_config <- function() {
  list(
    studyid  = "IDRX-42-001",
    dominoid = Sys.getenv("DOMINO_PROJECT_NAME", "unknown_project"),
    datadate = "15DEC2025",
    colors   = c(
      "#2E74BF", "#CB454A", "#82B870", "#E09411", "#9D4E84",
      "#7069A0", "#888D81", "#F3CEAF", "#F2A0A9", "#408288"
    )
  )
}


#' Build Canonical Path Registry
#'
#' All study paths are derived from a single `study_root`. Environment
#' variables take precedence for externally-mounted data directories.
#'
#' @param dominoid The Domino project identifier.
#' @return A named list of `fs_path` objects.
#' @noRd
.build_paths <- function(dominoid) {
  study_root <- fs::path("/mnt/data", dominoid)
  
  prod <- function(...) fs::path(study_root, "prod", ...)
  qc   <- function(...) fs::path(study_root, "qc",   ...)
  
  list(
    # Infrastructure
    functions       = fs::path("/mnt/code/functions"),
    study_root      = study_root,
    
    # External / env-var-driven
    rawdata         = Sys.getenv("RAWEXT_PATH", ""),
    sdtmdata        = Sys.getenv("SDTM_PATH",  ""),
    adamdata_ext    = Sys.getenv("ADAM_PATH",   ""),
    
    # Production
    adamdata        = prod("adamdata"),
    dddata          = prod("dddata"),
    metadata        = prod("metadata"),
    output          = prod("output"),
    submission      = prod("submission"),
    submission_data = prod("submission", "datasets"),
    
    # Shared input
    inputdata       = fs::path(study_root, "inputdata"),
    misc            = fs::path(study_root, "misc"),
    
    # QC
    qc_adamdata     = qc("adamdata"),
    qc_dddata       = qc("dddata"),
    qc_metadata     = qc("metadata"),
    qc_output       = qc("output"),
    qc_submission   = qc("submission")
  )
}


#' Recursively Source R Files from Directories
#'
#' Sources every `.R` file found under `dirs`, excluding this setup script
#' and any paths matching `exclude_dirs`.
#'
#' @param dirs Character vector of directories to scan.
#' @param exclude_dirs Character vector of subdirectory names to skip.
#' @noRd
.source_functions <- function(dirs, exclude_dirs = character()) {
  for (dir in dirs) {
    if (!nzchar(dir) || !fs::dir_exists(dir)) next
    
    r_files <- fs::dir_ls(dir, recurse = TRUE, regexp = "\\.[rR]$")
    
    # Never re-source this setup script
    r_files <- r_files[!grepl("r_setup\\.R$", basename(r_files), ignore.case = TRUE)]
    
    # Drop files under excluded subdirectories
    if (length(exclude_dirs) > 0L) {
      abs_exclude <- fs::path_abs(fs::path(dir, exclude_dirs))
      pattern     <- paste0("^", abs_exclude, collapse = "|")
      r_files     <- r_files[!grepl(pattern, fs::path_abs(r_files))]
    }
    
    for (f in r_files) {
      tryCatch(
        source(f, local = FALSE),
        error = function(e) {
          warning(
            sprintf("Failed to source '%s': %s", basename(f), conditionMessage(e)),
            call. = FALSE
          )
        }
      )
    }
  }
  
  invisible(NULL)
}


#' Build a Data Catalog for a Single Directory
#'
#' Scans `path` for supported data files and returns a named list mapping
#' lowercase dataset names (sans extension) to their full file paths.
#'
#' @param path Directory to scan.
#' @return A named list, or `NULL` if the directory is empty / missing.
#' @noRd
.build_catalog <- function(path) {
  if (!nzchar(path) || !fs::dir_exists(path)) return(NULL)
  
  supported_re <- "[.](sas7bdat|xpt|rds|parquet)$"
  files <- fs::dir_ls(path, regexp = supported_re, recurse = TRUE)
  
  if (length(files) == 0L) return(NULL)
  
  catalog <- as.list(files)
  names(catalog) <- tolower(fs::path_ext_remove(fs::path_file(files)))
  catalog
}


# ── Main entry point ─────────────────────────────────────────────────────────

#' One-Time Silent Study Setup
#'
#' Intended to be called once from `.Rprofile`. Builds the global
#' configuration, path registry, sources helper functions, and creates
#' per-domain data catalogs.
#'
#' @noRd
.run_study_setup <- function() {
  
  
  # ── 1. Global configuration & paths ──────────────────────────────────────
  
  g_config <- .build_config()
  g_paths  <- .build_paths(g_config$dominoid)
  
  assign("g_config", g_config, envir = .GlobalEnv)
  assign("g_paths",  g_paths,  envir = .GlobalEnv)
  
  
  # ── 2. Source function files ─────────────────────────────────────────────
  
  .source_functions(
    dirs = c(
      "/mnt/code/functions",
      "/mnt/imported/code/METEOR_standard_tools/common/parquet_md_inject"
    )
  )
  
  
  # ── 3. Data catalogs ────────────────────────────────────────────────────
  
  catalog_names <- c(
    "rawdata", "sdtmdata", "adamdata", "adamdata_ext",
    "dddata", "inputdata", "qc_adamdata", "qc_dddata"
  )
  
  for (name in catalog_names) {
    catalog <- .build_catalog(g_paths[[name]])
    if (!is.null(catalog)) {
      assign(name, catalog, envir = .GlobalEnv)
    }
  }
  
  invisible(NULL)
}


# ── Execute & clean up ───────────────────────────────────────────────────────

.run_study_setup()

# Remove all private helpers so only g_config, g_paths, and catalogs remain
rm(
  .build_config, .build_paths, .source_functions,
  .build_catalog, .run_study_setup,
  envir = environment()
)