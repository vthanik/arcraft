# Module: Header & Spans — Header styling + per-column header alignment + spans
# Maps to fr_header(bold, align, valign, bg, fg)
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_header_spans_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # ── Header Style ──
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Bold"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::radioButtons(ns("header_bold"), NULL,
            choices = c("Yes" = "yes", "No" = "no"),
            selected = "yes", inline = TRUE))
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Align"),
        htmltools::tags$div(class = "ar-prop__value",
          htmltools::tags$div(class = "ar-inline-radio",
            htmltools::tags$label(class = "ar-inline-radio__opt", title = "Left",
              htmltools::tags$input(type = "radio", name = ns("header_align"),
                value = "left",
                onchange = paste0("Shiny.setInputValue('", ns("header_align"), "', 'left')")),
              htmltools::tags$i(class = "fa fa-align-left")),
            htmltools::tags$label(class = "ar-inline-radio__opt", title = "Center",
              htmltools::tags$input(type = "radio", name = ns("header_align"),
                value = "center", checked = NA,
                onchange = paste0("Shiny.setInputValue('", ns("header_align"), "', 'center')")),
              htmltools::tags$i(class = "fa fa-align-center")),
            htmltools::tags$label(class = "ar-inline-radio__opt", title = "Right",
              htmltools::tags$input(type = "radio", name = ns("header_align"),
                value = "right",
                onchange = paste0("Shiny.setInputValue('", ns("header_align"), "', 'right')")),
              htmltools::tags$i(class = "fa fa-align-right"))
          ))
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "V-Align"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("header_valign"), NULL,
            choices = c("Top" = "top", "Middle" = "middle", "Bottom" = "bottom"),
            selected = "bottom", width = "100%"))
      )
    ),

    # ── Column Alignment (foldable) ──
    htmltools::tags$details(class = "ar-disclosure ar-mt-12",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Column Alignment"),
      htmltools::tags$div(class = "ar-disclosure__body",
        htmltools::tags$div(class = "ar-form-group",
          htmltools::tags$label(class = "ar-form-label ar-form-label--muted", "Left"),
          shiny::selectizeInput(ns("cols_left"), NULL, choices = NULL, multiple = TRUE, width = "100%",
            options = list(placeholder = "Choose columns..."))
        ),
        htmltools::tags$div(class = "ar-form-group",
          htmltools::tags$label(class = "ar-form-label ar-form-label--muted", "Center"),
          shiny::selectizeInput(ns("cols_center"), NULL, choices = NULL, multiple = TRUE, width = "100%",
            options = list(placeholder = "Choose columns..."))
        ),
        htmltools::tags$div(class = "ar-form-group",
          htmltools::tags$label(class = "ar-form-label ar-form-label--muted", "Right"),
          shiny::selectizeInput(ns("cols_right"), NULL, choices = NULL, multiple = TRUE, width = "100%",
            options = list(placeholder = "Choose columns..."))
        )
      )
    ),

    # ── Colors (foldable) ──
    htmltools::tags$details(class = "ar-disclosure ar-mt-12",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Colors"),
      htmltools::tags$div(class = "ar-disclosure__body",
        htmltools::tags$div(class = "ar-props",
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "BG"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::textInput(ns("header_bg"), NULL, value = "", width = "100%",
                               placeholder = "#003366"))
          ),
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "FG"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::textInput(ns("header_fg"), NULL, value = "", width = "100%",
                               placeholder = "#ffffff"))
          )
        )
      )
    ),

    # ── Spanning Headers ──
    htmltools::tags$div(class = "ar-section-header ar-mt-12",
      htmltools::tags$span(class = "ar-section-header__label", "Spanning Headers"),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn--xs",
        onclick = paste0("Shiny.setInputValue('", ns("add_span"), "', Math.random(), {priority: 'event'})"),
        htmltools::tags$i(class = "fa fa-plus"), "Add"
      )
    ),
    shiny::uiOutput(ns("span_inputs"))
  )
}

