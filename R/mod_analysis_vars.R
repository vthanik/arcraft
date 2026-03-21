# Module: Statistics — variable stat config cards (Analysis sidebar)
#
# Architecture: per-variable render isolation
# - Outer container (output$var_cards) renders card SHELLS (header + uiOutput placeholder)
#   Only re-renders when the variable LIST changes (add/remove/reorder)
# - Each card body (output$vcard_body_{var}) renders independently
#   Only re-renders when THAT variable's config changes (stat toggle, level sort, etc.)
# - This prevents editing one variable from wiping in-flight edits on other variables

mod_analysis_vars_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tagList(
    # Dynamic variable cards (sortable container)
    htmltools::tags$div(id = ns("var_cards_sortable"),
      class = "ar-var-cards-sortable",
      shiny::uiOutput(ns("var_cards"))
    )
  )
}

mod_analysis_vars_server <- function(id, store, grp) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    var_list_trigger <- shiny::reactiveVal(0L)
    open_card <- shiny::reactiveVal(NULL)

    # Track previous var set to detect add/remove vs reorder
    prev_analysis_vars <- shiny::reactiveVal(character(0))
    shiny::observe({
      vars <- grp$analysis_vars
      old <- isolate(prev_analysis_vars())
      prev_analysis_vars(vars)
      # Only trigger outer re-render when vars are added/removed, not reordered
      if (!setequal(vars, old)) {
        var_list_trigger(var_list_trigger() + 1L)
      }
    })

    # Per-variable body render triggers (isolates re-renders to single card)
    var_render <- shiny::reactiveValues()

    # Pending configs — holds edits before Apply
    pending <- shiny::reactiveValues()

    # Helper to bump a single variable's body render
    bump_var <- function(v) {
      var_render[[v]] <- (var_render[[v]] %||% 0L) + 1L
    }

    # ── Variable cards (outer shells only) ──
    output$var_cards <- shiny::renderUI({
      var_list_trigger()
      req(store$datasets)
      ds_name <- store$pipeline_filters$dataset %||% names(store$datasets)[1]
      req(ds_name, store$datasets[[ds_name]])
      d <- store$datasets[[ds_name]]

      # Apply pop filter
      pop <- store$pipeline_filters$pop_flag
      d <- apply_pop_filter(d, pop)

      # Detect if BDS
      is_bds <- "PARAMCD" %in% names(d)
      if (is_bds) {
        return(render_bds_params(d, ns, store, grp))
      }

      # Get analysis vars from store (isolated — var_list_trigger handles add/remove)
      analysis_vars <- isolate(grp$analysis_vars)
      if (length(analysis_vars) == 0) {
        return(htmltools::tags$div(class = "ar-text-sm ar-text-muted ar-py-8",
          "No variables selected. Select variables in the Template panel."))
      }

      # Filter to vars that exist in data
      analysis_vars <- analysis_vars[analysis_vars %in% names(d)]
      if (length(analysis_vars) == 0) return(NULL)

      # Ensure var_configs exist (isolate to avoid reactive dependency on var_configs)
      isolate({
        for (v in analysis_vars) {
          if (is.null(store$var_configs[[v]])) {
            vtype <- fct_detect_var_type(d, v)
            if (vtype == "continuous") {
              store$var_configs[[v]] <- list(
                type = "continuous",
                stats = c("n", "mean_sd", "median", "q1_q3", "min_max"),
                decimals = list(n = 0, mean = 1, sd = 2, median = 1, q1 = 1, q3 = 1, min = 0, max = 0),
                stat_labels = list(n = "n", mean_sd = "Mean (SD)", median = "Median",
                                   q1_q3 = "Q1, Q3", min_max = "Min, Max")
              )
            } else {
              store$var_configs[[v]] <- list(
                type = "categorical",
                cat_format = "npct",
                zero_style = "A",
                pct_dec = 1,
                count_dec = 0,
                levels = if (is.factor(d[[v]])) levels(d[[v]])
                         else get_unique_levels(d[[v]])
              )
            }
          }
        }
      })

      # Build card shells — body is a per-variable uiOutput
      cards <- lapply(analysis_vars, function(v) {
        config <- isolate(store$var_configs[[v]])
        vtype <- config$type %||% fct_detect_var_type(d, v)
        badge_type <- if (vtype == "continuous") "NUM" else if (vtype == "date") "DATE" else "CHR"

        card_id <- ns(paste0("vcard_", v))

        htmltools::tags$div(
          id = card_id,
          class = "ar-var-card",
          `data-var` = v,
          # Header with drag handle
          htmltools::tags$div(
            class = "ar-var-card__header",
            onclick = paste0("arToggleVarCard('", card_id, "')"),
            htmltools::tags$span(class = "ar-var-card__drag", htmltools::tags$i(class = "fa fa-grip-vertical")),
            htmltools::tags$span(class = "ar-var-card__chevron", htmltools::HTML("&#9656;")),
            htmltools::tags$span(class = "ar-var-card__name", v),
            ui_type_badge(badge_type)
          ),
          # Body — per-variable uiOutput (isolated re-renders)
          htmltools::tags$div(class = "ar-var-card__body",
            shiny::uiOutput(ns(paste0("vcard_body_", v)))
          )
        )
      })

      ui <- htmltools::tagList(cards)

      # Tell JS to init sortable after render
      session$sendCustomMessage("ar_init_var_sortable",
        list(container_id = ns("var_cards")))

      # Restore open card after re-render (isolate to avoid dependency)
      oc <- isolate(open_card())
      if (!is.null(oc) && oc %in% analysis_vars) {
        card_id <- ns(paste0("vcard_", oc))
        session$sendCustomMessage("ar_open_card", list(card_id = card_id))
      }

      ui
    })

    # ── Variable order from SortableJS ──
    shiny::observeEvent(input$var_order, {
      new_order <- input$var_order
      if (is.character(new_order) && length(new_order) > 0) {
        grp$analysis_vars <- new_order
      }
    })

    # ── Stat order from SortableJS ──
    shiny::observeEvent(input$stat_order, {
      req(input$stat_order)
      v <- input$stat_order$var
      new_stats <- input$stat_order$stats
      if (!is.null(v) && is.character(new_stats)) {
        store$var_configs[[v]]$stats <- new_stats
      }
    })

    # ── Card opened — snapshot for Discard + track open card ──
    shiny::observeEvent(input$card_opened, {
      req(input$card_opened)
      v <- input$card_opened$var
      open_card(v)
      if (!is.null(v) && !is.null(store$var_configs[[v]])) {
        pending[[v]] <- store$var_configs[[v]]
      }
    })

    # ── Card closed ──
    shiny::observeEvent(input$card_closed, {
      open_card(NULL)
    })

    # ── Per-variable body rendering + observers ──
    observed_vars <- character(0)
    shiny::observe({
      vars <- grp$analysis_vars
      new_vars <- setdiff(vars, observed_vars)
      if (length(new_vars) == 0) return()
      observed_vars <<- union(observed_vars, new_vars)
      for (v in new_vars) {
        local({
          my_var <- v

          # ── Per-variable body renderUI ──
          output[[paste0("vcard_body_", my_var)]] <- shiny::renderUI({
            var_render[[my_var]]  # per-var trigger dependency

            req(store$datasets)
            ds_name <- isolate(store$pipeline_filters$dataset) %||% names(store$datasets)[1]
            d <- store$datasets[[ds_name]]
            req(d, my_var %in% names(d))

            pop <- isolate(store$pipeline_filters$pop_flag)
            d <- apply_pop_filter(d, pop)

            config <- isolate(store$var_configs[[my_var]])
            if (is.null(config)) return(NULL)
            vtype <- config$type %||% fct_detect_var_type(d, my_var)

            custom_label <- isolate(store$var_labels[[my_var]])

            body <- if (vtype == "continuous") {
              ui_stat_card_cont(ns, my_var, config, d, custom_label = custom_label)
            } else {
              ui_stat_card_cat(ns, my_var, config, d, custom_label = custom_label,
                added_levels = isolate(store$added_levels[[my_var]]))
            }

            # Init stat grid sortable for continuous vars
            if (vtype == "continuous") {
              session$sendCustomMessage("ar_init_stat_sortable",
                list(container_id = ns(paste0("stat_grid_", my_var)),
                     var_name = my_var, ns_prefix = ns("")))
            }
            # Init level sortable for categorical vars
            if (vtype != "continuous") {
              session$sendCustomMessage("ar_init_level_sortable",
                list(container_id = ns(paste0("level_sortable_", my_var)),
                     input_id = ns(paste0("level_order_", my_var))))
            }

            body
          })

          # Apply — collapse card + toast (data already persisted)
          shiny::observeEvent(input[[paste0("apply_", my_var)]], {
            card_id <- ns(paste0("vcard_", my_var))
            open_card(NULL)
            session$sendCustomMessage("ar_collapse_card", list(card_id = card_id))
            session$sendCustomMessage("ar_toast",
              list(message = paste0(my_var, " saved"), type = "success"))
            pending[[my_var]] <- NULL
          })

          # Discard — revert to snapshot taken when card was opened
          shiny::observeEvent(input[[paste0("discard_", my_var)]], {
            if (!is.null(pending[[my_var]])) {
              store$var_configs[[my_var]] <- pending[[my_var]]
              pending[[my_var]] <- NULL
              bump_var(my_var)  # only re-render THIS card
              session$sendCustomMessage("ar_toast",
                list(message = paste0(my_var, " reverted"), type = "warning"))
            }
          })

          # Stat checkbox changes — update config + re-render THIS card only
          shiny::observeEvent(input[[paste0("stats_", my_var)]], {
            val <- input[[paste0("stats_", my_var)]]
            if (is.character(val)) {
              cfg <- isolate(store$var_configs[[my_var]])
              old <- if (!is.null(cfg)) cfg$stats else NULL
              if (!identical(sort(val), sort(old))) {
                store$var_configs[[my_var]]$stats <- val
                open_card(my_var)
                bump_var(my_var)  # only re-render THIS card
              }
            }
          }, ignoreNULL = FALSE, ignoreInit = TRUE)

          # Per-stat decimals
          for (stat_key in c("n", "mean", "sd", "median", "q1", "q3", "min", "max",
                             "geo_mean", "cv")) {
            local({
              my_stat <- stat_key
              input_id <- paste0("dec_", my_var, "_", my_stat)
              shiny::observeEvent(input[[input_id]], {
                val <- input[[input_id]]
                if (!is.null(val)) {
                  cfg <- isolate(store$var_configs[[my_var]])
                  old <- if (!is.null(cfg) && is.list(cfg$decimals)) cfg$decimals[[my_stat]] else NULL
                  if (!identical(val, old)) {
                    if (is.null(cfg) || !is.list(cfg$decimals)) {
                      store$var_configs[[my_var]]$decimals <- list(
                        n = 0, mean = 1, sd = 2, median = 1, q1 = 1, q3 = 1, min = 0, max = 0
                      )
                    }
                    store$var_configs[[my_var]]$decimals[[my_stat]] <- val
                  }
                }
              }, ignoreInit = TRUE)
            })
          }

          # Stat labels
          shiny::observeEvent(input[[paste0("statlabel_", my_var)]], {
            val <- input[[paste0("statlabel_", my_var)]]
            if (!is.null(val)) {
              if (!is.list(store$var_configs[[my_var]]$stat_labels)) {
                store$var_configs[[my_var]]$stat_labels <- list()
              }
              for (nm in names(val)) {
                store$var_configs[[my_var]]$stat_labels[[nm]] <- val[[nm]]
              }
            }
          }, ignoreInit = TRUE)

          # Categorical format
          shiny::observeEvent(input[[paste0("catfmt_", my_var)]], {
            val <- input[[paste0("catfmt_", my_var)]]
            cfg <- isolate(store$var_configs[[my_var]])
            old <- if (!is.null(cfg)) cfg$cat_format else NULL
            if (!identical(val, old)) {
              store$var_configs[[my_var]]$cat_format <- val
            }
          }, ignoreInit = TRUE)

          # Pct decimals
          shiny::observeEvent(input[[paste0("pct_dec_", my_var)]], {
            val <- input[[paste0("pct_dec_", my_var)]]
            cfg <- isolate(store$var_configs[[my_var]])
            old <- if (!is.null(cfg)) cfg$pct_dec else NULL
            if (!identical(val, old)) {
              store$var_configs[[my_var]]$pct_dec <- val
            }
          }, ignoreInit = TRUE)

          # Zero style
          shiny::observeEvent(input[[paste0("zero_", my_var)]], {
            val <- input[[paste0("zero_", my_var)]]
            cfg <- isolate(store$var_configs[[my_var]])
            old <- if (!is.null(cfg)) cfg$zero_style else NULL
            if (!identical(val, old)) {
              store$var_configs[[my_var]]$zero_style <- val
            }
          }, ignoreInit = TRUE)

          # Show n toggle (categorical)
          shiny::observeEvent(input[[paste0("show_n_", my_var)]], {
            val <- identical(input[[paste0("show_n_", my_var)]], "yes")
            store$var_configs[[my_var]]$show_n <- val
          }, ignoreInit = TRUE)

          # Variable label
          shiny::observeEvent(input[[paste0("vlabel_", my_var)]], {
            lbl <- input[[paste0("vlabel_", my_var)]]
            if (!is.null(lbl) && nzchar(lbl)) {
              store$var_labels[[my_var]] <- lbl
            }
          }, ignoreInit = TRUE)

          # Move level up/down
          # Level reorder via SortableJS drag
          shiny::observeEvent(input[[paste0("level_order_", my_var)]], {
            new_order <- input[[paste0("level_order_", my_var)]]
            if (is.character(new_order) && length(new_order) > 0) {
              store$var_configs[[my_var]]$levels <- new_order
              store$var_configs[[my_var]]$sorted_by_freq <- FALSE
            }
          })

          # Add dummy level
          shiny::observeEvent(input[[paste0("add_level_", my_var)]], {
            info <- input[[paste0("add_level_", my_var)]]
            req(info, info$level)
            lv <- trimws(info$level)
            if (!nzchar(lv)) return()
            existing <- store$var_configs[[my_var]]$levels %||% character(0)
            if (lv %in% existing) {
              session$sendCustomMessage("ar_toast",
                list(message = paste0("\"", lv, "\" already exists"), type = "warning"))
              return()
            }
            if (is.null(store$added_levels)) store$added_levels <- list()
            store$added_levels[[my_var]] <- unique(c(store$added_levels[[my_var]], lv))
            store$var_configs[[my_var]]$levels <- c(existing, lv)
            bump_var(my_var)  # only re-render THIS card
            session$sendCustomMessage("ar_toast",
              list(message = paste0("Added \"", lv, "\""), type = "success"))
          })

          # Remove added level
          shiny::observeEvent(input[[paste0("remove_level_", my_var)]], {
            info <- input[[paste0("remove_level_", my_var)]]
            req(info, info$level)
            lv <- info$level
            if (!is.null(store$added_levels[[my_var]])) {
              store$added_levels[[my_var]] <- setdiff(store$added_levels[[my_var]], lv)
            }
            store$var_configs[[my_var]]$levels <- setdiff(
              store$var_configs[[my_var]]$levels, lv)
            bump_var(my_var)  # only re-render THIS card
            session$sendCustomMessage("ar_toast",
              list(message = paste0("Removed \"", lv, "\""), type = "warning"))
          })

          # Sort by frequency
          shiny::observeEvent(input[[paste0("sort_freq_", my_var)]], {
            req(store$datasets)
            ds_name <- store$pipeline_filters$dataset %||% names(store$datasets)[1]
            d <- store$datasets[[ds_name]]
            pop <- store$pipeline_filters$pop_flag
            d <- apply_pop_filter(d, pop)
            x <- d[[my_var]]
            if (isTRUE(store$var_configs[[my_var]]$sorted_by_freq)) {
              # Toggle OFF — revert to alphabetical
              store$var_configs[[my_var]]$levels <- get_unique_levels(as.character(x))
              store$var_configs[[my_var]]$sorted_by_freq <- FALSE
            } else {
              # Toggle ON — sort by frequency
              freq <- sort(table(x), decreasing = TRUE)
              store$var_configs[[my_var]]$levels <- names(freq)
              store$var_configs[[my_var]]$sorted_by_freq <- TRUE
            }
            bump_var(my_var)  # only re-render THIS card
          })

          # Reset to defaults
          shiny::observeEvent(input[[paste0("reset_", my_var)]], {
            tmpl_spec_fn <- tryCatch({
              tmpl_def <- get_template_def(store$template)
              if (!is.null(tmpl_def)) get(tmpl_def$spec_fn) else spec_demog
            }, error = function(e) spec_demog)
            defaults <- tryCatch(tmpl_spec_fn()$var_configs[[my_var]], error = function(e) NULL)
            if (!is.null(defaults)) {
              store$var_configs[[my_var]] <- defaults
              store$var_labels[[my_var]] <- NULL
              bump_var(my_var)  # only re-render THIS card
              session$sendCustomMessage("ar_toast",
                list(message = paste0(my_var, " reset to defaults"), type = "success"))
            }
          })
        })
      }
    })
  })
}

