# Module: Treatment — Treatment + Group Variable + N Counts
#
# Clean foldable level lists for both treatment and group variable.
# N counts in a separate disclosure — view when needed, not cluttering levels.

mod_treatment_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Treatment variable
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Treatment"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("trt_var"), NULL, choices = NULL, width = "100%"))
      )
    ),

    # Treatment levels (foldable — clean: just drag dots + label)
    shiny::uiOutput(ns("trt_levels_ui")),

    # Include Total + label
    htmltools::tags$div(class = "ar-toggle-grid",
      htmltools::tags$div(class = "ar-toggle-grid__item",
        htmltools::tags$span(class = "ar-toggle-grid__label", "Total col"),
        shiny::radioButtons(ns("include_total"), NULL,
          choices = c("No" = "no", "Yes" = "yes"),
          selected = "yes", inline = TRUE)
      )
    ),
    # Include unassigned (dynamic)
    shiny::uiOutput(ns("unassigned_info")),

    # Group Variable
    htmltools::tags$div(class = "ar-section-divider"),
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Group Var"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("by_var"), NULL,
            choices = c("None" = ""), width = "100%"))
      )
    ),

    # Group variable levels (foldable — same style as treatment)
    shiny::uiOutput(ns("by_levels_ui")),

    # Denominator
    htmltools::tags$div(class = "ar-section-divider"),
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Denominator"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("denominator"), NULL,
            choices = c("Column N" = "col_n", "Row N" = "row_n",
                        "By-group N" = "bygroup_n"),
            selected = "col_n", width = "100%"))
      )
    )
  )
}

