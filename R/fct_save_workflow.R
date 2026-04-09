# Save/Load workflow helpers — thin wrappers over fct_save.R
# Called from app_server.R observers to keep them concise.
# Pure R + minimal Shiny dependency (only reactiveValuesToList).

# ── Save current output ──
# Returns list(success, message, output_name, target_dir)
save_current_output <- function(store, grp) {
  if (is.null(store$ard)) {
    return(list(success = FALSE, message = "Generate preview first"))
  }

  parent_dir <- store$output_dir %||% file.path(getwd(), ".local", "output")
  dir.create(parent_dir, recursive = TRUE, showWarnings = FALSE)
  store$output_dir <- parent_dir

  if (!is.null(store$current_output_dir) && dir.exists(store$current_output_dir)) {
    output_name <- store$current_output_id
    target_dir <- store$current_output_dir
  } else {
    output_name <- suggest_output_name(store$template)
    target_dir <- file.path(parent_dir, output_name)
  }

  grp_list <- shiny::reactiveValuesToList(grp)
  ds_name <- if (length(store$datasets) > 0) names(store$datasets)[1] else ""
  pop_flag <- tryCatch(store$pipeline_filters$pop_flag, error = function(e) "") %||% ""
  metadata <- build_save_metadata(output_name, store$template, ds_name, pop_flag)

  # Preserve original created time on re-save
  if (file.exists(file.path(target_dir, "config.yaml"))) {
    old_cfg <- tryCatch(
      yaml::read_yaml(file.path(target_dir, "config.yaml")),
      error = function(e) list()
    )
    if (!is.null(old_cfg$metadata$created)) {
      metadata$created <- old_cfg$metadata$created
    }
  }

  analysis <- build_save_analysis(grp_list, store$var_configs,
                                  var_labels = shiny::isolate(store$var_labels),
                                  added_levels = shiny::isolate(store$added_levels))
  result <- save_output(store$ard, store$raw_ard, store$fmt, store$code,
                        analysis, metadata, target_dir)

  if (result$success) {
    store$current_output_id <- output_name
    store$current_output_dir <- target_dir
    store$dirty <- FALSE
    store$saved_outputs <- scan_outputs(parent_dir)

    tryCatch(
      yaml::write_yaml(list(output_dir = parent_dir),
                        file.path(getwd(), ".local", "loom_prefs.yaml")),
      error = function(e) NULL
    )
  }

  list(success = result$success,
       message = if (result$success) paste0("Saved: ", output_name) else result$message,
       output_name = output_name,
       target_dir = target_dir)
}

# ── Load a saved output into store + grp ──
# Returns list(success, message, table_id)
load_saved_output <- function(dir_path, store, grp) {
  loaded <- load_output(dir_path)

  store$fmt <- loaded$fmt
  store$ard <- loaded$ard
  store$raw_ard <- loaded$raw_ard
  store$code <- loaded$code
  store$template <- loaded$metadata$template
  store$current_output_id <- loaded$metadata$table_id
  store$current_output_dir <- dir_path
  store$dirty <- FALSE
  store$show_saved_grid <- FALSE

  a <- loaded$analysis
  if (!is.null(a$trt_var)) grp$trt_var <- a$trt_var
  if (!is.null(a$trt_levels)) grp$trt_levels <- a$trt_levels
  if (!is.null(a$include_total)) grp$include_total <- a$include_total
  if (!is.null(a$total_label)) grp$total_label <- a$total_label
  if (!is.null(a$denominator)) grp$denominator <- a$denominator
  if (!is.null(a$by_var)) grp$by_var <- a$by_var
  if (!is.null(a$analysis_vars)) grp$analysis_vars <- a$analysis_vars
  if (!is.null(a$combined_groups)) grp$combined_groups <- a$combined_groups
  if (!is.null(a$var_configs)) store$var_configs <- a$var_configs
  if (!is.null(a$var_labels)) store$var_labels <- a$var_labels
  if (!is.null(a$added_levels)) store$added_levels <- a$added_levels

  list(success = TRUE, message = paste0("Loaded: ", loaded$metadata$table_id),
       table_id = loaded$metadata$table_id)
}

# ── Reset store for a new output ──
reset_for_new_output <- function(store, grp) {
  store$ard <- NULL
  store$raw_ard <- NULL
  store$code <- ""
  store$template <- NULL
  store$var_configs <- list()
  store$var_labels <- list()
  store$added_levels <- list()
  store$fmt <- normalize_fmt(list())
  store$figure <- NULL
  store$listing <- NULL
  store$current_output_id <- NULL
  store$current_output_dir <- NULL
  store$dirty <- FALSE
  store$show_saved_grid <- TRUE

  grp$trt_var <- NULL
  grp$trt_levels <- NULL
  grp$analysis_vars <- list()
  grp$combined_groups <- list()
  grp$by_var <- NULL
  grp$by_levels <- NULL

  if (!is.null(store$output_dir) && dir.exists(store$output_dir)) {
    store$saved_outputs <- scan_outputs(store$output_dir)
  }
}

