#' Titles & Footnotes Module
#' @return reactive: list(titles, population, align, footnotes, source)
mod_titles_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    shiny::textInput(ns("t1"), "Title 1", "Table 14.1.5"),
    shiny::textInput(ns("t2"), "Title 2", "Summary of Demographic and Baseline Characteristics"),
    shiny::textInput(ns("pop"), "Population", "Safety Population"),
    shiny::selectInput(ns("align"), "Align", c("center", "left", "right"), "center"),
    htmltools::tags$hr(class = "ar-divider"),
    htmltools::tags$div(class = "ar-section", "Footnotes"),
    shiny::textInput(ns("fn1"), "1", "Percentages based on N in each treatment group."),
    shiny::textInput(ns("src"), "Source", "ADSL")
  )
}

mod_titles_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::reactive({
      titles <- c(input$t1, input$t2)
      titles <- titles[nzchar(titles)]
      fns <- c(input$fn1)
      fns <- fns[nzchar(fns)]
      list(titles = titles, population = input$pop %||% "",
           align = input$align %||% "center", footnotes = fns,
           source = input$src %||% "")
    })
  })
}