mod_header_spans_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    spans_rv <- shiny::reactiveVal(list())

    # Get VISIBLE column names from ARD (exclude hidden meta columns)
    # Only columns where visible != FALSE in per_col config
    visible_data_cols <- shiny::reactive({
      ard <- store$ard
      if (is.null(ard)) return(character(0))
      meta_cols <- c("variable", "var_label", "var_type", "row_type",
                      "timepoint", "baseline_category", "post_category",
                      "group_value")
      all_data <- setdiff(names(ard), meta_cols)
      # Filter out columns hidden via columns module
      per_col <- store$fmt$cols$per_col %||% list()
      Filter(function(col) {
        pc <- per_col[[col]]
        is.null(pc$visible) || isTRUE(pc$visible)
      }, all_data)
    })

    # Init from store
    shiny::observe({
      hdr <- store$fmt$header
      if (!is.null(hdr$bold)) {
        shiny::updateRadioButtons(session, "header_bold",
          selected = if (isTRUE(hdr$bold)) "yes" else "no")
      }
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

    # Update column alignment choices — exclusive buckets (only show columns not in other buckets)
    shiny::observe({
      cols <- visible_data_cols()
      if (length(cols) == 0) return()

      # Read current per-col config to pre-select aligned columns
      per_col <- store$fmt$cols$per_col %||% list()
      left_cols <- names(Filter(function(pc) identical(pc$align, "left"), per_col))
      center_cols <- names(Filter(function(pc) identical(pc$align, "center"), per_col))
      right_cols <- names(Filter(function(pc) identical(pc$align, "right"), per_col))

      # Only show visible cols, filter to what's in our visible list
      left_cols <- intersect(left_cols, cols)
      center_cols <- intersect(center_cols, cols)
      right_cols <- intersect(right_cols, cols)

      # Available for left = cols not in center/right
      avail_left <- setdiff(cols, c(center_cols, right_cols))
      avail_center <- setdiff(cols, c(left_cols, right_cols))
      avail_right <- setdiff(cols, c(left_cols, center_cols))

      shiny::updateSelectizeInput(session, "cols_left", choices = avail_left, selected = left_cols)
      shiny::updateSelectizeInput(session, "cols_center", choices = avail_center, selected = center_cols)
      shiny::updateSelectizeInput(session, "cols_right", choices = avail_right, selected = right_cols)
    })

    # When user changes left selection, update center/right choices to exclude it
    shiny::observeEvent(input$cols_left, ignoreNULL = FALSE, ignoreInit = TRUE, {
      cols <- visible_data_cols()
      left <- input$cols_left %||% character(0)
      center <- input$cols_center %||% character(0)
      right <- input$cols_right %||% character(0)
      # Remove from center/right if moved to left
      center <- setdiff(center, left)
      right <- setdiff(right, left)
      shiny::updateSelectizeInput(session, "cols_center",
        choices = setdiff(cols, c(left, right)), selected = center)
      shiny::updateSelectizeInput(session, "cols_right",
        choices = setdiff(cols, c(left, center)), selected = right)
    })

    shiny::observeEvent(input$cols_center, ignoreNULL = FALSE, ignoreInit = TRUE, {
      cols <- visible_data_cols()
      left <- input$cols_left %||% character(0)
      center <- input$cols_center %||% character(0)
      right <- input$cols_right %||% character(0)
      left <- setdiff(left, center)
      right <- setdiff(right, center)
      shiny::updateSelectizeInput(session, "cols_left",
        choices = setdiff(cols, c(center, right)), selected = left)
      shiny::updateSelectizeInput(session, "cols_right",
        choices = setdiff(cols, c(left, center)), selected = right)
    })

    shiny::observeEvent(input$cols_right, ignoreNULL = FALSE, ignoreInit = TRUE, {
      cols <- visible_data_cols()
      left <- input$cols_left %||% character(0)
      center <- input$cols_center %||% character(0)
      right <- input$cols_right %||% character(0)
      left <- setdiff(left, right)
      center <- setdiff(center, right)
      shiny::updateSelectizeInput(session, "cols_left",
        choices = setdiff(cols, c(center, right)), selected = left)
      shiny::updateSelectizeInput(session, "cols_center",
        choices = setdiff(cols, c(left, right)), selected = center)
    })

    # Add span
    shiny::observeEvent(input$add_span, {
      current <- spans_rv()
      if (length(current) < 5) {
        spans_rv(c(current, list(list(label = "", cols = character(0), level = 1L))))
      }
    })

    # Remove span
    shiny::observeEvent(input$rm_span, {
      idx <- as.integer(input$rm_span)
      current <- spans_rv()
      if (idx >= 1 && idx <= length(current)) {
        current[[idx]] <- NULL
        spans_rv(current)
      }
    })

    # Render span inputs
    output$span_inputs <- shiny::renderUI({
      spans <- spans_rv()
      cols <- visible_data_cols()

      if (length(spans) == 0 && length(cols) == 0) {
        return(htmltools::tags$div(class = "ar-text-xs ar-text-muted",
          "Generate preview first to add spans"))
      }
      if (length(spans) == 0) return(NULL)

      lapply(seq_along(spans), function(i) {
        sp <- spans[[i]]
        htmltools::tags$div(class = "ar-span-card",
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
              htmltools::tags$i(class = "fa fa-times ar-icon-sm ar-icon-muted"))
          ),
          if (length(cols) > 0) {
            shiny::selectInput(ns(paste0("span_cols_", i)), "Columns",
              choices = cols, selected = sp$cols %||% character(0),
              multiple = TRUE, width = "100%")
          }
        )
      })
    })

    # get_draft: return header + column alignment + spans config
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

      # Build per-column alignment from the 3 selectize inputs
      col_aligns <- list()
      for (col in (shiny::isolate(input$cols_left) %||% character(0))) col_aligns[[col]] <- "left"
      for (col in (shiny::isolate(input$cols_center) %||% character(0))) col_aligns[[col]] <- "center"
      for (col in (shiny::isolate(input$cols_right) %||% character(0))) col_aligns[[col]] <- "right"

      list(
        header = list(
          bold = identical(shiny::isolate(input$header_bold), "yes"),
          align = shiny::isolate(input$header_align) %||% "center",
          valign = shiny::isolate(input$header_valign) %||% "bottom",
          bg = if (nzchar(bg_val)) bg_val else NULL,
          fg = if (nzchar(fg_val)) fg_val else NULL
        ),
        spans = spans,
        col_aligns = col_aligns
      )
    }

    return(get_draft)
  })
}
