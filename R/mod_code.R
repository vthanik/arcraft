# Module: Code Viewer — plain verbatimTextOutput (no shinyAce dependency)

mod_code_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tags$div(class = "ar-code-wrap",
    shiny::verbatimTextOutput(ns("code_display"))
  )
}

mod_code_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    output$code_display <- shiny::renderText({
      code <- store$code
      if (is.null(code) || !nzchar(code)) {
        "# Generated R script will appear here\n# Click 'Generate Preview' to build the pipeline"
      } else {
        code
      }
    })
  })
}
