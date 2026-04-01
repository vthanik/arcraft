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

          is_placeholder <- is.null(t$spec_fn)
          cls <- paste0("ar-tmpl-card--canvas",
                        if (is_active) " active" else "",
                        if (is_placeholder) " ar-tmpl-card--canvas--placeholder" else "")

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
      store$raw_ard <- NULL
      store$figure <- NULL
      store$listing <- NULL
      store$added_levels <- list()
      store$var_labels <- list()
      store$extra_vars <- character(0)

      # Look up spec function from registry
      tmpl_def <- get_template_def(tmpl_id)
      if (!is.null(tmpl_def) && is.null(tmpl_def$spec_fn)) {
        store$template <- tmpl_id
        store$pipeline_state$template <- TRUE
        session$sendCustomMessage("ar_toast",
          list(message = paste0(tmpl_def$name, " \u2014 coming soon"), type = "info"))
        return()
      }
      # Check if required datasets are loaded — warn if missing
      if (!is.null(tmpl_def)) {
        required_ds <- tmpl_def$adam_required %||% "adsl"
        missing_ds <- setdiff(required_ds, names(store$datasets))
        if (length(missing_ds) > 0) {
          session$sendCustomMessage("ar_toast",
            list(message = paste0("Load dataset: ", paste(toupper(missing_ds), collapse = ", ")),
                 type = "warning"))
        }
      }

      if (!is.null(tmpl_def) && !is.null(tmpl_def$spec_fn)) {
        spec_fn <- tryCatch(get(tmpl_def$spec_fn), error = function(e) NULL)
        if (!is.null(spec_fn)) {
          var_ds <- fct_template_var_dataset(tmpl_id)
          ds_name <- if (var_ds %in% names(store$datasets)) var_ds else names(store$datasets)[1] %||% "adsl"
          data <- store$datasets[[ds_name]]
          defaults <- spec_fn(data)

          # Update pipeline dataset to the template's primary dataset
          store$pipeline_filters$dataset <- ds_name

          # Treatment var lives in ADSL, not necessarily the analysis dataset
          adsl <- store$datasets[["adsl"]]
          trt_data <- if (!is.null(adsl)) adsl else data

          # Populate grouping
          if (!is.null(defaults$grouping)) {
            trt_var <- defaults$grouping$trt_var
            if (!is.null(trt_data) && trt_var %in% names(trt_data)) {
              pop_flag <- defaults$grouping$pop_flag %||% "SAFFL"
              trt_filtered <- apply_pop_filter(trt_data, pop_flag)
              trt_levels <- sort(unique(trt_filtered[[trt_var]]))
              trt_levels <- trt_levels[!is.na(trt_levels) & nzchar(trt_levels)]
            } else {
              trt_levels <- character(0)
            }
            grp$trt_var <- trt_var
            grp$trt_levels <- trt_levels
            grp$include_total <- defaults$grouping$include_total %||% TRUE

            # For BDS/response templates: use selected_params as analysis_vars
            if (fct_suggests_paramcds(tmpl_id)) {
              grp$analysis_vars <- defaults$grouping$selected_params %||%
                                   defaults$grouping$analysis_vars
            } else {
              grp$analysis_vars <- defaults$grouping$analysis_vars
            }

            # Store population flag
            store$pipeline_filters$pop_flag <- defaults$grouping$pop_flag %||%
                                                store$pipeline_filters$pop_flag %||% "SAFFL"
          }

          # Populate var_configs (demographics/AE) or param_configs (BDS) or category_configs (response)
          if (!is.null(defaults$var_configs)) {
            store$var_configs <- defaults$var_configs
          }
          if (!is.null(defaults$param_configs)) {
            store$param_configs <- defaults$param_configs
          }
          if (!is.null(defaults$stat_config)) {
            store$stat_config <- defaults$stat_config
          }
          if (!is.null(defaults$visit_configs)) {
            store$visit_configs <- defaults$visit_configs
          }
          if (!is.null(defaults$analysis_cols)) {
            store$analysis_cols <- defaults$analysis_cols
          }
          if (!is.null(defaults$visit_var)) {
            store$visit_var <- defaults$visit_var
          }
          if (!is.null(defaults$category_configs)) {
            store$category_configs <- defaults$category_configs
          }
          if (!is.null(defaults$format_config)) {
            store$format_config <- defaults$format_config
          }
          if (!is.null(defaults$comparison)) {
            store$comparison <- defaults$comparison
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
