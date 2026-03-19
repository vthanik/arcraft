# Module: Header & Spans — Header styling + dynamic spanning header editor
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_header_spans_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Header — compact: Bold + Align on one row
    htmltools::tags$div(class = "ar-header-row",
      htmltools::tags$div(class = "ar-header-row__bold",
        shiny::checkboxInput(ns("header_bold"), "Bold", value = TRUE)
      ),
      htmltools::tags$div(class = "ar-inline-radio",
        htmltools::tags$label(class = "ar-inline-radio__opt", title = "Left",
          htmltools::tags$input(type = "radio", name = ns("header_align"),
            value = "left",
            onchange = paste0("Shiny.setInputValue('", ns("header_align"), "', 'left')")),
          htmltools::tags$i(class = "fa fa-align-left", style = "font-size: 10px;")),
        htmltools::tags$label(class = "ar-inline-radio__opt", title = "Center",
          htmltools::tags$input(type = "radio", name = ns("header_align"),
            value = "center", checked = NA,
            onchange = paste0("Shiny.setInputValue('", ns("header_align"), "', 'center')")),
          htmltools::tags$i(class = "fa fa-align-center", style = "font-size: 10px;")),
        htmltools::tags$label(class = "ar-inline-radio__opt", title = "Right",
          htmltools::tags$input(type = "radio", name = ns("header_align"),
            value = "right",
            onchange = paste0("Shiny.setInputValue('", ns("header_align"), "', 'right')")),
          htmltools::tags$i(class = "fa fa-align-right", style = "font-size: 10px;"))
      )
    ),

    # V-Align, BG, FG — visible sub-section
    htmltools::tags$div(class = "ar-header-extras",
      htmltools::tags$div(class = "ar-flex ar-gap-8",
        htmltools::tags$div(class = "ar-form-group", style = "flex: 1;",
          htmltools::tags$label(class = "ar-form-label", "V-Align"),
          shiny::selectInput(ns("header_valign"), NULL,
            choices = c("Top" = "top", "Middle" = "middle", "Bottom" = "bottom"),
            selected = "bottom", width = "100%")
        ),
        htmltools::tags$div(class = "ar-form-group", style = "flex: 1;",
          htmltools::tags$label(class = "ar-form-label", "BG"),
          shiny::textInput(ns("header_bg"), NULL, value = "", width = "100%",
                           placeholder = "#003366")
        ),
        htmltools::tags$div(class = "ar-form-group", style = "flex: 1;",
          htmltools::tags$label(class = "ar-form-label", "FG"),
          shiny::textInput(ns("header_fg"), NULL, value = "", width = "100%",
                           placeholder = "#ffffff")
        )
      )
    ),

    # Spans subsection
    htmltools::tags$div(class = "ar-section-header ar-mt-12",
      htmltools::tags$span(class = "ar-section-header__label", "Spanning Headers"),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn--xs",
        onclick = paste0("Shiny.setInputValue('", ns("add_span"), "', Math.random(), {priority: 'event'})"),
        htmltools::tags$i(class = "fa fa-plus", style = "font-size: 9px; margin-right: 2px;"), "Add"
      )
    ),
    shiny::uiOutput(ns("span_inputs"))
  )
}

