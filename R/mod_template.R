# Module: Template — Table/Figure/Listing type selection from registry (canvas grid layout)

mod_template_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Search bar
    htmltools::tags$div(class = "ar-tmpl-search-wrap ar-mb-12",
      htmltools::tags$input(
        type = "text", id = ns("tmpl_search"),
        class = "ar-input ar-tmpl-search", placeholder = "Search templates...",
        oninput = paste0(
          "var q = this.value.toLowerCase();",
          "document.querySelectorAll('.ar-tmpl-card--canvas').forEach(function(c){",
          "  var name = (c.getAttribute('data-name') || '').toLowerCase();",
          "  var desc = (c.getAttribute('data-desc') || '').toLowerCase();",
          "  c.style.display = (name.indexOf(q) >= 0 || desc.indexOf(q) >= 0) ? '' : 'none';",
          "});",
          "document.querySelectorAll('.ar-tmpl-group').forEach(function(g){",
          "  var visible = g.querySelectorAll('.ar-tmpl-card--canvas:not([style*=\"display: none\"])');",
          "  g.style.display = visible.length > 0 ? '' : 'none';",
          "});"
        )
      )
    ),
    # Cards rendered from registry in grid
    shiny::uiOutput(ns("template_cards"))
  )
}

mod_template_server <- function(id, store, grp) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Render template cards from registry, grouped by category — canvas grid
    output$template_cards <- shiny::renderUI({
      registry <- Filter(function(t) isTRUE(t$enabled), template_registry())
      categories <- unique(vapply(registry, function(t) t$category, character(1)))
      loaded_ds <- names(store$datasets)

      card_groups <- lapply(categories, function(cat) {
        templates <- Filter(function(t) t$category == cat, registry)
        if (length(templates) == 0) return(NULL)

        cards <- lapply(templates, function(t) {
          required <- if (is.character(t$adam_required)) t$adam_required else "adsl"
          has_data <- all(required %in% loaded_ds) || length(loaded_ds) > 0
          is_active <- identical(store$template, t$id)

          output_type <- fct_template_output_type(t$id)
          type_label <- tools::toTitleCase(output_type)

          cls <- paste0("ar-tmpl-card--canvas",
                        if (is_active) " active" else "")

          htmltools::tags$div(
            class = cls,
            `data-name` = t$name,
            `data-desc` = t$description,
            onclick = paste0("Shiny.setInputValue('", ns("select_tmpl"), "', '", t$id, "', {priority: 'event'})"),
            htmltools::tags$div(class = "ar-tmpl-card--canvas__icon",
              htmltools::tags$i(class = paste("fa", t$icon))),
            htmltools::tags$div(class = "ar-tmpl-card--canvas__body",
              htmltools::tags$div(class = "ar-tmpl-card--canvas__name", t$name),
              htmltools::tags$div(class = "ar-tmpl-card--canvas__desc", t$description)
            ),
            {
              ds_chips <- lapply(required, function(ds) {
                loaded <- ds %in% loaded_ds
                icon_html <- if (loaded) "\u2713" else "\u25cb"
                htmltools::tags$span(
                  class = paste0("ar-ds-chip", if (loaded) " ar-ds-chip--loaded" else " ar-ds-chip--missing"),
                  htmltools::tags$span(class = "ar-ds-chip__icon", icon_html),
                  toupper(ds)
                )
              })
              htmltools::tags$div(class = "ar-tmpl-card--canvas__footer",
                htmltools::tags$span(class = "ar-tmpl-card--canvas__type-badge", type_label),
                htmltools::tags$div(class = "ar-tmpl-card--canvas__datasets", ds_chips)
              )
            }
          )
        })

        htmltools::tags$div(class = "ar-tmpl-group",
          htmltools::tags$div(class = "ar-tmpl-group__header",
            htmltools::tags$span(class = "ar-form-label", toupper(cat)),
            htmltools::tags$span(class = "ar-text-sm ar-text-muted",
              paste0(length(templates), " templates"))
          ),
          htmltools::tags$div(class = "ar-tmpl-grid", cards)
        )
      })

      htmltools::tagList(card_groups)
    })

    # Template selection handler
    shiny::observeEvent(input$select_tmpl, {
      tmpl_id <- input$select_tmpl
      store$template <- tmpl_id
      store$ard <- NULL
      store$figure <- NULL
      store$listing <- NULL

      # Look up spec function from registry
      tmpl_def <- get_template_def(tmpl_id)
      if (!is.null(tmpl_def) && !is.null(tmpl_def$spec_fn)) {
        spec_fn <- tryCatch(get(tmpl_def$spec_fn), error = function(e) NULL)
        if (!is.null(spec_fn)) {
          ds_name <- names(store$datasets)[1] %||% "adsl"
          data <- store$datasets[[ds_name]]
          defaults <- spec_fn(data)

          # Populate grouping if not already set or template changed
          if (!is.null(defaults$grouping)) {
            trt_var <- defaults$grouping$trt_var
            if (!is.null(data) && trt_var %in% names(data)) {
              trt_levels <- sort(unique(data[[trt_var]]))
            } else {
              trt_levels <- character(0)
            }
            grp$trt_var <- trt_var
            grp$trt_levels <- trt_levels
            grp$include_total <- defaults$grouping$include_total %||% TRUE
            grp$analysis_vars <- defaults$grouping$analysis_vars
          }

          # Populate var_configs
          if (!is.null(defaults$var_configs)) {
            store$var_configs <- defaults$var_configs
          }

          # Populate fig_configs for figures
          if (!is.null(defaults$fig_configs)) {
            store$fig_configs <- defaults$fig_configs
          }

          # Populate format defaults (merge with schema defaults for missing fields)
          if (!is.null(defaults$fmt)) {
            store$fmt <- normalize_fmt(defaults$fmt)
          }
        }
      }

      store$pipeline_state$template <- TRUE
      tmpl_name <- if (!is.null(tmpl_def)) tmpl_def$name else tmpl_id
      session$sendCustomMessage("ar_toast",
        list(message = paste0(tmpl_name, " template selected"), type = "success"))
    })
  })
}
