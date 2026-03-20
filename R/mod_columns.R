# Module: Columns — Per-column disclosure accordion
# Shows ALL ARD columns classified as STUB/BY/DATA with collapsible per-column config.
# Non-reactive draft: no per-input sync to store. Returns get_draft() function.

mod_columns_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Global defaults
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Width"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("width_mode"), NULL,
            choices = c("Auto" = "auto", "Fit to page" = "fit", "Equal" = "equal"),
            selected = "auto", width = "100%"))
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Indent"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::radioButtons(ns("spaces"), NULL,
            choices = c("Indent" = "indent", "Preserve" = "preserve"),
            selected = "indent", inline = TRUE))
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Split"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::radioButtons(ns("split"), NULL,
            choices = c("No" = "no", "Yes" = "yes"),
            selected = "no", inline = TRUE))
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Default Align"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("default_align"), NULL,
            choices = c("Left" = "left", "Center" = "center",
                        "Right" = "right", "Decimal" = "decimal"),
            selected = "center", width = "100%"))
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Stub Width (in)"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::numericInput(ns("stub_width"), NULL,
            value = 2.5, min = 0.5, max = 5, step = 0.25, width = "100%"))
      ),
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Stub Align"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::selectInput(ns("stub_align"), NULL,
            choices = c("Left" = "left", "Center" = "center", "Right" = "right"),
            selected = "left", width = "100%"))
      )
    ),

    # N counts
    htmltools::tags$div(class = "ar-section-divider"),
    htmltools::tags$div(class = "ar-props",
      htmltools::tags$div(class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "N counts"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::radioButtons(ns("n_counts"), NULL,
            choices = c("Show" = "show", "Hide" = "hide"),
            selected = "show", inline = TRUE))
      ),
      htmltools::tags$div(id = ns("n_format_wrap"), class = "ar-prop",
        htmltools::tags$span(class = "ar-prop__label", "Format"),
        htmltools::tags$div(class = "ar-prop__value",
          shiny::textInput(ns("n_format"), NULL,
            value = "{label}\\n(N={n})", width = "100%"))
      )
    ),

    # Column list (disclosure accordion)
    htmltools::tags$div(class = "ar-section-divider"),
    shiny::uiOutput(ns("col_list"))
  )
}

