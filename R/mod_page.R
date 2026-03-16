#' Page Layout Module
#' @return reactive: list(orientation, paper, font_size, font_family, hline_preset)
mod_page_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    shiny::selectInput(ns("orient"), "Orientation", c("landscape", "portrait"), "landscape"),
    shiny::selectInput(ns("paper"), "Paper", c("letter", "a4", "legal"), "letter"),
    shiny::numericInput(ns("fsize"), "Font Size (pt)", 9, min = 6, max = 14, step = 1),
    shiny::selectInput(ns("font"), "Font", c("Courier New", "Times New Roman", "Arial"), "Courier New"),
    shiny::selectInput(ns("hlines"), "Rules", c("header", "booktabs", "box", "open", "void"), "header")
  )
}

mod_page_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::reactive(list(
      orientation = input$orient %||% "landscape", paper = input$paper %||% "letter",
      font_size = input$fsize %||% 9, font_family = input$font %||% "Courier New",
      hline_preset = input$hlines %||% "header"))
  })
}
