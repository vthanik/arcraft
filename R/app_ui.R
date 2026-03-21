# App UI Shell — bslib native components
# Activity Bar + Sidebar (navset_hidden/accordion) + Canvas (navset_hidden/navset_tab)

app_ui <- function() {
  bslib::page_fillable(
    theme = ar_theme(),
    # No shinyjs — all JS via app.js + sendCustomMessage
    htmltools::tags$head(
      htmltools::tags$link(rel = "stylesheet", href = "www/app.css"),
      htmltools::tags$link(rel = "stylesheet", href = "www/dt-grid.css"),
      # Favicon (prevent 404)
      htmltools::tags$link(rel = "icon", href = "data:,"),
      # highlight.js for R syntax highlighting (local, no CDN)
      htmltools::tags$link(rel = "stylesheet", href = "www/highlight-github.min.css"),
      htmltools::tags$script(src = "www/highlight.min.js"),
      htmltools::tags$script(src = "www/highlight-r.min.js"),
      htmltools::tags$script(src = "www/Sortable.min.js"),
      htmltools::tags$script(src = "www/app.js")
    ),
    padding = 0,
    gap = 0,

    # ── Top Bar ──
    htmltools::tags$div(class = "ar-topbar",
      htmltools::tags$div(class = "ar-topbar__brand",
        htmltools::tags$span("ar"), "builder"
      ),

      # Status pill
      htmltools::tags$div(id = "ar_status_pill", class = "ar-status-pill",
        htmltools::tags$span(class = "ar-status-pill__dot"),
        htmltools::tags$span(class = "ar-status-pill__text", "Load data to start")
      ),

      htmltools::tags$div(class = "ar-topbar__spacer"),

      # Actions
      htmltools::tags$div(class = "ar-topbar__actions",
        shiny::actionButton("preview_btn",
          label = htmltools::tagList(shiny::icon("play"), "Generate Preview"),
          class = "ar-btn-primary"
        ),
        shiny::downloadButton("export_rtf", label = NULL,
          class = "ar-btn-outline",
          icon = shiny::icon("file-export")
        ),
        shiny::downloadButton("dl_script", label = NULL,
          class = "ar-btn-outline",
          icon = shiny::icon("code")
        )
      )
    ),

    # ── Context Summary Line ──
    htmltools::tags$div(class = "ar-context-line",
      shiny::uiOutput("context_line", inline = TRUE)
    ),

    # ── Body: Activity Bar + Sidebar + Canvas ──
    htmltools::tags$div(class = "ar-body",

      # Activity Bar — icon buttons with labels
      htmltools::tags$div(class = "ar-activity-bar",
        shiny::actionButton("ab_data",
          label = htmltools::tagList(
            htmltools::tags$div(class = "ar-ab-btn__icon-wrap",
              shiny::icon("database"),
              htmltools::tags$span(class = "ar-ab-badge", id = "ab_badge_data")),
            htmltools::tags$span(class = "ar-ab-btn__label", "DATA")
          ), class = "ar-ab-btn active", title = "Data (Ctrl+1)"),
        shiny::actionButton("ab_template",
          label = htmltools::tagList(
            htmltools::tags$div(class = "ar-ab-btn__icon-wrap",
              shiny::icon("th-list"),
              htmltools::tags$span(class = "ar-ab-badge", id = "ab_badge_template")),
            htmltools::tags$span(class = "ar-ab-btn__label", "TMPL")
          ), class = "ar-ab-btn", title = "Template (Ctrl+2)"),
        shiny::actionButton("ab_analysis",
          label = htmltools::tagList(
            htmltools::tags$div(class = "ar-ab-btn__icon-wrap",
              shiny::icon("chart-bar"),
              htmltools::tags$span(class = "ar-ab-badge", id = "ab_badge_analysis")),
            htmltools::tags$span(class = "ar-ab-btn__label", "ANLYS")
          ), class = "ar-ab-btn", title = "Analysis (Ctrl+3)"),
        shiny::actionButton("ab_format",
          label = htmltools::tagList(
            htmltools::tags$div(class = "ar-ab-btn__icon-wrap",
              shiny::icon("paint-brush"),
              htmltools::tags$span(class = "ar-ab-badge", id = "ab_badge_format")),
            htmltools::tags$span(class = "ar-ab-btn__label", "FMT")
          ), class = "ar-ab-btn", title = "Format (Ctrl+4)"),
        htmltools::tags$div(class = "ar-ab-spacer"),
        shiny::actionButton("ab_output",
          label = htmltools::tagList(
            htmltools::tags$div(class = "ar-ab-btn__icon-wrap",
              shiny::icon("download"),
              htmltools::tags$span(class = "ar-ab-badge", id = "ab_badge_output")),
            htmltools::tags$span(class = "ar-ab-btn__label", "OUT")
          ), class = "ar-ab-btn", title = "Output (Ctrl+5)")
      ),

      # Sidebar — navset_hidden switches panels
      htmltools::tags$div(class = "ar-sidebar",
        bslib::navset_hidden(id = "sidebar_panels",

          # DATA panel — streamlined (column explorer + filters moved to canvas data viewer)
          bslib::nav_panel_hidden("data",
            bslib::accordion(id = "acc_data",
              open = c("DATASETS", "LIBRARY"), multiple = TRUE,
              bslib::accordion_panel("DATASETS", value = "DATASETS",
                mod_data_ui("data")),
              bslib::accordion_panel("LIBRARY", value = "LIBRARY",
                mod_data_summary_ui("data"))
            )
          ),

          # TEMPLATE panel
          bslib::nav_panel_hidden("template",
            bslib::accordion(id = "acc_template",
              open = c("TEMPLATE INFO", "DATA SOURCE", "VARIABLES"), multiple = TRUE,
              bslib::accordion_panel("TEMPLATE INFO", value = "TEMPLATE INFO",
                shiny::uiOutput("template_info_display")
              ),
              bslib::accordion_panel("DATA SOURCE", value = "DATA SOURCE",
                mod_data_pipeline_dataset_ui("data"),
                mod_data_pipeline_pop_ui("data"),
                shiny::uiOutput("data_source_n")
              ),
              bslib::accordion_panel("VARIABLES", value = "VARIABLES",
                mod_grouping_vars_ui("grouping")
              )
            )
          ),

          # ANALYSIS panel
          bslib::nav_panel_hidden("analysis",
            bslib::accordion(id = "acc_analysis",
              open = c("TREATMENT", "STATISTICS"), multiple = TRUE,
              bslib::accordion_panel("TREATMENT", value = "TREATMENT",
                mod_treatment_ui("treatment"),
                # N counts — separated from treatment config
                htmltools::tags$div(class = "ar-section-divider"),
                htmltools::tags$div(class = "ar-form-label", "N COUNTS"),
                n_counts_ui("n_counts")
              ),
              bslib::accordion_panel("STATISTICS", value = "STATISTICS",
                mod_analysis_vars_ui("analysis_vars")
              )
            )
          ),

          # FORMAT panel — Two-Tab Split (Content + Style)
          bslib::nav_panel_hidden("format",
            format_panel_ui()
          ),

          # OUTPUT panel
          bslib::nav_panel_hidden("output",
            bslib::accordion(id = "acc_output", open = "VALIDATION", multiple = TRUE,
              bslib::accordion_panel("VALIDATION", mod_validation_ui("validation")),
              bslib::accordion_panel("EXPORT",
                htmltools::tags$div(class = "ar-flex-col ar-gap-8",
                  shiny::downloadButton("export_rtf_side", "Export RTF",
                    class = "ar-btn-primary ar-w-full"),
                  shiny::downloadButton("export_pdf_side", "Export PDF",
                    class = "ar-btn-outline ar-w-full"),
                  shiny::downloadButton("export_html_side", "Export HTML",
                    class = "ar-btn-outline ar-w-full"),
                  shiny::downloadButton("dl_script_side", "Download R Script",
                    class = "ar-btn-outline ar-w-full")
                )
              )
            )
          )
        ),

        # Sidebar footer hint
        htmltools::tags$div(class = "ar-sidebar__footer",
          shiny::uiOutput("sidebar_hint", inline = TRUE)
        )
      ),

      # Resize handle (drag to resize sidebar)
      htmltools::tags$div(class = "ar-resize-handle", id = "ar_resize_handle"),

      # Canvas — navset_hidden switches content, navset_tab for inner tabs
      htmltools::tags$div(class = "ar-canvas",
        bslib::navset_hidden(id = "canvas_panels",

          # DATA canvas — direct viewer, no tabs
          bslib::nav_panel_hidden("data",
            mod_data_viewer_ui("data_viewer")
          ),

          # TEMPLATE canvas — template gallery only
          bslib::nav_panel_hidden("template",
            htmltools::tags$div(class = "ar-canvas-padded",
              mod_template_ui("template")
            )
          ),

          # ANALYSIS canvas — full-width ARD data grid (N counts moved to treatment sidebar)
          bslib::nav_panel_hidden("analysis",
            htmltools::tags$div(class = "ar-dv",
              htmltools::tags$div(class = "ar-dv__toolbar",
                htmltools::tags$div(class = "ar-dv__dims",
                  shiny::textOutput("ard_dims", inline = TRUE)
                )
              ),
              htmltools::tags$div(class = "ar-dv__grid",
                shiny::uiOutput("ard_empty_state"),
                reactable::reactableOutput("ard_data_table")
              )
            )
          ),

          # FORMAT canvas
          bslib::nav_panel_hidden("format",
            bslib::navset_tab(
              bslib::nav_panel("Table Preview",
                htmltools::tags$div(class = "ar-canvas-padded",
                  shiny::uiOutput("preview_display_fmt")
                )
              ),
              bslib::nav_panel("R Code",
                htmltools::tags$div(class = "ar-canvas-padded",
                  shiny::uiOutput("code_display_fmt")
                )
              )
            )
          ),

          # OUTPUT canvas
          bslib::nav_panel_hidden("output",
            bslib::navset_tab(
              bslib::nav_panel("Final Table",
                htmltools::tags$div(class = "ar-canvas-padded",
                  shiny::uiOutput("preview_display_out")
                )
              ),
              bslib::nav_panel("R Code",
                htmltools::tags$div(class = "ar-canvas-padded",
                  shiny::uiOutput("code_display_out")
                )
              )
            )
          )
        )
      )
    )
  )
}
