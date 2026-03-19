# Module: Titles & Footnotes — Per-title align/bold, footnote separator/placement
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_titles_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Title lines — compact header with inline +Add
    htmltools::tags$div(class = "ar-section-header",
      htmltools::tags$span(class = "ar-section-header__label", "Titles"),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn--xs",
        onclick = paste0("Shiny.setInputValue('", ns("add_title"), "', Math.random(), {priority: 'event'})"),
        htmltools::tags$i(class = "fa fa-plus", style = "font-size: 9px; margin-right: 2px;"), "Add"
      )
    ),
    shiny::uiOutput(ns("title_inputs")),

    # Footnotes — compact header with inline +Add
    htmltools::tags$div(class = "ar-section-header ar-mt-12",
      htmltools::tags$span(class = "ar-section-header__label", "Footnotes"),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn--xs",
        onclick = paste0("Shiny.setInputValue('", ns("add_fn"), "', Math.random(), {priority: 'event'})"),
        htmltools::tags$i(class = "fa fa-plus", style = "font-size: 9px; margin-right: 2px;"), "Add"
      )
    ),
    shiny::uiOutput(ns("fn_inputs")),

    # Footnote options — static DOM, toggled via shinyjs
    htmltools::tags$div(id = ns("fn_options_wrap"), class = "ar-fn-options",
      style = "display: none;",
      htmltools::tags$div(class = "ar-fn-options__page",
        shiny::selectInput(ns("fn_placement"), NULL,
          choices = c("Every page" = "every", "Last page" = "last"),
          selected = "every", width = "120px")
      ),
      shiny::checkboxInput(ns("fn_separator"), "Separator", value = FALSE)
    )
  )
}

