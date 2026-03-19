# Module: Page Chrome — Running page headers/footers (multiple rows, add/remove)
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_page_chrome_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Header rows
    htmltools::tags$div(class = "ar-section-header",
      htmltools::tags$span(class = "ar-section-header__label", "Running Header"),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn--xs",
        onclick = paste0("Shiny.setInputValue('", ns("add_header"), "', Math.random(), {priority: 'event'})"),
        htmltools::tags$i(class = "fa fa-plus", style = "font-size: 9px; margin-right: 2px;"), "Add"
      )
    ),
    shiny::uiOutput(ns("header_rows")),

    # Footer rows
    htmltools::tags$div(class = "ar-section-header ar-mt-12",
      htmltools::tags$span(class = "ar-section-header__label", "Running Footer"),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn--xs",
        onclick = paste0("Shiny.setInputValue('", ns("add_footer"), "', Math.random(), {priority: 'event'})"),
        htmltools::tags$i(class = "fa fa-plus", style = "font-size: 9px; margin-right: 2px;"), "Add"
      )
    ),
    shiny::uiOutput(ns("footer_rows")),

    # Token hint
    htmltools::tags$div(class = "ar-chrome-hint",
      htmltools::tags$i(class = "fa fa-info-circle",
        style = "font-size: 10px; margin-right: 4px; opacity: 0.5;"),
      "{thepage}, {total_pages}, {program}, {datetime}"
    )
  )
}

