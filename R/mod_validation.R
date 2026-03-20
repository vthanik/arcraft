# Module: Validation — Pipeline checklist

mod_validation_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$button(
      class = "ar-btn-outline ar-w-full ar-mb-12",
      onclick = paste0("Shiny.setInputValue('", ns("run_validation"), "', Math.random(), {priority: 'event'})"),
      htmltools::tags$i(class = "fa fa-check-circle ar-icon-mr-6"),
      "Run Validation"
    ),
    shiny::uiOutput(ns("checklist"))
  )
}

mod_validation_server <- function(id, store, grp) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    output$checklist <- shiny::renderUI({
      req(input$run_validation)

      snapshot <- shiny::reactiveValuesToList(store)
      grp_snapshot <- shiny::reactiveValuesToList(grp)
      checks <- fct_validate_pipeline(snapshot, grp_snapshot)
      n_pass <- sum(vapply(checks, function(c) isTRUE(c$pass), logical(1)))
      n_total <- length(checks)

      htmltools::tagList(
        htmltools::tags$div(class = "ar-flex ar-items-center ar-gap-8 ar-mb-12",
          htmltools::tags$span(class = "ar-validation-summary",
                               paste0(n_pass, "/", n_total, " checks passed")),
          if (n_pass == n_total) {
            htmltools::tags$span(class = "ar-validation-ready", "Ready to export")
          }
        ),
        htmltools::tags$ul(class = "ar-check-list",
          lapply(checks, function(c) {
            icon_cls <- if (isTRUE(c$pass)) "fa fa-check-circle ar-check-icon ar-check-icon--pass"
                        else "fa fa-times-circle ar-check-icon ar-check-icon--fail"
            htmltools::tags$li(class = "ar-check-item",
              htmltools::tags$i(class = icon_cls),
              htmltools::tags$span(class = "ar-check-label", c$label),
              htmltools::tags$span(class = "ar-check-detail", c$detail)
            )
          })
        )
      )
    })
  })
}
