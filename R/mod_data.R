# Module: Data — Datasets, Summary, Column Explorer, Filters

# ── DATASETS section ──
mod_data_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$div(class = "ar-form-group",
      shiny::selectizeInput(ns("ds_select"), NULL,
        choices = c("adsl", "adae", "adcm", "adeff", "adeg",
                    "adex", "adlb", "adpc", "adrs", "adtte", "advs"),
        selected = NULL, multiple = TRUE,
        options = list(
          placeholder = "Select datasets to load...",
          allowEmptyOption = TRUE
        )
      )
    ),
    htmltools::tags$div(class = "ar-flex ar-gap-8 ar-mb-8",
      htmltools::tags$button(
        id = ns("load_btn"), class = "ar-btn-primary",
        onclick = paste0("Shiny.setInputValue('", ns("load_btn"), "', Math.random(), {priority: 'event'})"),
        htmltools::tags$i(class = "fa fa-download", style = "font-size: 11px;"),
        "Load"
      ),
      htmltools::tags$button(
        id = ns("load_demo"), class = "ar-btn-outline",
        onclick = paste0("Shiny.setInputValue('", ns("load_demo"), "', Math.random(), {priority: 'event'})"),
        "Demo Data"
      ),
      htmltools::tags$label(
        `for` = ns("upload_file"),
        class = "ar-btn-outline",
        style = "cursor: pointer; margin: 0;",
        htmltools::tags$i(class = "fa fa-upload", style = "font-size: 11px; margin-right: 4px;"),
        "Upload"
      ),
      htmltools::tags$div(style = "display: none;",
        shiny::fileInput(ns("upload_file"), NULL,
          accept = c(".rds", ".csv", ".sas7bdat", ".xpt")
        )
      )
    )
  )
}

# ── DATA SUMMARY section ──
mod_data_summary_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$div(class = "ar-form-group",
      shiny::uiOutput(ns("summary_ds_picker"))
    ),
    shiny::uiOutput(ns("summary_stats"))
  )
}

# ── COLUMN EXPLORER section ──
mod_data_col_explorer_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$div(class = "ar-form-group",
      shiny::selectizeInput(ns("explore_col"), NULL, choices = NULL, width = "100%",
        options = list(placeholder = "Select a column...", allowEmptyOption = TRUE)
      )
    ),
    shiny::uiOutput(ns("col_detail")),
    shiny::uiOutput(ns("col_explorer_actions"))
  )
}

# ── FILTERS section ──
mod_data_filters_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$div(class = "ar-form-group",
      shiny::selectizeInput(ns("filter_col_pick"), NULL, choices = NULL,
        multiple = TRUE, width = "100%",
        options = list(placeholder = "Select columns to filter...", allowEmptyOption = TRUE)
      )
    ),
    shiny::uiOutput(ns("filter_cards")),
    shiny::uiOutput(ns("filter_actions"))
  )
}

# ── DATASET section (Template sidebar) ──
mod_data_pipeline_dataset_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Analysis Dataset"),
      shiny::selectInput(ns("pipeline_ds"), NULL, choices = NULL, width = "100%")
    ),
    htmltools::tags$div(class = "ar-form-group ar-mt-8",
      htmltools::tags$label(class = "ar-form-label", "Dataset Filter"),
      htmltools::tags$input(
        type = "text", class = "ar-input ar-input--sm",
        id = ns("data_filter"),
        placeholder = "e.g. AVISIT == 'Week 24'",
        style = "width: 100%;",
        onchange = paste0(
          "Shiny.setInputValue('", ns("data_filter"),
          "', this.value, {priority: 'event'})"
        )
      ),
      htmltools::tags$div(class = "ar-form-hint", "Filter applied to the primary dataset")
    )
  )
}

