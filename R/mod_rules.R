# Module: Rules — Horizontal/vertical line presets + custom width/color/style
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_rules_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # ── Essential controls ──
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Horizontal"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("hline_preset"), NULL,
            choices = c("Header only" = "header", "Booktabs" = "booktabs",
                        "Box" = "box", "Open" = "open", "H-sides" = "hsides",
                        "Above" = "above", "Below" = "below", "None" = "void"),
            selected = "header", width = "100%")
        )
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Vertical"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("vline_preset"), NULL,
            choices = c("None" = "none", "Inner" = "inner", "Box" = "box", "All" = "all"),
            selected = "none", width = "100%")
        )
      )
    ),

    # ── Line style disclosure ──
    htmltools::tags$details(class = "ar-disclosure",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Line style"),
      htmltools::tags$div(class = "ar-disclosure__body",
        htmltools::tags$div(class = "ar-props",
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Width"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::selectInput(ns("line_width"), NULL,
                choices = c("Hairline" = "hairline", "Thin" = "thin",
                            "Medium" = "medium", "Thick" = "thick"),
                selected = "thin", width = "100%")
            )
          ),
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Color"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::textInput(ns("line_color"), NULL, value = "#000000",
                width = "100%", placeholder = "#000000")
            )
          ),
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Style"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::radioButtons(ns("line_style"), NULL,
                choices = c("Solid" = "solid", "Dashed" = "dashed", "Dotted" = "dotted"),
                selected = "solid", inline = TRUE)
            )
          )
        )
      )
    )
  )
}

mod_rules_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    # Init from store (re-fires on store$fmt changes)
    shiny::observe({
      rl <- store$fmt$rules
      if (!is.null(rl$hline_preset)) shiny::updateSelectInput(session, "hline_preset", selected = rl$hline_preset)
      if (!is.null(rl$vline_preset)) shiny::updateSelectInput(session, "vline_preset", selected = rl$vline_preset)
      if (!is.null(rl$line_width)) shiny::updateSelectInput(session, "line_width", selected = rl$line_width)
      if (!is.null(rl$line_color)) shiny::updateTextInput(session, "line_color", value = rl$line_color)
      if (!is.null(rl$line_style)) shiny::updateRadioButtons(session, "line_style", selected = rl$line_style)
    })

    # get_draft: return current rules config
    get_draft <- function() {
      list(
        hline_preset = shiny::isolate(input$hline_preset) %||% "header",
        vline_preset = shiny::isolate(input$vline_preset) %||% "none",
        line_width = shiny::isolate(input$line_width) %||% "thin",
        line_color = shiny::isolate(input$line_color) %||% "#000000",
        line_style = shiny::isolate(input$line_style) %||% "solid"
      )
    }

    return(get_draft)
  })
}
