# Module: Page Output — Merged page layout, rules, chrome, spacing, and output format
# Combines mod_page.R + mod_rules.R + mod_page_chrome.R into a single module.
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_page_output_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(

    # ── PAGE LAYOUT (always visible) ──
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Orientation"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::radioButtons(ns("orientation"), NULL,
            choices = c("Landscape" = "landscape", "Portrait" = "portrait"),
            selected = "landscape", inline = TRUE)
        )
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Paper"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("paper"), NULL,
            choices = c("US Letter" = "letter", "A4" = "a4", "Legal" = "legal"),
            selected = "letter", width = "100%")
        )
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Font"),
        htmltools::tags$div(class = "ar-prop__value ar-prop__split",
          shiny::selectInput(ns("font_family"), NULL,
            choices = c("Courier New", "Times New Roman", "Arial"),
            selected = "Courier New", width = "100%"),
          shiny::numericInput(ns("font_size"), NULL, value = 9,
            min = 6, max = 14, step = 1, width = "100%")
        )
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Margins"),
        htmltools::tags$div(class = "ar-prop__value ar-margin-grid",
          shiny::numericInput(ns("margin_top"), "T", value = 1,
            min = 0.5, max = 3, step = 0.25, width = "100%"),
          shiny::numericInput(ns("margin_right"), "R", value = 1,
            min = 0.5, max = 3, step = 0.25, width = "100%"),
          shiny::numericInput(ns("margin_bottom"), "B", value = 1,
            min = 0.5, max = 3, step = 0.25, width = "100%"),
          shiny::numericInput(ns("margin_left"), "L", value = 1,
            min = 0.5, max = 3, step = 0.25, width = "100%")
        )
      )
    ),

    # ── RULES (disclosure, default closed) ──
    htmltools::tags$details(class = "ar-disclosure",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Rules"),
      htmltools::tags$div(class = "ar-disclosure__body",
        htmltools::tags$div(class = "ar-props",
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Horizontal"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::selectInput(ns("hline_preset"), NULL,
                choices = c("Header only" = "header", "Booktabs" = "booktabs",
                            "Box" = "box", "Open" = "open", "H-sides" = "hsides",
                            "Above" = "above", "Below" = "below", "None" = "void"),
                selected = "header", width = "100%")
            )
          ),
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Vertical"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::selectInput(ns("vline_preset"), NULL,
                choices = c("None" = "none", "Inner" = "inner", "Box" = "box", "All" = "all"),
                selected = "none", width = "100%")
            )
          )
        ),
        # Advanced line style
        htmltools::tags$details(class = "ar-disclosure",
          htmltools::tags$summary(class = "ar-disclosure__trigger", "Line style"),
          htmltools::tags$div(class = "ar-disclosure__body",
            htmltools::tags$div(class = "ar-props",
              htmltools::tags$div(class = "ar-prop",
                htmltools::tags$span(class = "ar-prop__label", "Width"),
                htmltools::tags$div(class = "ar-prop__value",
                  shiny::selectInput(ns("line_width"), NULL,
                    choices = c("Hairline" = "hairline", "Thin" = "thin",
                                "Medium" = "medium", "Thick" = "thick"),
                    selected = "thin", width = "100%")
                )
              ),
              htmltools::tags$div(class = "ar-prop",
                htmltools::tags$span(class = "ar-prop__label", "Color"),
                htmltools::tags$div(class = "ar-prop__value",
                  shiny::textInput(ns("line_color"), NULL, value = "#000000",
                    width = "100%", placeholder = "#000000")
                )
              ),
              htmltools::tags$div(class = "ar-prop",
                htmltools::tags$span(class = "ar-prop__label", "Style"),
                htmltools::tags$div(class = "ar-prop__value",
                  shiny::radioButtons(ns("line_style"), NULL,
                    choices = c("Solid" = "solid", "Dashed" = "dashed", "Dotted" = "dotted"),
                    selected = "solid", inline = TRUE)
                )
              )
            )
          )
        )
      )
    ),

    # ── RUNNING HEADER (disclosure, default closed) ──
    htmltools::tags$details(class = "ar-disclosure",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Running Header"),
      htmltools::tags$div(class = "ar-disclosure__body",
        htmltools::tags$div(class = "ar-section-header",
          htmltools::tags$span(class = "ar-section-header__label", "Header Rows"),
          htmltools::tags$button(
            class = "ar-btn-ghost ar-btn--xs",
            onclick = paste0("Shiny.setInputValue('", ns("add_header"),
              "', Math.random(), {priority: 'event'})"),
            htmltools::tags$i(class = "fa fa-plus ar-icon-xs ar-icon-mr-2"), "Add"
          )
        ),
        shiny::uiOutput(ns("header_rows"))
      )
    ),

    # ── RUNNING FOOTER (disclosure, default closed) ──
    htmltools::tags$details(class = "ar-disclosure",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Running Footer"),
      htmltools::tags$div(class = "ar-disclosure__body",
        htmltools::tags$div(class = "ar-section-header",
          htmltools::tags$span(class = "ar-section-header__label", "Footer Rows"),
          htmltools::tags$button(
            class = "ar-btn-ghost ar-btn--xs",
            onclick = paste0("Shiny.setInputValue('", ns("add_footer"),
              "', Math.random(), {priority: 'event'})"),
            htmltools::tags$i(class = "fa fa-plus ar-icon-xs ar-icon-mr-2"), "Add"
          )
        ),
        shiny::uiOutput(ns("footer_rows")),
        htmltools::tags$div(class = "ar-chrome-hint",
          htmltools::tags$i(class = "fa fa-info-circle ar-icon-sm ar-icon-mr ar-icon-hint"),
          "{thepage}, {total_pages}, {program}, {datetime}"
        )
      )
    ),

    # ── SPACING (disclosure, default closed) ──
    htmltools::tags$details(class = "ar-disclosure",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Spacing"),
      htmltools::tags$div(class = "ar-disclosure__body",
        htmltools::tags$div(class = "ar-spacing-grid",
          htmltools::tags$div(class = "ar-spacing-grid__item",
            htmltools::tags$label(class = "ar-spacing-grid__label", "After titles"),
            shiny::numericInput(ns("titles_after"), NULL, value = 1,
              min = 0, max = 5, step = 1, width = "100%")
          ),
          htmltools::tags$div(class = "ar-spacing-grid__item",
            htmltools::tags$label(class = "ar-spacing-grid__label", "Before footnotes"),
            shiny::numericInput(ns("footnotes_before"), NULL, value = 1,
              min = 0, max = 5, step = 1, width = "100%")
          ),
          htmltools::tags$div(class = "ar-spacing-grid__item",
            htmltools::tags$label(class = "ar-spacing-grid__label", "After header"),
            shiny::numericInput(ns("pagehead_after"), NULL, value = 0,
              min = 0, max = 5, step = 1, width = "100%")
          ),
          htmltools::tags$div(class = "ar-spacing-grid__item",
            htmltools::tags$label(class = "ar-spacing-grid__label", "Before footer"),
            shiny::numericInput(ns("pagefoot_before"), NULL, value = 0,
              min = 0, max = 5, step = 1, width = "100%")
          ),
          htmltools::tags$div(class = "ar-spacing-grid__item",
            htmltools::tags$label(class = "ar-spacing-grid__label", "After page_by"),
            shiny::numericInput(ns("page_by_after"), NULL, value = 1,
              min = 0, max = 5, step = 1, width = "100%")
          )
        )
      )
    ),

    # ── ADVANCED (disclosure, default closed) ──
    htmltools::tags$details(class = "ar-disclosure",
      htmltools::tags$summary(class = "ar-disclosure__trigger", "Advanced"),
      htmltools::tags$div(class = "ar-disclosure__body",
        htmltools::tags$div(class = "ar-props",
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Column gap"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::numericInput(ns("col_gap"), NULL, value = 4,
                min = 0, max = 12, step = 1, width = "100%")
            )
          ),
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Continuation"),
            htmltools::tags$div(class = "ar-prop__value",
              shiny::textInput(ns("continuation"), NULL, value = "",
                width = "100%", placeholder = "(continued)")
            )
          ),
          htmltools::tags$div(class = "ar-prop",
            htmltools::tags$span(class = "ar-prop__label", "Orphan / Widow"),
            htmltools::tags$div(class = "ar-prop__value ar-prop__split ar-prop__split--equal",
              shiny::numericInput(ns("orphan_min"), NULL, value = 3,
                min = 1, max = 10, step = 1, width = "100%"),
              shiny::numericInput(ns("widow_min"), NULL, value = 3,
                min = 1, max = 10, step = 1, width = "100%")
            )
          )
        )
      )
    ),

    # ── OUTPUT FORMAT ──
    htmltools::tags$div(class = "ar-section-divider"),
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Export as"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::radioButtons(ns("output_format"), NULL,
            choices = c("RTF" = "rtf", "PDF" = "pdf", "HTML" = "html"),
            selected = "rtf", inline = TRUE)
        )
      )
    )
  )
}

