# Module: Rows & Pagination — Group by, page by, indent, listing features
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_rows_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Group By — select + related checkbox grouped together
    htmltools::tags$div(class = "ar-row-group",
      htmltools::tags$div(class = "ar-form-group",
        htmltools::tags$label(class = "ar-form-label", "Group By"),
        shiny::selectInput(ns("group_by"), NULL,
          choices = c("(none)" = ""), selected = "", width = "100%")
      ),
      htmltools::tags$div(class = "ar-row-group__option",
        shiny::checkboxInput(ns("blank_after"), "Blank line after group", value = FALSE)
      )
    ),

    # Page By — select + related checkbox grouped together
    htmltools::tags$div(class = "ar-row-group",
      htmltools::tags$div(class = "ar-form-group",
        htmltools::tags$label(class = "ar-form-label", "Page By"),
        shiny::selectInput(ns("page_by"), NULL,
          choices = c("(none)" = ""), selected = "", width = "100%")
      ),
      htmltools::tags$div(class = "ar-row-group__option",
        shiny::checkboxInput(ns("page_by_bold"), "Bold page-by label", value = FALSE)
      )
    ),

    # Indent By — with Repeat Columns below
    htmltools::tags$div(class = "ar-row-group",
      htmltools::tags$div(class = "ar-form-group",
        htmltools::tags$label(class = "ar-form-label", "Indent By"),
        shiny::selectInput(ns("indent_by"), NULL,
          choices = c("(none)" = ""), selected = "", width = "100%")
      )
    ),

    # Repeat Columns
    htmltools::tags$div(class = "ar-row-group",
      htmltools::tags$div(class = "ar-form-group",
        htmltools::tags$label(class = "ar-form-label", "Repeat Columns"),
        shiny::selectInput(ns("repeat_cols"), NULL,
          choices = c("(none)" = ""), selected = "",
          multiple = TRUE, width = "100%")
      )
    ),

    # Wrap long text — prominent standalone option
    htmltools::tags$div(class = "ar-row-group ar-row-group--wrap",
      shiny::checkboxInput(ns("wrap"), "Wrap long text", value = FALSE)
    )
  )
}

mod_rows_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    # Update column choices when ARD changes
    shiny::observe({
      ard <- store$ard
      if (is.null(ard)) return()
      col_choices <- c("(none)" = "", stats::setNames(names(ard), names(ard)))
      shiny::updateSelectInput(session, "group_by", choices = col_choices,
        selected = store$fmt$rows$group_by %||% "")
      shiny::updateSelectInput(session, "page_by", choices = col_choices,
        selected = store$fmt$rows$page_by %||% "")
      shiny::updateSelectInput(session, "indent_by", choices = col_choices,
        selected = store$fmt$rows$indent_by %||% "")
      shiny::updateSelectInput(session, "repeat_cols", choices = col_choices,
        selected = store$fmt$rows$repeat_cols %||% "")
    })

    # Init from store (re-fires on store$fmt changes)
    shiny::observe({
      rows <- store$fmt$rows
      if (!is.null(rows$blank_after)) shiny::updateCheckboxInput(session, "blank_after",
        value = !is.null(rows$blank_after))
      if (!is.null(rows$wrap)) shiny::updateCheckboxInput(session, "wrap", value = rows$wrap)
      if (!is.null(rows$page_by_bold)) shiny::updateCheckboxInput(session, "page_by_bold", value = rows$page_by_bold)
    })

    # get_draft: return current rows config
    get_draft <- function() {
      group_val <- shiny::isolate(input$group_by) %||% ""
      page_val <- shiny::isolate(input$page_by) %||% ""
      indent_val <- shiny::isolate(input$indent_by) %||% ""
      repeat_val <- shiny::isolate(input$repeat_cols)
      blank_after_val <- shiny::isolate(input$blank_after) %||% FALSE

      list(
        group_by = if (nzchar(group_val)) group_val else NULL,
        blank_after = if (blank_after_val && nzchar(group_val)) group_val else NULL,
        page_by = if (nzchar(page_val)) page_val else NULL,
        page_by_bold = shiny::isolate(input$page_by_bold) %||% FALSE,
        indent_by = if (nzchar(indent_val)) indent_val else NULL,
        wrap = shiny::isolate(input$wrap) %||% FALSE,
        repeat_cols = if (length(repeat_val) > 0 && any(nzchar(repeat_val)))
          repeat_val[nzchar(repeat_val)] else NULL
      )
    }

    return(get_draft)
  })
}
