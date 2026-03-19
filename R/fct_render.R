# arframe rendering orchestrator — pure R, no Shiny
# Uses full store$fmt schema → all arframe verb families

fct_render_rtf <- function(tbl_data, format_cfg, path, combined_groups = NULL) {
  # Drop by_value before rendering — handled as row grouping in preview
  if ("by_value" %in% names(tbl_data)) {
    tbl_data$by_value <- NULL
  }

  spec <- tbl_data |> arframe::fr_table()

  # ── Columns (per-column + global) ──
  cols_cfg <- format_cfg$cols %||% list()
  data_cols <- setdiff(names(tbl_data),
    c("variable", "var_label", "var_type", "stat_label", "row_type",
      "timepoint", "baseline_category", "post_category"))

  # Build per-column specs
  per_col <- cols_cfg$per_col %||% list()
  cgs <- combined_groups %||% list()
  spanners <- Filter(function(cg) !is.null(cg$spanner) && nzchar(cg$spanner), cgs)

  col_specs <- list()
  for (col_name in data_cols) {
    args <- list()
    pc <- per_col[[col_name]]

    # Per-column overrides
    if (!is.null(pc$label)) args$label <- pc$label
    if (!is.null(pc$width)) args$width <- pc$width
    if (!is.null(pc$align) && nzchar(pc$align)) args$align <- pc$align
    if (!is.null(pc$visible) && !pc$visible) args$visible <- FALSE

    # Spanner group assignment
    for (sp in spanners) {
      if (col_name %in% sp$arms || col_name == sp$label) {
        args$group <- sp$spanner
        break
      }
    }

    if (length(args) > 0) {
      col_specs[[col_name]] <- do.call(arframe::fr_col, args)
    }
  }

  # Mark first data column as stub with width + alignment
  stub_w <- cols_cfg$stub_width
  stub_a <- cols_cfg$stub_align %||% "left"
  if (length(data_cols) > 0) {
    stub_col <- data_cols[1]
    stub_args <- list(stub = TRUE)
    if (!is.null(stub_w)) stub_args$width <- stub_w
    if (!is.null(stub_a)) stub_args$align <- stub_a
    # Merge with existing per-col spec if present
    if (!is.null(col_specs[[stub_col]])) {
      existing <- col_specs[[stub_col]]
      stub_args <- c(stub_args, as.list(existing))
      stub_args <- stub_args[!duplicated(names(stub_args))]
    }
    col_specs[[stub_col]] <- do.call(arframe::fr_col, stub_args)
  }

  # Apply fr_cols with global + per-column
  cols_args <- list(spec)
  if (length(col_specs) > 0) cols_args <- c(cols_args, col_specs)
  # Global column options
  if (!is.null(cols_cfg$width_mode) && cols_cfg$width_mode != "auto") {
    cols_args$.width <- cols_cfg$width_mode
  }
  if (!is.null(cols_cfg$default_align)) cols_args$.align <- cols_cfg$default_align
  if (!is.null(cols_cfg$spaces) && cols_cfg$spaces != "indent") cols_args$.spaces <- cols_cfg$spaces
  if (isTRUE(cols_cfg$split)) cols_args$.split <- TRUE
  if (!is.null(cols_cfg$n_counts)) cols_args$.n <- cols_cfg$n_counts
  if (!is.null(cols_cfg$n_format)) cols_args$.n_format <- cols_cfg$n_format

  if (length(cols_args) > 1 || length(names(cols_args)) > 1) {
    spec <- do.call(arframe::fr_cols, cols_args)
  }

  # ── Titles (per-title align/bold) ──
  titles <- format_cfg$titles
  title_defaults <- format_cfg$title_defaults %||% list()
  if (length(titles) > 0) {
    title_items <- lapply(titles, function(t) {
      text <- t$text %||% as.character(t)
      bold <- t$bold %||% title_defaults$bold %||% FALSE
      align <- t$align %||% title_defaults$align %||% "center"
      if (bold || align != "center") {
        list(text, bold = bold, align = align)
      } else {
        text
      }
    })
    title_args <- c(list(spec), title_items)
    if (!is.null(title_defaults$align)) title_args$.align <- title_defaults$align
    if (isTRUE(title_defaults$bold)) title_args$.bold <- TRUE
    spec <- do.call(arframe::fr_titles, title_args)
  }

  # ── Footnotes (separator, placement) ──
  footnotes <- format_cfg$footnotes
  fn_texts <- list()
  if (length(footnotes) > 0) {
    fn_texts <- lapply(footnotes, function(f) f$text %||% as.character(f))
  }

  if (length(fn_texts) > 0) {
    fn_args <- c(list(spec), fn_texts)
    if (isTRUE(format_cfg$fn_separator)) fn_args$.separator <- TRUE
    if (!is.null(format_cfg$fn_placement) && format_cfg$fn_placement != "every") {
      fn_args$.placement <- format_cfg$fn_placement
    }
    spec <- do.call(arframe::fr_footnotes, fn_args)
  }

  # ── Header (bold, align, valign, bg, fg) ──
  hdr <- format_cfg$header %||% list(bold = TRUE, align = "center")
  hdr_args <- list(spec)
  if (!is.null(hdr$bold)) hdr_args$bold <- hdr$bold
  if (!is.null(hdr$align)) hdr_args$align <- hdr$align
  if (!is.null(hdr$valign)) hdr_args$valign <- hdr$valign
  if (!is.null(hdr$bg) && nzchar(hdr$bg)) hdr_args$bg <- hdr$bg
  if (!is.null(hdr$fg) && nzchar(hdr$fg)) hdr_args$fg <- hdr$fg
  spec <- do.call(arframe::fr_header, hdr_args)

  # ── Spans (multi-level) ──
  spans <- format_cfg$spans %||% list()
  for (sp in spans) {
    if (nzchar(sp$label) && length(sp$cols) > 0) {
      span_args <- list(spec)
      span_args[[sp$label]] <- sp$cols
      if (!is.null(sp$level) && sp$level > 1) span_args$.level <- sp$level
      spec <- do.call(arframe::fr_spans, span_args)
    }
  }

  # ── Page layout (all params) ──
  page <- format_cfg$page
  if (!is.null(page)) {
    page_args <- list(spec)
    if (!is.null(page$orientation)) page_args$orientation <- page$orientation
    if (!is.null(page$paper)) page_args$paper <- page$paper
    if (!is.null(page$font_family)) page_args$font_family <- page$font_family
    if (!is.null(page$font_size)) page_args$font_size <- page$font_size
    if (!is.null(page$margins)) page_args$margins <- page$margins
    if (!is.null(page$col_gap)) page_args$col_gap <- page$col_gap
    if (!is.null(page$continuation) && nzchar(page$continuation)) page_args$continuation <- page$continuation
    if (!is.null(page$orphan_min)) page_args$orphan_min <- page$orphan_min
    if (!is.null(page$widow_min)) page_args$widow_min <- page$widow_min
    spec <- do.call(arframe::fr_page, page_args)
  }

  # ── Rules (presets + custom) ──
  rules <- format_cfg$rules
  if (!is.null(rules)) {
    if (!is.null(rules$hline_preset)) {
      hline_args <- list(spec, rules$hline_preset)
      if (!is.null(rules$line_width) && rules$line_width != "thin") hline_args$width <- rules$line_width
      if (!is.null(rules$line_color) && rules$line_color != "#000000") hline_args$color <- rules$line_color
      if (!is.null(rules$line_style) && rules$line_style != "solid") hline_args$linestyle <- rules$line_style
      spec <- do.call(arframe::fr_hlines, hline_args)
    }
    if (!is.null(rules$vline_preset) && rules$vline_preset != "none") {
      spec <- arframe::fr_vlines(spec, rules$vline_preset)
    }
  }

  # ── Rows (group, page, indent, etc.) ──
  rows <- format_cfg$rows %||% list()
  row_args <- list(spec)
  has_row_arg <- FALSE
  if (!is.null(rows$group_by)) { row_args$group_by <- rows$group_by; has_row_arg <- TRUE }
  if (!is.null(rows$blank_after)) { row_args$blank_after <- rows$blank_after; has_row_arg <- TRUE }
  if (!is.null(rows$page_by)) { row_args$page_by <- rows$page_by; has_row_arg <- TRUE }
  if (isTRUE(rows$page_by_bold)) { row_args$page_by_bold <- TRUE; has_row_arg <- TRUE }
  if (!is.null(rows$indent_by)) { row_args$indent_by <- rows$indent_by; has_row_arg <- TRUE }
  if (!is.null(rows$repeat_cols)) { row_args$repeat_cols <- rows$repeat_cols; has_row_arg <- TRUE }
  if (isTRUE(rows$wrap)) { row_args$wrap <- TRUE; has_row_arg <- TRUE }
  if (has_row_arg) {
    spec <- do.call(arframe::fr_rows, row_args)
  }

  # ── Page chrome ──
  ph <- format_cfg$pagehead %||% list()
  if (any(nzchar(c(ph$left, ph$center, ph$right)))) {
    ph_args <- list(spec)
    if (nzchar(ph$left %||% "")) ph_args$left <- ph$left
    if (nzchar(ph$center %||% "")) ph_args$center <- ph$center
    if (nzchar(ph$right %||% "")) ph_args$right <- ph$right
    spec <- do.call(arframe::fr_pagehead, ph_args)
  }

  pf <- format_cfg$pagefoot %||% list()
  if (any(nzchar(c(pf$left, pf$center, pf$right)))) {
    pf_args <- list(spec)
    if (nzchar(pf$left %||% "")) pf_args$left <- pf$left
    if (nzchar(pf$center %||% "")) pf_args$center <- pf$center
    if (nzchar(pf$right %||% "")) pf_args$right <- pf$right
    spec <- do.call(arframe::fr_pagefoot, pf_args)
  }

  # ── Spacing ──
  sp <- format_cfg$spacing %||% list()
  sp_args <- list(spec)
  has_sp <- FALSE
  if (!is.null(sp$titles_after) && sp$titles_after != 1L) { sp_args$titles_after <- sp$titles_after; has_sp <- TRUE }
  if (!is.null(sp$footnotes_before) && sp$footnotes_before != 1L) { sp_args$footnotes_before <- sp$footnotes_before; has_sp <- TRUE }
  if (!is.null(sp$pagehead_after) && sp$pagehead_after != 0L) { sp_args$pagehead_after <- sp$pagehead_after; has_sp <- TRUE }
  if (!is.null(sp$pagefoot_before) && sp$pagefoot_before != 0L) { sp_args$pagefoot_before <- sp$pagefoot_before; has_sp <- TRUE }
  if (has_sp) {
    spec <- do.call(arframe::fr_spacing, sp_args)
  }

  arframe::fr_render(spec, path)
  path
}
