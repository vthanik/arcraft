# Module: Data — Datasets, Summary, Pipeline filters

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
        htmltools::tags$i(class = "fa fa-download ar-icon-md"),
        "Load"
      ),
      htmltools::tags$button(
        id = ns("load_demo"), class = "ar-btn-outline",
        onclick = paste0("Shiny.setInputValue('", ns("load_demo"), "', Math.random(), {priority: 'event'})"),
        "Demo Data"
      ),
      htmltools::tags$label(
        `for` = ns("upload_file"),
        class = "ar-btn-outline ar-cursor-pointer ar-m-0",
        htmltools::tags$i(class = "fa fa-upload ar-icon-md ar-icon-mr"),
        "Upload"
      ),
      htmltools::tags$div(class = "ar-hidden",
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
  shiny::uiOutput(ns("library_table"))
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
        type = "text", class = "ar-input ar-input--sm ar-w-full",
        id = ns("data_filter"),
        placeholder = "AGE > 65 | SEX %in% c('F','M') | !is.na(COL)",
        oninput = paste0(
          "clearTimeout(this._deb); var el=this; this._deb=setTimeout(function(){",
          "Shiny.setInputValue('", ns("data_filter"),
          "', el.value, {priority: 'event'})}, 500)"
        )
      ),
      shiny::uiOutput(ns("data_filter_status"))
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
        htmltools::tags$span(class = "ar-text-sm ar-text-secondary ar-text-medium", "ADSL"),
        htmltools::tags$span(class = "ar-text-xs ar-text-muted", "(always)")
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
        type = "text", class = "ar-input ar-input--sm ar-w-full",
        id = ns("pop_filter"),
        placeholder = "e.g. AGE >= 18",
        oninput = paste0(
          "clearTimeout(this._deb); var el=this; this._deb=setTimeout(function(){",
          "Shiny.setInputValue('", ns("pop_filter"),
          "', el.value, {priority: 'event'})}, 500)"
        )
      ),
      shiny::uiOutput(ns("pop_filter_status"))
    ),
    shiny::uiOutput(ns("pipeline_n"))
  )
}

# Helper: validate a filter expression against a data frame
validate_filter_expr <- function(expr, data, label = "rows") {
  if (is.null(expr) || !nzchar(expr)) return(NULL)
  if (is.null(data)) {
    return(htmltools::tags$div(class = "ar-filter-status ar-filter-status--error", "No dataset loaded"))
  }
  tryCatch({
    mask <- eval(parse(text = expr), envir = data)
    if (!is.logical(mask)) {
      return(htmltools::tags$div(class = "ar-filter-status ar-filter-status--error",
        "Expression must return logical (TRUE/FALSE)"))
    }
    n_match <- sum(mask & !is.na(mask))
    htmltools::tags$div(class = "ar-filter-status ar-filter-status--ok",
      paste0("\u2713 ", format(n_match, big.mark = ","), " of ",
             format(nrow(data), big.mark = ","), " ", label, " match"))
  }, error = function(e) {
    msg <- conditionMessage(e)
    hint <- ""
    if (grepl("object.*not found", msg)) {
      bad_name <- gsub(".*object '([^']+)'.*", "\\1", msg)
      dists <- utils::adist(tolower(bad_name), tolower(names(data)))[1, ]
      close <- names(data)[dists <= 2]
      if (length(close) > 0) hint <- paste0(" Did you mean: ", paste(close, collapse = ", "), "?")
    }
    htmltools::tags$div(class = "ar-filter-status ar-filter-status--error",
      paste0("\u2717 ", msg, hint))
  })
}

# ── Server ──
mod_data_server <- function(id, store, grp) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

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

    # ════════════════════════════════════════
    # DATA SUMMARY outputs
    # ════════════════════════════════════════

    # SAS-style library table — all loaded datasets as rows
    output$library_table <- shiny::renderUI({
      ds_names <- names(store$datasets)
      if (length(ds_names) == 0) {
        return(htmltools::tags$div(class = "ar-text-sm ar-text-muted ar-py-4",
          "No datasets loaded"))
      }

      active <- store$active_ds
      rows <- lapply(ds_names, function(nm) {
        d <- store$datasets[[nm]]
        is_active <- identical(nm, active)
        row_cls <- paste0("ar-lib-row", if (is_active) " ar-lib-row--active" else "")
        htmltools::tags$tr(
          class = row_cls,
          onclick = paste0("Shiny.setInputValue('", ns("switch_lib_ds"),
            "', '", nm, "', {priority: 'event'})"),
          htmltools::tags$td(class = "ar-lib-row__name", toupper(nm)),
          htmltools::tags$td(class = "ar-lib-row__val", format(nrow(d), big.mark = ",")),
          htmltools::tags$td(class = "ar-lib-row__val", ncol(d))
        )
      })

      htmltools::tags$table(class = "ar-lib-table",
        htmltools::tags$thead(
          htmltools::tags$tr(
            htmltools::tags$th(class = "ar-lib-th", "Dataset"),
            htmltools::tags$th(class = "ar-lib-th ar-lib-th--num", "Rows"),
            htmltools::tags$th(class = "ar-lib-th ar-lib-th--num", "Cols")
          )
        ),
        htmltools::tags$tbody(rows)
      )
    })

    # Switch active dataset from library table click
    shiny::observeEvent(input$switch_lib_ds, {
      if (!is.null(input$switch_lib_ds) && nzchar(input$switch_lib_ds)) {
        store$active_ds <- input$switch_lib_ds
      }
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
          class = paste0("ar-ds-chip", if (loaded) " ar-ds-chip--loaded" else ""),
          htmltools::tags$span(class = "ar-text-xs", icon_html),
          toupper(ds)
        )
      })

      htmltools::tags$div(class = "ar-flex ar-gap-4 ar-mb-8 ar-flex-wrap",
        chips
      )
    })

    # Row count display for DATASET section
    output$pipeline_row_count <- shiny::renderUI({
      req(input$pipeline_ds, nzchar(input$pipeline_ds))
      req(store$datasets[[input$pipeline_ds]])
      d <- store$datasets[[input$pipeline_ds]]
      htmltools::tags$div(
        class = "ar-pipeline-label",
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

    # ── Live validation: Dataset Filter ──
    output$data_filter_status <- shiny::renderUI({
      expr <- input$data_filter
      if (is.null(expr) || !nzchar(expr)) {
        return(htmltools::tags$div(class = "ar-form-hint", "Filter applied to the primary dataset"))
      }
      ds_name <- input$pipeline_ds %||% names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      validate_filter_expr(expr, d, label = "rows")
    })

    # ── Live validation: Population Filter ──
    output$pop_filter_status <- shiny::renderUI({
      expr <- input$pop_filter
      if (is.null(expr) || !nzchar(expr)) {
        return(htmltools::tags$div(class = "ar-form-hint", "Filter applied to ADSL population"))
      }
      adsl <- store$datasets[["adsl"]]
      if (is.null(adsl)) {
        ds_name <- input$pipeline_ds %||% names(store$datasets)[1]
        adsl <- store$datasets[[ds_name]]
      }
      # Apply pop flag first
      pop <- input$pop_flag
      if (!is.null(pop) && nzchar(pop) && !is.null(adsl) && pop %in% names(adsl)) {
        adsl <- adsl[adsl[[pop]] == "Y", ]
      }
      validate_filter_expr(expr, adsl, label = "subjects")
    })

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
        class = "ar-pipeline-label ar-pipeline-label--top",
        paste0("Analysis N \u00b7 ", format(n_pop, big.mark = ","))
      )
    })

  })
}