mod_header_spans_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    spans_rv <- shiny::reactiveVal(list())

    # Init from store (re-fires on store$fmt changes)
    shiny::observe({
      hdr <- store$fmt$header
      if (!is.null(hdr$bold)) shiny::updateCheckboxInput(session, "header_bold", value = hdr$bold)
      if (!is.null(hdr$align)) shiny::updateRadioButtons(session, "header_align", selected = hdr$align)
      if (!is.null(hdr$valign)) shiny::updateSelectInput(session, "header_valign", selected = hdr$valign)
      if (!is.null(hdr$bg) && nzchar(hdr$bg)) shiny::updateTextInput(session, "header_bg", value = hdr$bg)
      if (!is.null(hdr$fg) && nzchar(hdr$fg)) shiny::updateTextInput(session, "header_fg", value = hdr$fg)

      spans <- store$fmt$spans
      if (length(spans) > 0) {
        spans_rv(lapply(spans, function(s) {
          list(label = s$label %||% "", cols = s$cols %||% character(0), level = s$level %||% 1L)
        }))
      }
    })

    # Add span
    shiny::observeEvent(input$add_span, {
      current <- spans_rv()
      if (length(current) < 5) {
        spans_rv(c(current, list(list(label = "", cols = character(0), level = 1L))))
      }
    })

    # Remove span (unified handler)
    shiny::observeEvent(input$rm_span, {
      idx <- as.integer(input$rm_span)
      current <- spans_rv()
      if (idx >= 1 && idx <= length(current)) {
        current[[idx]] <- NULL
        spans_rv(current)
      }
    })

    # Get available column names from ARD
    ard_cols <- shiny::reactive({
      ard <- store$ard
      if (is.null(ard)) return(character(0))
      meta_cols <- c("variable", "var_label", "var_type", "stat_label",
                      "row_type", "timepoint", "baseline_category", "post_category",
                      "by_value")
      setdiff(names(ard), meta_cols)
    })

    # Render span inputs
    output$span_inputs <- shiny::renderUI({
      spans <- spans_rv()
      cols <- ard_cols()

      if (length(spans) == 0 && length(cols) == 0) {
        return(htmltools::tags$div(class = "ar-text-xs ar-text-muted",
          "Generate preview first to add spans"))
      }
      if (length(spans) == 0) return(NULL)

      lapply(seq_along(spans), function(i) {
        sp <- spans[[i]]

        htmltools::tags$div(class = "ar-span-card",
          # Top bar: label input + level + remove button
          htmltools::tags$div(class = "ar-span-card__header",
            shiny::textInput(ns(paste0("span_label_", i)), NULL,
              value = sp$label %||% "", width = "100%",
              placeholder = paste0("Span label ", i)),
            htmltools::tags$div(class = "ar-span-card__level",
              htmltools::tags$label(class = "ar-form-label", "Lvl"),
              shiny::numericInput(ns(paste0("span_level_", i)), NULL,
                value = sp$level %||% 1L, min = 1, max = 3, width = "50px")
            ),
            htmltools::tags$button(
              class = "ar-btn-ghost ar-btn--xs ar-span-card__remove",
              onclick = paste0("Shiny.setInputValue('", ns("rm_span"), "', '", i, "', {priority: 'event'})"),
              htmltools::tags$i(class = "fa fa-times", style = "font-size: 10px; color: var(--fg-muted);"))
          ),
          # Column selector
          if (length(cols) > 0) {
            shiny::selectInput(ns(paste0("span_cols_", i)), "Columns",
              choices = cols, selected = sp$cols %||% character(0),
              multiple = TRUE, width = "100%")
          }
        )
      })
    })

    # get_draft: return header + spans config
    get_draft <- function() {
      current_spans <- shiny::isolate(spans_rv())
      n <- length(current_spans)
      spans <- if (n == 0) list() else {
        raw <- lapply(seq_len(n), function(i) {
          label <- shiny::isolate(input[[paste0("span_label_", i)]])
          cols <- shiny::isolate(input[[paste0("span_cols_", i)]])
          level <- shiny::isolate(input[[paste0("span_level_", i)]]) %||% 1L
          list(label = label %||% "", cols = cols %||% character(0), level = as.integer(level))
        })
        Filter(function(s) nzchar(s$label) && length(s$cols) > 0, raw)
      }

      bg_val <- shiny::isolate(input$header_bg) %||% ""
      fg_val <- shiny::isolate(input$header_fg) %||% ""

      list(
        header = list(
          bold = shiny::isolate(input$header_bold) %||% TRUE,
          align = shiny::isolate(input$header_align) %||% "center",
          valign = shiny::isolate(input$header_valign) %||% "bottom",
          bg = if (nzchar(bg_val)) bg_val else NULL,
          fg = if (nzchar(fg_val)) fg_val else NULL
        ),
        spans = spans
      )
    }

    return(get_draft)
  })
}
