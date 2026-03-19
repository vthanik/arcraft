# Format Panel — Two-Tab Split (Content + Style)
# Non-reactive draft architecture: modules don't sync to store on every keystroke.
# Format drafts are collected into store$fmt only on Generate Preview.

# ── Preset Pill Helper ──
preset_pill <- function(id, label) {
  htmltools::tags$button(
    class = "ar-pill",
    onclick = sprintf(
      "Shiny.setInputValue('%s', Math.random(), {priority: 'event'}); arFmtPresetActive(this);", id),
    label
  )
}

# ── Preset Definitions ──
fmt_preset_values <- function(preset_name) {
  presets <- list(
    fda = list(
      page = list(orientation = "landscape", paper = "letter",
                  font_family = "Courier New", font_size = 9,
                  margins = c(1, 1, 1, 1)),
      cols = list(default_align = "center", n_counts = TRUE,
                  n_format = "(N={n})", width_mode = "auto",
                  stub_align = "left"),
      rules = list(hline_preset = "header", vline_preset = "none",
                   line_width = "thin", line_style = "solid"),
      header = list(bold = TRUE, align = "center")
    ),
    booktabs = list(
      page = list(font_family = "Times New Roman", font_size = 10),
      cols = list(default_align = "center", stub_align = "left"),
      rules = list(hline_preset = "booktabs", vline_preset = "none",
                   line_width = "thin", line_style = "solid"),
      header = list(bold = TRUE, align = "center")
    ),
    minimal = list(
      page = list(font_family = "Arial", font_size = 9),
      cols = list(default_align = "left", stub_align = "left"),
      rules = list(hline_preset = "above", vline_preset = "none",
                   line_width = "hairline", line_style = "solid"),
      header = list(bold = FALSE, align = "left")
    ),
    company = NULL
  )
  yml <- read_arframe_yml()
  if (!is.null(yml)) {
    presets$company <- yml
  }
  presets[[preset_name]]
}

# ── Collect Format Drafts from All Modules ──
collect_format_drafts <- function(titles, cols, page, rules, header_spans,
                                  rows, chrome, base_fmt = NULL) {
  fmt <- normalize_fmt(base_fmt %||% list())
  # Titles
  fmt$titles <- titles$titles %||% fmt$titles
  fmt$footnotes <- titles$footnotes %||% fmt$footnotes
  fmt$fn_separator <- titles$fn_separator %||% fmt$fn_separator
  fmt$fn_placement <- titles$fn_placement %||% fmt$fn_placement
  # Columns
  fmt$cols <- coalesce_list(fmt$cols, cols)
  # Page
  fmt$page <- coalesce_list(fmt$page, page)
  # Rules
  fmt$rules <- coalesce_list(fmt$rules, rules)
  # Header & Spans
  fmt$header <- coalesce_list(fmt$header, header_spans$header)
  fmt$spans <- header_spans$spans %||% fmt$spans
  # Rows
  fmt$rows <- coalesce_list(fmt$rows, rows)
  # Chrome
  fmt$pagehead <- coalesce_list(fmt$pagehead, chrome$pagehead)
  fmt$pagefoot <- coalesce_list(fmt$pagefoot, chrome$pagefoot)
  fmt
}

# ── Apply Preset to Store ──
apply_fmt_preset <- function(store, preset_name) {
  vals <- fmt_preset_values(preset_name)
  if (is.null(vals)) return(invisible())
  current <- shiny::isolate(store$fmt)
  base <- normalize_fmt(list())
  # Merge preset over base
  for (section in names(vals)) {
    if (is.list(base[[section]]) && is.list(vals[[section]])) {
      base[[section]] <- coalesce_list(base[[section]], vals[[section]])
    } else {
      base[[section]] <- vals[[section]]
    }
  }
  # Preserve user content (titles, footnotes, spans, rows, chrome)
  base$titles <- current$titles
  base$footnotes <- current$footnotes
  base$fn_separator <- current$fn_separator
  base$fn_placement <- current$fn_placement
  base$spans <- current$spans
  base$rows <- current$rows
  base$pagehead <- current$pagehead
  base$pagefoot <- current$pagefoot
  store$fmt <- base
}

# ── Format Panel UI: Two-Tab Split (Content + Style) ──
format_panel_ui <- function() {
  htmltools::tags$div(class = "ar-fmt ar-fmt-v2",
    bslib::navset_pill(id = "fmt_tabs",
      # ── Content Tab ──
      bslib::nav_panel("Content",
        icon = shiny::icon("align-left"),
        htmltools::tags$div(class = "ar-fmt-tab-body",
          bslib::accordion(id = "acc_fmt_content",
            open = "TITLES & FOOTNOTES", multiple = TRUE,
            bslib::accordion_panel("TITLES & FOOTNOTES",
              mod_titles_ui("titles")),
            bslib::accordion_panel("HEADER & SPANS",
              mod_header_spans_ui("header_spans")),
            bslib::accordion_panel("ROW STRUCTURE",
              mod_rows_ui("rows"))
          )
        )
      ),
      # ── Style Tab ──
      bslib::nav_panel("Style",
        icon = shiny::icon("palette"),
        htmltools::tags$div(class = "ar-fmt-tab-body ar-style",
          # Preset pills — clean, no label
          htmltools::tags$div(class = "ar-style__presets",
            htmltools::tags$span(class = "ar-style__presets-label", "Preset"),
            htmltools::tags$div(class = "ar-fmt-preset-pills",
              preset_pill("fmt_preset_fda", "FDA"),
              preset_pill("fmt_preset_booktabs", "Booktabs"),
              preset_pill("fmt_preset_minimal", "Minimal"),
              preset_pill("fmt_preset_company", "Company")
            )
          ),
          bslib::accordion(id = "acc_fmt_style",
            open = "Page", multiple = TRUE,
            bslib::accordion_panel("Page",
              mod_page_ui("page")),
            bslib::accordion_panel("Columns",
              mod_columns_ui("cols")),
            bslib::accordion_panel("Rules",
              mod_rules_ui("rules")),
            bslib::accordion_panel("Page Chrome",
              mod_page_chrome_ui("page_chrome"))
          )
        )
      )
    )
  )
}
