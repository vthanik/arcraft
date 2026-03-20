# Module: Grouping — Treatment variable (mod_grouping_ui) + Rich variable list (mod_grouping_vars_ui)

# ── Treatment config UI (Analysis sidebar) ──
mod_grouping_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Treatment variable
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Treatment Variable"),
      shiny::selectInput(ns("trt_var"), NULL, choices = NULL, width = "100%")
    ),

    # Include Total
    shiny::checkboxInput(ns("include_total"), "Include Total column", value = TRUE),

    # Treatment levels display
    shiny::uiOutput(ns("trt_levels_display"))
  )
}

# ── Rich expandable variable list UI (Template sidebar) ──
mod_grouping_vars_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Variable list container (dynamic)
    shiny::uiOutput(ns("var_list")),
    # Static selectize + reset (never destroyed/recreated, avoids auto-add bug)
    htmltools::tags$div(class = "ar-mt-8",
      htmltools::tags$label(class = "ar-form-label", "Add Variable"),
      shiny::selectizeInput(ns("add_extra_var"), NULL,
        choices = NULL, selected = NULL, width = "100%",
        options = list(placeholder = "Select column to add...")
      ),
      htmltools::tags$div(class = "ar-mt-8",
        htmltools::tags$button(
          class = "ar-btn-ghost",
          onclick = paste0("Shiny.setInputValue('", ns("reset_vars"),
                           "', Math.random(), {priority: 'event'})"),
          htmltools::tags$i(class = "fa fa-undo ar-icon-md ar-icon-mr"),
          "Reset Variables"
        )
      )
    )
  )
}

