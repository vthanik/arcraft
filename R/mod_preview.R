# Module: Preview — Formatted table HTML preview

mod_preview_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::uiOutput(ns("preview_output"))
}

mod_preview_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$preview_output <- shiny::renderUI({
      ard <- store$ard
      fmt <- store$fmt

      if (is.null(ard)) {
        return(ui_empty_state(
          "No preview available",
          "Configure your table and click Generate Preview (Ctrl+Enter).",
          "fa-table",
          cta = htmltools::tags$button(
            class = "ar-btn-primary",
            onclick = "document.getElementById('preview_btn').click();",
            htmltools::tags$i(class = "fa fa-play", style = "font-size: 10px;"),
            "Generate Preview"
          )
        ))
      }

      fct_build_preview_html(ard, fmt)
    })
  })
}
