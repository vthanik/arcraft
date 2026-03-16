#' Table Preview Module — renders inside the persistent right pane
mod_preview_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::uiOutput(ns("preview"))
}

mod_preview_server <- function(id, ard, fmt) {
  shiny::moduleServer(id, function(input, output, session) {

    output$preview <- shiny::renderUI({
      tbl <- tryCatch(ard(), error = function(e) NULL)
      if (is.null(tbl) || nrow(tbl) == 0) {
        return(htmltools::tags$div(class = "ar-empty",
          htmltools::tags$div(class = "ar-empty__title", "No table yet"),
          htmltools::tags$div(class = "ar-empty__desc",
            "Configure your analysis and press Preview (or Ctrl+Enter).")))
      }

      f <- fmt()
      tc <- f$titles; pg <- f$page

      # Title lines
      title_html <- purrr::map(tc$titles, function(t) {
        htmltools::tags$div(style = sprintf("text-align:%s;font-weight:bold;font-size:10pt;", tc$align), t)
      })
      pop_html <- if (nzchar(tc$population)) {
        htmltools::tags$div(style = sprintf("text-align:%s;font-size:9pt;margin-bottom:6px;", tc$align),
          tc$population)
      }

      # Table
      cns <- names(tbl)
      ths <- purrr::map(cns, function(cn) {
        htmltools::tags$th(style = sprintf("text-align:%s;padding:3px 8px;border-bottom:1px solid #000;",
          if (cn == "param") "left" else f$cols$body_align), cn)
      })
      trs <- purrr::map(seq_len(nrow(tbl)), function(i) {
        tds <- purrr::map(cns, function(cn) {
          htmltools::tags$td(style = sprintf("text-align:%s;padding:2px 8px;font-size:%dpt;",
            if (cn == "param") "left" else f$cols$body_align, pg$font_size),
            as.character(tbl[[cn]][i]))
        })
        htmltools::tags$tr(tds)
      })

      # Footnotes
      fn_html <- purrr::map(tc$footnotes, function(fn) {
        htmltools::tags$div(style = "font-size:8pt;", fn)
      })
      src_html <- if (nzchar(tc$source)) {
        htmltools::tags$div(style = "font-size:8pt;margin-top:3px;", paste("Source:", tc$source))
      }

      htmltools::tags$div(class = "ar-preview ar-fade-in",
        style = sprintf("font-family:'%s',monospace;", pg$font_family),
        title_html, pop_html,
        htmltools::tags$table(
          htmltools::tags$thead(htmltools::tags$tr(ths)),
          htmltools::tags$tbody(trs)),
        htmltools::tags$div(style = "border-top:1px solid #000;margin-top:4px;padding-top:4px;",
          fn_html, src_html))
    })
  })
}
