#' Grouping Module — treatment var + analysis variables
#' @param data_out list with $filtered reactive and $datasets reactiveVal
#' @return reactive: list(trt_var, trt_levels, include_total, analysis_vars)
mod_grouping_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    shiny::selectInput(ns("trt"), "Treatment Variable", choices = NULL),
    shiny::checkboxInput(ns("total"), "Include Total", value = TRUE),
    htmltools::tags$div(class = "ar-section", "Analysis Variables"),
    shiny::uiOutput(ns("vars"))
  )
}

mod_grouping_server <- function(id, data_out, analysis) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    adsl <- shiny::reactive({
      fd <- data_out$filtered()
      shiny::req(fd)
      get_adsl(fd)
    })

    shiny::observe({
      d <- adsl(); shiny::req(d)
      tvars <- fct_detect_trt_vars(names(d))
      shiny::updateSelectInput(session, "trt", choices = tvars,
        selected = if ("TRT01A" %in% tvars) "TRT01A" else tvars[1])
    })

    output$vars <- shiny::renderUI({
      d <- adsl(); shiny::req(d)
      vi <- fct_detect_demog_vars(d)
      shiny::req(nrow(vi) > 0)
      choices <- stats::setNames(vi$variable, paste0(vi$label, "  \u2014  ", vi$type))
      shiny::checkboxGroupInput(ns("analysis_vars"), NULL,
        choices = choices, selected = utils::head(vi$variable, 5))
    })

    shiny::reactive({
      d <- adsl(); tv <- input$trt
      shiny::req(d, tv, tv %in% names(d))
      vars <- input$analysis_vars %||% character(0)
      var_info <- purrr::map(vars, function(v) {
        list(variable = v, label = fct_get_var_label(d, v), type = fct_detect_var_type(d, v))
      })
      list(trt_var = tv, trt_levels = sort(unique(d[[tv]])),
           include_total = isTRUE(input$total), analysis_vars = var_info)
    })
  })
}
