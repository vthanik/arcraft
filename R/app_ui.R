#' App UI — Builder layout: left config accordion + right live preview
app_ui <- function() {
  theme <- ar_theme()

  htmltools::tagList(
    bslib::bs_theme_dependencies(theme),
    shinyjs::useShinyjs(),
    htmltools::tags$head(
      htmltools::tags$meta(charset = "utf-8"),
      htmltools::tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
      htmltools::tags$title("arbuilder"),
      htmltools::tags$link(rel = "stylesheet", href = "www/app.css"),
      htmltools::tags$script(src = "www/app.js")
    ),

    htmltools::tags$div(
      class = "ar-app",

      # ── Top Bar ──
      htmltools::tags$div(class = "ar-topbar",
        htmltools::tags$div(class = "ar-topbar__brand",
          htmltools::tags$span(class = "ar-topbar__dot"),
          "arbuilder"),
        htmltools::tags$div(class = "ar-topbar__actions",
          shiny::downloadButton("export_rtf", "Export RTF",
            class = "ar-btn-outline btn-sm"),
          shiny::downloadButton("dl_script", ".R",
            class = "ar-btn-ghost btn-sm"),
          htmltools::tags$button(id = "toggle_config",
            class = "ar-btn-ghost btn-sm",
            onclick = "arToggleConfig()",
            htmltools::tags$i(class = "fa fa-columns")))
      ),

      # ── Body: config + preview ──
      htmltools::tags$div(class = "ar-body",

        # Left: Config Accordion
        htmltools::tags$aside(class = "ar-config", id = "ar_config",
          htmltools::tags$div(class = "ar-config__scroll",

            # ── 1. DATA ──
            ar_accordion("data", "Data", icon = "database", is_open = TRUE,
              mod_data_ui("data")
            ),

            # ── 2. ANALYSIS ──
            ar_accordion("analysis", "Analysis", icon = "chart-bar",
              mod_analysis_ui("analysis"),
              htmltools::tags$hr(class = "ar-divider"),
              mod_grouping_ui("grouping"),
              htmltools::tags$hr(class = "ar-divider"),
              mod_stats_ui("stats")
            ),

            # ── 3. FORMAT ──
            ar_accordion("format", "Format", icon = "paint-brush",
              mod_titles_ui("titles"),
              htmltools::tags$hr(class = "ar-divider"),
              mod_columns_ui("cols"),
              htmltools::tags$hr(class = "ar-divider"),
              mod_page_ui("page")
            ),

            # Generate button at bottom
            htmltools::tags$div(class = "ar-config__footer",
              shiny::actionButton("preview_btn", "Generate Preview",
                class = "ar-btn-primary w-100", icon = shiny::icon("play")),
              htmltools::tags$div(class = "ar-config__hint", "Ctrl+Enter")
            )
          )
        ),

        # Right: Live Preview + tabs
        htmltools::tags$div(class = "ar-canvas",
          # Tab bar at top
          htmltools::tags$div(class = "ar-canvas__tabs",
            htmltools::tags$button(id = "tab_data", class = "ar-canvas-tab active",
              onclick = "arSwitchTab('data')",
              shiny::icon("database"), "Data"),
            htmltools::tags$button(id = "tab_ard", class = "ar-canvas-tab",
              onclick = "arSwitchTab('ard')",
              shiny::icon("th"), "ARD"),
            htmltools::tags$button(id = "tab_table", class = "ar-canvas-tab",
              onclick = "arSwitchTab('table')",
              shiny::icon("table"), "Table"),
            htmltools::tags$button(id = "tab_code", class = "ar-canvas-tab",
              onclick = "arSwitchTab('code')",
              shiny::icon("code"), "R Code")
          ),
          # Tab panels
          htmltools::tags$div(class = "ar-canvas__body",
            htmltools::tags$div(id = "panel_data", class = "ar-canvas-panel active",
              mod_data_viewer_ui("data_viewer")),
            htmltools::tags$div(id = "panel_ard", class = "ar-canvas-panel",
              shiny::uiOutput("ard_view")),
            htmltools::tags$div(id = "panel_table", class = "ar-canvas-panel",
              mod_preview_ui("preview")),
            htmltools::tags$div(id = "panel_code", class = "ar-canvas-panel",
              mod_code_ui("code"))
          )
        )
      )
    )
  )
}

#' Accordion section helper
ar_accordion <- function(id, label, icon = NULL, is_open = FALSE, ...) {
  cls <- if (isTRUE(is_open)) "ar-acc ar-acc--open" else "ar-acc"
  htmltools::tags$div(class = cls,
    id = paste0("acc_", id),
    htmltools::tags$button(class = "ar-acc__header",
      onclick = sprintf("arToggleAcc('%s')", id),
      htmltools::tags$span(class = "ar-acc__arrow", "\u25b6"),
      if (!is.null(icon)) htmltools::tags$i(class = paste("fa", paste0("fa-", icon))),
      htmltools::tags$span(class = "ar-acc__label", label)
    ),
    htmltools::tags$div(class = "ar-acc__body", ...)
  )
}

#' bslib theme
ar_theme <- function() {
  bslib::bs_theme(
    version = 5,
    bg = "#ffffff", fg = "#1a1918",
    primary = "#4a6fa5", secondary = "#6b6966",
    success = "#2d8a4e", warning = "#c17a2f", danger = "#c53030",
    base_font = bslib::font_google("Inter", wght = "400;500;600;700"),
    code_font = bslib::font_google("JetBrains Mono", wght = "400;500"),
    heading_font = bslib::font_google("Inter", wght = "600;700"),
    font_scale = 0.875,
    `enable-rounded` = TRUE, `border-radius` = "6px",
    `card-border-color` = "#e5e4e2", `input-border-color` = "#e5e4e2",
    `box-shadow` = "none", `card-box-shadow` = "none"
  )
}