mod_titles_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive list of titles — each: list(text, align, bold)
    titles_rv <- shiny::reactiveVal(list())
    # Reactive list of footnotes — each: list(text)
    fns_rv <- shiny::reactiveVal(list())

    # Initialize from store (re-fires when store$fmt changes, e.g., preset/template)
    shiny::observe({
      titles <- store$fmt$titles
      if (length(titles) > 0) {
        normalized <- lapply(titles, function(t) {
          if (is.list(t)) {
            list(text = t$text %||% "", align = t$align %||% "center", bold = isTRUE(t$bold))
          } else {
            list(text = as.character(t), align = "center", bold = FALSE)
          }
        })
        titles_rv(normalized)
      }
      fns <- store$fmt$footnotes
      if (length(fns) > 0) {
        normalized <- lapply(fns, function(f) {
          if (is.list(f)) list(text = f$text %||% "") else list(text = as.character(f))
        })
        fns_rv(normalized)
      }
      if (!is.null(store$fmt$fn_separator))
        shiny::updateCheckboxInput(session, "fn_separator", value = store$fmt$fn_separator)
      if (!is.null(store$fmt$fn_placement))
        shiny::updateSelectInput(session, "fn_placement", selected = store$fmt$fn_placement)
    })

    # ── Add title ──
    shiny::observeEvent(input$add_title, {
      current <- titles_rv()
      if (length(current) < 5) {
        titles_rv(c(current, list(list(text = "", align = "center", bold = FALSE))))
      }
    })

    # ── Remove title ──
    shiny::observeEvent(input$rm_title, {
      idx <- as.integer(input$rm_title)
      current <- titles_rv()
      if (idx >= 1 && idx <= length(current)) {
        current[[idx]] <- NULL
        titles_rv(current)
      }
    })

    # ── Add footnote ──
    shiny::observeEvent(input$add_fn, {
      current <- fns_rv()
      if (length(current) < 10) {
        fns_rv(c(current, list(list(text = ""))))
      }
    })

    # ── Remove footnote ──
    shiny::observeEvent(input$rm_fn, {
      idx <- as.integer(input$rm_fn)
      current <- fns_rv()
      if (idx >= 1 && idx <= length(current)) {
        current[[idx]] <- NULL
        fns_rv(current)
      }
    })

    # ── Render title inputs ──
    output$title_inputs <- shiny::renderUI({
      titles <- titles_rv()
      if (length(titles) == 0) return(NULL)

      lapply(seq_along(titles), function(i) {
        t <- titles[[i]]
        val <- t$text %||% ""
        bold_val <- isTRUE(t$bold)
        align_val <- t$align %||% "center"

        htmltools::tags$div(class = "ar-title-row ar-mb-8",
          htmltools::tags$div(class = "ar-title-row__text",
            shiny::textInput(ns(paste0("title_", i)), NULL, value = val, width = "100%",
                             placeholder = paste0("Title line ", i))
          ),
          htmltools::tags$div(class = "ar-title-row__controls",
            htmltools::tags$div(class = "ar-inline-radio",
              htmltools::tags$label(class = "ar-inline-radio__opt",
                title = "Left",
                htmltools::tags$input(type = "radio", name = ns(paste0("talign_", i)),
                  value = "left", checked = if (align_val == "left") NA else NULL,
                  onchange = paste0("Shiny.setInputValue('", ns(paste0("talign_", i)), "', 'left')")),
                htmltools::tags$i(class = "fa fa-align-left", style = "font-size: 10px;")
              ),
              htmltools::tags$label(class = "ar-inline-radio__opt",
                title = "Center",
                htmltools::tags$input(type = "radio", name = ns(paste0("talign_", i)),
                  value = "center", checked = if (align_val == "center") NA else NULL,
                  onchange = paste0("Shiny.setInputValue('", ns(paste0("talign_", i)), "', 'center')")),
                htmltools::tags$i(class = "fa fa-align-center", style = "font-size: 10px;")
              ),
              htmltools::tags$label(class = "ar-inline-radio__opt",
                title = "Right",
                htmltools::tags$input(type = "radio", name = ns(paste0("talign_", i)),
                  value = "right", checked = if (align_val == "right") NA else NULL,
                  onchange = paste0("Shiny.setInputValue('", ns(paste0("talign_", i)), "', 'right')")),
                htmltools::tags$i(class = "fa fa-align-right", style = "font-size: 10px;")
              )
            ),
            htmltools::tags$label(class = "ar-inline-check", title = "Bold",
              htmltools::tags$input(type = "checkbox",
                checked = if (bold_val) NA else NULL,
                onchange = paste0("Shiny.setInputValue('", ns(paste0("tbold_", i)),
                  "', this.checked, {priority: 'event'})")),
              htmltools::tags$span(class = "ar-text-sm", style = "font-weight: 700;", "B")
            ),
            htmltools::tags$button(
              class = "ar-btn-ghost",
              onclick = paste0("Shiny.setInputValue('", ns("rm_title"), "', '", i, "', {priority: 'event'})"),
              htmltools::tags$i(class = "fa fa-times", style = "font-size: 11px; color: var(--fg-muted);")
            )
          )
        )
      })
    })

    # ── Render footnote inputs ──
    output$fn_inputs <- shiny::renderUI({
      fns <- fns_rv()
      if (length(fns) == 0) return(NULL)

      lapply(seq_along(fns), function(i) {
        val <- fns[[i]]$text %||% ""

        htmltools::tags$div(class = "ar-fn-row",
          shiny::textInput(ns(paste0("fn_", i)), NULL, value = val, width = "100%",
                           placeholder = paste0("Footnote ", i)),
          htmltools::tags$button(
            class = "ar-btn-ghost ar-btn--xs",
            onclick = paste0("Shiny.setInputValue('", ns("rm_fn"), "', '", i, "', {priority: 'event'})"),
            htmltools::tags$i(class = "fa fa-times", style = "font-size: 10px; color: var(--fg-muted);")
          )
        )
      })
    })

    # ── Toggle footnote options visibility ──
    shiny::observe({
      shinyjs::toggle("fn_options_wrap", condition = length(fns_rv()) > 0)
    })

    # ── get_draft: return current input state as plain list ──
    get_draft <- function() {
      titles <- shiny::isolate(titles_rv())
      n <- length(titles)
      title_list <- if (n == 0) list() else {
        lapply(seq_len(n), function(i) {
          list(
            text = shiny::isolate(input[[paste0("title_", i)]]) %||% titles[[i]]$text %||% "",
            bold = shiny::isolate(input[[paste0("tbold_", i)]]) %||% titles[[i]]$bold %||% FALSE,
            align = shiny::isolate(input[[paste0("talign_", i)]]) %||% titles[[i]]$align %||% "center"
          )
        })
      }
      fns <- shiny::isolate(fns_rv())
      fn_n <- length(fns)
      fn_list <- if (fn_n == 0) list() else {
        lapply(seq_len(fn_n), function(i) {
          list(text = shiny::isolate(input[[paste0("fn_", i)]]) %||% fns[[i]]$text %||% "")
        })
      }
      list(
        titles = title_list,
        footnotes = fn_list,
        fn_separator = shiny::isolate(input$fn_separator) %||% FALSE,
        fn_placement = shiny::isolate(input$fn_placement) %||% "every"
      )
    }

    return(get_draft)
  })
}
