# Module: Treatment — CDISC-aligned treatment configuration
#
# Flat layout (no accordion). CDISC terminology:
# - Treatment Variable (not Arm Variable)
# - Include unassigned subjects (not screen failures)
# - By Variable (not Subgroup)
# - Denominator (Column N / Row N / By-group N)
# - Big N format

mod_treatment_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Treatment variable
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Treatment Variable"),
      shiny::selectInput(ns("trt_var"), NULL, choices = NULL, width = "100%")
    ),

    # Treatment levels (collapsible disclosure with N counts)
    shiny::uiOutput(ns("trt_levels_ui")),

    # Include Total column
    shiny::checkboxInput(ns("include_total"), "Include Total column", value = TRUE),

    # Include unassigned (dynamic — shows count when applicable)
    shiny::uiOutput(ns("unassigned_info")),

    # By Variable
    htmltools::tags$div(class = "ar-form-group ar-mt-8",
      htmltools::tags$label(class = "ar-form-label", "By Variable"),
      shiny::selectInput(ns("by_var"), NULL,
        choices = c("None" = ""), width = "100%")
    ),

    # By-variable level counts (crossed with treatment)
    shiny::uiOutput(ns("by_levels_ui")),

    # Denominator
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Denominator"),
      shiny::selectInput(ns("denominator"), NULL,
        choices = c(
          "Column N" = "col_n",
          "Row N" = "row_n",
          "By-group N" = "bygroup_n"
        ),
        selected = "col_n", width = "100%")
    ),

    # Big N format — configured in Format > Columns panel
  )
}