# ── UI Helper: Continuous stat card body ──
ui_stat_card_cont <- function(ns, var, config, data, custom_label = NULL) {
  # Full stat vocabulary
  stats_all <- c("n", "mean", "sd", "mean_sd", "median",
                 "q1", "q3", "q1_q3", "min", "max", "min_max",
                 "geo_mean", "cv", "geo_mean_cv")
  stats_labels <- c("N", "Mean", "SD", "Mean (SD)", "Median",
                     "Q1", "Q3", "Q1, Q3", "Min", "Max", "Min, Max",
                     "GeoMean", "CV%", "GeoMean (CV%)")
  selected_stats <- config$stats %||% c("n", "mean_sd", "median", "q1_q3", "min_max")
  decs <- config$decimals
  stat_labels <- config$stat_labels %||% list()

  # Default stat labels and decimals (from shared constants in utils_helpers.R)
  default_labels <- STAT_LABELS
  default_decs <- STAT_DECIMALS

  # Stats checkbox (chip-styled via CSS)
  stat_choices <- stats::setNames(stats_all, stats_labels)

  # Combined stat pairs: stat -> (key1, key2)
  combined_pairs <- list(
    mean_sd = c("mean", "sd"),
    q1_q3 = c("q1", "q3"),
    min_max = c("min", "max"),
    geo_mean_cv = c("geo_mean", "cv")
  )

  # Build the stat-label-decimal grid (only selected stats rendered)
  grid_rows <- lapply(selected_stats, function(s) {
    lbl <- stat_labels[[s]] %||% (default_labels[[s]] %||% s)
    row_class <- "ar-stat-grid__row"

    # Decimal input(s): plain HTML inputs (no Shiny numericInput)
    if (s %in% names(combined_pairs)) {
      keys <- combined_pairs[[s]]
      dec1 <- if (is.list(decs)) decs[[keys[1]]] %||% (default_decs[[keys[1]]] %||% 1)
              else decs %||% (default_decs[[keys[1]]] %||% 1)
      dec2 <- if (is.list(decs)) decs[[keys[2]]] %||% (default_decs[[keys[2]]] %||% 1)
              else decs %||% (default_decs[[keys[2]]] %||% 1)
      dec_ui <- htmltools::tags$div(class = "ar-dec-dual",
        htmltools::tags$input(type = "number", class = "ar-dec-input",
          id = ns(paste0("cdec_", var, "_", s, "_1")),
          value = dec1, min = 0, max = 6, step = 1,
          onchange = paste0("Shiny.setInputValue('", ns(paste0("dec_", var, "_", keys[1])),
            "', parseInt(this.value)||0, {priority:'event'})")),
        htmltools::tags$span(class = "ar-dec-dual__sep", "/"),
        htmltools::tags$input(type = "number", class = "ar-dec-input",
          id = ns(paste0("cdec_", var, "_", s, "_2")),
          value = dec2, min = 0, max = 6, step = 1,
          onchange = paste0("Shiny.setInputValue('", ns(paste0("dec_", var, "_", keys[2])),
            "', parseInt(this.value)||0, {priority:'event'})"))
      )
    } else if (s == "n") {
      # N is always integer — no decimal input needed
      dec_ui <- htmltools::tags$span()
    } else {
      dec_key <- s
      dec_val <- if (is.list(decs)) decs[[dec_key]] %||% (default_decs[[dec_key]] %||% 1)
                 else decs %||% (default_decs[[dec_key]] %||% 1)
      dec_ui <- htmltools::tags$input(type = "number", class = "ar-dec-input ar-dec-input--single",
        id = ns(paste0("dec_", var, "_", dec_key)),
        value = dec_val, min = 0, max = 6, step = 1,
        onchange = paste0("Shiny.setInputValue('", ns(paste0("dec_", var, "_", dec_key)),
          "', parseInt(this.value)||0, {priority:'event'})"))
    }

    htmltools::tags$div(
      class = row_class,
      `data-stat` = s,
      htmltools::tags$span(class = "ar-stat-grid__drag", htmltools::tags$i(class = "fa fa-grip-vertical")),
      htmltools::tags$span(class = "ar-stat-grid__name",
        STAT_LABELS[[s]] %||% s
      ),
      htmltools::tags$input(
        type = "text", class = "ar-input ar-input--sm ar-stat-grid__label",
        id = ns(paste0("slbl_", var, "_", s)),
        value = lbl,
        onchange = paste0(
          "Shiny.setInputValue('", ns(paste0("statlabel_", var)),
          "', {", s, ": this.value}, {priority: 'event'})"
        )
      ),
      dec_ui
    )
  })

  # Variable label
  label_text <- custom_label %||% fct_get_var_label(data, var)

  htmltools::tags$div(class = "ar-var-card__content",
    # Variable Label
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Label"),
      htmltools::tags$input(
        type = "text", class = "ar-input ar-input--sm",
        id = ns(paste0("vlabel_", var)),
        value = label_text, class = "ar-w-full",
        onchange = paste0(
          "Shiny.setInputValue('", ns(paste0("vlabel_", var)),
          "', this.value, {priority: 'event'})"
        )
      )
    ),

    # Stat chips
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Statistics"),
      htmltools::tags$div(class = "ar-stat-chips",
        shiny::checkboxGroupInput(
          ns(paste0("stats_", var)), NULL,
          choiceNames = as.list(stats_labels),
          choiceValues = as.list(stats_all),
          selected = selected_stats,
          inline = TRUE
        )
      )
    ),

    # Stat-label-decimal grid
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$div(class = "ar-stat-grid__header",
        htmltools::tags$span(""),
        htmltools::tags$span("Stat"),
        htmltools::tags$span("Label"),
        htmltools::tags$span("Dec")
      ),
      htmltools::tags$div(
        class = "ar-stat-grid",
        id = ns(paste0("stat_grid_", var)),
        grid_rows
      )
    ),

    # Actions: Discard | Reset | Apply
    htmltools::tags$div(class = "ar-var-card__actions",
      htmltools::tags$button(
        class = "ar-btn-ghost",
        onclick = paste0("Shiny.setInputValue('", ns(paste0("discard_", var)),
          "', Math.random(), {priority: 'event'})"),
        "Discard"
      ),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-text-muted",
        onclick = paste0("Shiny.setInputValue('", ns(paste0("reset_", var)),
          "', Math.random(), {priority: 'event'})"),
        "Reset"
      ),
      htmltools::tags$button(
        class = "ar-btn-primary ar-btn--sm",
        onclick = paste0("Shiny.setInputValue('", ns(paste0("apply_", var)),
          "', Math.random(), {priority: 'event'})"),
        "Apply"
      )
    )
  )
}

