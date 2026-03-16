#' Column Config Module
#' @return reactive: list(stub_width, body_align)
mod_columns_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    shiny::numericInput(ns("stub"), "Stub Width (in)", 2, min = 0.5, max = 5, step = 0.25),
    shiny::selectInput(ns("align"), "Body Align", c("center", "left", "right"), "center")
  )
}

mod_columns_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::reactive(list(stub_width = input$stub %||% 2, body_align = input$align %||% "center"))
  })
}