mod_page_output_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # ── Reactive lists for chrome rows ──
    headers_rv <- shiny::reactiveVal(list())
    footers_rv <- shiny::reactiveVal(list())

    # ── Init from store: page settings ──
    shiny::observe({
      pg <- store$fmt$page
      if (!is.null(pg$orientation))
        shiny::updateRadioButtons(session, "orientation", selected = pg$orientation)
      if (!is.null(pg$paper))
        shiny::updateSelectInput(session, "paper", selected = pg$paper)
      if (!is.null(pg$font_family))
        shiny::updateSelectInput(session, "font_family", selected = pg$font_family)
      if (!is.null(pg$font_size))
        shiny::updateNumericInput(session, "font_size", value = pg$font_size)
      if (!is.null(pg$margins) && length(pg$margins) == 4) {
        shiny::updateNumericInput(session, "margin_top", value = pg$margins[1])
        shiny::updateNumericInput(session, "margin_right", value = pg$margins[2])
        shiny::updateNumericInput(session, "margin_bottom", value = pg$margins[3])
        shiny::updateNumericInput(session, "margin_left", value = pg$margins[4])
      }
      if (!is.null(pg$col_gap))
        shiny::updateNumericInput(session, "col_gap", value = pg$col_gap)
      if (!is.null(pg$continuation))
        shiny::updateTextInput(session, "continuation", value = pg$continuation)
      if (!is.null(pg$orphan_min))
        shiny::updateNumericInput(session, "orphan_min", value = pg$orphan_min)
      if (!is.null(pg$widow_min))
        shiny::updateNumericInput(session, "widow_min", value = pg$widow_min)
    })

    # ── Init from store: rules settings ──
    shiny::observe({
      rl <- store$fmt$rules
      if (!is.null(rl$hline_preset))
        shiny::updateSelectInput(session, "hline_preset", selected = rl$hline_preset)
      if (!is.null(rl$vline_preset))
        shiny::updateSelectInput(session, "vline_preset", selected = rl$vline_preset)
      if (!is.null(rl$line_width))
        shiny::updateSelectInput(session, "line_width", selected = rl$line_width)
      if (!is.null(rl$line_color))
        shiny::updateTextInput(session, "line_color", value = rl$line_color)
      if (!is.null(rl$line_style))
        shiny::updateRadioButtons(session, "line_style", selected = rl$line_style)
    })

    # ── Init from store: spacing settings ──
    shiny::observe({
      sp <- store$fmt$spacing
      if (!is.null(sp$titles_after))
        shiny::updateNumericInput(session, "titles_after", value = sp$titles_after)
      if (!is.null(sp$footnotes_before))
        shiny::updateNumericInput(session, "footnotes_before", value = sp$footnotes_before)
      if (!is.null(sp$pagehead_after))
        shiny::updateNumericInput(session, "pagehead_after", value = sp$pagehead_after)
      if (!is.null(sp$pagefoot_before))
        shiny::updateNumericInput(session, "pagefoot_before", value = sp$pagefoot_before)
      if (!is.null(sp$page_by_after))
        shiny::updateNumericInput(session, "page_by_after", value = sp$page_by_after)
    })

    # ── Init from store: output format ──
    shiny::observe({
      of <- store$fmt$output_format
      if (!is.null(of)) shiny::updateRadioButtons(session, "output_format", selected = of)
    })

    # ── Init from store: page chrome (headers/footers) ──
    shiny::observe({
      ph <- store$fmt$pagehead
      if (is.list(ph)) {
        # Support flat list (old) and list-of-rows (new)
        if (!is.null(ph$left) || !is.null(ph$center) || !is.null(ph$right)) {
          if (any(nzchar(c(ph$left, ph$center, ph$right)))) {
            headers_rv(list(list(left = ph$left %||% "", center = ph$center %||% "",
                                 right = ph$right %||% "")))
          }
        } else if (length(ph) > 0 && is.list(ph[[1]])) {
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

    # ── Add/remove header rows ──
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

    # ── Add/remove footer rows ──
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

    # ── Render header rows ──
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
              htmltools::tags$i(class = "fa fa-times ar-icon-sm ar-icon-muted"))
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

    # ── Render footer rows ──
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
              htmltools::tags$i(class = "fa fa-times ar-icon-sm ar-icon-muted"))
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

    # ── Single get_draft() returning all sections ──
    get_draft <- function() {
      # Helper: merge dynamic chrome rows into left/center/right strings
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
        page = list(
          orientation = shiny::isolate(input$orientation) %||% "landscape",
          paper       = shiny::isolate(input$paper) %||% "letter",
          font_family = shiny::isolate(input$font_family) %||% "Courier New",
          font_size   = shiny::isolate(input$font_size) %||% 9,
          margins     = c(
            shiny::isolate(input$margin_top)    %||% 1,
            shiny::isolate(input$margin_right)  %||% 1,
            shiny::isolate(input$margin_bottom) %||% 1,
            shiny::isolate(input$margin_left)   %||% 1
          ),
          col_gap      = shiny::isolate(input$col_gap) %||% 4,
          continuation = shiny::isolate(input$continuation) %||% "",
          orphan_min   = shiny::isolate(input$orphan_min) %||% 3L,
          widow_min    = shiny::isolate(input$widow_min) %||% 3L
        ),
        rules = list(
          hline_preset = shiny::isolate(input$hline_preset) %||% "header",
          vline_preset = shiny::isolate(input$vline_preset) %||% "none",
          line_width   = shiny::isolate(input$line_width) %||% "thin",
          line_color   = shiny::isolate(input$line_color) %||% "#000000",
          line_style   = shiny::isolate(input$line_style) %||% "solid"
        ),
        pagehead = merge_rows("ph_", shiny::isolate(headers_rv())),
        pagefoot = merge_rows("pf_", shiny::isolate(footers_rv())),
        spacing = list(
          titles_after    = shiny::isolate(input$titles_after) %||% 1L,
          footnotes_before = shiny::isolate(input$footnotes_before) %||% 1L,
          pagehead_after  = shiny::isolate(input$pagehead_after) %||% 0L,
          pagefoot_before = shiny::isolate(input$pagefoot_before) %||% 0L,
          page_by_after   = shiny::isolate(input$page_by_after) %||% 1L
        ),
        output_format = shiny::isolate(input$output_format) %||% "rtf"
      )
    }

    return(get_draft)
  })
}