# ── UI Helper: Categorical stat card body ──
ui_stat_card_cat <- function(ns, var, config, data, custom_label = NULL, added_levels = NULL) {
  fmt <- config$cat_format %||% "npct"
  pct_dec <- config$pct_dec %||% 1
  style <- config$zero_style %||% "A"
  show_n <- config$show_n %||% TRUE
  label_text <- custom_label %||% fct_get_var_label(data, var)
  added <- added_levels %||% character(0)

  x <- data[[var]]
  obs_levels <- get_unique_levels(as.character(x))
  cfg_levels <- config$levels %||% obs_levels

  # Level rows with drag handles (SortableJS)
  level_rows <- lapply(seq_along(cfg_levels), function(i) {
    lv <- cfg_levels[i]
    is_added <- lv %in% added
    row_class <- paste0("ar-trt-row", if (is_added) " ar-trt-row--added" else "")

    htmltools::tags$div(class = row_class, `data-level` = lv,
      htmltools::tags$span(class = "ar-trt-row__drag", htmltools::tags$i(class = "fa fa-grip-vertical")),
      htmltools::tags$span(class = "ar-trt-row__label", lv),
      if (is_added) htmltools::tags$span(class = "ar-trt-row__badge", "added") else NULL,
      if (is_added) htmltools::tags$button(
        class = "ar-btn-icon--xs ar-level-btn--remove",
        title = "Remove added level",
        onclick = paste0(
          "Shiny.setInputValue('", ns(paste0("remove_level_", var)),
          "', {level: '", gsub("'", "\\\\'", lv), "', ts: Date.now()}, {priority: 'event'})"
        ),
        htmltools::HTML("&#10005;")
      ) else NULL
    )
  })

  htmltools::tags$div(class = "ar-var-card__content",
    # Variable Label
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Label"),
      htmltools::tags$input(
        type = "text", class = "ar-input ar-input--sm",
        id = ns(paste0("vlabel_", var)),
        value = label_text, class = "ar-w-full",
        onchange = paste0(
          "Shiny.setInputValue('", ns(paste0("vlabel_", var)),
          "', this.value, {priority: 'event'})"
        )
      )
    ),

    # Format + Pct decimals + Zero display — inline row
    htmltools::tags$div(class = "ar-var-settings-row",
      htmltools::tags$div(class = "ar-form-group",
        htmltools::tags$label(class = "ar-form-label", "Format"),
        shiny::radioButtons(
          ns(paste0("catfmt_", var)), NULL,
          choices = c("n (%)" = "npct", "n" = "n", "n/N (%)" = "nn_pct"),
          selected = fmt, inline = TRUE
        )
      ),
      htmltools::tags$div(class = "ar-form-group",
        htmltools::tags$label(class = "ar-form-label", "Dec %"),
        htmltools::tags$input(type = "number", class = "ar-dec-input ar-dec-input--single",
          id = ns(paste0("pct_dec_", var)),
          value = pct_dec, min = 0, max = 3, step = 1,
          onchange = paste0("Shiny.setInputValue('", ns(paste0("pct_dec_", var)),
            "', parseInt(this.value)||0, {priority:'event'})"))
      ),
      htmltools::tags$div(class = "ar-form-group",
        htmltools::tags$label(class = "ar-form-label", "Zero"),
        shiny::radioButtons(
          ns(paste0("zero_", var)), NULL,
          choices = c("0" = "A", "0 (0.0)" = "D"),
          selected = style, inline = TRUE
        )
      ),
      htmltools::tags$div(class = "ar-form-group",
        htmltools::tags$label(class = "ar-form-label", "Show n"),
        shiny::radioButtons(
          ns(paste0("show_n_", var)), NULL,
          choices = c("Yes" = "yes", "No" = "no"),
          selected = if (isTRUE(show_n)) "yes" else "no", inline = TRUE
        )
      )
    ),

    # Levels with reorder + Add level
    htmltools::tags$div(class = "ar-form-group",
      htmltools::tags$div(class = "ar-flex ar-items-center ar-gap-8",
        htmltools::tags$label(class = "ar-form-label ar-mb-0",
          paste0("Levels (", length(cfg_levels), ")")),
        htmltools::tags$button(
          id = ns(paste0("sort_freq_btn_", var)),
          class = paste0("ar-btn-ghost ar-btn--xs ar-sort-freq-btn ar-ml-auto",
            if (isTRUE(config$sorted_by_freq)) " ar-sort-freq-btn--active" else ""),
          onclick = paste0(
            "this.classList.toggle('ar-sort-freq-btn--active');",
            "Shiny.setInputValue('", ns(paste0("sort_freq_", var)),
            "', Math.random(), {priority: 'event'})"),
          "Sort by frequency"
        )
      ),
      htmltools::tags$div(class = "ar-level-list", id = ns(paste0("level_sortable_", var)), level_rows),
      htmltools::tags$div(class = "ar-flex ar-items-center ar-gap-8 ar-mt-4",
        htmltools::tags$input(
          type = "text", class = "ar-input ar-input--sm ar-flex-1",
          id = ns(paste0("add_level_input_", var)),
          placeholder = "Add level...",
          onkeydown = paste0(
            "if(event.key==='Enter'){event.preventDefault();",
            "var v=this.value.trim();if(v){",
            "Shiny.setInputValue('", ns(paste0("add_level_", var)),
            "',{level:v,ts:Date.now()},{priority:'event'});",
            "this.value='';}}"
          )
        ),
        htmltools::tags$button(
          class = "ar-btn-outline ar-btn--sm ar-flex-shrink-0",
          onclick = paste0(
            "var inp=document.getElementById('", ns(paste0("add_level_input_", var)), "');",
            "var v=inp.value.trim();if(v){",
            "Shiny.setInputValue('", ns(paste0("add_level_", var)),
            "',{level:v,ts:Date.now()},{priority:'event'});",
            "inp.value='';}"
          ),
          "+ Add"
        )
      )
    ),

    # Actions: Discard | Reset | Apply
    htmltools::tags$div(class = "ar-var-card__actions",
      htmltools::tags$button(
        class = "ar-btn-ghost",
        onclick = paste0("Shiny.setInputValue('", ns(paste0("discard_", var)),
          "', Math.random(), {priority: 'event'})"),
        "Discard"
      ),
      htmltools::tags$button(
        class = "ar-btn-ghost ar-text-muted",
        onclick = paste0("Shiny.setInputValue('", ns(paste0("reset_", var)),
          "', Math.random(), {priority: 'event'})"),
        "Reset"
      ),
      htmltools::tags$button(
        class = "ar-btn-primary ar-btn--sm",
        onclick = paste0("Shiny.setInputValue('", ns(paste0("apply_", var)),
          "', Math.random(), {priority: 'event'})"),
        "Apply"
      )
    )
  )
}
