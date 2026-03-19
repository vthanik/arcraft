# Module: Columns — Width mode, alignment, N counts, per-column editor
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_columns_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # ── Essential controls ──
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Width"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("width_mode"), NULL,
            choices = c("Auto" = "auto", "Fit to page" = "fit", "Equal" = "equal"),
            selected = "auto", width = "100%")
        )
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Alignment"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::radioButtons(ns("default_align"), NULL,
            choices = c("Left" = "left", "Center" = "center",
                        "Right" = "right", "Decimal" = "decimal"),
            selected = "center", inline = TRUE)
        )
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Indent"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::radioButtons(ns("spaces"), NULL,
            choices = c("Indent" = "indent", "Preserve" = "preserve"),
            selected = "indent", inline = TRUE)
        )
      )
    ),

    # ── Stub column section ──
    htmltools::tags$div(class = "ar-prop-section", "Stub column"),
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Width"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::numericInput(ns("stub_width"), NULL, value = 2.5,
            min = 1, max = 5, step = 0.25, width = "80px")
        )
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Alignment"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::radioButtons(ns("stub_align"), NULL,
            choices = c("Left" = "left", "Center" = "center", "Right" = "right"),
            selected = "left", inline = TRUE)
        )
      )
    ),

    # ── Toggles ──
    htmltools::tags$div(class = "ar-toggles",
      shiny::checkboxInput(ns("n_counts"), "Show N in column headers", value = TRUE),
      htmltools::tags$div(class = "ar-prop ar-prop--sub",
        htmltools::tags$span(class = "ar-prop__label", "N format"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::textInput(ns("n_format"), NULL, value = "(N={n})",
            width = "100%", placeholder = "(N={n})")
        )
      ),
      shiny::checkboxInput(ns("split"), "Split wide tables across pages", value = FALSE)
    ),

    # ── Column labels disclosure ──
    htmltools::tags$details(class = "ar-disclosure",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Column labels"),
      htmltools::tags$div(class = "ar-disclosure__body",
        shiny::uiOutput(ns("col_labels_editor"))
      )
    ),

    # ── Column sizing disclosure ──
    htmltools::tags$details(class = "ar-disclosure",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Column sizing"),
      htmltools::tags$div(class = "ar-disclosure__body",
        shiny::uiOutput(ns("col_sizing_editor"))
      )
    )
  )
}

