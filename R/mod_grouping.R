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
    # Variable list container (dynamic — switches based on sidebar_pattern)
    shiny::uiOutput(ns("var_list")),
    # Add Variable + Reset (only for column-name templates, hidden for BDS/response)
    shiny::uiOutput(ns("var_add_controls"))
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
      tmpl <- store$template
      # Use template-specific dataset (ADAE for AE templates, ADSL for demographics)
      var_ds <- fct_template_var_dataset(tmpl)
      ds_name <- if (var_ds %in% names(store$datasets)) var_ds
                 else store$pipeline_filters$dataset %||% names(store$datasets)[1]
      req(ds_name, store$datasets[[ds_name]])
      d <- store$datasets[[ds_name]]

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
      d <- apply_pop_filter(d, pop)

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
      tmpl <- store$template
      # Use template-specific dataset
      var_ds <- fct_template_var_dataset(tmpl)
      ds_name <- if (var_ds %in% names(store$datasets)) var_ds
                 else store$pipeline_filters$dataset %||% names(store$datasets)[1]
      req(ds_name, store$datasets[[ds_name]])
      d <- store$datasets[[ds_name]]

      # Apply pop filter for accurate counts
      pop <- store$pipeline_filters$pop_flag
      d <- apply_pop_filter(d, pop)

      # Detect if BDS dataset (has PARAMCD)
      is_bds <- "PARAMCD" %in% names(d)

      if (is_bds) {
        return(render_bds_params(d, ns, store, grp))
      }

      # Template-aware variable suggestions
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
          } else if (cfg$type %in% c("flag", "hierarchy")) {
            fmt_label <- switch(cfg$cat_format %||% "npct",
              npct = "n(%)", n = "n", nn_pct = "n/N(%)", "n(%)")
            paste0(fmt_label, ", ", cfg$label %||% v)
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
                "if(vals.length === 0){ this.checked = true; return; }",
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

    # Render Add Variable / Reset controls (hidden for BDS/response templates)
    output$var_add_controls <- shiny::renderUI({
      tmpl <- store$template
      if (fct_suggests_paramcds(tmpl)) return(NULL)

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
      # Use template-specific dataset for reset
      var_ds <- fct_template_var_dataset(tmpl)
      ds_name <- if (var_ds %in% names(store$datasets)) var_ds
                 else store$pipeline_filters$dataset %||% names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      if (!is.null(tmpl) && !is.null(d)) {
        # Look up spec function from registry
        tmpl_def <- get_template_def(tmpl)
        spec_fn <- if (!is.null(tmpl_def) && !is.null(tmpl_def$spec_fn)) {
          tryCatch(get(tmpl_def$spec_fn), error = function(e) NULL)
        }
        if (!is.null(spec_fn)) {
          defaults <- spec_fn(d)
          if (fct_suggests_paramcds(tmpl)) {
            grp$analysis_vars <- defaults$grouping$selected_params %||%
                                  defaults$grouping$analysis_vars
            store$param_configs <- defaults$param_configs %||% list()
            store$stat_config <- defaults$stat_config %||% list()
            store$visit_configs <- defaults$visit_configs %||% list()
          } else {
            grp$analysis_vars <- defaults$grouping$analysis_vars
            store$var_configs <- defaults$var_configs
          }
        } else {
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

# ── Helper: Render BDS parameter list (VARIABLES panel — params only) ──
render_bds_params <- function(d, ns, store, grp) {
  # Apply dataset filter to subset available parameters
  filter_expr <- store$pipeline_filters$data_filter
  if (!is.null(filter_expr) && nzchar(filter_expr)) {
    mask <- tryCatch(safe_eval_filter(filter_expr, d), error = function(e) NULL)
    if (is.logical(mask) && length(mask) == nrow(d)) {
      d <- d[mask, , drop = FALSE]
    }
  }

  # Extract unique PARAMCD/PARAM from (filtered) data
  if (!("PARAMCD" %in% names(d))) {
    return(htmltools::tags$div(class = "ar-text-sm ar-text-muted", "No PARAMCD column found"))
  }

  params_df <- unique(d[, intersect(c("PARAMCD", "PARAM"), names(d)), drop = FALSE])
  params_df <- params_df[!is.na(params_df[["PARAMCD"]]) & nzchar(params_df[["PARAMCD"]]), , drop = FALSE]
  if (nrow(params_df) == 0L) {
    return(htmltools::tags$div(class = "ar-text-sm ar-text-muted", "No parameters match the current filter"))
  }

  param_configs <- store$param_configs
  selected_params <- grp$analysis_vars %||% character(0)
  ds_label <- toupper(store$pipeline_filters$dataset %||% "")
  all_paramcds <- as.character(params_df[["PARAMCD"]])

  # Build parameter rows

  param_rows <- lapply(all_paramcds, function(pc) {
    cfg <- param_configs[[pc]]
    # PARAM label from data or config
    param_label <- if ("PARAM" %in% names(params_df)) {
      row_match <- params_df[params_df[["PARAMCD"]] == pc, , drop = FALSE]
      if (nrow(row_match) > 0L) as.character(row_match[["PARAM"]][1L]) else pc
    } else pc
    # User override
    user_label <- store$var_labels[[pc]]
    if (!is.null(user_label)) param_label <- user_label

    checked <- pc %in% selected_params

    htmltools::tags$div(
      class = "ar-param-row",
      `data-param` = pc,
      `data-label` = tolower(param_label),
      htmltools::tags$span(class = "ar-param-row__drag", "\u2630"),
      htmltools::tags$input(
        type = "checkbox",
        id = ns(paste0("avar_", pc)),
        checked = if (checked) "checked" else NULL,
        onchange = paste0(
          "var checked = document.querySelectorAll('input[id^=\"", ns("avar_"), "\"]:checked');",
          "var vals = Array.from(checked).map(function(c) { return c.id.replace('", ns("avar_"), "', ''); });",
          "if(vals.length === 0){ this.checked = true; return; }",
          "Shiny.setInputValue('", ns("analysis_vars"), "', vals);"
        ),
        class = "ar-accent-check"
      ),
      htmltools::tags$div(class = "ar-param-row__info",
        htmltools::tags$span(class = "ar-param-row__code", pc),
        htmltools::tags$span(class = "ar-param-row__label", param_label)
      )
    )
  })

  n_total <- length(all_paramcds)
  n_selected <- sum(all_paramcds %in% selected_params)
  show_search <- n_total > 10L

  htmltools::tags$div(class = "ar-varlist",
    htmltools::tags$div(class = "ar-varlist__header",
      htmltools::tags$span(class = "ar-form-label",
        paste0("PARAMETERS (", ds_label, ")")),
      htmltools::tags$span(class = "ar-text-sm ar-text-muted",
        paste0(n_selected, " / ", n_total, " selected"))
    ),
    # Search input for large param lists (lab 50+)
    if (show_search) {
      htmltools::tags$input(
        type = "text",
        class = "ar-input ar-param-search",
        placeholder = "Filter parameters...",
        oninput = paste0(
          "var q = this.value.toLowerCase();",
          "this.closest('.ar-varlist').querySelectorAll('.ar-param-row').forEach(function(r){",
          "  var pc = (r.getAttribute('data-param') || '').toLowerCase();",
          "  var lb = (r.getAttribute('data-label') || '').toLowerCase();",
          "  r.style.display = (pc.indexOf(q) >= 0 || lb.indexOf(q) >= 0) ? '' : 'none';",
          "});"
        )
      )
    },
    # Select All / Deselect All
    htmltools::tags$div(class = "ar-param-actions",
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn-ghost--xs",
        onclick = paste0(
          "document.querySelectorAll('input[id^=\"", ns("avar_"), "\"]').forEach(function(c){ c.checked = true; });",
          "var vals = Array.from(document.querySelectorAll('input[id^=\"", ns("avar_"), "\"]')).map(function(c){ return c.id.replace('", ns("avar_"), "', ''); });",
          "Shiny.setInputValue('", ns("analysis_vars"), "', vals);"
        ),
        "Select All"
      ),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn-ghost--xs",
        onclick = paste0(
          "var all = document.querySelectorAll('input[id^=\"", ns("avar_"), "\"]');",
          "all.forEach(function(c, i){ c.checked = (i === 0); });",
          "var first = all[0] ? [all[0].id.replace('", ns("avar_"), "', '')] : [];",
          "Shiny.setInputValue('", ns("analysis_vars"), "', first);"
        ),
        "Deselect All"
      )
    ),
    htmltools::tags$div(class = "ar-param-list", id = ns("param_sortable"), param_rows)
  )
}
