# Module: Rows & Pagination — Group by, page by, indent, listing features
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_rows_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Group By
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Row Group"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("group_by"), NULL,
            choices = c("(none)" = ""), selected = "", width = "100%"))
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Row Label"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("group_label"), NULL,
            choices = c("(none)" = ""), selected = "", width = "100%"))
      )
    ),
    htmltools::tags$div(class = "ar-toggle-grid",
      htmltools::tags$div(class = "ar-toggle-grid__item",
        htmltools::tags$span(class = "ar-toggle-grid__label", "Blank after"),
        shiny::radioButtons(ns("blank_after"), NULL,
          choices = c("No" = "no", "Yes" = "yes"),
          selected = "no", inline = TRUE)
      ),
      htmltools::tags$div(class = "ar-toggle-grid__item",
        htmltools::tags$span(class = "ar-toggle-grid__label", "Keep rows"),
        shiny::radioButtons(ns("group_keep"), NULL,
          choices = c("No" = "no", "Yes" = "yes"),
          selected = "yes", inline = TRUE)
      )
    ),

    # Page By
    htmltools::tags$div(class = "ar-section-divider"),
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Page By"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("page_by"), NULL,
            choices = c("(none)" = ""), selected = "", width = "100%"))
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Align"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("page_by_align"), NULL,
            choices = c("Left" = "left", "Center" = "center", "Right" = "right"),
            selected = "left", width = "100%"))
      )
    ),
    htmltools::tags$div(class = "ar-toggle-grid",
      htmltools::tags$div(class = "ar-toggle-grid__item",
        htmltools::tags$span(class = "ar-toggle-grid__label", "Bold label"),
        shiny::radioButtons(ns("page_by_bold"), NULL,
          choices = c("No" = "no", "Yes" = "yes"),
          selected = "no", inline = TRUE)
      ),
      htmltools::tags$div(class = "ar-toggle-grid__item",
        htmltools::tags$span(class = "ar-toggle-grid__label", "Show value"),
        shiny::radioButtons(ns("page_by_visible"), NULL,
          choices = c("No" = "no", "Yes" = "yes"),
          selected = "yes", inline = TRUE)
      )
    ),

    # Indent + Repeat
    htmltools::tags$div(class = "ar-section-divider"),
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Indent By"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("indent_by"), NULL,
            choices = c("(none)" = ""), selected = "", width = "100%"))
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Repeat Cols"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("repeat_cols"), NULL,
            choices = c("(none)" = ""), selected = "",
            multiple = TRUE, width = "100%"))
      )
    ),

    # Sort & Display
    htmltools::tags$details(class = "ar-disclosure",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Sort & Display"),
      htmltools::tags$div(class = "ar-disclosure__body",
        htmltools::tags$div(class = "ar-props",
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Sort By"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::selectInput(ns("sort_by"), NULL,
                choices = c("(none)" = ""), selected = "",
                multiple = TRUE, width = "100%"))
          ),
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Wrap"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::radioButtons(ns("wrap"), NULL,
                choices = c("No" = "no", "Yes" = "yes"),
                selected = "no", inline = TRUE))
          )
        )
      )
    )
  )
}

mod_rows_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    # Update column choices when ARD changes
    shiny::observe({
      ard <- store$ard
      if (is.null(ard)) return()
      # Include ALL ARD columns (including meta columns like variable, var_label, etc.)
      all_cols <- names(ard)
      col_choices <- c("(none)" = "", stats::setNames(all_cols, all_cols))
      shiny::updateSelectInput(session, "group_by", choices = col_choices,
        selected = store$fmt$rows$group_by %||% "")
      shiny::updateSelectInput(session, "group_label", choices = col_choices,
        selected = store$fmt$rows$group_label %||% "")
      shiny::updateSelectInput(session, "page_by", choices = col_choices,
        selected = store$fmt$rows$page_by %||% "")
      shiny::updateSelectInput(session, "indent_by", choices = col_choices,
        selected = store$fmt$rows$indent_by %||% "")
      shiny::updateSelectInput(session, "repeat_cols", choices = col_choices,
        selected = store$fmt$rows$repeat_cols %||% "")
      shiny::updateSelectInput(session, "sort_by", choices = col_choices,
        selected = store$fmt$rows$sort_by %||% "")
    })

    # Init from store (re-fires on store$fmt changes)
    shiny::observe({
      rows <- store$fmt$rows
      shiny::updateRadioButtons(session, "blank_after",
        selected = if (!is.null(rows$blank_after)) "yes" else "no")
      shiny::updateRadioButtons(session, "wrap",
        selected = if (isTRUE(rows$wrap)) "yes" else "no")
      shiny::updateRadioButtons(session, "page_by_bold",
        selected = if (isTRUE(rows$page_by_bold)) "yes" else "no")
      shiny::updateRadioButtons(session, "group_keep",
        selected = if (isTRUE(rows$group_keep %||% TRUE)) "yes" else "no")
      shiny::updateRadioButtons(session, "page_by_visible",
        selected = if (isTRUE(rows$page_by_visible %||% TRUE)) "yes" else "no")
      if (!is.null(rows$page_by_align)) shiny::updateSelectInput(session, "page_by_align", selected = rows$page_by_align)
    })

    # get_draft: return current rows config
    get_draft <- function() {
      group_val <- shiny::isolate(input$group_by) %||% ""
      group_label_val <- shiny::isolate(input$group_label) %||% ""
      page_val <- shiny::isolate(input$page_by) %||% ""
      indent_val <- shiny::isolate(input$indent_by) %||% ""
      repeat_val <- shiny::isolate(input$repeat_cols)
      sort_val <- shiny::isolate(input$sort_by)
      blank_yes <- identical(shiny::isolate(input$blank_after), "yes")

      list(
        group_by = if (nzchar(group_val)) group_val else NULL,
        group_label = if (nzchar(group_label_val)) group_label_val else NULL,
        group_keep = identical(shiny::isolate(input$group_keep), "yes"),
        blank_after = if (blank_yes && nzchar(group_val)) group_val else NULL,
        page_by = if (nzchar(page_val)) page_val else NULL,
        page_by_bold = identical(shiny::isolate(input$page_by_bold), "yes"),
        page_by_align = shiny::isolate(input$page_by_align) %||% "left",
        page_by_visible = identical(shiny::isolate(input$page_by_visible) %||% "yes", "yes"),
        indent_by = if (nzchar(indent_val)) indent_val else NULL,
        wrap = identical(shiny::isolate(input$wrap), "yes"),
        repeat_cols = if (length(repeat_val) > 0 && any(nzchar(repeat_val)))
          repeat_val[nzchar(repeat_val)] else NULL,
        sort_by = if (length(sort_val) > 0 && any(nzchar(sort_val)))
          sort_val[nzchar(sort_val)] else NULL
      )
    }

    return(get_draft)
  })
}