mod_grouping_server <- function(id, store, grp) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive trigger to force var_list re-render
    var_list_trigger <- shiny::reactiveVal(0L)

    # ══════════════════════════════════════
    # UPDATE ADD-VARIABLE SELECTIZE CHOICES
    # ══════════════════════════════════════
    shiny::observe({
      req(store$datasets)
      # Re-run when var list changes
      var_list_trigger()
      ds_name <- store$pipeline_filters$dataset %||% names(store$datasets)[1]
      req(ds_name, store$datasets[[ds_name]])
      d <- store$datasets[[ds_name]]

      tmpl <- store$template
      candidate_vars <- if (!is.null(tmpl)) {
        suggested <- fct_suggest_vars(tmpl, d)
        if (length(suggested) == 0) fct_detect_demog_vars(d) else suggested
      } else {
        fct_detect_demog_vars(d)
      }
      extra <- store$extra_vars %||% character(0)
      candidate_vars <- unique(c(candidate_vars, extra[extra %in% names(d)]))
      available_cols <- setdiff(names(d), candidate_vars)

      shiny::updateSelectizeInput(session, "add_extra_var",
        choices = available_cols, selected = character(0))
    })

    # ══════════════════════════════════════
    # TREATMENT CONFIG
    # ══════════════════════════════════════

    # Auto-detect treatment vars from data
    shiny::observe({
      req(store$datasets)
      ds_name <- names(store$datasets)[1]
      req(ds_name)
      d <- store$datasets[[ds_name]]
      trt_vars <- fct_detect_trt_vars(names(d))
      current <- grp$trt_var
      sel <- if (!is.null(current) && current %in% trt_vars) current else trt_vars[1]
      shiny::updateSelectInput(session, "trt_var", choices = trt_vars, selected = sel)
    })

    # When treatment var changes, update levels
    shiny::observeEvent(input$trt_var, {
      req(input$trt_var, store$datasets)
      ds_name <- names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      if (input$trt_var %in% names(d)) {
        lvls <- sort(unique(d[[input$trt_var]]))
        grp$trt_var <- input$trt_var
        grp$trt_levels <- lvls
      }
    })

    shiny::observeEvent(input$include_total, {
      grp$include_total <- input$include_total
    })

    # Display treatment levels with counts
    output$trt_levels_display <- shiny::renderUI({
      req(grp$trt_var, store$datasets)
      ds_name <- names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      trt_var <- grp$trt_var

      # Apply pop filter if available
      pop <- store$pipeline_filters$pop_flag
      if (!is.null(pop) && nzchar(pop) && pop %in% names(d)) {
        d <- d[d[[pop]] == "Y", ]
      }

      counts <- table(d[[trt_var]])
      lvls <- sort(unique(d[[trt_var]]))

      htmltools::tags$div(class = "ar-flex-col ar-gap-4 ar-mb-8",
        lapply(lvls, function(lv) {
          n <- as.integer(counts[lv])
          htmltools::tags$div(class = "ar-flex ar-items-center ar-gap-8",
            htmltools::tags$span(class = "ar-text-sm ar-text-secondary", lv),
            htmltools::tags$span(class = "ar-text-sm ar-text-muted ar-ml-auto",
                                 paste0("N=", n))
          )
        }),
        if (isTRUE(input$include_total)) {
          htmltools::tags$div(class = "ar-flex ar-items-center ar-gap-8 ar-trt-divider",
            htmltools::tags$span(class = "ar-text-sm ar-text-bold", "Total"),
            htmltools::tags$span(class = "ar-text-sm ar-text-muted ar-ml-auto",
                                 paste0("N=", nrow(d)))
          )
        }
      )
    })

    # ══════════════════════════════════════
    # RICH VARIABLE LIST (Template sidebar)
    # ══════════════════════════════════════

    # Render expandable variable list with inline mini-stats
    output$var_list <- shiny::renderUI({
      # Read trigger to force re-render when extra vars change
      var_list_trigger()
      req(store$datasets)
      ds_name <- store$pipeline_filters$dataset %||% names(store$datasets)[1]
      req(ds_name, store$datasets[[ds_name]])
      d <- store$datasets[[ds_name]]

      # Apply pop filter for accurate counts
      pop <- store$pipeline_filters$pop_flag
      if (!is.null(pop) && nzchar(pop) && pop %in% names(d)) {
        d <- d[d[[pop]] == "Y", ]
      }

      # Detect if BDS dataset (has PARAMCD)
      is_bds <- "PARAMCD" %in% names(d)

      if (is_bds) {
        return(render_bds_params(d, ns, store, grp))
      }

      # Template-aware variable suggestions
      tmpl <- store$template
      candidate_vars <- if (!is.null(tmpl)) {
        suggested <- fct_suggest_vars(tmpl, d)
        if (length(suggested) == 0) fct_detect_demog_vars(d) else suggested
      } else {
        fct_detect_demog_vars(d)
      }

      if (length(candidate_vars) == 0) {
        return(htmltools::tags$div(class = "ar-text-sm ar-text-muted",
          "No candidate variables detected"))
      }

      selected <- grp$analysis_vars %||% candidate_vars

      # Merge in extra vars
      extra <- store$extra_vars %||% character(0)
      extra <- extra[extra %in% names(d) & !extra %in% candidate_vars]
      candidate_vars <- unique(c(candidate_vars, extra))

      # Build simple one-liner variable rows (no expand/collapse — config lives in Analysis)
      var_rows <- lapply(candidate_vars, function(v) {
        vtype <- fct_detect_var_type(d, v)
        label_text <- store$var_labels[[v]] %||% fct_get_var_label(d, v)
        checked <- v %in% selected
        badge_type <- if (vtype == "continuous") "NUM" else if (vtype == "date") "DATE" else "CHR"

        # Configured-stats summary (read from store$var_configs)
        cfg <- store$var_configs[[v]]
        mini_stat <- if (!is.null(cfg)) {
          if (cfg$type == "continuous") {
            stats_sel <- cfg$stats %||% c("n", "mean_sd", "median", "q1_q3", "min_max")
            stat_names <- vapply(stats_sel, function(s) {
              switch(s, n = "N", mean = "Mean", sd = "SD", mean_sd = "Mean(SD)",
                median = "Med", q1 = "Q1", q3 = "Q3", q1_q3 = "Q1/Q3",
                min = "Min", max = "Max", min_max = "Min/Max",
                geo_mean = "GeoM", cv = "CV%", geo_mean_cv = "GeoM(CV%)", s)
            }, character(1))
            paste(stat_names, collapse = ",")
          } else {
            fmt_label <- switch(cfg$cat_format %||% "npct",
              npct = "n(%)", n = "n", nn_pct = "n/N(%)", "n(%)")
            n_lvl <- length(cfg$levels %||% character(0))
            paste0(fmt_label, ", ", n_lvl, " lvl")
          }
        } else {
          "not configured"
        }

        htmltools::tags$div(
          class = "ar-varlist-row",
          htmltools::tags$div(class = "ar-varlist-row__header",
            htmltools::tags$input(
              type = "checkbox",
              id = ns(paste0("avar_", v)),
              checked = if (checked) "checked" else NULL,
              onchange = paste0(
                "var checked = document.querySelectorAll('input[id^=\"", ns("avar_"), "\"]:checked');",
                "var vals = Array.from(checked).map(function(c) { return c.id.replace('", ns("avar_"), "', ''); });",
                "Shiny.setInputValue('", ns("analysis_vars"), "', vals);"
              ),
              class = "ar-accent-check"
            ),
            htmltools::tags$span(class = "ar-varlist-row__name", v),
            ui_type_badge(badge_type),
            htmltools::tags$span(class = "ar-varlist-row__label", label_text),
            htmltools::tags$span(class = paste0("ar-varlist-row__mini",
              if (is.null(cfg)) " ar-text-italic" else ""),
              mini_stat),
            if (v %in% (store$extra_vars %||% character(0))) {
              htmltools::tags$button(
                class = "ar-btn-icon--xs",
                title = "Remove variable",
                onclick = paste0(
                  "Shiny.setInputValue('", ns("remove_extra_var"),
                  "', '", v, "', {priority: 'event'})"
                ),
                htmltools::HTML("&times;")
              )
            }
          )
        )
      })

      htmltools::tags$div(class = "ar-varlist", var_rows)
    })

    # Handle analysis vars change
    shiny::observeEvent(input$analysis_vars, {
      grp$analysis_vars <- input$analysis_vars
      store$pipeline_state$analysis <- length(input$analysis_vars) > 0
      if (length(input$analysis_vars) > 0) {
      }
    }, ignoreNULL = FALSE)

    # Handle add extra variable
    shiny::observeEvent(input$add_extra_var, ignoreInit = TRUE, {
      req(input$add_extra_var, nzchar(input$add_extra_var))
      v <- input$add_extra_var
      current <- store$extra_vars %||% character(0)
      if (!v %in% current) {
        store$extra_vars <- c(current, v)
        # Also auto-select it for analysis
        avars <- grp$analysis_vars %||% character(0)
        if (!v %in% avars) {
          grp$analysis_vars <- c(avars, v)
        }
        # Bump trigger to force re-render
        var_list_trigger(var_list_trigger() + 1L)
        session$sendCustomMessage("ar_toast",
          list(message = paste0("Added variable: ", v), type = "success"))
      }
      # Reset selectize
      shiny::updateSelectizeInput(session, "add_extra_var", selected = character(0))
    })

    # Handle remove extra variable
    shiny::observeEvent(input$remove_extra_var, {
      req(input$remove_extra_var)
      v <- input$remove_extra_var
      store$extra_vars <- setdiff(store$extra_vars %||% character(0), v)
      grp$analysis_vars <- setdiff(grp$analysis_vars %||% character(0), v)
      var_list_trigger(var_list_trigger() + 1L)
    })

    # Handle reset variables — restore to template spec defaults (not all candidates)
    shiny::observeEvent(input$reset_vars, {
      store$extra_vars <- character(0)
      store$added_levels <- list()
      store$var_labels <- list()

      tmpl <- store$template
      ds_name <- store$pipeline_filters$dataset %||% names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      if (!is.null(tmpl) && !is.null(d)) {
        # Use the spec function to get original selected vars (not fct_suggest_vars which returns ALL candidates)
        spec_fn <- switch(tmpl,
          demog = spec_demog,
          NULL
        )
        if (!is.null(spec_fn)) {
          defaults <- spec_fn(d)
          grp$analysis_vars <- defaults$grouping$analysis_vars
          store$var_configs <- defaults$var_configs
        } else {
          # Fallback: use detect for non-spec templates
          candidate_vars <- fct_suggest_vars(tmpl, d)
          if (length(candidate_vars) == 0) candidate_vars <- fct_detect_demog_vars(d)
          grp$analysis_vars <- candidate_vars
        }
      }
      var_list_trigger(var_list_trigger() + 1L)
      session$sendCustomMessage("ar_toast",
        list(message = "Variables reset to template defaults", type = "success"))
    })
  })
}