mod_columns_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Init from store (re-fires on store$fmt changes)
    shiny::observe({
      cols <- store$fmt$cols
      if (!is.null(cols$width_mode)) shiny::updateSelectInput(session, "width_mode", selected = cols$width_mode)
      if (!is.null(cols$default_align)) shiny::updateRadioButtons(session, "default_align", selected = cols$default_align)
      if (!is.null(cols$stub_width)) shiny::updateNumericInput(session, "stub_width", value = cols$stub_width)
      if (!is.null(cols$stub_align)) shiny::updateRadioButtons(session, "stub_align", selected = cols$stub_align)
      if (!is.null(cols$n_counts)) shiny::updateCheckboxInput(session, "n_counts", value = cols$n_counts)
      if (!is.null(cols$n_format)) shiny::updateTextInput(session, "n_format", value = cols$n_format)
      if (!is.null(cols$spaces)) shiny::updateRadioButtons(session, "spaces", selected = cols$spaces)
      if (!is.null(cols$split)) shiny::updateCheckboxInput(session, "split", value = cols$split)
    })

    # Helper: get data columns from ARD
    get_data_cols <- function() {
      ard <- store$ard
      if (is.null(ard)) return(NULL)
      meta_cols <- c("variable", "var_label", "var_type", "stat_label",
                      "row_type", "timepoint", "baseline_category", "post_category",
                      "by_value")
      cols <- setdiff(names(ard), meta_cols)
      if (length(cols) == 0) return(NULL)
      cols
    }

    # Column labels editor
    output$col_labels_editor <- shiny::renderUI({
      data_cols <- get_data_cols()
      if (is.null(data_cols)) {
        return(htmltools::tags$div(class = "ar-text-sm ar-text-muted",
          "Generate Preview first to configure columns"))
      }
      per_col <- store$fmt$cols$per_col %||% list()

      htmltools::tags$div(class = "ar-col-labels-grid",
        lapply(data_cols, function(col) {
          cfg <- per_col[[col]] %||% list()
          htmltools::tags$div(class = "ar-col-labels__row",
            htmltools::tags$span(class = "ar-col-labels__name", title = col, col),
            shiny::textInput(ns(paste0("col_label_", col)), NULL,
              value = cfg$label %||% "", width = "100%",
              placeholder = col)
          )
        })
      )
    })

    # Column sizing editor
    output$col_sizing_editor <- shiny::renderUI({
      data_cols <- get_data_cols()
      if (is.null(data_cols)) {
        return(htmltools::tags$div(class = "ar-text-sm ar-text-muted",
          "Generate Preview first to configure columns"))
      }
      per_col <- store$fmt$cols$per_col %||% list()

      htmltools::tags$div(class = "ar-col-sizing-grid",
        htmltools::tags$div(class = "ar-col-sizing__header",
          htmltools::tags$span(class = "ar-col-sizing__th", "Column"),
          htmltools::tags$span(class = "ar-col-sizing__th", "Width"),
          htmltools::tags$span(class = "ar-col-sizing__th", "Align"),
          htmltools::tags$span(class = "ar-col-sizing__th", "")
        ),
        lapply(data_cols, function(col) {
          cfg <- per_col[[col]] %||% list()
          htmltools::tags$div(class = "ar-col-sizing__row",
            htmltools::tags$span(class = "ar-col-sizing__name", title = col, col),
            shiny::numericInput(ns(paste0("col_width_", col)), NULL,
              value = cfg$width, min = 0.5, max = 8, step = 0.25,
              width = "100%"),
            shiny::selectInput(ns(paste0("col_align_", col)), NULL,
              choices = c("Inherit" = "", "Left" = "left", "Center" = "center",
                          "Right" = "right", "Decimal" = "decimal"),
              selected = cfg$align %||% "", width = "100%"),
            htmltools::tags$label(class = "ar-col-editor__vis", title = "Toggle visibility",
              htmltools::tags$input(type = "checkbox",
                checked = if (cfg$visible %||% TRUE) NA else NULL,
                onchange = paste0("Shiny.setInputValue('", ns(paste0("col_visible_", col)),
                  "', this.checked, {priority: 'event'})")),
              htmltools::tags$i(class = "fa fa-eye", style = "font-size: 11px;")
            )
          )
        })
      )
    })

    # get_draft: return current column config
    get_draft <- function() {
      per_col <- list()
      ard <- shiny::isolate(store$ard)
      if (!is.null(ard)) {
        meta_cols <- c("variable", "var_label", "var_type", "stat_label",
                        "row_type", "timepoint", "baseline_category", "post_category",
                        "by_value")
        data_cols <- setdiff(names(ard), meta_cols)
        for (col in data_cols) {
          label <- shiny::isolate(input[[paste0("col_label_", col)]])
          width <- shiny::isolate(input[[paste0("col_width_", col)]])
          align <- shiny::isolate(input[[paste0("col_align_", col)]])
          visible <- shiny::isolate(input[[paste0("col_visible_", col)]])
          if (!is.null(label) || !is.null(width) || (!is.null(align) && nzchar(align)) ||
              (!is.null(visible) && !visible)) {
            per_col[[col]] <- list(
              label = label %||% col,
              width = if (!is.null(width) && !is.na(width)) width else NULL,
              align = if (!is.null(align) && nzchar(align)) align else NULL,
              visible = visible %||% TRUE
            )
          }
        }
      }
      list(
        width_mode = shiny::isolate(input$width_mode) %||% "auto",
        default_align = shiny::isolate(input$default_align) %||% "center",
        stub_width = shiny::isolate(input$stub_width) %||% 2.5,
        stub_align = shiny::isolate(input$stub_align) %||% "left",
        n_counts = shiny::isolate(input$n_counts) %||% TRUE,
        n_format = shiny::isolate(input$n_format) %||% "(N={n})",
        spaces = shiny::isolate(input$spaces) %||% "indent",
        split = shiny::isolate(input$split) %||% FALSE,
        per_col = per_col
      )
    }

    return(get_draft)
  })
}
