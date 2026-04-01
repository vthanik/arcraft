# Save/Load output folders — pure R, no Shiny
#
# Each saved output is a self-contained folder:
#   config.yaml       — metadata + analysis params + format config (human-readable)
#   ard.parquet        — wide ARD data frame
#   raw_ard.parquet    — cards long ARD (QC audit trail)
#   script.R           — standalone R script

# ── Save output to a named directory ──
save_output <- function(ard, raw_ard, fmt, code, analysis, metadata, dir) {
  dir <- normalizePath(dir, mustWork = FALSE)

  # Validate
 if (is.null(ard)) {
    return(list(success = FALSE, path = dir,
                message = "No ARD data to save. Generate preview first."))
  }

  # Create directory
  if (!dir.exists(dir)) {
    created <- tryCatch(dir.create(dir, recursive = TRUE), error = function(e) FALSE)
    if (!isTRUE(created)) {
      return(list(success = FALSE, path = dir,
                  message = paste0("Cannot create directory: ", dir)))
    }
  }

  # Check writable
  if (!file.access(dir, 2) == 0) {
    return(list(success = FALSE, path = dir,
                message = paste0("Directory not writable: ", dir)))
  }

  # Build config
  config <- list(
    metadata = metadata,
    analysis = analysis,
    format = fmt
  )

  # Write files
  tryCatch({
    yaml::write_yaml(config, file.path(dir, "config.yaml"))
    arrow::write_parquet(ard, file.path(dir, "ard.parquet"))
    if (!is.null(raw_ard)) {
      # Convert cards ARD to parquet-safe format:
      # - Drop fmt_fun (closures can't be serialized)
      # - Convert list columns to character
      raw_df <- as.data.frame(raw_ard, stringsAsFactors = FALSE)
      drop_cols <- c("fmt_fun", "fmt_fn")
      raw_df <- raw_df[, setdiff(names(raw_df), drop_cols), drop = FALSE]
      for (col in names(raw_df)) {
        if (is.list(raw_df[[col]])) {
          raw_df[[col]] <- vapply(raw_df[[col]], function(x) {
            if (is.null(x) || length(x) == 0L) NA_character_
            else tryCatch(as.character(x[[1L]]), error = function(e) NA_character_)
          }, character(1L))
        }
      }
      arrow::write_parquet(raw_df, file.path(dir, "raw_ard.parquet"))
    }
    writeLines(code, file.path(dir, "script.R"))

    list(success = TRUE, path = dir, message = "Output saved successfully.")
  }, error = function(e) {
    list(success = FALSE, path = dir,
         message = paste0("Save failed: ", e$message))
  })
}

# ── Load output from a directory ──
load_output <- function(dir) {
  dir <- normalizePath(dir, mustWork = FALSE)
  config_path <- file.path(dir, "config.yaml")
  ard_path <- file.path(dir, "ard.parquet")
  script_path <- file.path(dir, "script.R")
  raw_ard_path <- file.path(dir, "raw_ard.parquet")

  # Validate required files
  if (!file.exists(config_path)) {
    cli::cli_abort("config.yaml not found in {dir}", call = NULL)
  }
  if (!file.exists(ard_path)) {
    cli::cli_abort("ard.parquet not found in {dir}", call = NULL)
  }

  # Read config
  config <- tryCatch(
    yaml::read_yaml(config_path),
    error = function(e) cli::cli_abort("Invalid config.yaml: {e$message}", call = NULL)
  )

  # Read ARD
  ard <- tryCatch(
    arrow::read_parquet(ard_path),
    error = function(e) cli::cli_abort("Cannot read ard.parquet: {e$message}", call = NULL)
  )

  # Read raw ARD (optional)
  raw_ard <- NULL
  if (file.exists(raw_ard_path)) {
    raw_ard <- tryCatch(
      arrow::read_parquet(raw_ard_path),
      error = function(e) NULL
    )
  }

  # Read code
  code <- ""
  if (file.exists(script_path)) {
    code <- paste(readLines(script_path, warn = FALSE), collapse = "\n")
  }

  # Extract sections with defaults
  list(
    fmt = normalize_fmt(config$format %||% list()),
    ard = as.data.frame(ard, stringsAsFactors = FALSE),
    raw_ard = raw_ard,
    code = code,
    analysis = config$analysis %||% list(),
    metadata = config$metadata %||% list()
  )
}