mod_treatment_server <- function(id, store, grp) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Auto-detect treatment/grouping variables ──
    shiny::observe({
      req(store$datasets)
      ds_name <- names(store$datasets)[1]
      req(ds_name)
      d <- store$datasets[[ds_name]]
      groups <- fct_detect_grouping_vars(d)
      groups <- groups[vapply(groups, length, integer(1)) > 0]
      trt_vars <- unlist(groups, use.names = FALSE)
      choices <- lapply(groups, function(vars) stats::setNames(vars, vars))
      current <- grp$trt_var
      sel <- if (!is.null(current) && current %in% trt_vars) current else trt_vars[1]
      shiny::updateSelectInput(session, "trt_var", choices = choices, selected = sel)
    })

    # ── When treatment var changes, update levels ──
    shiny::observeEvent(input$trt_var, {
      req(input$trt_var, store$datasets)
      ds_name <- names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      if (input$trt_var %in% names(d)) {
        new_lvls <- sort(unique(d[[input$trt_var]]))
        prev_var <- grp$trt_var
        grp$trt_var <- input$trt_var
        if (is.null(prev_var) || prev_var != input$trt_var ||
            !setequal(grp$trt_levels %||% character(0), new_lvls)) {
          grp$trt_levels <- new_lvls
        }
      }
    })

    # ── Include Total (radio) ──
    shiny::observeEvent(input$include_total, {
      grp$include_total <- identical(input$include_total, "yes")
    })

    # ── Include unassigned ──
    shiny::observeEvent(input$include_unassigned, {
      grp$include_unassigned <- input$include_unassigned
    })

    output$unassigned_info <- shiny::renderUI({
      req(grp$trt_var, store$datasets)
      ds_name <- names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      trt_var <- grp$trt_var
      pop <- store$pipeline_filters$pop_flag
      if (!is.null(pop) && nzchar(pop) && pop %in% names(d)) {
        d <- d[d[[pop]] == "Y", ]
      }
      n_unassigned <- sum(is.na(d[[trt_var]]) | !nzchar(as.character(d[[trt_var]])))
      if (n_unassigned > 0) {
        htmltools::tags$div(class = "ar-unassigned-info",
          htmltools::tags$span(
            paste0(n_unassigned, " subject", if (n_unassigned > 1) "s" else "",
                   " with missing treatment")),
          shiny::checkboxInput(ns("include_unassigned"),
            paste0("Include missing (N=", n_unassigned, ")"), value = TRUE)
        )
      }
    })

    # ── Treatment levels — clean: drag dots + label only ──
    output$trt_levels_ui <- shiny::renderUI({
      req(grp$trt_var, grp$trt_levels, store$datasets)
      lvls <- grp$trt_levels
      n_lvls <- length(lvls)

      level_rows <- lapply(lvls, function(lv) {
        htmltools::tags$div(class = "ar-trt-row", `data-level` = lv,
          htmltools::tags$span(class = "ar-trt-row__drag", htmltools::tags$i(class = "fa fa-grip-vertical")),
          htmltools::tags$span(class = "ar-trt-row__label", lv)
        )
      })

      summary_text <- paste0(n_lvls, " level", if (n_lvls != 1) "s")
      container_id <- ns("trt_sortable")
      session$sendCustomMessage("ar_init_trt_sortable", list(
        container_id = container_id, input_id = ns("trt_order")))

      htmltools::tags$details(id = ns("trt_disclosure"),
        class = "ar-disclosure", open = NA,
        htmltools::tags$summary(class = "ar-disclosure__summary", summary_text),
        htmltools::tags$div(class = "ar-disclosure__body",
          htmltools::tags$div(id = container_id, level_rows),
        )
      )
    })

    # ── Treatment level reorder ──
    shiny::observeEvent(input$trt_order, {
      req(input$trt_order)
      grp$trt_levels <- input$trt_order
    })

    # ── Group Variable choices ──
    shiny::observe({
      req(store$datasets, length(store$datasets) > 0)
      ds_name <- names(store$datasets)[1]
      req(ds_name)
      d <- store$datasets[[ds_name]]
      cat_cols <- names(d)[vapply(d, function(x) {
        is.character(x) || is.factor(x)
      }, logical(1))]
      trt <- grp$trt_var
      cat_cols <- setdiff(cat_cols, c(trt, "USUBJID", "SUBJID", "STUDYID"))
      choices <- c("None" = "", cat_cols)
      current <- grp$by_var
      sel <- if (!is.null(current) && current %in% cat_cols) current else ""
      shiny::updateSelectInput(session, "by_var", choices = choices, selected = sel)
    })

    shiny::observeEvent(input$by_var, {
      if (nzchar(input$by_var)) {
        grp$by_var <- input$by_var
        ds_name <- names(store$datasets)[1]
        d <- store$datasets[[ds_name]]
        pop <- store$pipeline_filters$pop_flag
        if (!is.null(pop) && nzchar(pop) && pop %in% names(d)) {
          d <- d[d[[pop]] == "Y", ]
        }
        grp$by_levels <- sort(unique(d[[input$by_var]]))
      } else {
        grp$by_var <- NULL
        grp$by_levels <- NULL
      }
    })

    # ── Group variable levels — same clean style as treatment ──
    output$by_levels_ui <- shiny::renderUI({
      req(input$by_var, nzchar(input$by_var))
      req(store$datasets)
      ds_name <- names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      by_var <- input$by_var
      pop <- store$pipeline_filters$pop_flag
      if (!is.null(pop) && nzchar(pop) && pop %in% names(d)) {
        d <- d[d[[pop]] == "Y", ]
      }

      by_lvls <- grp$by_levels %||% sort(unique(d[[by_var]]))
      n_by <- length(by_lvls)

      by_rows <- lapply(by_lvls, function(bv) {
        htmltools::tags$div(class = "ar-trt-row", `data-level` = bv,
          htmltools::tags$span(class = "ar-trt-row__drag", htmltools::tags$i(class = "fa fa-grip-vertical")),
          htmltools::tags$span(class = "ar-trt-row__label", bv)
        )
      })

      summary_text <- paste0(n_by, " level", if (n_by != 1) "s")
      container_id <- ns("by_sortable")
      session$sendCustomMessage("ar_init_by_sortable", list(
        container_id = container_id, input_id = ns("by_order")))

      htmltools::tags$details(id = ns("by_disclosure"),
        class = "ar-disclosure", open = NA,
        htmltools::tags$summary(class = "ar-disclosure__summary", summary_text),
        htmltools::tags$div(class = "ar-disclosure__body",
          htmltools::tags$div(id = container_id, by_rows),
        )
      )
    })

    # ── By-level reorder ──
    shiny::observeEvent(input$by_order, {
      req(input$by_order)
      grp$by_levels <- input$by_order
    })

    # ── Denominator ──
    shiny::observeEvent(input$denominator, {
      grp$denominator <- input$denominator
    })
  })
}