# ── POPULATION section (Template sidebar) ──
mod_data_pipeline_pop_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Population Source"),
      htmltools::tags$div(class = "ar-flex ar-items-center ar-gap-8",
        htmltools::tags$span(style = "font-size: 12px; color: var(--fg-2); font-weight: 500;", "ADSL"),
        htmltools::tags$span(style = "font-size: 11px; color: var(--fg-muted);", "(always)")
      )
    ),
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Analysis Population"),
      shiny::selectInput(ns("pop_flag"), NULL,
        choices = c("None" = "", "SAFFL", "ITTFL", "EFFFL", "FASFL"),
        selected = "SAFFL", width = "100%"
      )
    ),
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Population Filter"),
      htmltools::tags$input(
        type = "text", class = "ar-input ar-input--sm",
        id = ns("pop_filter"),
        placeholder = "e.g. AGE >= 18",
        style = "width: 100%;",
        onchange = paste0(
          "Shiny.setInputValue('", ns("pop_filter"),
          "', this.value, {priority: 'event'})"
        )
      ),
      htmltools::tags$div(class = "ar-form-hint", "Filter applied to ADSL population")
    ),
    shiny::uiOutput(ns("pipeline_n"))
  )
}

# ── Server ──
mod_data_server <- function(id, store, grp) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # --- Internal state for filters ---
    active_filters <- shiny::reactiveVal(list())

    # ── Load selected datasets ──
    shiny::observeEvent(input$load_btn, {
      req(input$ds_select)
      for (ds_name in input$ds_select) {
        path <- file.path("/home/vignesh/R_Projects/adam_pilot/data", paste0(ds_name, ".rds"))
        if (file.exists(path)) {
          store$datasets[[ds_name]] <- readRDS(path)
        }
      }
      session$sendCustomMessage("ar_toast",
        list(message = paste("Loaded:", paste(input$ds_select, collapse = ", ")), type = "success"))

      ds_names <- names(store$datasets)
      shiny::updateSelectInput(session, "pipeline_ds", choices = ds_names, selected = ds_names[1])
      store$active_ds <- ds_names[1]

      if ("adsl" %in% ds_names) {
        flags <- fct_detect_pop_flags(names(store$datasets[["adsl"]]))
        shiny::updateSelectInput(session, "pop_flag",
          choices = c("None" = "", flags),
          selected = if ("SAFFL" %in% flags) "SAFFL" else "")
      }

      session$sendCustomMessage("ar_unlock_step", list(step = "template"))
      store$pipeline_state$data <- TRUE
    })

    # ── Load Demo Data ──
    shiny::observeEvent(input$load_demo, {
      path <- "/home/vignesh/R_Projects/adam_pilot/data/adsl.rds"
      if (file.exists(path)) {
        store$datasets[["adsl"]] <- readRDS(path)
        store$active_ds <- "adsl"

        shiny::updateSelectInput(session, "pipeline_ds", choices = "adsl", selected = "adsl")

        flags <- fct_detect_pop_flags(names(store$datasets[["adsl"]]))
        shiny::updateSelectInput(session, "pop_flag",
          choices = c("None" = "", flags),
          selected = if ("SAFFL" %in% flags) "SAFFL" else "")

        store$template <- "demog"
        adsl <- store$datasets[["adsl"]]
        defaults <- spec_demog(adsl)

        trt_var <- defaults$grouping$trt_var
        trt_levels <- sort(unique(adsl[[trt_var]]))
        grp$trt_var <- trt_var
        grp$trt_levels <- trt_levels
        grp$include_total <- TRUE
        grp$analysis_vars <- defaults$grouping$analysis_vars
        store$var_configs <- defaults$var_configs
        store$fmt <- defaults$fmt

        session$sendCustomMessage("ar_unlock_step", list(step = "template"))
        session$sendCustomMessage("ar_unlock_step", list(step = "analysis"))
        session$sendCustomMessage("ar_unlock_step", list(step = "format"))
        store$pipeline_state$data <- TRUE
        store$pipeline_state$template <- TRUE
        store$pipeline_state$analysis <- TRUE

        session$sendCustomMessage("ar_toast",
          list(message = "Demo data loaded: ADSL + Demographics template", type = "success"))
      }
    })

    # ── Upload file ──
    shiny::observeEvent(input$upload_file, {
      req(input$upload_file)
      f <- input$upload_file
      ext <- tolower(tools::file_ext(f$name))
      ds_name <- tools::file_path_sans_ext(f$name)

      tryCatch({
        data <- switch(ext,
          rds = readRDS(f$datapath),
          csv = readr::read_csv(f$datapath, show_col_types = FALSE),
          stop("Unsupported format")
        )
        store$datasets[[ds_name]] <- data
        ds_names <- names(store$datasets)
        shiny::updateSelectInput(session, "pipeline_ds", choices = ds_names, selected = ds_names[1])
        store$active_ds <- ds_name
        session$sendCustomMessage("ar_toast",
          list(message = paste("Uploaded:", ds_name), type = "success"))
        session$sendCustomMessage("ar_unlock_step", list(step = "template"))
        store$pipeline_state$data <- TRUE
      }, error = function(e) {
        session$sendCustomMessage("ar_toast",
          list(message = paste("Upload failed:", e$message), type = "error"))
      })
    })

    # ── Switch active dataset from pill click ──
    shiny::observeEvent(input$switch_ds, {
      store$active_ds <- input$switch_ds
    })

    # ── Update column explorer + filter dropdowns when dataset changes ──
    shiny::observe({
      req(store$active_ds, store$datasets[[store$active_ds]])
      cols <- names(store$datasets[[store$active_ds]])
      shiny::updateSelectizeInput(session, "explore_col", choices = cols, selected = character(0))
      shiny::updateSelectizeInput(session, "filter_col_pick", choices = cols, selected = character(0))
    })

    # ════════════════════════════════════════
    # DATA SUMMARY outputs
    # ════════════════════════════════════════

    output$summary_ds_picker <- shiny::renderUI({
      ds_names <- names(store$datasets)
      if (length(ds_names) == 0) {
        return(htmltools::tags$span(
          style = "font-size: 11px; color: var(--fg-muted);", "No datasets loaded"))
      }
      # Build choices with row counts
      choices <- stats::setNames(ds_names, vapply(ds_names, function(nm) {
        paste0(nm, " (", format(nrow(store$datasets[[nm]]), big.mark = ","), " rows)")
      }, character(1)))
      shiny::selectInput(ns("summary_ds"), NULL,
        choices = choices, selected = store$active_ds, width = "100%")
    })

    # Switch active dataset from summary picker
    shiny::observeEvent(input$summary_ds, {
      if (!is.null(input$summary_ds) && nzchar(input$summary_ds)) {
        store$active_ds <- input$summary_ds
      }
    })

    output$summary_stats <- shiny::renderUI({
      req(store$active_ds, store$datasets[[store$active_ds]])
      d <- store$datasets[[store$active_ds]]
      n_row <- nrow(d)
      n_col <- ncol(d)

      # Missing %
      total_cells <- n_row * n_col
      n_missing <- sum(vapply(d, function(x) sum(is.na(x)), integer(1)))
      pct_missing <- if (total_cells > 0) round(n_missing / total_cells * 100, 1) else 0

      # Type counts
      col_types <- vapply(d, function(x) {
        if (is.numeric(x)) "NUM"
        else if (inherits(x, "Date") || inherits(x, "POSIXt")) "DATE"
        else "CHR"
      }, character(1))
      type_counts <- table(col_types)

      type_badges <- lapply(names(type_counts), function(tp) {
        htmltools::tags$span(class = "ar-ds-summary__type-chip",
          ui_type_badge(tp),
          htmltools::tags$span(class = "ar-ds-summary__type-count", unname(type_counts[tp]))
        )
      })

      htmltools::tags$div(class = "ar-ds-summary",
        htmltools::tags$div(class = "ar-ds-summary__grid",
          htmltools::tags$div(class = "ar-ds-summary__cell",
            htmltools::tags$div(class = "ar-ds-summary__value", format(n_row, big.mark = ",")),
            htmltools::tags$div(class = "ar-ds-summary__label", "Rows")
          ),
          htmltools::tags$div(class = "ar-ds-summary__cell",
            htmltools::tags$div(class = "ar-ds-summary__value", n_col),
            htmltools::tags$div(class = "ar-ds-summary__label", "Columns")
          ),
          htmltools::tags$div(class = "ar-ds-summary__cell",
            htmltools::tags$div(class = "ar-ds-summary__value", paste0(pct_missing, "%")),
            htmltools::tags$div(class = "ar-ds-summary__label", "Missing")
          ),
          htmltools::tags$div(class = "ar-ds-summary__cell",
            htmltools::tags$div(class = "ar-ds-summary__types", do.call(htmltools::tagList, type_badges)),
            htmltools::tags$div(class = "ar-ds-summary__label", "Types")
          )
        )
      )
    })

    # ════════════════════════════════════════
    # COLUMN EXPLORER outputs
    # ════════════════════════════════════════

    output$col_detail <- shiny::renderUI({
      req(store$active_ds, store$datasets[[store$active_ds]], input$explore_col)
      d <- store$datasets[[store$active_ds]]
      col <- input$explore_col
      if (!col %in% names(d)) return(NULL)

      p <- fct_profile_column(d[[col]], col, nrow(d))

      # Build detail card
      stats_rows <- list()

      if (p$type == "NUM" && !is.null(p$summary)) {
        s <- p$summary
        stats_rows <- list(
          list("Count", format(nrow(d) - p$n_missing, big.mark = ",")),
          list("Missing", paste0(p$n_missing, " (", p$pct_missing, "%)")),
          list("Distinct", p$n_unique),
          list("Mean", s$mean),
          list("SD", s$sd),
          list("Median", s$median),
          list("Min", s$min),
          list("Q1", s$q1),
          list("Q3", s$q3),
          list("Max", s$max)
        )
      } else if (p$type == "DATE" && !is.null(p$summary)) {
        s <- p$summary
        stats_rows <- list(
          list("Count", format(nrow(d) - p$n_missing, big.mark = ",")),
          list("Missing", paste0(p$n_missing, " (", p$pct_missing, "%)")),
          list("Distinct", p$n_unique),
          list("Min", s$min),
          list("Max", s$max)
        )
      } else if (p$type == "CHR" && !is.null(p$summary)) {
        stats_rows <- list(
          list("Count", format(nrow(d) - p$n_missing, big.mark = ",")),
          list("Missing", paste0(p$n_missing, " (", p$pct_missing, "%)")),
          list("Distinct", p$n_unique)
        )
      }

      # Stats table
      stats_ui <- if (length(stats_rows) > 0) {
        htmltools::tags$div(class = "ar-col-detail__stats",
          lapply(stats_rows, function(r) {
            htmltools::tags$div(class = "ar-col-detail__row",
              htmltools::tags$span(class = "ar-col-detail__key", r[[1]]),
              htmltools::tags$span(class = "ar-col-detail__val", as.character(r[[2]]))
            )
          })
        )
      }

      # Frequency bars for CHR
      freq_ui <- NULL
      if (p$type == "CHR" && !is.null(p$summary) && length(p$summary$top_values) > 0) {
        tv <- p$summary$top_values
        max_count <- max(tv)
        freq_ui <- htmltools::tags$div(class = "ar-col-detail__freq ar-mt-8",
          htmltools::tags$div(class = "ar-form-label", "Top Values"),
          lapply(seq_along(tv), function(i) {
            pct <- round(tv[i] / nrow(d) * 100, 1)
            bar_width <- round(tv[i] / max_count * 100)
            htmltools::tags$div(class = "ar-freq-bar",
              htmltools::tags$div(class = "ar-freq-bar__label", names(tv)[i]),
              htmltools::tags$div(class = "ar-freq-bar__track",
                htmltools::tags$div(class = "ar-freq-bar__fill",
                  style = paste0("width:", bar_width, "%;"))
              ),
              htmltools::tags$span(class = "ar-freq-bar__count",
                paste0(tv[i], " (", pct, "%)"))
            )
          })
        )
      }

      # R attributes footer
      attr_parts <- c(
        paste0("class: ", p$r_class),
        if (nzchar(p$label)) paste0("label: \"", p$label, "\""),
        if (nzchar(p$format)) paste0("format: ", p$format)
      )

      htmltools::tags$div(class = "ar-col-detail",
        htmltools::tags$div(class = "ar-col-detail__header",
          ui_type_badge(p$type),
          htmltools::tags$span(class = "ar-col-detail__name", col),
          if (nzchar(p$label)) htmltools::tags$span(class = "ar-col-detail__label", p$label)
        ),
        stats_ui,
        freq_ui,
        htmltools::tags$div(class = "ar-col-detail__attrs ar-mt-8",
          htmltools::tags$div(class = "ar-form-label", "Attributes"),
          htmltools::tags$div(class = "ar-text-sm ar-font-mono",
            style = "color: var(--fg-muted);",
            paste(attr_parts, collapse = "  |  "))
        )
      )
    })

    # Column Explorer — Clear button
    output$col_explorer_actions <- shiny::renderUI({
      req(input$explore_col)
      if (!nzchar(input$explore_col)) return(NULL)
      htmltools::tags$div(class = "ar-mt-8",
        htmltools::tags$button(
          class = "ar-btn-ghost",
          onclick = paste0("Shiny.setInputValue('", ns("col_explorer_clear"), "', Math.random(), {priority: 'event'})"),
          "Clear"
        )
      )
    })

    shiny::observeEvent(input$col_explorer_clear, {
      shiny::updateSelectizeInput(session, "explore_col", selected = character(0))
    })

    # ════════════════════════════════════════
    # FILTERS
    # ════════════════════════════════════════

    # Helper: create a filter entry for a column
    make_filter_entry <- function(col, d) {
      x <- d[[col]]
      if (is.numeric(x) && length(unique(stats::na.omit(x))) <= 10) {
        levs <- sort(unique(stats::na.omit(x)))
        list(col = col, type = "checkbox", levels = as.character(levs), selected = as.character(levs))
      } else if (is.numeric(x)) {
        vals <- stats::na.omit(x)
        list(col = col, type = "range", min = min(vals), max = max(vals),
             cur_min = min(vals), cur_max = max(vals))
      } else if (inherits(x, "Date") || inherits(x, "POSIXt")) {
        vals <- stats::na.omit(x)
        list(col = col, type = "date_range",
             min = as.character(min(vals)), max = as.character(max(vals)),
             cur_min = as.character(min(vals)), cur_max = as.character(max(vals)))
      } else {
        levs <- sort(unique(stats::na.omit(as.character(x))))
        if (length(levs) > 15) {
          list(col = col, type = "search_select", levels = levs, selected = character(0))
        } else {
          list(col = col, type = "checkbox", levels = levs, selected = levs)
        }
      }
    }

    # Snapshot current widget values into filter entries (preserves state across re-renders)
    snapshot_filters <- function(filts) {
      lapply(filts, function(f) {
        col <- f$col
        if (f$type == "range") {
          val <- input[[paste0("filt_range_", col)]]
          if (!is.null(val)) { f$cur_min <- val[1]; f$cur_max <- val[2] }
        } else if (f$type == "date_range") {
          val <- input[[paste0("filt_date_", col)]]
          if (!is.null(val)) { f$cur_min <- as.character(val[1]); f$cur_max <- as.character(val[2]) }
        } else if (f$type == "search_select") {
          val <- input[[paste0("filt_sel_", col)]]
          if (!is.null(val)) f$selected <- val
        } else if (f$type == "checkbox") {
          val <- input[[paste0("filt_chk_", col)]]
          if (!is.null(val)) f$selected <- val
        }
        f
      })
    }

    # Watch multi-select: add/remove filters to match selected chips
    shiny::observeEvent(input$filter_col_pick, ignoreNULL = FALSE, {
      req(store$active_ds, store$datasets[[store$active_ds]])
      d <- store$datasets[[store$active_ds]]
      selected <- input$filter_col_pick %||% character(0)
      current <- active_filters()
      existing_cols <- vapply(current, function(f) f$col, character(1))

      new_cols <- setdiff(selected, existing_cols)
      removed_cols <- setdiff(existing_cols, selected)

      # Only update if there's an actual change
      if (length(new_cols) == 0 && length(removed_cols) == 0) return()

      # Snapshot current widget values before re-render
      current <- snapshot_filters(current)

      # Remove filters for deselected columns
      if (length(removed_cols) > 0) {
        current <- current[!vapply(current, function(f) f$col %in% removed_cols, logical(1))]
      }

      # Add filters for newly selected columns
      for (col in new_cols) {
        if (col %in% names(d)) {
          current <- c(current, list(make_filter_entry(col, d)))
        }
      }

      active_filters(current)
    })

    # Remove filter via × button — also sync selectize chips
    shiny::observeEvent(input$filter_remove, {
      col <- input$filter_remove
      current <- active_filters()
      active_filters(current[vapply(current, function(f) f$col != col, logical(1))])
      # Sync selectize: remove this column from selected
      remaining <- vapply(active_filters(), function(f) f$col, character(1))
      shiny::updateSelectizeInput(session, "filter_col_pick", selected = remaining)
    })

    # Clear all filters — also clear selectize
    shiny::observeEvent(input$filter_clear_all, {
      active_filters(list())
      shiny::updateSelectizeInput(session, "filter_col_pick", selected = character(0))
    })

    # Render filter cards
    output$filter_cards <- shiny::renderUI({
      filts <- active_filters()
      if (length(filts) == 0) {
        return(htmltools::tags$div(
          style = "font-size: 11px; color: var(--fg-muted); padding: 4px 0;",
          "No active filters"))
      }

      htmltools::tagList(lapply(filts, function(f) {
        col <- f$col
        remove_btn <- htmltools::tags$button(
          class = "ar-filter-card__remove",
          onclick = paste0("Shiny.setInputValue('", ns("filter_remove"), "', '",
                           col, "', {priority: 'event'})"),
          htmltools::HTML("&times;")
        )

        widget <- if (f$type == "range") {
          shiny::sliderInput(ns(paste0("filt_range_", col)), NULL,
            min = f$min, max = f$max,
            value = c(f$cur_min, f$cur_max),
            step = if (f$max - f$min > 100) 1 else round((f$max - f$min) / 100, 2),
            width = "100%")
        } else if (f$type == "date_range") {
          shiny::dateRangeInput(ns(paste0("filt_date_", col)), NULL,
            start = f$cur_min, end = f$cur_max,
            min = f$min, max = f$max, width = "100%")
        } else if (f$type == "search_select") {
          # Searchable multi-select — empty = all included, pick values to filter TO
          n_total <- length(f$levels)
          hint <- htmltools::tags$div(
            class = "ar-filter-hint",
            if (length(f$selected) == 0)
              paste0("All ", n_total, " values included")
            else
              paste0("Showing ", length(f$selected), " of ", n_total)
          )
          htmltools::tagList(
            hint,
            shiny::selectizeInput(ns(paste0("filt_sel_", col)), NULL,
              choices = f$levels, selected = f$selected, multiple = TRUE,
              width = "100%",
              options = list(
                plugins = list("remove_button"),
                placeholder = paste0("Type to search ", n_total, " values..."),
                maxOptions = 200
              ))
          )
        } else {
          # Checkbox — all levels
          shiny::checkboxGroupInput(ns(paste0("filt_chk_", col)), NULL,
            choices = f$levels, selected = f$selected,
            inline = FALSE)
        }

        htmltools::tags$div(class = "ar-filter-card",
          htmltools::tags$div(class = "ar-filter-card__header",
            htmltools::tags$span(class = "ar-filter-card__col", col),
            htmltools::tags$span(class = "ar-filter-card__type", gsub("_", " ", f$type)),
            remove_btn
          ),
          htmltools::tags$div(class = "ar-filter-card__body", widget)
        )
      }))
    })

    output$filter_actions <- shiny::renderUI({
      filts <- active_filters()
      if (length(filts) == 0) return(NULL)
      htmltools::tags$div(class = "ar-mt-8",
        htmltools::tags$button(
          class = "ar-btn-ghost",
          onclick = paste0("Shiny.setInputValue('", ns("filter_clear_all"), "', Math.random(), {priority: 'event'})"),
          "Clear All Filters"
        )
      )
    })

    # Push filter values into store$explore_filters
    shiny::observe({
      filts <- active_filters()
      if (length(filts) == 0) {
        store$explore_filters <- list()
        return()
      }

      result <- list()
      for (f in filts) {
        col <- f$col
        if (f$type == "range") {
          val <- input[[paste0("filt_range_", col)]]
          if (!is.null(val)) {
            result[[col]] <- list(type = "range", min = val[1], max = val[2])
          }
        } else if (f$type == "date_range") {
          val <- input[[paste0("filt_date_", col)]]
          if (!is.null(val)) {
            result[[col]] <- list(type = "date_range", min = val[1], max = val[2])
          }
        } else if (f$type == "search_select") {
          val <- input[[paste0("filt_sel_", col)]]
          # Empty selection = all included, don't filter
          if (length(val) > 0) {
            result[[col]] <- list(type = "checkbox", selected = val)
          }
        } else if (f$type == "checkbox") {
          val <- input[[paste0("filt_chk_", col)]]
          result[[col]] <- list(type = "checkbox", selected = val %||% character(0))
        }
      }
      store$explore_filters <- result
    })

    # ════════════════════════════════════════
    # PIPELINE (Analysis Source)
    # ════════════════════════════════════════

    # Required dataset chips for DATASET section
    output$required_ds_chips <- shiny::renderUI({
      tmpl <- store$template
      if (is.null(tmpl)) return(NULL)
      required_ds <- fct_template_required_datasets(tmpl)
      loaded_ds <- names(store$datasets)

      chips <- lapply(required_ds, function(ds) {
        loaded <- ds %in% loaded_ds
        icon_html <- if (loaded) "\u2713" else "\u25cb"
        htmltools::tags$span(
          style = paste0(
            "display: inline-flex; align-items: center; gap: 4px; ",
            "padding: 2px 8px; border-radius: var(--radius-sm); ",
            "font-size: 11px; font-weight: 500; margin-right: 4px; ",
            if (loaded) "background: var(--success-bg); color: var(--success);"
            else "background: var(--bg-muted); color: var(--fg-muted); border: 1px solid var(--border-light);"
          ),
          htmltools::tags$span(style = "font-size: 10px;", icon_html),
          toupper(ds)
        )
      })

      htmltools::tags$div(class = "ar-flex ar-gap-4 ar-mb-8",
        style = "flex-wrap: wrap;",
        chips
      )
    })

    # Row count display for DATASET section
    output$pipeline_row_count <- shiny::renderUI({
      req(input$pipeline_ds, nzchar(input$pipeline_ds))
      req(store$datasets[[input$pipeline_ds]])
      d <- store$datasets[[input$pipeline_ds]]
      htmltools::tags$div(
        style = "font-size: 12px; color: var(--fg-2); font-weight: 500; margin: 4px 0;",
        paste0(toupper(input$pipeline_ds), " \u00b7 ", format(nrow(d), big.mark = ","), " rows")
      )
    })

    # Store filter expressions
    shiny::observeEvent(input$data_filter, {
      store$pipeline_filters$data_filter <- input$data_filter
    }, ignoreNULL = FALSE)

    shiny::observeEvent(input$pop_filter, {
      store$pipeline_filters$pop_filter <- input$pop_filter
    }, ignoreNULL = FALSE)

    output$pipeline_n <- shiny::renderUI({
      pop <- input$pop_flag
      adsl <- store$datasets[["adsl"]]

      # Start with ADSL for population N
      if (is.null(adsl)) {
        # Fall back to primary dataset
        req(input$pipeline_ds, nzchar(input$pipeline_ds))
        req(store$datasets[[input$pipeline_ds]])
        adsl <- store$datasets[[input$pipeline_ds]]
      }

      n_total <- nrow(adsl)

      # Apply pop flag on ADSL
      pop_d <- adsl
      if (!is.null(pop) && nzchar(pop) && pop %in% names(pop_d)) {
        pop_d <- pop_d[pop_d[[pop]] == "Y", ]
      }
      # Apply pop_filter on ADSL
      ps <- input$pop_filter
      if (!is.null(ps) && nzchar(ps)) {
        tryCatch({
          mask <- eval(parse(text = ps), envir = pop_d)
          if (is.logical(mask)) pop_d <- pop_d[mask & !is.na(mask), ]
        }, error = function(e) NULL)
      }

      n_pop <- nrow(pop_d)

      # Apply data_filter on primary dataset
      ds_name <- if (!is.null(input$pipeline_ds) && nzchar(input$pipeline_ds)) {
        input$pipeline_ds
      } else {
        names(store$datasets)[1]
      }
      primary_d <- if (!is.null(ds_name) && nzchar(ds_name)) store$datasets[[ds_name]] else NULL
      n_data <- if (!is.null(primary_d)) {
        # Apply pop flag on primary too
        if (!is.null(pop) && nzchar(pop) && pop %in% names(primary_d)) {
          primary_d <- primary_d[primary_d[[pop]] == "Y", ]
        }
        df <- input$data_filter
        if (!is.null(df) && nzchar(df)) {
          tryCatch({
            mask <- eval(parse(text = df), envir = primary_d)
            if (is.logical(mask)) primary_d <- primary_d[mask & !is.na(mask), ]
          }, error = function(e) NULL)
        }
        nrow(primary_d)
      } else n_pop

      store$pipeline_filters <- list(
        dataset = ds_name,
        pop_flag = pop,
        data_filter = input$data_filter %||% "",
        pop_filter = ps %||% "",
        n = n_pop
      )

      htmltools::tags$div(
        style = "font-size: 12px; color: var(--fg-2); font-weight: 500; margin-top: 8px;",
        paste0("Analysis N \u00b7 ", format(n_pop, big.mark = ","))
      )
    })

  })
}
