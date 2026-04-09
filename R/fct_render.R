# vellum rendering orchestrator — pure R, no Shiny
# Consumes IR from fct_build_ir() → walks sections → vellum verbs

# ── Build fr_spec from ARD data + format config ──
fct_build_spec <- function(tbl_data, format_cfg, combined_groups = NULL) {
  ir <- fct_build_ir(format_cfg, combined_groups)
  # Only drop group_value if it's not used by any row structure feature
  row_cols <- c(ir$rows$page_by, ir$rows$group_by, ir$rows$indent_by)
  if ("group_value" %in% names(tbl_data) && !"group_value" %in% row_cols) {
    tbl_data$group_value <- NULL
  }
  spec <- tbl_data |> vellum::fr_table()

  # ── Columns ──
  col_specs <- list()
  for (mc in intersect(ir$cols$meta_hidden, names(tbl_data)))
    col_specs[[mc]] <- vellum::fr_col(visible = FALSE)

  for (cn in names(tbl_data)) {
    a <- list()
    pc <- ir$cols$per_col[[cn]]
    if (!is.null(pc$label))                      a$label   <- resolve_newlines(pc$label)
    if (!is.null(pc$width))                      a$width   <- pc$width
    if (!is.null(pc$align) && nzchar(pc$align))  a$align   <- pc$align
    if (!is.null(pc$visible) && !pc$visible)     a$visible <- FALSE
    for (sp in ir$spans)
      if (cn %in% (sp$cols %||% character(0))) { a$group <- sp$label; break }
    ha <- ir$header$col_aligns[[cn]]
    if (!is.null(ha)) a$header_align <- ha
    if (length(a) > 0) col_specs[[cn]] <- do.call(vellum::fr_col, a)
  }

  # Stub column
  sc <- ir$cols$stub$col
  if (!is.null(sc) && sc %in% names(tbl_data)) {
    sa <- list(stub = TRUE)
    if (!is.null(ir$cols$stub$width)) sa$width <- ir$cols$stub$width
    if (!is.null(col_specs[[sc]])) {
      ex <- Filter(Negate(is.null), as.list(col_specs[[sc]])); ex$id <- NULL
      sa <- c(ex, sa); sa <- sa[!duplicated(names(sa))]
    }
    if (is.null(sa$align)) sa$align <- ir$cols$stub$align
    col_specs[[sc]] <- do.call(vellum::fr_col, sa)
  }

  # Global column options
  g <- ir$cols$global
  ca <- c(list(spec), col_specs)
  if (!is.null(g$width_mode) && g$width_mode != "auto") ca$.width    <- g$width_mode
  if (!is.null(g$align))                                ca$.align    <- g$align
  if (!is.null(g$space_mode) && g$space_mode != "indent") ca$.space_mode <- g$space_mode
  if (isTRUE(g$split))                                  ca$.split    <- TRUE
  if (isTRUE(g$n_counts) && length(g$n_values) > 0)     ca$.n        <- g$n_values
  if (!is.null(g$n_format))                              ca$.n_format <- resolve_newlines(g$n_format)
  if (length(ca) > 1) spec <- do.call(vellum::fr_cols, ca)

  # ── Titles ──
  if (length(ir$titles$items) > 0) {
    d <- ir$titles$defaults
    ti <- lapply(ir$titles$items, function(t) {
      txt <- resolve_newlines(t$text %||% as.character(t))
      b <- t$bold %||% d$bold %||% FALSE; al <- t$align %||% d$align %||% "center"
      if (b || al != "center") list(txt, bold = b, align = al) else txt
    })
    ta <- c(list(spec), ti)
    if (!is.null(d$align)) ta$.align <- d$align
    if (isTRUE(d$bold))   ta$.bold  <- TRUE
    spec <- do.call(vellum::fr_titles, ta)
  }

  # ── Footnotes ──
  ft <- lapply(ir$footnotes$items, function(f) resolve_newlines(f$text %||% as.character(f)))
  if (length(ft) > 0) {
    fa <- c(list(spec), ft)
    if (isTRUE(ir$footnotes$separator))    fa$.separator <- TRUE
    if (ir$footnotes$placement != "every") fa$.placement <- ir$footnotes$placement
    spec <- do.call(vellum::fr_footnotes, fa)
  }

  # ── Header ──
  h <- ir$header
  ha <- list(spec)
  if (!is.null(h$bold))                  ha$bold   <- h$bold
  if (!is.null(h$align))                 ha$align  <- h$align
  if (!is.null(h$valign))                ha$valign <- h$valign
  if (!is.null(h$background) && nzchar(h$background)) ha$background <- h$background
  if (!is.null(h$color) && nzchar(h$color))           ha$color      <- h$color
  if (!is.null(h$font_size))                           ha$font_size  <- h$font_size
  if (!is.null(h$repeat_on_page))                      ha$repeat_on_page <- h$repeat_on_page
  spec <- do.call(vellum::fr_header, ha)

  # ── Spans ──
  for (sp in ir$spans) {
    if (nzchar(sp$label) && length(sp$cols) > 0) {
      sa <- list(spec); sa[[sp$label]] <- sp$cols
      if (!is.null(sp$level) && sp$level > 1) sa$.level <- sp$level
      spec <- do.call(vellum::fr_spans, sa)
    }
  }

  # ── Page ──
  if (!is.null(ir$page)) {
    pa <- list(spec)
    for (nm in c("orientation","paper","font_family","font_size","margins","col_gap","orphan_min","widow_min"))
      if (!is.null(ir$page[[nm]])) pa[[nm]] <- ir$page[[nm]]
    if (!is.null(ir$page$continuation) && nzchar(ir$page$continuation))
      pa$continuation <- resolve_newlines(ir$page$continuation)
    spec <- do.call(vellum::fr_page, pa)
  }

  # ── Rules ──
  r <- ir$rules
  if (!is.null(r$hline_preset)) {
    ra <- list(spec, r$hline_preset)
    if (r$line_width != "thin")    ra$width     <- r$line_width
    if (r$line_color != "#000000") ra$color     <- r$line_color
    if (r$line_style != "solid")   ra$linestyle <- r$line_style
    spec <- do.call(vellum::fr_hlines, ra)
  }
  if (!is.null(r$vline_preset) && r$vline_preset != "none")
    spec <- vellum::fr_vlines(spec, r$vline_preset)

  # ── Rows — only pass column refs that exist in tbl_data ──
  data_cols <- names(tbl_data)
  rw <- ir$rows; ra <- list(spec); hr <- FALSE
  # Column-reference params: validate they exist in data
  for (nm in c("group_by","blank_after","page_by","indent_by"))
    if (!is.null(rw[[nm]]) && rw[[nm]] %in% data_cols) { ra[[nm]] <- rw[[nm]]; hr <- TRUE }
  if (!is.null(rw$sort_by)) {
    valid_sort <- rw$sort_by[rw$sort_by %in% data_cols]
    if (length(valid_sort) > 0) { ra$sort_by <- valid_sort; hr <- TRUE }
  }
  if (!is.null(rw$suppress)) {
    valid <- rw$suppress[rw$suppress %in% data_cols]
    if (length(valid) > 0) { ra$suppress <- valid; hr <- TRUE }
  }
  # group_by list form: include label if group_label is set
  if (!is.null(ra$group_by) && !is.null(rw$group_label) && rw$group_label %in% data_cols) {
    ra$group_by <- list(cols = ra$group_by, label = rw$group_label); hr <- TRUE
  }
  # page_by list form: include visible = FALSE if page_by_visible is FALSE
  if (!is.null(ra$page_by) && isFALSE(rw$page_by_visible)) {
    ra$page_by <- list(cols = ra$page_by, visible = FALSE); hr <- TRUE
  }
  # Boolean/scalar params
  if (!is.null(ra$group_by) && isFALSE(rw$group_keep)) {
    ra$group_keep <- FALSE; hr <- TRUE
  }
  if (isTRUE(rw$wrap)) { ra$wrap <- TRUE; hr <- TRUE }
  if (hr) spec <- do.call(vellum::fr_rows, ra)

  # ── Page chrome ──
  for (verb in c("pagehead", "pagefoot")) {
    chrome <- ir[[verb]]
    if (any(nzchar(c(chrome$left, chrome$center, chrome$right)))) {
      va <- list(spec)
      for (nm in c("left","center","right"))
        if (nzchar(chrome[[nm]])) va[[nm]] <- resolve_newlines(chrome[[nm]])
      spec <- do.call(getExportedValue("vellum", paste0("fr_", verb)), va)
    }
  }

  # ── Spacing ──
  s <- ir$spacing; sa <- list(spec); hs <- FALSE
  if (s$titles_after != 1L)     { sa$titles_after     <- s$titles_after;     hs <- TRUE }
  if (s$footnotes_before != 1L) { sa$footnotes_before <- s$footnotes_before; hs <- TRUE }
  if (s$pagehead_after != 0L)   { sa$pagehead_after   <- s$pagehead_after;   hs <- TRUE }
  if (s$pagefoot_before != 0L)  { sa$pagefoot_before  <- s$pagefoot_before;  hs <- TRUE }
  if (!is.null(s$page_by_after)) { sa$page_by_after  <- s$page_by_after;   hs <- TRUE }
  if (hs) spec <- do.call(vellum::fr_spacing, sa)

  # ── Styles ──
  stys <- ir$styles
  if (length(stys) > 0) {
    style_objs <- list()
    for (sname in names(stys)) {
      s <- stys[[sname]]
      if (s$type == "row_match") {
        # fr_row_style + fr_rows_matches: pattern-based row styling
        match_args <- list(col = s$col)
        if (!is.null(s$pattern)) match_args$pattern <- s$pattern
        if (!is.null(s$value))   match_args$value   <- s$value
        rs_args <- list(rows = do.call(vellum::fr_rows_matches, match_args))
        if (isTRUE(s$bold))       rs_args$bold       <- TRUE
        if (!is.null(s$background)) rs_args$background <- s$background
        if (!is.null(s$color))     rs_args$color      <- s$color
        if (!is.null(s$italic))   rs_args$italic     <- s$italic
        style_objs[[length(style_objs) + 1]] <- do.call(vellum::fr_row_style, rs_args)
      } else if (s$type == "conditional") {
        # fr_style_if: condition-based styling
        si_args <- list(condition = rlang::as_function(stats::as.formula(s$condition)))
        if (!is.null(s$cols))     si_args$cols     <- s$cols
        if (!is.null(s$apply_to)) si_args$apply_to <- s$apply_to
        if (isTRUE(s$bold))       si_args$bold     <- TRUE
        if (!is.null(s$background)) si_args$background <- s$background
        if (!is.null(s$color))     si_args$color      <- s$color
        if (!is.null(s$italic))   si_args$italic   <- s$italic
        style_objs[[length(style_objs) + 1]] <- do.call(vellum::fr_style_if, si_args)
      } else if (s$type == "row") {
        rs_args <- list()
        if (!is.null(s$match))  rs_args$rows   <- s$match
        if (isTRUE(s$bold))     rs_args$bold   <- TRUE
        if (!is.null(s$background)) rs_args$background <- s$background
        if (!is.null(s$color))     rs_args$color      <- s$color
        if (!is.null(s$italic)) rs_args$italic <- s$italic
        style_objs[[length(style_objs) + 1]] <- do.call(vellum::fr_row_style, rs_args)
      }
    }
    if (length(style_objs) > 0) {
      spec <- do.call(vellum::fr_styles, c(list(spec), style_objs))
    }
  }

  spec
}

# ── Render to RTF file ──
fct_render_rtf <- function(tbl_data, format_cfg, path, combined_groups = NULL) {
  spec <- fct_build_spec(tbl_data, format_cfg, combined_groups)
  vellum::fr_render(spec, path)
  path
}

# ── Render to HTML string for live preview ──
fct_render_html_preview <- function(tbl_data, format_cfg, combined_groups = NULL) {
  spec <- fct_build_spec(tbl_data, format_cfg, combined_groups)
  tmp <- tempfile(fileext = ".html")
  on.exit(unlink(tmp), add = TRUE)
  vellum::fr_render(spec, tmp)
  paste0(readLines(tmp, warn = FALSE), collapse = "\n")
}
