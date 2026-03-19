# App UI Shell — bslib native components
# Activity Bar + Sidebar (navset_hidden/accordion) + Canvas (navset_hidden/navset_tab)

app_ui <- function() {
  bslib::page_fillable(
    theme = ar_theme(),
    shinyjs::useShinyjs(),
    htmltools::tags$head(
      htmltools::tags$link(rel = "stylesheet", href = "www/app.css"),
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

      # Pipeline dots
      htmltools::tags$div(class = "ar-pipeline",
        htmltools::tags$div(id = "pip_data", class = "ar-pipeline__dot ar-pipeline__dot--active"),
        htmltools::tags$div(id = "pip_line_template", class = "ar-pipeline__line"),
        htmltools::tags$div(id = "pip_template", class = "ar-pipeline__dot"),
        htmltools::tags$div(id = "pip_line_analysis", class = "ar-pipeline__line"),
        htmltools::tags$div(id = "pip_analysis", class = "ar-pipeline__dot"),
        htmltools::tags$div(id = "pip_line_format", class = "ar-pipeline__line"),
        htmltools::tags$div(id = "pip_format", class = "ar-pipeline__dot"),
        htmltools::tags$div(id = "pip_line_output", class = "ar-pipeline__line"),
        htmltools::tags$div(id = "pip_output", class = "ar-pipeline__dot")
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

      # Activity Bar — icon buttons
      htmltools::tags$div(class = "ar-activity-bar",
        shiny::actionButton("ab_data", NULL, icon = shiny::icon("database"),
          class = "ar-ab-btn active", title = "Data (Ctrl+1)"),
        shiny::actionButton("ab_template", NULL, icon = shiny::icon("th-list"),
          class = "ar-ab-btn", title = "Template (Ctrl+2)"),
        shiny::actionButton("ab_analysis", NULL, icon = shiny::icon("chart-bar"),
          class = "ar-ab-btn", title = "Analysis (Ctrl+3)"),
        shiny::actionButton("ab_format", NULL, icon = shiny::icon("paint-brush"),
          class = "ar-ab-btn", title = "Format (Ctrl+4)"),
        htmltools::tags$div(class = "ar-ab-spacer"),
        shiny::actionButton("ab_output", NULL, icon = shiny::icon("download"),
          class = "ar-ab-btn", title = "Output (Ctrl+5)")
      ),

      # Sidebar — navset_hidden switches panels
      htmltools::tags$div(class = "ar-sidebar",
        bslib::navset_hidden(id = "sidebar_panels",

          # DATA panel
          bslib::nav_panel_hidden("data",
            bslib::accordion(id = "acc_data",
              open = c("DATASETS", "SUMMARY"), multiple = TRUE,
              bslib::accordion_panel("DATASETS", mod_data_ui("data")),
              bslib::accordion_panel("SUMMARY", mod_data_summary_ui("data")),
              bslib::accordion_panel("COLUMN EXPLORER", mod_data_col_explorer_ui("data")),
              bslib::accordion_panel("FILTERS", mod_data_filters_ui("data"))
            )
          ),

          # TEMPLATE panel
          bslib::nav_panel_hidden("template",
            bslib::accordion(id = "acc_template",
              open = c("TEMPLATE INFO", "DATA SOURCE", "VARIABLES"), multiple = TRUE,
              bslib::accordion_panel("TEMPLATE INFO",
                shiny::uiOutput("template_info_display")
              ),
              bslib::accordion_panel("DATA SOURCE",
                mod_data_pipeline_dataset_ui("data"),
                mod_data_pipeline_pop_ui("data"),
                shiny::uiOutput("data_source_n")
              ),
              bslib::accordion_panel("VARIABLES",
                mod_grouping_vars_ui("grouping")
              )
            )
          ),

          # ANALYSIS panel
          bslib::nav_panel_hidden("analysis",
            bslib::accordion(id = "acc_analysis",
              open = c("TREATMENT", "STATISTICS"), multiple = TRUE,
              bslib::accordion_panel("TREATMENT",
                mod_treatment_ui("treatment")
              ),
              bslib::accordion_panel("STATISTICS",
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

          # ANALYSIS canvas — tabbed: N Counts + ARD Data
          bslib::nav_panel_hidden("analysis",
            bslib::navset_underline(
              bslib::nav_panel("N Counts",
                htmltools::tags$div(class = "ar-canvas-padded",
                  shiny::uiOutput("n_counts_display")
                )
              ),
              bslib::nav_panel("ARD Data",
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
