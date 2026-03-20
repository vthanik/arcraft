# Module: Styles — Bold Group Labels toggle
# Submission-ready formatting. Keep it simple — one pill.

mod_styles_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tags$div(class = "ar-style-pills",
    htmltools::tags$button(
      id = ns("pill_bold_groups"), class = "ar-pill ar-pill--toggle",
      onclick = paste0(
        "this.classList.toggle('ar-pill--active');",
        "Shiny.setInputValue('", ns("pill_bold_groups"),
        "', this.classList.contains('ar-pill--active'), {priority: 'event'})"),
      "Bold Group Labels"
    )
  )
}

mod_styles_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    get_draft <- function() {
      styles <- list()
      if (isTRUE(shiny::isolate(input$pill_bold_groups))) {
        styles$bold_groups <- list(
          type = "conditional",
          condition = "~ !grepl('^\\\\s', .x)",
          cols = "stat_label",
          apply_to = "row",
          bold = TRUE
        )
      }
      list(styles = styles)
    }
    return(get_draft)
  })
}