mod_columns_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Init from store
    shiny::observe({
      cols <- store$fmt$cols
      if (!is.null(cols$width_mode)) shiny::updateSelectInput(session, "width_mode", selected = cols$width_mode)
      if (!is.null(cols$n_counts)) {
        shiny::updateRadioButtons(session, "n_counts", selected = if (isTRUE(cols$n_counts)) "show" else "hide")
      }
      if (!is.null(cols$n_format)) shiny::updateTextInput(session, "n_format", value = cols$n_format)
      if (!is.null(cols$spaces)) shiny::updateRadioButtons(session, "spaces", selected = cols$spaces)
      if (!is.null(cols$split)) {
        shiny::updateRadioButtons(session, "split", selected = if (isTRUE(cols$split)) "yes" else "no")
      }
      if (!is.null(cols$default_align)) shiny::updateSelectInput(session, "default_align", selected = cols$default_align)
      if (!is.null(cols$stub_width)) shiny::updateNumericInput(session, "stub_width", value = cols$stub_width)
      if (!is.null(cols$stub_align)) shiny::updateSelectInput(session, "stub_align", selected = cols$stub_align)
    })

    # Toggle N format visibility
    shiny::observe({
      show <- identical(input$n_counts, "show")
      session$sendCustomMessage("ar_toggle", list(id = ns("n_format_wrap"), show = show))
    })

    # Classify columns from ARD
    classify_col <- function(col_name, ard) {
      if (col_name == "stat_label") return("stub")
      if (col_name == "group_value") return("by")
      meta_cols <- c("variable", "var_label", "var_type", "row_type",
                     "timepoint", "baseline_category", "post_category")
      if (col_name %in% meta_cols) return("meta")
      # Treatment/data columns — never stub
      "data"
    }

    # Get ALL ARD columns with classification
    get_all_cols <- function() {
      ard <- store$ard
      if (is.null(ard)) return(NULL)
      cols <- names(ard)
      types <- vapply(cols, function(c) classify_col(c, ard), character(1))
      list(names = cols, types = stats::setNames(types, cols))
    }

    # Column list — per-column disclosure rows
    output$col_list <- shiny::renderUI({
      col_info <- get_all_cols()
      if (is.null(col_info)) {
        return(htmltools::tags$div(class = "ar-empty-state ar-empty-state--padded",
          htmltools::tags$div(class = "ar-empty-state__hint",
            "Generate preview to configure columns")
        ))
      }

      per_col <- store$fmt$cols$per_col %||% list()

      # Only show visible columns (stub/by/data — not hidden meta)
      visible_names <- col_info$names[col_info$types != "meta"]

      col_items <- lapply(visible_names, function(col) {
        col_type <- col_info$types[[col]]
        cfg <- per_col[[col]] %||% list()

        # Badge class + text
        badge_cls <- switch(col_type,
          stub = "ar-col-item__badge ar-col-item__badge--stub",
          by = "ar-col-item__badge ar-col-item__badge--by",
          data = "ar-col-item__badge ar-col-item__badge--data",
          "ar-col-item__badge"
        )
        badge_text <- toupper(col_type)

        # Current label preview (right side of collapsed header)
        label_preview <- cfg$label %||% ""
        if (!nzchar(label_preview)) label_preview <- col

        # Visibility state
        is_visible <- cfg$visible %||% TRUE

        # Unique IDs for disclosure
        disc_id <- ns(paste0("disc_", col))
        chk_id <- ns(paste0("col_visible_", col))

        htmltools::tags$div(class = paste0("ar-col-item", if (!is_visible) " ar-col-item--hidden" else ""),
          # Collapsed header (clickable)
          htmltools::tags$div(class = "ar-col-item__header",
            onclick = paste0(
              "var body = document.getElementById('", disc_id, "');",
              "var chevron = this.querySelector('.ar-col-item__chevron');",
              "if (body.classList.contains('ar-col-item__body--open')) {",
              "  body.classList.remove('ar-col-item__body--open');",
              "  chevron.classList.remove('ar-col-item__chevron--open');",
              "} else {",
              "  body.classList.add('ar-col-item__body--open');",
              "  chevron.classList.add('ar-col-item__chevron--open');",
              "}"
            ),
            htmltools::tags$span(class = "ar-col-item__chevron", "\u25b8"),
            htmltools::tags$span(class = "ar-col-item__name", col),
            htmltools::tags$span(class = badge_cls, badge_text),
            htmltools::tags$span(class = "ar-col-item__label-preview", label_preview),
            # Eye toggle — instant visual feedback via JS
            htmltools::tags$label(class = "ar-col-item__vis-toggle",
              onclick = "event.stopPropagation();",
              title = if (is_visible) "Visible" else "Hidden",
              htmltools::tags$input(type = "checkbox",
                checked = if (is_visible) NA else NULL,
                onchange = paste0(
                  "var icon = this.nextElementSibling;",
                  "var row = this.closest('.ar-col-item');",
                  "if (this.checked) {",
                  "  icon.className = 'fa fa-eye';",
                  "  row.classList.remove('ar-col-item--hidden');",
                  "} else {",
                  "  icon.className = 'fa fa-eye-slash';",
                  "  row.classList.add('ar-col-item--hidden');",
                  "}",
                  "Shiny.setInputValue('", chk_id,
                  "', this.checked, {priority: 'event'});")),
              htmltools::tags$i(class = if (is_visible) "fa fa-eye ar-icon-md" else "fa fa-eye-slash ar-icon-md")
            )
          ),
          # Expandable body
          htmltools::tags$div(id = disc_id, class = "ar-col-item__body",
            htmltools::tags$div(class = "ar-col-item__field",
              htmltools::tags$label(class = "ar-col-item__field-label", "Label"),
              shiny::textInput(ns(paste0("col_label_", col)), NULL,
                value = cfg$label %||% "", width = "100%",
                placeholder = col)
            ),
            htmltools::tags$div(class = "ar-col-item__field-row",
              htmltools::tags$div(class = "ar-col-item__field",
                htmltools::tags$label(class = "ar-col-item__field-label", "Width (in)"),
                shiny::numericInput(ns(paste0("col_width_", col)), NULL,
                  value = cfg$width, min = 0.3, max = 8, step = 0.25,
                  width = "100%")
              ),
              htmltools::tags$div(class = "ar-col-item__field",
                htmltools::tags$label(class = "ar-col-item__field-label", "Align"),
                shiny::selectInput(ns(paste0("col_align_", col)), NULL,
                  choices = stats::setNames(
                    c("", "left", "center", "right", "decimal"),
                    c("\u2014", "Left", "Center", "Right", "Decimal")),
                  selected = cfg$align %||% "", width = "100%")
              )
            )
          )
        )
      })

      # Hidden metadata note
      meta_names <- col_info$names[col_info$types == "meta"]
      meta_note <- if (length(meta_names) > 0) {
        htmltools::tags$div(class = "ar-col-item__meta-note",
          htmltools::tags$span(class = "ar-form-label ar-form-label--muted",
            paste0("Hidden: ", paste(meta_names, collapse = ", ")))
        )
      }

      htmltools::tagList(col_items, meta_note)
    })

    # get_draft
    get_draft <- function() {
      per_col <- list()
      col_info <- shiny::isolate(get_all_cols())
      if (!is.null(col_info)) {
        visible_names <- col_info$names[col_info$types != "meta"]
        for (col in visible_names) {
          label_raw <- shiny::isolate(input[[paste0("col_label_", col)]])
          label <- if (!is.null(label_raw)) trimws(label_raw) else NULL
          width <- shiny::isolate(input[[paste0("col_width_", col)]])
          align <- shiny::isolate(input[[paste0("col_align_", col)]])
          visible <- shiny::isolate(input[[paste0("col_visible_", col)]])

          # Determine effective label:
          # - NULL or same as col name = no override (keep default)
          # - empty string (user cleared it) = " " (blank header)
          # - different text = user's custom label
          # Only override label when user explicitly typed something different
          # Empty input = default (no override), not blank header
          # User must type a single space " " to get a blank header
          eff_label <- NULL
          if (!is.null(label_raw) && nzchar(label_raw)) {
            trimmed <- trimws(label_raw)
            if (nzchar(trimmed) && trimmed != col) {
              eff_label <- trimmed  # user typed a custom label
            } else if (!nzchar(trimmed) && nzchar(label_raw)) {
              eff_label <- " "  # user typed only spaces = blank header
            }
          }

          has_change <- !is.null(eff_label) || (!is.null(width) && !is.na(width)) ||
            (!is.null(align) && nzchar(align)) || (!is.null(visible) && !visible)

          if (has_change) {
            entry <- list(
              width = if (!is.null(width) && !is.na(width)) width else NULL,
              align = if (!is.null(align) && nzchar(align)) align else NULL,
              visible = visible %||% TRUE
            )
            if (!is.null(eff_label)) entry$label <- eff_label
            per_col[[col]] <- entry
          }
        }
      }
      list(
        width_mode = shiny::isolate(input$width_mode) %||% "auto",
        default_align = shiny::isolate(input$default_align) %||% "center",
        stub_width = shiny::isolate(input$stub_width) %||% 2.5,
        stub_align = shiny::isolate(input$stub_align) %||% "left",
        n_counts = identical(shiny::isolate(input$n_counts), "show"),
        n_format = shiny::isolate(input$n_format) %||% "{label}\\n(N={n})",
        spaces = shiny::isolate(input$spaces) %||% "indent",
        split = identical(shiny::isolate(input$split), "yes"),
        per_col = per_col
      )
    }

    return(get_draft)
  })
}