# ── Load startup preferences ──
load_startup_prefs <- function(store) {
  prefs_path <- file.path(getwd(), ".local", "loom_prefs.yaml")
  if (file.exists(prefs_path)) {
    prefs <- tryCatch(yaml::read_yaml(prefs_path), error = function(e) list())
    if (!is.null(prefs$output_dir) && dir.exists(prefs$output_dir)) {
      store$output_dir <- prefs$output_dir
      store$saved_outputs <- scan_outputs(prefs$output_dir)
      if (nrow(store$saved_outputs) > 0) store$show_saved_grid <- TRUE
    }
  } else {
    default_dir <- file.path(getwd(), ".local", "output")
    dir.create(default_dir, recursive = TRUE, showWarnings = FALSE)
    store$output_dir <- default_dir
    tryCatch(
      yaml::write_yaml(list(output_dir = default_dir), prefs_path),
      error = function(e) NULL
    )
  }
}

# ── Build saved outputs viewer (reactable-based for 100+ outputs) ──
render_saved_grid <- function(store) {
  if (!isTRUE(store$show_saved_grid)) return(NULL)

  outputs <- store$saved_outputs
  has_outputs <- !is.null(outputs) && nrow(outputs) > 0
  out_dir <- store$output_dir %||% file.path(getwd(), ".local", "output")

  # Toolbar (always shown)
  toolbar <- htmltools::tags$div(class = "ar-saved-grid__header",
    htmltools::tags$h3(class = "ar-saved-grid__title", "Saved Outputs"),
    htmltools::tags$div(class = "ar-saved-grid__toolbar",
      if (has_outputs) htmltools::tags$span(class = "ar-saved-grid__count",
        paste0(nrow(outputs), " output", if (nrow(outputs) != 1) "s")),
      htmltools::tags$span(class = "ar-saved-grid__dir", out_dir),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn--xs",
        onclick = "Shiny.setInputValue('change_output_dir', Math.random(), {priority: 'event'})",
        "\u2699 Change"
      ),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn--xs",
        onclick = "Shiny.setInputValue('close_saved_grid', Math.random(), {priority: 'event'})",
        "\u2715 Close"
      )
    )
  )

  if (!has_outputs) {
    return(htmltools::tags$div(class = "ar-saved-overlay",
      htmltools::tags$div(class = "ar-saved-grid-wrap",
        toolbar,
        ui_empty_state(
          "No saved outputs",
          "Build a table and press Ctrl+S to save.",
          "fa-folder-open"
        )
      )
    ))
  }

  # Build display table
  display <- data.frame(
    Name = outputs$table_id,
    Template = outputs$template,
    Dataset = outputs$dataset,
    Modified = outputs$modified,
    dir_path = outputs$dir_path,
    stringsAsFactors = FALSE
  )

  current_id <- store$current_output_id

  tbl <- reactable::reactable(
    display,
    columns = list(
      Name = reactable::colDef(
        name = "Name", minWidth = 200,
        cell = function(value, index) {
          is_active <- identical(value, current_id)
          htmltools::tags$span(
            class = if (is_active) "ar-saved-tbl__name--active" else "",
            style = list(fontWeight = 500, fontSize = "12px"),
            value,
            if (is_active) htmltools::tags$span(
              style = list(fontSize = "9px", color = "var(--accent)", marginLeft = "6px"),
              "(current)")
          )
        }
      ),
      Template = reactable::colDef(
        name = "Type", width = 90, align = "center",
        cell = function(value) {
          htmltools::tags$span(
            class = "ar-saved-card__badge",
            toupper(value)
          )
        }
      ),
      Dataset = reactable::colDef(name = "Dataset", width = 80, align = "center"),
      Modified = reactable::colDef(name = "Modified", width = 140),
      dir_path = reactable::colDef(
        name = "", width = 120, align = "right",
        cell = function(value, index) {
          name <- display$Name[index]
          htmltools::tags$div(
            style = list(display = "flex", gap = "4px"),
            htmltools::tags$button(
              class = "ar-btn-primary ar-btn--xs",
              onclick = sprintf(
                "Shiny.setInputValue('load_output', '%s', {priority: 'event'})",
                value),
              "Load"
            ),
            htmltools::tags$button(
              class = "ar-btn-outline ar-btn--xs ar-btn--danger",
              onclick = sprintf(
                "if(confirm('Delete %s?')) Shiny.setInputValue('delete_output', '%s', {priority: 'event'})",
                name, value),
              "\u2715"
            )
          )
        }
      )
    ),
    searchable = TRUE,
    defaultPageSize = 25,
    pagination = nrow(display) > 25,
    compact = TRUE,
    highlight = TRUE,
    borderless = TRUE,
    theme = reactable::reactableTheme(
      headerStyle = list(
        fontSize = "10px", fontWeight = 600, textTransform = "uppercase",
        letterSpacing = "0.5px", color = "var(--fg-muted)",
        borderBottom = "1px solid var(--border-light)"
      ),
      cellStyle = list(fontSize = "11px"),
      searchInputStyle = list(
        fontSize = "11px", padding = "6px 10px",
        border = "1px solid var(--border-light)", borderRadius = "4px",
        width = "100%", marginBottom = "12px"
      )
    )
  )

  htmltools::tags$div(class = "ar-saved-overlay",
    htmltools::tags$div(class = "ar-saved-grid-wrap", toolbar, tbl)
  )
}
