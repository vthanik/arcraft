# Shared intermediate representation for format configuration
# Both fct_render.R and fct_codegen.R consume this IR instead of
# duplicating format-config normalization logic.

#' Build a normalized IR (intermediate representation) from format_cfg
#'
#' @param format_cfg List — the raw format configuration from the store
#' @param combined_groups List — optional combined treatment groups with spanner info
#' @return A plain list with normalized sections: cols, titles, footnotes,
#'   header, spans, page, rules, rows, pagehead, pagefoot, spacing, styles, output_format
fct_build_ir <- function(format_cfg, combined_groups = NULL) {
  format_cfg <- format_cfg %||% list()

  # ── Columns ──
  cols_cfg <- format_cfg$cols %||% list()

  cols <- list(
    global = list(
      align      = cols_cfg$default_align,
      width_mode = cols_cfg$width_mode,
      space_mode = cols_cfg$space_mode,
      split      = cols_cfg$split,
      n_counts   = cols_cfg$n_counts,
      n_values   = cols_cfg$n_values,
      n_format   = cols_cfg$n_format
    ),
    stub = list(
      col   = cols_cfg$stub_col %||% "stat_label",
      width = cols_cfg$stub_width,
      align = cols_cfg$stub_align %||% "left"
    ),
    per_col     = cols_cfg$per_col %||% list(),
    meta_hidden = c("variable", "var_label", "var_type", "row_type",
                    "category", "soc",
                    "timepoint", "baseline_category", "post_category")
  )

  # ── Titles ──
  titles <- list(
    items    = format_cfg$titles %||% list(),
    defaults = format_cfg$title_defaults %||% list(align = "center", bold = FALSE)
  )

  # ── Footnotes ──
  footnotes <- list(
    items     = format_cfg$footnotes %||% list(),
    separator = format_cfg$fn_separator %||% FALSE,
    placement = format_cfg$fn_placement %||% "every"
  )

  # ── Header ──
  hdr_cfg <- format_cfg$header %||% list()
  header <- list(
    bold           = hdr_cfg$bold %||% TRUE,
    align          = hdr_cfg$align %||% "center",
    valign         = hdr_cfg$valign %||% "bottom",
    background     = hdr_cfg$background,
    color          = hdr_cfg$color,
    font_size      = hdr_cfg$font_size,
    repeat_on_page = hdr_cfg$repeat_on_page,
    col_aligns     = hdr_cfg$col_aligns %||% list()
  )

  # ── Spans (from format_cfg + combined_groups spanners) ──
  spans <- format_cfg$spans %||% list()

  cgs <- combined_groups %||% list()
  spanners <- Filter(function(cg) !is.null(cg$spanner) && nzchar(cg$spanner), cgs)
  if (length(spanners) > 0) {
    for (sp in spanners) {
      spans[[length(spans) + 1L]] <- list(
        label = sp$spanner,
        cols  = sp$arms %||% character(0)
      )
    }
  }

  # ── Page ──
  page_defaults <- list(
    orientation  = "landscape",
    paper        = "letter",
    font_family  = "Courier New",
    font_size    = 9,
    margins      = c(1, 1, 1, 1),
    col_gap      = 4,
    continuation = "",
    orphan_min   = 3L,
    widow_min    = 3L
  )
  page <- format_cfg$page %||% page_defaults

  # ── Rules ──
  rules_cfg <- format_cfg$rules %||% list()
  rules <- list(
    hline_preset   = rules_cfg$hline_preset,
    vline_preset   = rules_cfg$vline_preset,
    line_width     = rules_cfg$line_width %||% "thin",
    line_color     = rules_cfg$line_color %||% "#000000",
    line_style     = rules_cfg$line_style %||% "solid",
    vline_cols     = rules_cfg$vline_cols,
    vline_abovepos = rules_cfg$vline_abovepos,
    vline_belowpos = rules_cfg$vline_belowpos
  )

  # ── Rows ──
  rows_cfg <- format_cfg$rows %||% list()
  rows <- list(
    group_by        = rows_cfg$group_by,
    group_label     = rows_cfg$group_label,
    group_keep      = rows_cfg$group_keep,
    blank_after     = rows_cfg$blank_after,
    page_by         = rows_cfg$page_by,
    page_by_visible = rows_cfg$page_by_visible,
    indent_by       = rows_cfg$indent_by,
    sort_by         = rows_cfg$sort_by,
    suppress        = rows_cfg$suppress,
    wrap            = rows_cfg$wrap %||% FALSE
  )

  # ── Page header ──
  ph_cfg <- format_cfg$pagehead %||% list()
  pagehead <- list(
    left      = ph_cfg$left %||% "",
    center    = ph_cfg$center %||% "",
    right     = ph_cfg$right %||% "",
    font_size = ph_cfg$font_size,
    bold      = ph_cfg$bold
  )

  # ── Page footer ──
  pf_cfg <- format_cfg$pagefoot %||% list()
  pagefoot <- list(
    left      = pf_cfg$left %||% "",
    center    = pf_cfg$center %||% "",
    right     = pf_cfg$right %||% "",
    font_size = pf_cfg$font_size,
    bold      = pf_cfg$bold
  )

  # ── Spacing ──
  sp_cfg <- format_cfg$spacing %||% list()
  spacing <- list(
    titles_after     = sp_cfg$titles_after %||% 1L,
    footnotes_before = sp_cfg$footnotes_before %||% 1L,
    pagehead_after   = sp_cfg$pagehead_after %||% 0L,
    pagefoot_before  = sp_cfg$pagefoot_before %||% 0L,
    page_by_after    = sp_cfg$page_by_after
  )

  # ── Assemble ──
  list(
    cols          = cols,
    titles        = titles,
    footnotes     = footnotes,
    header        = header,
    spans         = spans,
    page          = page,
    rules         = rules,
    rows          = rows,
    pagehead      = pagehead,
    pagefoot      = pagefoot,
    spacing       = spacing,
    styles        = format_cfg$styles %||% list(),
    output_format = format_cfg$output_format %||% "rtf"
  )
}
