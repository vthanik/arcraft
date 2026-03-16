#' Analysis Type Module
#' @return reactive: list(type)
mod_analysis_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    htmltools::tags$div(class = "ar-section", "Table Type"),
    htmltools::tags$div(class = "ar-cards-row",
      analysis_card(ns("demog"), "Demographics",
        "Baseline characteristics by treatment group", "users", active = TRUE),
      analysis_card(ns("ae"), "Adverse Events",
        "AE summary by SOC and preferred term", "triangle-exclamation", disabled = TRUE),
      analysis_card(ns("disp"), "Disposition",
        "Subject disposition summary", "right-from-bracket", disabled = TRUE)
    ),
    shiny::uiOutput(ns("desc"))
  )
}

#' Analysis card UI helper
analysis_card <- function(id, title, desc, icon, active = FALSE, disabled = FALSE) {
  cls <- paste0("ar-analysis-card", if (active) " active", if (disabled) " disabled")
  htmltools::tags$button(id = id, class = cls,
    onclick = if (!disabled) sprintf(
      "document.querySelectorAll('.ar-analysis-card').forEach(c=>c.classList.remove('active'));this.classList.add('active');Shiny.setInputValue('%s_type',this.id)",
      gsub("-[^-]+$", "", id)) else NULL,
    htmltools::tags$div(class = "ar-analysis-card__icon", shiny::icon(icon)),
    htmltools::tags$div(class = "ar-analysis-card__body",
      htmltools::tags$div(class = "ar-analysis-card__title", title),
      htmltools::tags$div(class = "ar-analysis-card__desc", desc)),
    if (disabled) htmltools::tags$span(class = "ar-pill ar-pill--warning", "Phase 2")
  )
}

mod_analysis_server <- function(id, datasets) {
  shiny::moduleServer(id, function(input, output, session) {
    # For Phase 1, only demographics is active
    shiny::reactive(list(type = "demog"))
  })
}
