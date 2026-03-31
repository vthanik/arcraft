# App Server — Store + Module Wiring + Panel Switching + Preview/Export

app_server <- function(input, output, session) {

  # ── 1. Central Store ──
  store <- shiny::reactiveValues(
    datasets = list(),
    active_ds = NULL,
    explore_filters = list(),
    pipeline_filters = list(),
    template = NULL,
    var_configs = list(),
    var_labels = list(),
    added_levels = list(),
    extra_vars = character(0),
    fig_configs = list(),
    fmt = normalize_fmt(list()),
    ard = NULL,
    raw_ard = NULL,
    figure = NULL,
    listing = NULL,
    code = "",
    pipeline_state = list(
      data = FALSE, template = FALSE,
      analysis = FALSE, format = FALSE, output = FALSE
    ),
    # Save/restore state
    show_saved_grid = FALSE,
    saved_outputs = data.frame(
      table_id = character(0), template = character(0),
      dataset = character(0), created = character(0),
      modified = character(0), dir_path = character(0),
      stringsAsFactors = FALSE
    ),
    current_output_id = NULL,
    current_output_dir = NULL,
    output_dir = NULL,
    dirty = FALSE
  )

  # ── 1b. Independent Grouping ReactiveValues ──
  # Each sub-key is independently reactive — writing trt_levels won't
  # invalidate observers that only read by_var, etc.
  grp <- shiny::reactiveValues(
    trt_var = NULL, trt_levels = NULL,
    include_total = TRUE, include_unassigned = FALSE,
    combined_groups = list(),
    by_var = NULL, by_levels = NULL,
    denominator = "col_n", total_label = "Total",
    analysis_vars = list()
  )

  # ── 2. Module Servers ──
  mod_data_server("data", store, grp)
  mod_data_viewer_server("data_viewer", store)
  mod_template_server("template", store, grp)
  mod_grouping_server("grouping", store, grp)
  mod_treatment_server("treatment", store, grp)
  mod_analysis_vars_server("analysis_vars", store, grp)

  # Format modules return get_draft() functions (non-reactive architecture)
  titles_draft <- mod_titles_server("titles", store)
  cols_draft <- mod_columns_server("cols", store)
  header_spans_draft <- mod_header_spans_server("header_spans", store)
  rows_draft <- mod_rows_server("rows", store)
  page_output_draft <- mod_page_output_server("page_output", store)
  styles_draft <- mod_styles_server("styles", store)

  mod_n_counts_server("n_counts", store, grp)
  mod_validation_server("validation", store, grp)
  mod_code_server("code", store)

  # ── 2a. Auto-Preview DISABLED ──
  # User controls when to generate via Ctrl+Enter (Generate Preview).
  # No auto-trigger on config changes — avoids spinner-hangs and unwanted recomputation.

  # ── 2b. Preset Handlers ──
  shiny::observeEvent(input$fmt_preset_fda, {
    store$fmt <- apply_fmt_preset(shiny::isolate(store$fmt), "fda")
  })
  shiny::observeEvent(input$fmt_preset_booktabs, {
    store$fmt <- apply_fmt_preset(shiny::isolate(store$fmt), "booktabs")
  })
  shiny::observeEvent(input$fmt_preset_minimal, {
    store$fmt <- apply_fmt_preset(shiny::isolate(store$fmt), "minimal")
  })
  shiny::observeEvent(input$fmt_preset_company, {
    store$fmt <- apply_fmt_preset(shiny::isolate(store$fmt), "company")
  })

  # ── 2b. Template Info Display ──
  output$template_info_display <- shiny::renderUI({
    tmpl <- store$template
    if (is.null(tmpl)) {
      return(htmltools::tags$div(class = "ar-text-sm ar-text-muted ar-py-4",
        "Select a template from the gallery"))
    }
    tmpl_def <- get_template_def(tmpl)
    if (is.null(tmpl_def)) {
      return(htmltools::tags$div(class = "ar-text-sm",
        htmltools::tags$span(class = "ar-text-bold", tools::toTitleCase(tmpl))))
    }
    output_type <- fct_template_output_type(tmpl)
    type_label <- switch(output_type, table = "Table", figure = "Figure", listing = "Listing", "Table")
    dataset_label <- toupper(tmpl_def$adam_required[1] %||% "ADSL")

    htmltools::tags$div(class = "ar-template-info",
      htmltools::tags$div(class = "ar-template-info__name", tmpl_def$name),
      htmltools::tags$div(class = "ar-template-info__meta",
        htmltools::tags$span(class = "ar-template-info__type", type_label),
        htmltools::HTML(" &middot; "),
        htmltools::tags$span(dataset_label)
      ),
      if (!is.null(tmpl_def$description)) {
        htmltools::tags$div(class = "ar-template-info__desc", tmpl_def$description)
      }
    )
  })

  # ── 2c. Data Source N display ──
  output$data_source_n <- shiny::renderUI({
    req(length(store$datasets) > 0)
    ds_name <- store$pipeline_filters$dataset %||% names(store$datasets)[1]
    req(ds_name)
    d <- store$datasets[[ds_name]]
    req(d)
    pop <- store$pipeline_filters$pop_flag
    d <- apply_pop_filter(d, pop)
    n <- nrow(d)
    pop_label <- if (!is.null(pop) && nzchar(pop)) paste0(" (", pop, " = Y)") else ""
    htmltools::tags$div(class = "ar-data-source-n",
      htmltools::tags$span(class = "ar-text-sm ar-text-secondary ar-text-medium",
        paste0("N = ", n, " subjects", pop_label))
    )
  })

  # ── 2d. N Counts — extracted to mod_n_counts.R ──

  # ── 2e. ARD Data Table (reactable) ──
  output$ard_data_table <- reactable::renderReactable({
    ard <- store$ard
    if (is.null(ard)) return(NULL)
    ar_build_reactable(ard)
  })

  # ARD empty state
  output$ard_empty_state <- shiny::renderUI({
    if (!is.null(store$ard)) return(NULL)
    ui_empty_state(
      "ARD data will appear here",
      "Configure your analysis and press Ctrl+Enter to generate the Analysis Results Dataset.",
      "fa-table",
      cta = if (length(grp$analysis_vars) > 0) {
        htmltools::tags$button(
          class = "ar-btn-primary",
          onclick = "document.getElementById('preview_btn').click();",
          htmltools::tags$i(class = "fa fa-play ar-icon-sm ar-icon-mr"),
          "Generate Preview"
        )
      }
    )
  })

  # ARD dimensions text
  output$ard_dims <- shiny::renderText({
    ard <- store$ard
    if (is.null(ard)) return("")
    paste0(format(nrow(ard), big.mark = ","), " rows \u00d7 ", ncol(ard), " cols")
  })

  # ── 3. Activity Bar — Panel Switching ──
  switch_panel <- function(panel) {
    bslib::nav_select("sidebar_panels", panel, session = session)
    bslib::nav_select("canvas_panels", panel, session = session)
    session$sendCustomMessage("ar_switch_panel", list(panel = panel))
  }

  shiny::observeEvent(input$ab_data, switch_panel("data"))
  shiny::observeEvent(input$ab_template, switch_panel("template"))
  shiny::observeEvent(input$ab_analysis, switch_panel("analysis"))
  shiny::observeEvent(input$ab_format, switch_panel("format"))
  shiny::observeEvent(input$ab_output, switch_panel("output"))

  # ── 4. Generate Preview ──
  shiny::observeEvent(input$preview_btn, {
    # Validate requirements
    if (length(store$datasets) == 0) {
      session$sendCustomMessage("ar_toast",
        list(message = "Load data first", type = "warning"))
      return()
    }
    if (is.null(store$template)) {
      session$sendCustomMessage("ar_toast",
        list(message = "Select a template first", type = "warning"))
      return()
    }
    if (length(grp$analysis_vars) == 0) {
      session$sendCustomMessage("ar_toast",
        list(message = "Select analysis variables first", type = "warning"))
      return()
    }

    # Show loading spinner — always hide on exit (even on error)
    session$sendCustomMessage("ar_loading", list(show = TRUE))
    on.exit(session$sendCustomMessage("ar_loading", list(show = FALSE)), add = TRUE)

    tryCatch({
      # Snapshot format drafts from all modules into store (non-reactive architecture)
      store$fmt <- collect_format_drafts(
        titles_draft(), cols_draft(), header_spans_draft(),
        rows_draft(), page_output_draft(), styles_draft()
      )
      store$dirty <- TRUE

      template <- store$template
      output_type <- fct_template_output_type(template)

      # Get analysis dataset + apply population filter
      ds_name <- store$pipeline_filters$dataset %||% names(store$datasets)[1]
      datasets <- store$datasets

      # Apply pop filter to primary dataset (ADSL)
      pop_flag <- store$pipeline_filters$pop_flag
      if (!is.null(pop_flag) && nzchar(pop_flag)) {
        for (ds in c("adsl", ds_name)) {
          if (ds %in% names(datasets) && pop_flag %in% names(datasets[[ds]])) {
            datasets[[ds]] <- datasets[[ds]][datasets[[ds]][[pop_flag]] == "Y", ]
          }
        }
      }

      # Ensure trt_levels contains all actual levels (preserve user order)
      trt_var <- grp$trt_var
      adsl <- datasets[["adsl"]] %||% datasets[[ds_name]]
      if (!is.null(trt_var) && trt_var %in% names(adsl)) {
        actual <- sort(unique(adsl[[trt_var]]))
        current <- grp$trt_levels
        if (is.null(current) || !setequal(current, actual)) {
          # Only reset if the variable changed (new levels appeared/disappeared)
          grp$trt_levels <- actual
        }
      }

      # Snapshot grouping as plain list for dispatch functions
      grp_list <- reactiveValuesToList(grp)

      # Dispatch based on output type
      if (output_type == "table") {
        store$ard <- fct_ard_dispatch(template, datasets, grp_list, store$var_configs,
                                      added_levels = store$added_levels,
                                      combined_groups = grp_list$combined_groups,
                                      var_labels = store$var_labels)
        store$raw_ard <- attr(store$ard, "raw_ard")
        store$figure <- NULL
        store$listing <- NULL
      }
      # NOTE: figure and listing branches removed (demographics only)

      # Auto-populate format defaults for hierarchical templates
      if (get_sidebar_pattern(template) == "hierarchical" && !is.null(store$ard)) {
        ard_cols <- names(store$ard)
        # fr_wide_ard: soc = L1 group, pt = deepest level (last meta col before row_type)
        if ("soc" %in% ard_cols) store$fmt$rows$group_by <- "soc"
        # Find the deepest hierarchy column (last non-data column before row_type)
        meta_cols <- setdiff(ard_cols, c(grp_list$trt_levels,
          grp_list$total_label %||% "Total", "row_type"))
        if (length(meta_cols) > 0) {
          deepest <- meta_cols[length(meta_cols)]
          store$fmt$rows$indent_by <- deepest
          store$fmt$cols$stub_col <- deepest
        }
      }

      # Compute N counts for column headers (reuse same logic as N Counts display)
      if (output_type == "table" && !is.null(trt_var) && !is.null(adsl) && trt_var %in% names(adsl)) {
        trt_lvls <- grp_list$trt_levels %||% sort(unique(adsl[[trt_var]]))
        counts <- table(adsl[[trt_var]])
        n_vec <- vapply(trt_lvls, function(lv) {
          n <- as.integer(counts[lv])
          if (is.na(n)) 0L else n
        }, integer(1))
        names(n_vec) <- trt_lvls
        if (isTRUE(grp_list$include_total)) {
          total_label <- grp_list$total_label %||% "Total"
          n_vec <- c(n_vec, stats::setNames(nrow(adsl), total_label))
        }
        # Combined groups
        for (cg in grp_list$combined_groups) {
          if (!is.null(cg$label) && length(cg$arms) > 0) {
            cg_n <- sum(adsl[[trt_var]] %in% cg$arms)
            n_vec <- c(n_vec, stats::setNames(as.integer(cg_n), cg$label))
          }
        }
        store$fmt$cols$n_values <- n_vec
      }

      # Generate code
      data_cfg <- list(
        dataset = ds_name,
        paths = stats::setNames(
          lapply(names(datasets), function(d) paste0("data/", d, ".rds")),
          names(datasets)
        ),
        pop_flag = pop_flag
      )
      # Merge custom labels into var_configs for codegen
      vc <- store$var_configs
      for (vn in names(store$var_labels)) {
        if (!is.null(vc[[vn]]) && nzchar(store$var_labels[[vn]])) {
          vc[[vn]]$label <- store$var_labels[[vn]]
        }
      }
      store$code <- fct_codegen_dispatch(template, data_cfg, grp_list, vc, store$fmt)

      # Update pipeline state
      store$pipeline_state$analysis <- TRUE
      store$pipeline_state$format <- TRUE
      store$pipeline_state$output <- TRUE
      store$show_saved_grid <- FALSE

      session$sendCustomMessage("ar_toast",
        list(message = "Preview generated", type = "success"))
      # No auto-navigation — user moves to Format/Output when ready
    }, error = function(e) {
      session$sendCustomMessage("ar_toast",
        list(message = paste("Error:", e$message), type = "error"))
    })
  })

  # ── 5. Pipeline State Tracking ──
  shiny::observe({
    state <- list(
      data = length(store$datasets) > 0,
      template = !is.null(store$template),
      analysis = length(grp$analysis_vars) > 0,
      format = !is.null(store$ard),
      output = !is.null(store$ard)
    )
    session$sendCustomMessage("ar_pipeline_update", state)
  })

  # ── 5b. Accordion Status Dots ──
  shiny::observe({
    has_data <- length(store$datasets) > 0
    has_template <- !is.null(store$template)
    has_trt <- !is.null(grp$trt_var) && nzchar(grp$trt_var %||% "")
    has_vars <- length(grp$analysis_vars) > 0
    has_ard <- !is.null(store$ard)

    dots <- list(
      # Data panel
      datasets = if (has_data) "done" else "",
      summary = if (has_data) "done" else "",
      # Template panel
      template_info = if (has_template) "done" else "",
      data_source = if (has_data) "done" else "",
      variables = if (has_vars) "done" else if (has_template) "active" else "",
      # Analysis panel
      treatment = if (has_trt) "done" else if (has_data) "active" else "",
      statistics = if (has_vars) "done" else if (has_trt) "active" else ""
    )
    acc_map <- list(
      datasets = "DATASETS", summary = "SUMMARY", col_explorer = "COLUMN EXPLORER",
      filters = "FILTERS", template_info = "TEMPLATE INFO", data_source = "DATA SOURCE",
      variables = "VARIABLES", treatment = "TREATMENT", statistics = "STATISTICS"
    )
    session$sendCustomMessage("ar_acc_dots", list(dots = dots, map = acc_map))
  })

  # ── 6. Context Summary Line ──
  output$context_line <- shiny::renderUI({
    # Show the template's primary dataset (ADAE for AE templates, ADSL for demographics)
    tmpl <- store$template %||% "No template"
    tmpl_ds <- if (!is.null(store$template)) fct_template_var_dataset(store$template) else NULL
    ds_name <- tmpl_ds %||% store$active_ds %||% "No data"
    tmpl_def <- get_template_def(tmpl)
    tmpl_label <- if (!is.null(tmpl_def)) tmpl_def$name else tmpl

    n_val <- NULL
    pop <- store$pipeline_filters$pop_flag
    if (length(store$datasets) > 0) {
      ds_n <- store$datasets[[store$pipeline_filters$dataset %||% names(store$datasets)[1]]]
      if (!is.null(ds_n)) {
        ds_n <- apply_pop_filter(ds_n, pop)
        n_val <- nrow(ds_n)
      }
    }
    n_text <- if (!is.null(n_val)) {
      pop_label <- if (!is.null(pop) && nzchar(pop)) paste0(" (", pop, "=Y)") else ""
      paste0("N=", n_val, pop_label)
    } else "N=?"

    n_vars <- length(grp$analysis_vars)
    orient <- store$fmt$page$orientation %||% "landscape"

    sep <- htmltools::tags$span(class = "ar-context-line__sep", "|")

    htmltools::tagList(
      htmltools::tags$span(class = "ar-context-line__value", toupper(ds_name)), sep,
      htmltools::tags$span(class = "ar-context-line__value", tmpl_label), sep,
      htmltools::tags$span(class = "ar-context-line__value", n_text), sep,
      htmltools::tags$span(class = "ar-context-line__value", paste0(n_vars, " vars")), sep,
      htmltools::tags$span(class = "ar-context-line__value",
                           tools::toTitleCase(orient))
    )
  })

  # ── 8. Code Display Outputs (non-module, simple pre/code) ──
  render_code_display <- function() {
    shiny::renderUI({
      code <- store$code
      if (is.null(code) || !nzchar(code)) {
        # Contextual hint based on pipeline state
        hint <- if (length(store$datasets) == 0) {
          "Load an ADaM dataset in the Data tab first"
        } else if (is.null(store$template)) {
          "Select a template to define your table structure"
        } else if (length(grp$analysis_vars) == 0) {
          "Choose analysis variables, then press Ctrl+Enter"
        } else {
          "Press Ctrl+Enter to generate"
        }
        return(ui_empty_state("R script will appear here",
          desc = hint,
          icon = "fa-code"))
      }
      htmltools::tags$div(class = "ar-code-wrap",
        htmltools::tags$div(class = "ar-code-toolbar",
          htmltools::tags$button(
            class = "ar-btn-ghost ar-btn--xs ar-code-copy",
            onclick = "var c=this.closest('.ar-code-wrap').querySelector('code').textContent;navigator.clipboard.writeText(c).then(function(){var b=event.target.closest('.ar-code-copy');b.textContent='Copied!';setTimeout(function(){b.innerHTML='<i class=\"fa fa-copy\"></i> Copy';},1500);})",
            htmltools::tags$i(class = "fa fa-copy"),
            "Copy"
          )
        ),
        htmltools::tags$pre(
          class = "ar-code-display",
          htmltools::tags$code(class = "language-r", code)
        ),
        # Trigger highlight.js
        htmltools::tags$script(htmltools::HTML(
          "if(window.hljs){document.querySelectorAll('.ar-code-display code.language-r').forEach(function(el){hljs.highlightElement(el);});}"
        ))
      )
    })
  }

  output$code_display_analysis <- render_code_display()
  output$code_display_fmt <- render_code_display()
  output$code_display_out <- render_code_display()

  # ── 10. Preview Display Outputs (table, figure, listing) ──
  # Shared reactive computes the preview UI once; both outputs read from it.

  preview_ui <- shiny::reactive({
    output_type <- if (!is.null(store$template)) fct_template_output_type(store$template) else "table"

    if (output_type == "figure" && !is.null(store$figure)) {
      return(htmltools::tags$div(
        class = "ar-preview",
        shiny::plotOutput("figure_preview_plot", height = "500px")
      ))
    }

    if (output_type == "listing" && !is.null(store$listing)) {
      return(htmltools::tags$div(
        class = "ar-preview",
        reactable::reactableOutput("listing_preview_table")
      ))
    }

    ard <- store$ard
    fmt <- store$fmt
    if (is.null(ard)) {
      # Contextual empty state with CTA
      if (length(store$datasets) == 0) {
        return(ui_empty_state(
          "Load data to get started",
          "Upload an ADaM dataset (ADSL) to begin building your table.",
          "fa-database",
          cta = htmltools::tags$button(
            class = "ar-btn-primary",
            onclick = "document.getElementById('ab_data').click();",
            "Open Data Tab"
          )
        ))
      }
      if (is.null(store$template)) {
        return(ui_empty_state(
          "Select a template",
          "Choose a table template to define the output structure.",
          "fa-th-list",
          cta = htmltools::tags$button(
            class = "ar-btn-primary",
            onclick = "document.getElementById('ab_template').click();",
            "Browse Templates"
          )
        ))
      }
      if (length(grp$analysis_vars) == 0) {
        return(ui_empty_state(
          "Configure analysis variables",
          "Select the variables to include in your demographics table.",
          "fa-chart-bar",
          cta = htmltools::tags$button(
            class = "ar-btn-primary",
            onclick = "document.getElementById('ab_analysis').click();",
            "Open Analysis"
          )
        ))
      }
      return(ui_empty_state(
        "Ready to generate",
        "Your table is configured. Press Ctrl+Enter or click the button below.",
        "fa-play",
        cta = htmltools::tags$button(
          class = "ar-btn-primary",
          onclick = "document.getElementById('preview_btn').click();",
          htmltools::tags$i(class = "fa fa-play ar-icon-sm ar-icon-mr"),
          "Generate Preview"
        )
      ))
    }

    # arframe native HTML preview in full-screen scrollable iframe
    tryCatch({
      html_string <- fct_render_html_preview(ard, fmt)
      htmltools::tags$iframe(
        srcdoc = html_string,
        class = "ar-preview-frame",
        scrolling = "yes"
      )
    }, error = function(e) {
      ui_empty_state(
        "Preview error",
        e$message,
        "fa-exclamation-triangle"
      )
    })
  })

  output$preview_display_fmt <- shiny::renderUI({ preview_ui() })
  output$preview_display_out <- shiny::renderUI({ preview_ui() })

  # Figure plot output
  output$figure_preview_plot <- shiny::renderPlot({
    req(store$figure)
    store$figure
  })

  # Listing reactable output
  output$listing_preview_table <- reactable::renderReactable({
    req(store$listing)
    reactable::reactable(
      store$listing,
      theme = ar_grid_theme(),
      pagination = TRUE, defaultPageSize = 25,
      sortable = TRUE, searchable = TRUE, striped = TRUE,
      compact = TRUE
    )
  })

  # ── 11. Sidebar Hint ──
  output$sidebar_hint <- shiny::renderUI({
    if (length(store$datasets) == 0) {
      return(htmltools::tags$span("Load data to get started"))
    }
    if (is.null(store$template)) {
      return(htmltools::tags$span("Select a table template"))
    }
    if (length(grp$analysis_vars) == 0) {
      return(htmltools::tags$span("Select analysis variables"))
    }
    if (is.null(store$ard)) {
      return(htmltools::tags$span("Press Ctrl+Enter to generate preview"))
    }
    htmltools::tags$span("Ready to export")
  })

  # ── 12. Export Handlers ──
  export_filename <- function(fmt = NULL) {
    tmpl <- store$template %||% "table"
    out_fmt <- fmt %||% store$fmt$output_format %||% "rtf"
    ext <- switch(out_fmt, pdf = ".pdf", html = ".html", ".rtf")
    paste0("t_", tmpl, "_", format(Sys.time(), "%Y%m%dT%H%M%S"), ext)
  }

  export_content <- function(file, fmt = NULL) {
    if (is.null(store$ard)) {
      writeLines("Generate preview first (Ctrl+Enter)", file)
      return()
    }
    out_fmt <- fmt %||% store$fmt$output_format %||% "rtf"
    spec <- fct_build_spec(store$ard, store$fmt)
    arframe::fr_render(spec, file)
  }

  script_filename <- function() {
    tmpl <- store$template %||% "table"
    paste0("t_", tmpl, ".R")
  }
  script_content <- function(file) {
    if (is.null(store$code)) {
      writeLines("# Generate preview first (Ctrl+Enter)", file)
      return()
    }
    writeLines(store$code, file)
  }

  # Top bar buttons — use current output_format
  output$export_rtf <- shiny::downloadHandler(
    filename = export_filename,
    content = function(file) {
      export_content(file)
      session$sendCustomMessage("ar_toast",
        list(message = "Export complete", type = "success"))
    }
  )
  output$dl_script <- shiny::downloadHandler(
    filename = script_filename, content = script_content)

  # Sidebar buttons — format-specific
  output$export_rtf_side <- shiny::downloadHandler(
    filename = function() export_filename("rtf"),
    content = function(file) export_content(file, "rtf"))
  output$export_pdf_side <- shiny::downloadHandler(
    filename = function() export_filename("pdf"),
    content = function(file) export_content(file, "pdf"))
  output$export_html_side <- shiny::downloadHandler(
    filename = function() export_filename("html"),
    content = function(file) export_content(file, "html"))
  output$dl_script_side <- shiny::downloadHandler(
    filename = script_filename, content = script_content)

  # ── 13. Save/Load Workflow ──
  # Logic extracted to fct_save_workflow.R; observers stay here (non-namespaced inputs).

  # Mark dirty on ARD/fmt changes
  shiny::observeEvent(store$ard, { store$dirty <- TRUE }, ignoreInit = TRUE)

  # ── Startup: load prefs or show folder setup ──
  startup_done <- shiny::reactiveVal(FALSE)
  shiny::observe({
    if (startup_done()) return()
    startup_done(TRUE)
    load_startup_prefs(store)
  })

  # Show folder setup modal on first click if no prefs
  shiny::observeEvent(input$change_output_dir, {
    shiny::showModal(shiny::modalDialog(
      title = "Output Directory",
      htmltools::tags$p(class = "ar-text-sm",
        "Choose where arbuilder saves your outputs (config.yaml, ard.parquet, script.R)."
      ),
      shiny::textInput("new_output_dir", "Directory Path",
        value = store$output_dir %||% file.path(getwd(), ".local", "output"),
        width = "100%",
        placeholder = "/path/to/your/outputs"),
      footer = htmltools::tagList(
        shiny::modalButton("Cancel"),
        shiny::actionButton("confirm_output_dir", "Set Directory",
          class = "btn-primary")
      ),
      easyClose = TRUE
    ))
  })

  shiny::observeEvent(input$confirm_output_dir, {
    shiny::removeModal()
    new_dir <- trimws(input$new_output_dir)
    if (!nzchar(new_dir)) return()

    if (!dir.exists(new_dir)) {
      tryCatch(
        dir.create(new_dir, recursive = TRUE),
        error = function(e) {
          session$sendCustomMessage("ar_toast",
            list(message = paste0("Cannot create: ", e$message), type = "error"))
          return()
        }
      )
    }

    store$output_dir <- new_dir
    dir.create(".local", showWarnings = FALSE)
    tryCatch(
      yaml::write_yaml(list(output_dir = new_dir), file.path(getwd(), ".local", "arbuilder_prefs.yaml")),
      error = function(e) NULL
    )

    store$saved_outputs <- scan_outputs(new_dir)
    session$sendCustomMessage("ar_toast",
      list(message = paste0("Output directory: ", new_dir), type = "success"))
  })

  # Topbar output name + dirty indicator
  output$output_name_display <- shiny::renderUI({
    name <- store$current_output_id %||% "Untitled"
    dirty <- isTRUE(store$dirty)
    htmltools::tags$span(
      class = "ar-topbar__output-name",
      name,
      if (dirty) htmltools::tags$span(class = "ar-dirty-dot")
    )
  })

  # Saved outputs overlay — delegates to render_saved_grid()
  output$saved_grid_overlay <- shiny::renderUI({
    render_saved_grid(store)
  })

  # Close saved grid
  shiny::observeEvent(input$close_saved_grid, {
    store$show_saved_grid <- FALSE
  })

  # Save button — delegates to save_current_output()
  shiny::observeEvent(input$save_output_btn, {
    tryCatch({
      result <- save_current_output(store, grp)
      msg_type <- if (result$success) "success" else "error"
      if (!result$success && is.null(store$ard)) msg_type <- "warning"
      session$sendCustomMessage("ar_toast",
        list(message = result$message, type = msg_type))
    }, error = function(e) {
      session$sendCustomMessage("ar_toast",
        list(message = paste0("Save error: ", e$message), type = "error"))
    })
  })

  # Load output — delegates to load_saved_output()
  shiny::observeEvent(input$load_output, {
    tryCatch({
      result <- load_saved_output(input$load_output, store, grp)
      session$sendCustomMessage("ar_toast",
        list(message = result$message, type = "success"))
    }, error = function(e) {
      session$sendCustomMessage("ar_toast",
        list(message = paste0("Load failed: ", e$message), type = "error"))
    })
  })

  # Open saved outputs grid
  shiny::observeEvent(input$open_outputs_btn, {
    store$show_saved_grid <- TRUE
    if (!is.null(store$output_dir) && dir.exists(store$output_dir))
      store$saved_outputs <- scan_outputs(store$output_dir)
  })

  # New Output — delegates to reset_for_new_output()
  shiny::observeEvent(input$new_output_btn, {
    reset_for_new_output(store, grp)
    session$sendCustomMessage("ar_toast",
      list(message = "Ready for new output", type = "info"))
  })

  # Delete output
  shiny::observeEvent(input$delete_output, {
    dir_path <- input$delete_output
    table_id <- basename(dir_path)

    if (delete_output(dir_path)) {
      if (identical(store$current_output_dir, dir_path)) {
        store$current_output_id <- NULL
        store$current_output_dir <- NULL
      }
      if (!is.null(store$output_dir))
        store$saved_outputs <- scan_outputs(store$output_dir)
      session$sendCustomMessage("ar_toast",
        list(message = paste0("Deleted: ", table_id), type = "info"))
    } else {
      session$sendCustomMessage("ar_toast",
        list(message = "Delete failed", type = "error"))
    }
  })
}
