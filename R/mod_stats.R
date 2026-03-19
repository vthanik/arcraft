# Module: Per-Variable Stats Config — SIGNATURE FEATURE

mod_stats_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::uiOutput(ns("var_cards"))
}

mod_stats_server <- function(id, store, grp) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Track default configs for reset comparison
    default_configs <- shiny::reactiveVal(list())

    # Generate variable cards dynamically
    output$var_cards <- shiny::renderUI({
      vars <- grp$analysis_vars
      if (length(vars) == 0) {
        return(ui_empty_state(
          "No variables selected",
          "Select analysis variables in the Grouping section above.",
          "fa-sliders-h"
        ))
      }

      ds_name <- names(store$datasets)[1]
      data <- store$datasets[[ds_name]]
      req(data)

      # Ensure var_configs exist for all vars
      for (v in vars) {
        if (is.null(store$var_configs[[v]])) {
          vtype <- fct_detect_var_type(data, v)
          if (vtype == "continuous") {
            store$var_configs[[v]] <- list(
              type = "continuous",
              stats = c("n", "mean_sd", "median", "q1_q3", "min_max"),
              decimals = 1
            )
          } else {
            store$var_configs[[v]] <- list(
              type = "categorical",
              cat_format = "npct",
              zero_style = "A",
              pct_dec = 1,
              levels = if (is.factor(data[[v]])) levels(data[[v]])
                       else sort(unique(stats::na.omit(data[[v]])))
            )
          }
        }
      }

      # Save defaults for reset
      default_configs(store$var_configs)

      # Build cards
      cards <- lapply(vars, function(v) {
        config <- store$var_configs[[v]]
        vtype <- config$type %||% fct_detect_var_type(data, v)
        label <- fct_get_var_label(data, v)

        # Summary text for collapsed view
        summary <- if (vtype == "continuous") {
          n_stats <- length(config$stats %||% 5)
          dec <- config$decimals %||% 1
          paste0(n_stats, " stats, ", dec, " dec")
        } else {
          fmt <- switch(config$cat_format %||% "npct",
            npct = "n (%)", n = "n only", nn_pct = "n/N (%)", "n (%)")
          n_levels <- length(config$levels %||% character(0))
          paste0(fmt, ", ", n_levels, " levels")
        }

        # Check if modified — use current template's spec
        tmpl_spec_fn <- tryCatch({
          tmpl_def <- get_template_def(store$template)
          if (!is.null(tmpl_def)) get(tmpl_def$spec_fn) else spec_demog
        }, error = function(e) spec_demog)
        defaults <- tmpl_spec_fn()$var_configs[[v]]
        modified <- !identical(config, defaults)

        # Build card
        card_body <- if (vtype == "continuous") {
          ui_var_card_cont(ns, v, config)
        } else {
          ui_var_card_cat(ns, v, config, config$levels)
        }

        htmltools::tags$div(
          id = ns(paste0("card_", v)),
          class = "ar-var-card",
          ui_var_card_header(ns, v, label, vtype, summary, modified),
          htmltools::tags$div(class = "ar-var-card__body", card_body)
        )
      })

      htmltools::tagList(cards)
    })

    # Observe stat changes for continuous vars
    shiny::observe({
      vars <- grp$analysis_vars
      for (v in vars) {
        local({
          my_var <- v
          # Stats checkboxes
          shiny::observeEvent(input[[paste0("stats_", my_var)]], {
            store$var_configs[[my_var]]$stats <- input[[paste0("stats_", my_var)]]
          }, ignoreNULL = FALSE, ignoreInit = TRUE)

          # Decimals
          shiny::observeEvent(input[[paste0("dec_", my_var)]], {
            store$var_configs[[my_var]]$decimals <- input[[paste0("dec_", my_var)]]
          }, ignoreInit = TRUE)

          # Categorical format
          shiny::observeEvent(input[[paste0("catfmt_", my_var)]], {
            store$var_configs[[my_var]]$cat_format <- input[[paste0("catfmt_", my_var)]]
          }, ignoreInit = TRUE)

          # Categorical pct decimals
          shiny::observeEvent(input[[paste0("catdec_", my_var)]], {
            store$var_configs[[my_var]]$pct_dec <- input[[paste0("catdec_", my_var)]]
          }, ignoreInit = TRUE)

          # Zero style
          shiny::observeEvent(input[[paste0("zero_", my_var)]], {
            store$var_configs[[my_var]]$zero_style <- input[[paste0("zero_", my_var)]]
          }, ignoreInit = TRUE)

          # Reset to default — use current template's spec
          shiny::observeEvent(input[[paste0("reset_", my_var)]], {
            tmpl_spec_fn <- tryCatch({
              tmpl_def <- get_template_def(store$template)
              if (!is.null(tmpl_def)) get(tmpl_def$spec_fn) else spec_demog
            }, error = function(e) spec_demog)
            defaults <- tmpl_spec_fn()$var_configs[[my_var]]
            if (!is.null(defaults)) {
              store$var_configs[[my_var]] <- defaults
              session$sendCustomMessage("ar_toast",
                list(message = paste0(my_var, " reset to defaults"), type = "success"))
            }
          })
        })
      }
    })
  })
}