mod_page_chrome_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive lists — each entry: list(left, center, right)
    headers_rv <- shiny::reactiveVal(list())
    footers_rv <- shiny::reactiveVal(list())

    # Init from store
    shiny::observe({
      ph <- store$fmt$pagehead
      if (is.list(ph)) {
        # Support both old format (flat list) and new format (list of rows)
        if (!is.null(ph$left) || !is.null(ph$center) || !is.null(ph$right)) {
          # Old format — single row
          if (any(nzchar(c(ph$left, ph$center, ph$right)))) {
            headers_rv(list(list(left = ph$left %||% "", center = ph$center %||% "",
                                 right = ph$right %||% "")))
          }
        } else if (length(ph) > 0 && is.list(ph[[1]])) {
          # New format — list of rows
          headers_rv(ph)
        }
      }

      pf <- store$fmt$pagefoot
      if (is.list(pf)) {
        if (!is.null(pf$left) || !is.null(pf$center) || !is.null(pf$right)) {
          if (any(nzchar(c(pf$left, pf$center, pf$right)))) {
            footers_rv(list(list(left = pf$left %||% "", center = pf$center %||% "",
                                  right = pf$right %||% "")))
          }
        } else if (length(pf) > 0 && is.list(pf[[1]])) {
          footers_rv(pf)
        }
      }
    })

    # Add/remove handlers
    shiny::observeEvent(input$add_header, {
      current <- headers_rv()
      if (length(current) < 3) {
        headers_rv(c(current, list(list(left = "", center = "", right = ""))))
      }
    })

    shiny::observeEvent(input$rm_header, {
      idx <- as.integer(input$rm_header)
      current <- headers_rv()
      if (idx >= 1 && idx <= length(current)) {
        current[[idx]] <- NULL
        headers_rv(current)
      }
    })

    shiny::observeEvent(input$add_footer, {
      current <- footers_rv()
      if (length(current) < 3) {
        footers_rv(c(current, list(list(left = "", center = "", right = ""))))
      }
    })

    shiny::observeEvent(input$rm_footer, {
      idx <- as.integer(input$rm_footer)
      current <- footers_rv()
      if (idx >= 1 && idx <= length(current)) {
        current[[idx]] <- NULL
        footers_rv(current)
      }
    })

    # Render header rows
    output$header_rows <- shiny::renderUI({
      rows <- headers_rv()
      if (length(rows) == 0) return(NULL)

      lapply(seq_along(rows), function(i) {
        r <- rows[[i]]
        htmltools::tags$div(class = "ar-chrome-row",
          htmltools::tags$div(class = "ar-chrome-row__bar",
            if (length(rows) > 1) {
              htmltools::tags$span(class = "ar-chrome-row__num", paste0("Row ", i))
            },
            htmltools::tags$button(
              class = "ar-btn-ghost ar-btn--xs",
              onclick = paste0("Shiny.setInputValue('", ns("rm_header"),
                "', '", i, "', {priority: 'event'})"),
              htmltools::tags$i(class = "fa fa-times",
                style = "font-size: 10px; color: var(--fg-muted);"))
          ),
          htmltools::tags$div(class = "ar-chrome-row__fields",
            shiny::textInput(ns(paste0("ph_left_", i)), "Left",
              value = r$left %||% "", width = "100%",
              placeholder = "Protocol ABC-123"),
            shiny::textInput(ns(paste0("ph_center_", i)), "Center",
              value = r$center %||% "", width = "100%"),
            shiny::textInput(ns(paste0("ph_right_", i)), "Right",
              value = r$right %||% "", width = "100%",
              placeholder = "{datetime}")
          )
        )
      })
    })

    # Render footer rows
    output$footer_rows <- shiny::renderUI({
      rows <- footers_rv()
      if (length(rows) == 0) return(NULL)

      lapply(seq_along(rows), function(i) {
        r <- rows[[i]]
        htmltools::tags$div(class = "ar-chrome-row",
          htmltools::tags$div(class = "ar-chrome-row__bar",
            if (length(rows) > 1) {
              htmltools::tags$span(class = "ar-chrome-row__num", paste0("Row ", i))
            },
            htmltools::tags$button(
              class = "ar-btn-ghost ar-btn--xs",
              onclick = paste0("Shiny.setInputValue('", ns("rm_footer"),
                "', '", i, "', {priority: 'event'})"),
              htmltools::tags$i(class = "fa fa-times",
                style = "font-size: 10px; color: var(--fg-muted);"))
          ),
          htmltools::tags$div(class = "ar-chrome-row__fields",
            shiny::textInput(ns(paste0("pf_left_", i)), "Left",
              value = r$left %||% "", width = "100%",
              placeholder = "{program}"),
            shiny::textInput(ns(paste0("pf_center_", i)), "Center",
              value = r$center %||% "", width = "100%"),
            shiny::textInput(ns(paste0("pf_right_", i)), "Right",
              value = r$right %||% "", width = "100%",
              placeholder = "Page {thepage} of {total_pages}")
          )
        )
      })
    })

    # get_draft: merge all rows into single pagehead/pagefoot
    # Multiple rows get joined with \n for each position
    get_draft <- function() {
      merge_rows <- function(prefix, rows) {
        n <- length(rows)
        if (n == 0) return(list(left = "", center = "", right = ""))

        lefts <- vapply(seq_len(n), function(i) {
          shiny::isolate(input[[paste0(prefix, "left_", i)]]) %||%
            rows[[i]]$left %||% ""
        }, character(1))

        centers <- vapply(seq_len(n), function(i) {
          shiny::isolate(input[[paste0(prefix, "center_", i)]]) %||%
            rows[[i]]$center %||% ""
        }, character(1))

        rights <- vapply(seq_len(n), function(i) {
          shiny::isolate(input[[paste0(prefix, "right_", i)]]) %||%
            rows[[i]]$right %||% ""
        }, character(1))

        list(
          left = paste(lefts, collapse = "\n"),
          center = paste(centers, collapse = "\n"),
          right = paste(rights, collapse = "\n")
        )
      }

      list(
        pagehead = merge_rows("ph_", shiny::isolate(headers_rv())),
        pagefoot = merge_rows("pf_", shiny::isolate(footers_rv()))
      )
    }

    return(get_draft)
  })
}