# ── Helper: Render BDS parameter picker ──
render_bds_params <- function(d, ns, store, grp) {
  params <- unique(d[, c("PARAMCD", "PARAM"), drop = FALSE])
  params <- params[order(params$PARAMCD), ]

  # Template-aware pre-selection
  tmpl <- store$template
  selected_params <- grp$analysis_vars %||% character(0)

  param_rows <- lapply(seq_len(nrow(params)), function(i) {
    pc <- params$PARAMCD[i]
    pl <- params$PARAM[i]
    user_label <- store$var_labels[[pc]]
    display_label <- if (!is.null(user_label)) user_label else pl
    checked <- pc %in% selected_params

    htmltools::tags$div(class = "ar-varlist-row",
      htmltools::tags$div(class = "ar-varlist-row__header",
        htmltools::tags$input(
          type = "checkbox",
          id = ns(paste0("avar_", pc)),
          checked = if (checked) "checked" else NULL,
          onchange = paste0(
            "var checked = document.querySelectorAll('input[id^=\"", ns("avar_"), "\"]:checked');",
            "var vals = Array.from(checked).map(function(c) { return c.id.replace('", ns("avar_"), "', ''); });",
            "Shiny.setInputValue('", ns("analysis_vars"), "', vals);"
          ),
          class = "ar-accent-check"
        ),
        htmltools::tags$span(class = "ar-varlist-row__name", pc),
        htmltools::tags$span(class = "ar-varlist-row__label", display_label)
      )
    )
  })

  htmltools::tags$div(class = "ar-varlist",
    htmltools::tags$div(class = "ar-varlist__header",
      htmltools::tags$span(class = "ar-form-label",
        paste0("PARAMETERS (from ", toupper(store$pipeline_filters$dataset %||% ""), ")")),
      htmltools::tags$span(class = "ar-text-sm ar-text-muted",
        paste0(nrow(params), " parameters available"))
    ),
    param_rows
  )
}
