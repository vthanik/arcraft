# Format Panel — Two-Tab Split (Content + Style)
# Non-reactive draft architecture: modules don't sync to store on every keystroke.
# Format drafts are collected into store$fmt only on Generate Preview.

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
  yml <- read_vellum_yml()
  if (!is.null(yml)) {
    presets$company <- yml
  }
  presets[[preset_name]]
}

# ── Collect Format Drafts from All Modules ──
# Accepts either old 7-module signature or new 5-module signature
collect_format_drafts <- function(titles, cols, header_spans, rows,
                                  page_output, styles = NULL,
                                  base_fmt = NULL) {
  fmt <- normalize_fmt(base_fmt %||% list())
  # Titles
  fmt$titles <- titles$titles %||% fmt$titles
  fmt$footnotes <- titles$footnotes %||% fmt$footnotes
  fmt$fn_separator <- titles$fn_separator %||% fmt$fn_separator
  fmt$fn_placement <- titles$fn_placement %||% fmt$fn_placement
  # Columns
  fmt$cols <- coalesce_list(fmt$cols, cols)
  # Header & Spans
  fmt$header <- coalesce_list(fmt$header, header_spans$header)
  fmt$spans <- header_spans$spans %||% fmt$spans
  col_aligns <- header_spans$col_aligns %||% list()
  if (length(col_aligns) > 0) {
    fmt$header$col_aligns <- col_aligns
  }
  # Rows
  fmt$rows <- coalesce_list(fmt$rows, rows)
  # Page + Rules + Chrome + Spacing + Output (from merged page_output module)
  fmt$page <- coalesce_list(fmt$page, page_output$page)
  fmt$rules <- coalesce_list(fmt$rules, page_output$rules)
  fmt$pagehead <- coalesce_list(fmt$pagehead, page_output$pagehead)
  fmt$pagefoot <- coalesce_list(fmt$pagefoot, page_output$pagefoot)
  if (!is.null(page_output$spacing)) {
    fmt$spacing <- coalesce_list(fmt$spacing, page_output$spacing)
  }
  fmt$output_format <- page_output$output_format %||% fmt$output_format %||% "rtf"
  # Styles
  if (!is.null(styles)) fmt$styles <- styles$styles %||% fmt$styles
  fmt
}

# ── Apply Preset to Store ──
apply_fmt_preset <- function(current_fmt, preset_name) {
  vals <- fmt_preset_values(preset_name)
  if (is.null(vals)) return(current_fmt)
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
  base$titles <- current_fmt$titles
  base$footnotes <- current_fmt$footnotes
  base$fn_separator <- current_fmt$fn_separator
  base$fn_placement <- current_fmt$fn_placement
  base$spans <- current_fmt$spans
  base$rows <- current_fmt$rows
  base$pagehead <- current_fmt$pagehead
  base$pagefoot <- current_fmt$pagefoot
  base
}
