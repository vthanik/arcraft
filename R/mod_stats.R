#' Statistics Config Module
#' @return reactive: list(cont_stats, cont_dec, cat_fmt, pct_dec)
mod_stats_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$div(class = "ar-section", "Continuous"),
    shiny::checkboxGroupInput(ns("cont"), NULL,
      choices = c("N" = "n", "Mean (SD)" = "mean_sd", "Median" = "median",
                  "Q1, Q3" = "q1_q3", "Min, Max" = "min_max"),
      selected = c("n", "mean_sd", "median", "q1_q3", "min_max")),
    shiny::numericInput(ns("dec"), "Decimals", value = 1, min = 0, max = 4, step = 1),
    htmltools::tags$hr(class = "ar-divider"),
    htmltools::tags$div(class = "ar-section", "Categorical"),
    shiny::radioButtons(ns("cat"), NULL,
      choices = c("n (%)" = "npct", "n only" = "n_only", "n/N (%)" = "nn_pct"),
      selected = "npct"),
    shiny::numericInput(ns("pct_dec"), "% Decimals", value = 1, min = 0, max = 2, step = 1)
  )
}

mod_stats_server <- function(id, analysis) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::reactive(list(
      cont_stats = input$cont %||% c("n", "mean_sd", "median", "min_max"),
      cont_dec = input$dec %||% 1, cat_fmt = input$cat %||% "npct",
      pct_dec = input$pct_dec %||% 1))
  })
}