# ── Scan a parent directory for saved outputs ──
scan_outputs <- function(parent_dir) {
  if (!dir.exists(parent_dir)) {
    return(data.frame(
      table_id = character(0), template = character(0),
      dataset = character(0), created = character(0),
      modified = character(0), dir_path = character(0),
      stringsAsFactors = FALSE
    ))
  }

  subdirs <- list.dirs(parent_dir, full.names = TRUE, recursive = FALSE)
  configs <- file.path(subdirs, "config.yaml")
  has_config <- file.exists(configs)
  subdirs <- subdirs[has_config]
  configs <- configs[has_config]

  if (length(subdirs) == 0) {
    return(data.frame(
      table_id = character(0), template = character(0),
      dataset = character(0), created = character(0),
      modified = character(0), dir_path = character(0),
      stringsAsFactors = FALSE
    ))
  }

  rows <- lapply(seq_along(subdirs), function(i) {
    cfg <- tryCatch(yaml::read_yaml(configs[i]), error = function(e) list())
    meta <- cfg$metadata %||% list()
    data.frame(
      table_id = meta$table_id %||% basename(subdirs[i]),
      template = meta$template %||% "unknown",
      dataset = cfg$data$dataset %||% meta$dataset %||% "",
      created = meta$created %||% "",
      modified = meta$modified %||% meta$created %||% "",
      dir_path = subdirs[i],
      stringsAsFactors = FALSE
    )
  })

  dplyr::bind_rows(rows)
}

# ── Delete an output directory ──
delete_output <- function(dir) {
  dir <- normalizePath(dir, mustWork = FALSE)
  # Safety: only delete if config.yaml exists (confirms it's an arcraft output)
  if (!file.exists(file.path(dir, "config.yaml"))) {
    return(FALSE)
  }
  # Prevent deleting system directories or paths outside working tree
  wd <- normalizePath(getwd(), mustWork = FALSE)
  if (!startsWith(dir, wd)) {
    return(FALSE)
  }
  unlink(dir, recursive = TRUE)
  !dir.exists(dir)
}

# ── Validate before save ──
validate_save_target <- function(parent_dir, output_name) {
  # Check parent exists
  if (!dir.exists(parent_dir)) {
    return(list(ok = FALSE, conflict = FALSE,
                message = paste0("Directory does not exist: ", parent_dir)))
  }

  # Check writable
  if (!file.access(parent_dir, 2) == 0) {
    return(list(ok = FALSE, conflict = FALSE,
                message = paste0("Directory not writable: ", parent_dir)))
  }

  # Sanitize name
  safe_name <- gsub("[^A-Za-z0-9._-]", "_", output_name)
  if (nchar(safe_name) == 0 || nchar(safe_name) > 100) {
    return(list(ok = FALSE, conflict = FALSE,
                message = "Output name must be 1-100 characters (letters, numbers, -, _, .)"))
  }

  # Check conflict
  target <- file.path(parent_dir, safe_name)
  if (dir.exists(target)) {
    return(list(ok = TRUE, conflict = TRUE,
                message = paste0("Output '", safe_name, "' already exists."),
                safe_name = safe_name, target = target))
  }

  list(ok = TRUE, conflict = FALSE, safe_name = safe_name, target = target)
}

# ── Suggest a default name ──
suggest_output_name <- function(template) {
  ts <- format(Sys.time(), "%Y%m%d_%H%M%S")
  paste0(template %||% "output", "_", ts)
}

# ── Build metadata list ──
build_save_metadata <- function(table_id, template, dataset, pop_flag = NULL) {
  list(
    table_id = table_id,
    template = template %||% "unknown",
    output_type = "table",
    dataset = dataset %||% "",
    pop_flag = pop_flag %||% "",
    created = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
    modified = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
    arcraft_version = tryCatch(
      as.character(utils::packageVersion("arcraft")),
      error = function(e) "dev"
    ),
    arframe_version = tryCatch(
      as.character(utils::packageVersion("arframe")),
      error = function(e) "dev"
    ),
    cards_version = tryCatch(
      as.character(utils::packageVersion("cards")),
      error = function(e) "unknown"
    ),
    r_version = paste0(R.version$major, ".", R.version$minor)
  )
}

# ── Build analysis params list (from grouping) ──
build_save_analysis <- function(grp_list, var_configs, var_labels = NULL,
                               added_levels = NULL) {
  list(
    trt_var = grp_list$trt_var,
    trt_levels = grp_list$trt_levels,
    include_total = grp_list$include_total %||% TRUE,
    total_label = grp_list$total_label %||% "Total",
    denominator = grp_list$denominator %||% "col_n",
    by_var = grp_list$by_var,
    combined_groups = grp_list$combined_groups %||% list(),
    analysis_vars = as.character(grp_list$analysis_vars),
    var_configs = var_configs,
    var_labels = var_labels %||% list(),
    added_levels = added_levels %||% list()
  )
}
