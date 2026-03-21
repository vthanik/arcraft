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
    figure = NULL,
    listing = NULL,
    code = "",
    pipeline_state = list(
      data = FALSE, template = FALSE,
      analysis = FALSE, format = FALSE, output = FALSE
    )
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

  n_counts_server("n_counts", store, grp)
  mod_validation_server("validation", store, grp)
  mod_code_server("code", store)

  # ── 2a. Auto-Preview (debounced — triggers ONCE when config changes) ──
  # Uses a fingerprint to detect real changes vs reactive noise.
  # Only fires when the user actually changes something meaningful.
  auto_preview_fingerprint <- shiny::reactiveVal("")

  shiny::observe({
    # Build a fingerprint from key config values
    vars <- grp$analysis_vars
    trt <- grp$trt_var
    total <- grp$include_total
    tmpl <- store$template

    # Only watch when we have minimum requirements
    req(length(store$datasets) > 0, !is.null(tmpl), length(vars) > 0)

    fp <- paste(tmpl, trt, total, paste(vars, collapse = ","), sep = "|")
    old_fp <- shiny::isolate(auto_preview_fingerprint())

    if (nzchar(old_fp) && fp != old_fp) {
      # Config actually changed — trigger preview via JS after 800ms debounce
      auto_preview_fingerprint(fp)
      session$sendCustomMessage("ar_debounce_preview", list(delay = 800))
    } else if (!nzchar(old_fp)) {
      # First time — just record the fingerprint, don't trigger
      auto_preview_fingerprint(fp)
    }
  })

  # ── 2b. Preset Handlers ──
  shiny::observeEvent(input$fmt_preset_fda, {
    apply_fmt_preset(store, "fda")
  })
  shiny::observeEvent(input$fmt_preset_booktabs, {
    apply_fmt_preset(store, "booktabs")
  })
  shiny::observeEvent(input$fmt_preset_minimal, {
    apply_fmt_preset(store, "minimal")
  })
  shiny::observeEvent(input$fmt_preset_company, {
    apply_fmt_preset(store, "company")
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

    tryCatch({
      # Snapshot format drafts from all modules into store (non-reactive architecture)
      store$fmt <- collect_format_drafts(
        titles_draft(), cols_draft(), header_spans_draft(),
        rows_draft(), page_output_draft(), styles_draft()
      )

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
        store$figure <- NULL
        store$listing <- NULL
      }
      # NOTE: figure and listing branches removed (demographics only)

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

      session$sendCustomMessage("ar_toast",
        list(message = "Preview generated", type = "success"))
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
    ds_name <- store$active_ds %||% "No data"
    tmpl <- store$template %||% "No template"
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
}
