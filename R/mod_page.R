# Module: Page Layout — Orientation, paper, font, margins + advanced options
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_page_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # ── Essential controls ──
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Orientation"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::radioButtons(ns("orientation"), NULL,
            choices = c("Landscape" = "landscape", "Portrait" = "portrait"),
            selected = "landscape", inline = TRUE)
        )
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Paper"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("paper"), NULL,
            choices = c("US Letter" = "letter", "A4" = "a4", "Legal" = "legal"),
            selected = "letter", width = "100%")
        )
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Font"),
        htmltools::tags$div(class = "ar-prop__value ar-prop__split",
          shiny::selectInput(ns("font_family"), NULL,
            choices = c("Courier New", "Times New Roman", "Arial"),
            selected = "Courier New", width = "100%"),
          shiny::numericInput(ns("font_size"), NULL, value = 9,
            min = 6, max = 14, step = 1, width = "100%")
        )
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Margins"),
        htmltools::tags$div(class = "ar-prop__value ar-margin-grid",
          shiny::numericInput(ns("margin_top"), "T", value = 1,
            min = 0.5, max = 3, step = 0.25, width = "100%"),
          shiny::numericInput(ns("margin_right"), "R", value = 1,
            min = 0.5, max = 3, step = 0.25, width = "100%"),
          shiny::numericInput(ns("margin_bottom"), "B", value = 1,
            min = 0.5, max = 3, step = 0.25, width = "100%"),
          shiny::numericInput(ns("margin_left"), "L", value = 1,
            min = 0.5, max = 3, step = 0.25, width = "100%")
        )
      )
    ),

    # ── Advanced options ──
    htmltools::tags$details(class = "ar-disclosure",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Advanced"),
      htmltools::tags$div(class = "ar-disclosure__body",
        htmltools::tags$div(class = "ar-props",
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Column gap"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::numericInput(ns("col_gap"), NULL, value = 4,
                min = 0, max = 12, step = 1, width = "100%")
            )
          ),
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Continuation"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::textInput(ns("continuation"), NULL, value = "",
                width = "100%", placeholder = "(continued)")
            )
          ),
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Orphan / Widow"),
            htmltools::tags$div(class = "ar-prop__value ar-prop__split ar-prop__split--equal",
              shiny::numericInput(ns("orphan_min"), NULL, value = 3,
                min = 1, max = 10, step = 1, width = "100%"),
              shiny::numericInput(ns("widow_min"), NULL, value = 3,
                min = 1, max = 10, step = 1, width = "100%")
            )
          )
        )
      )
    )
  )
}

mod_page_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    # Init from store (re-fires on store$fmt changes)
    shiny::observe({
      pg <- store$fmt$page
      if (!is.null(pg$orientation)) shiny::updateRadioButtons(session, "orientation", selected = pg$orientation)
      if (!is.null(pg$paper)) shiny::updateSelectInput(session, "paper", selected = pg$paper)
      if (!is.null(pg$font_family)) shiny::updateSelectInput(session, "font_family", selected = pg$font_family)
      if (!is.null(pg$font_size)) shiny::updateNumericInput(session, "font_size", value = pg$font_size)
      if (!is.null(pg$margins) && length(pg$margins) == 4) {
        shiny::updateNumericInput(session, "margin_top", value = pg$margins[1])
        shiny::updateNumericInput(session, "margin_right", value = pg$margins[2])
        shiny::updateNumericInput(session, "margin_bottom", value = pg$margins[3])
        shiny::updateNumericInput(session, "margin_left", value = pg$margins[4])
      }
      if (!is.null(pg$col_gap)) shiny::updateNumericInput(session, "col_gap", value = pg$col_gap)
      if (!is.null(pg$continuation)) shiny::updateTextInput(session, "continuation", value = pg$continuation)
      if (!is.null(pg$orphan_min)) shiny::updateNumericInput(session, "orphan_min", value = pg$orphan_min)
      if (!is.null(pg$widow_min)) shiny::updateNumericInput(session, "widow_min", value = pg$widow_min)
    })

    # get_draft: return current page config
    get_draft <- function() {
      list(
        orientation = shiny::isolate(input$orientation) %||% "landscape",
        paper = shiny::isolate(input$paper) %||% "letter",
        font_family = shiny::isolate(input$font_family) %||% "Courier New",
        font_size = shiny::isolate(input$font_size) %||% 9,
        margins = c(
          shiny::isolate(input$margin_top) %||% 1,
          shiny::isolate(input$margin_right) %||% 1,
          shiny::isolate(input$margin_bottom) %||% 1,
          shiny::isolate(input$margin_left) %||% 1
        ),
        col_gap = shiny::isolate(input$col_gap) %||% 4,
        continuation = shiny::isolate(input$continuation) %||% "",
        orphan_min = shiny::isolate(input$orphan_min) %||% 3L,
        widow_min = shiny::isolate(input$widow_min) %||% 3L
      )
    }

    return(get_draft)
  })
}
