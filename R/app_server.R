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
    fmt = list(
      # Section 1: Titles & Footnotes
      titles = list(), footnotes = list(), population = "", source = "",
      title_defaults = list(align = "center", bold = FALSE),
      fn_separator = FALSE, fn_placement = "every",
      # Section 2: Columns
      cols = list(width_mode = "auto", default_align = "center",
                  spaces = "indent", split = FALSE,
                  n_counts = TRUE, n_format = "(N={n})",
                  stub_width = 2.5, per_col = list()),
      # Section 3: Page Layout
      page = list(orientation = "landscape", paper = "letter",
                  font_family = "Courier New", font_size = 9,
                  margins = c(1, 1, 1, 1), col_gap = 4,
                  continuation = "", orphan_min = 3L, widow_min = 3L),
      # Section 4: Rules
      rules = list(hline_preset = "header", vline_preset = "none",
                   line_width = "thin", line_color = "#000000", line_style = "solid"),
      # Section 5: Header & Spans
      header = list(bold = TRUE, align = "center", valign = "bottom", bg = NULL, fg = NULL),
      spans = list(),
      # Section 6: Rows & Pagination
      rows = list(group_by = NULL, blank_after = NULL, page_by = NULL,
                  page_by_bold = FALSE, indent_by = NULL,
                  repeat_cols = NULL, wrap = FALSE),
      # Section 7: Page Chrome
      pagehead = list(left = "", center = "", right = ""),
      pagefoot = list(left = "", center = "", right = ""),
      spacing = list(titles_after = 1L, footnotes_before = 1L,
                     pagehead_after = 0L, pagefoot_before = 0L)
    ),
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
  page_draft <- mod_page_server("page", store)
  rules_draft <- mod_rules_server("rules", store)
  header_spans_draft <- mod_header_spans_server("header_spans", store)
  rows_draft <- mod_rows_server("rows", store)
  chrome_draft <- mod_page_chrome_server("page_chrome", store)

  mod_validation_server("validation", store)
  mod_preview_server("preview", store)
  mod_code_server("code", store)

  # ── 2a. Preset Handlers ──
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
      return(htmltools::tags$div(class = "ar-text-sm ar-text-muted",
        style = "padding: 4px 0;",
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
    req(store$datasets)
    ds_name <- store$pipeline_filters$dataset %||% names(store$datasets)[1]
    d <- store$datasets[[ds_name]]
    req(d)
    pop <- store$pipeline_filters$pop_flag
    if (!is.null(pop) && nzchar(pop) && pop %in% names(d)) {
      d <- d[d[[pop]] == "Y", ]
    }
    n <- nrow(d)
    pop_label <- if (!is.null(pop) && nzchar(pop)) paste0(" (", pop, " = Y)") else ""
    htmltools::tags$div(class = "ar-data-source-n",
      htmltools::tags$span(class = "ar-text-sm",
        style = "font-weight: 500; color: var(--fg-2);",
        paste0("N = ", n, " subjects", pop_label))
    )
  })

  # ── 2d. N Counts Display (canvas tab) ──
  output$n_counts_display <- shiny::renderUI({
    req(store$datasets)
    ds_name <- names(store$datasets)[1]
    req(ds_name)
    d <- store$datasets[[ds_name]]

    trt_var <- grp$trt_var
    if (is.null(trt_var) || !trt_var %in% names(d)) {
      return(htmltools::tags$div(class = "ar-empty-state",
        htmltools::tags$div(class = "ar-empty-state__icon", shiny::icon("users")),
        htmltools::tags$div(class = "ar-empty-state__text", "No Treatment Variable"),
        htmltools::tags$div(class = "ar-empty-state__hint",
          "Select a treatment variable in the sidebar to view N counts")
      ))
    }

    # Apply pop filter
    pop <- store$pipeline_filters$pop_flag
    if (!is.null(pop) && nzchar(pop) && pop %in% names(d)) {
      d <- d[d[[pop]] == "Y", ]
    }

    trt_lvls <- grp$trt_levels %||% sort(unique(d[[trt_var]]))
    counts <- table(d[[trt_var]])
    n_total <- nrow(d)
    include_total <- grp$include_total %||% TRUE
    total_label <- grp$total_label %||% "Total"

    # Treatment Arms table
    trt_rows <- lapply(trt_lvls, function(lv) {
      n <- as.integer(counts[lv])
      if (is.na(n)) n <- 0L
      pct <- sprintf("%.1f%%", 100 * n / n_total)
      htmltools::tags$tr(
        htmltools::tags$td(class = "ar-nc__cell", lv),
        htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", n),
        htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", pct)
      )
    })

    total_row <- if (isTRUE(include_total)) {
      htmltools::tags$tr(class = "ar-nc__total",
        htmltools::tags$td(class = "ar-nc__cell", total_label),
        htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", n_total),
        htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", "100.0%")
      )
    }

    trt_table <- htmltools::tags$div(class = "ar-n-counts__section",
      htmltools::tags$h4(class = "ar-n-counts__heading", "Treatment Arms"),
      htmltools::tags$table(class = "ar-nc__table",
        htmltools::tags$thead(
          htmltools::tags$tr(
            htmltools::tags$th(class = "ar-nc__th", "Arm"),
            htmltools::tags$th(class = "ar-nc__th ar-nc__th--num", "N"),
            htmltools::tags$th(class = "ar-nc__th ar-nc__th--num", "%")
          )
        ),
        htmltools::tags$tbody(trt_rows, total_row)
      )
    )

    # By Variable section (if selected)
    by_var <- grp$by_var
    by_section <- NULL
    if (!is.null(by_var) && nzchar(by_var) && by_var %in% names(d)) {
      by_lvls <- grp$by_levels %||% sort(unique(d[[by_var]]))

      by_blocks <- lapply(by_lvls, function(bv) {
        sub <- d[d[[by_var]] == bv, ]
        trt_counts <- table(sub[[trt_var]])
        n_by_total <- nrow(sub)

        rows <- lapply(trt_lvls, function(tv) {
          n <- as.integer(trt_counts[tv])
          if (is.na(n)) n <- 0L
          pct <- if (n_by_total > 0) sprintf("%.1f%%", 100 * n / n_by_total) else "0.0%"
          htmltools::tags$tr(
            htmltools::tags$td(class = "ar-nc__cell", tv),
            htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", n),
            htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", pct)
          )
        })

        t_row <- if (isTRUE(include_total)) {
          htmltools::tags$tr(class = "ar-nc__total",
            htmltools::tags$td(class = "ar-nc__cell", total_label),
            htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", n_by_total),
            htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", "100.0%")
          )
        }

        htmltools::tags$div(class = "ar-n-counts__by-block",
          htmltools::tags$h5(class = "ar-n-counts__by-label", bv),
          htmltools::tags$table(class = "ar-nc__table",
            htmltools::tags$thead(
              htmltools::tags$tr(
                htmltools::tags$th(class = "ar-nc__th", "Arm"),
                htmltools::tags$th(class = "ar-nc__th ar-nc__th--num", "N"),
                htmltools::tags$th(class = "ar-nc__th ar-nc__th--num", "%")
              )
            ),
            htmltools::tags$tbody(rows, t_row)
          )
        )
      })

      by_section <- htmltools::tags$div(class = "ar-n-counts__section",
        htmltools::tags$h4(class = "ar-n-counts__heading",
          paste0("By Variable: ", by_var)),
        htmltools::tagList(by_blocks)
      )
    }

    htmltools::tags$div(class = "ar-n-counts", trt_table, by_section)
  })

  # ── 2e. ARD Data Table (reactable) ──
  output$ard_data_table <- reactable::renderReactable({
    ard <- store$ard
    if (is.null(ard)) return(NULL)
    ar_build_reactable(ard)
  })

  # ARD empty state
  output$ard_empty_state <- shiny::renderUI({
    if (!is.null(store$ard)) return(NULL)
    htmltools::tags$div(class = "ar-empty-state",
      htmltools::tags$div(class = "ar-empty-state__icon", shiny::icon("play")),
      htmltools::tags$div(class = "ar-empty-state__text", "Generate Preview"),
      htmltools::tags$div(class = "ar-empty-state__hint",
        "Configure your analysis and click Generate Preview in the top bar")
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
    shinyjs::runjs(sprintf(
      "document.querySelectorAll('.ar-ab-btn').forEach(function(b){b.classList.remove('active')});
       document.getElementById('ab_%s').classList.add('active');",
      panel
    ))
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
        titles_draft(), cols_draft(), page_draft(), rules_draft(),
        header_spans_draft(), rows_draft(), chrome_draft()
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
      } else if (output_type == "figure") {
        fig_cfgs <- store$fig_configs
        if (length(fig_cfgs) == 0) {
          tmpl_def <- get_template_def(template)
          if (!is.null(tmpl_def)) {
            spec_fn <- get(tmpl_def$spec_fn, envir = globalenv())
            spec <- spec_fn()
            fig_cfgs <- spec$fig_configs %||% list()
          }
        }
        store$figure <- fct_figure_dispatch(template, datasets, grp_list, fig_cfgs)
        store$ard <- NULL
        store$listing <- NULL
      } else if (output_type == "listing") {
        listing_config <- store$var_configs
        listing_config$dataset <- ds_name
        store$listing <- fct_listing_dispatch(template, datasets, listing_config)
        store$ard <- NULL
        store$figure <- NULL
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
      store$code <- fct_codegen_dispatch(template, data_cfg, grp_list,
                                          store$var_configs, store$fmt)

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
        if (!is.null(pop) && nzchar(pop) && pop %in% names(ds_n))
          ds_n <- ds_n[ds_n[[pop]] == "Y", ]
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
        return(ui_empty_state("No code generated yet",
          desc = "Click Generate Preview to build the pipeline",
          icon = "fa-code"))
      }
      htmltools::tags$div(class = "ar-code-wrap",
        htmltools::tags$pre(
          class = "ar-code-display",
          htmltools::tags$code(code)
        )
      )
    })
  }

  output$code_display_analysis <- render_code_display()
  output$code_display_fmt <- render_code_display()
  output$code_display_out <- render_code_display()

  # ── 10. Preview Display Outputs (table, figure, listing) ──
  render_preview_display <- function() {
    shiny::renderUI({
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
      if (is.null(ard)) {
        return(ui_empty_state(
          "No preview available",
          "Configure your table and click Generate Preview (Ctrl+Enter).",
          "fa-table"
        ))
      }
      fct_build_preview_html(ard, store$fmt)
    })
  }

  output$preview_display_fmt <- render_preview_display()
  output$preview_display_out <- render_preview_display()

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
  export_filename <- function() {
    tmpl <- store$template %||% "table"
    output_type <- fct_template_output_type(tmpl)
    prefix <- switch(output_type, figure = "f_", listing = "l_", "t_")
    ext <- switch(output_type, figure = ".png", ".rtf")
    paste0(prefix, tmpl, "_", format(Sys.Date(), "%Y%m%d"), ext)
  }

  export_content <- function(file) {
    output_type <- fct_template_output_type(store$template)
    if (output_type == "figure") {
      req(store$figure)
      ggplot2::ggsave(file, store$figure, width = 10, height = 7, dpi = 300)
    } else if (output_type == "listing") {
      req(store$listing)
      fct_render_listing(store$listing, store$fmt, file)
    } else {
      req(store$ard)
      fct_render_rtf(store$ard, store$fmt, file)
    }
  }

  output$export_rtf <- shiny::downloadHandler(
    filename = export_filename,
    content = function(file) {
      export_content(file)
      session$sendCustomMessage("ar_toast",
        list(message = "Export complete", type = "success"))
    }
  )

  output$export_rtf_side <- shiny::downloadHandler(
    filename = export_filename,
    content = export_content
  )

  output$dl_script <- shiny::downloadHandler(
    filename = function() {
      tmpl <- store$template %||% "table"
      paste0("t_", tmpl, ".R")
    },
    content = function(file) {
      req(store$code)
      writeLines(store$code, file)
    }
  )

  output$dl_script_side <- shiny::downloadHandler(
    filename = function() {
      tmpl <- store$template %||% "table"
      paste0("t_", tmpl, ".R")
    },
    content = function(file) {
      req(store$code)
      writeLines(store$code, file)
    }
  )
}
