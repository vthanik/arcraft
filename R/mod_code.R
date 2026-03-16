#' Code Viewer Module — displays generated R script
mod_code_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::uiOutput(ns("editor"))
}

mod_code_server <- function(id, code_text) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    output$editor <- shiny::renderUI({
      script <- tryCatch(code_text(), error = function(e) NULL)
      if (is.null(script) || !nzchar(script)) {
        return(htmltools::tags$div(class = "ar-empty",
          htmltools::tags$div(class = "ar-empty__title", "No code yet"),
          htmltools::tags$div(class = "ar-empty__desc",
            "Press Preview to generate the R script.")))
      }
      htmltools::tags$div(class = "ar-code-wrap ar-fade-in",
        shinyAce::aceEditor(ns("ace"), value = script, mode = "r",
          theme = "tomorrow", readOnly = TRUE, height = "500px", fontSize = 13))
    })
  })
}