mod_treatment_server <- function(id, store, grp) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Auto-detect treatment/grouping variables (Fix 3: optgroups) ──
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

    # ── When treatment var changes, update levels (only if var actually changed) ──
    shiny::observeEvent(input$trt_var, {
      req(input$trt_var, store$datasets)
      ds_name <- names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      if (input$trt_var %in% names(d)) {
        new_lvls <- sort(unique(d[[input$trt_var]]))
        prev_var <- grp$trt_var
        grp$trt_var <- input$trt_var
        # Only reset levels if treatment variable itself changed
        if (is.null(prev_var) || prev_var != input$trt_var ||
            !setequal(grp$trt_levels %||% character(0), new_lvls)) {
          grp$trt_levels <- new_lvls
        }
      }
    })

    # ── Include Total ──
    shiny::observeEvent(input$include_total, {
      grp$include_total <- input$include_total
    })

    # ── Total column label ──
    shiny::observeEvent(input$total_label, {
      lbl <- trimws(input$total_label)
      if (nzchar(lbl)) grp$total_label <- lbl
    })

    # ── Include unassigned (Fix 2: dynamic info with count) ──
    shiny::observeEvent(input$include_unassigned, {
      grp$include_unassigned <- input$include_unassigned
    })

    output$unassigned_info <- shiny::renderUI({
      req(grp$trt_var, store$datasets)
      ds_name <- names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      trt_var <- grp$trt_var

      # Apply pop filter
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

    # ── Treatment levels (with N counts + reorder) ──
    output$trt_levels_ui <- shiny::renderUI({
      req(grp$trt_var, grp$trt_levels, store$datasets)
      ds_name <- names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      trt_var <- grp$trt_var

      # Apply pop filter for accurate counts
      pop <- store$pipeline_filters$pop_flag
      if (!is.null(pop) && nzchar(pop) && pop %in% names(d)) {
        d <- d[d[[pop]] == "Y", ]
      }

      counts <- table(d[[trt_var]])
      lvls <- grp$trt_levels
      n_lvls <- length(lvls)

      level_rows <- lapply(seq_along(lvls), function(idx) {
        lv <- lvls[idx]
        n <- as.integer(counts[lv])
        if (is.na(n)) n <- 0L

        htmltools::tags$div(class = "ar-trt-row", `data-level` = lv,
          htmltools::tags$span(class = "ar-trt-row__drag", htmltools::HTML("&#8942;&#8942;")),
          htmltools::tags$span(class = "ar-trt-row__label", lv)
        )
      })

      # Total row + label input
      total_label <- grp$total_label %||% "Total"
      n_total <- nrow(d)
      total_row <- if (isTRUE(input$include_total)) {
        htmltools::tagList(
          htmltools::tags$div(
            style = "border-top: 1px solid var(--border-light); margin-top: 4px; padding-top: 4px;"),
          htmltools::tags$div(class = "ar-trt-row ar-trt-row--total",
            htmltools::tags$span(class = "ar-trt-row__label ar-trt-row__label--total",
              total_label)
          ),
          htmltools::tags$div(
            style = "padding-top: 4px;",
            shiny::textInput(ns("total_label"), "Label", value = total_label,
              width = "100%", placeholder = "Total")
          )
        )
      }

      summary_text <- paste0(n_lvls, " arms")

      container_id <- ns("trt_sortable")
      session$sendCustomMessage("ar_init_trt_sortable", list(
        container_id = container_id,
        input_id = ns("trt_order")
      ))

      htmltools::tags$details(id = ns("trt_disclosure"),
        class = "ar-disclosure", open = NA,
        htmltools::tags$summary(class = "ar-disclosure__summary", summary_text),
        htmltools::tags$div(class = "ar-disclosure__body",
          htmltools::tags$div(id = container_id, level_rows),
          total_row
        )
      )
    })

    # ── Treatment level reorder handler (Sortable.js drag-and-drop) ──
    shiny::observeEvent(input$trt_order, {
      new_order <- input$trt_order
      req(new_order)
      grp$trt_levels <- new_order
    })

    # ── By Variable ──
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
        # Compute and store by-levels for reordering
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

    # ── By-variable level counts (crossed with treatment) + reorder ──
    output$by_levels_ui <- shiny::renderUI({
      req(input$by_var, nzchar(input$by_var))
      req(store$datasets)
      ds_name <- names(store$datasets)[1]
      d <- store$datasets[[ds_name]]
      by_var <- input$by_var

      # Apply pop filter
      pop <- store$pipeline_filters$pop_flag
      if (!is.null(pop) && nzchar(pop) && pop %in% names(d)) {
        d <- d[d[[pop]] == "Y", ]
      }

      # Use stored order if available, else sorted
      by_lvls <- grp$by_levels %||% sort(unique(d[[by_var]]))
      n_by <- length(by_lvls)

      by_blocks <- lapply(seq_along(by_lvls), function(idx) {
        bv <- by_lvls[idx]
        htmltools::tags$div(
          class = "ar-by-block", `data-level` = bv,
          htmltools::tags$div(
            class = "ar-flex ar-items-center ar-gap-4",
            style = "padding: 2px 0;",
            htmltools::tags$span(class = "ar-trt-row__drag", htmltools::HTML("&#8942;&#8942;")),
            htmltools::tags$span(
              style = "font-size: 12px; font-weight: 500; color: var(--fg-2); flex: 1;",
              bv)
          )
        )
      })

      summary_text <- paste0(n_by, " level", if (n_by != 1) "s")

      container_id <- ns("by_sortable")
      session$sendCustomMessage("ar_init_by_sortable", list(
        container_id = container_id,
        input_id = ns("by_order")
      ))

      htmltools::tags$details(id = ns("by_disclosure"),
        class = "ar-disclosure", open = NA,
        htmltools::tags$summary(class = "ar-disclosure__summary", summary_text),
        htmltools::tags$div(class = "ar-disclosure__body",
          htmltools::tags$div(id = container_id, by_blocks)
        )
      )
    })

    # ── By-level reorder handler (Sortable.js drag-and-drop) ──
    shiny::observeEvent(input$by_order, {
      new_order <- input$by_order
      req(new_order)
      grp$by_levels <- new_order
    })

    # ── Denominator ──
    shiny::observeEvent(input$denominator, {
      grp$denominator <- input$denominator
    })

    # Big N format removed from here — configured in Format > Columns
  })
}
