# HTML preview builder — pure R, no Shiny
# Builds a structural HTML approximation of the final RTF table
# Handles: standard ARD, hierarchical (row_type), timepoint, shift
# Enhanced: spans, header colors, rules borders, per-title align/bold

fct_build_preview_html <- function(ard, format_cfg) {
  if (is.null(ard) || nrow(ard) == 0) return(NULL)

  titles <- format_cfg$titles %||% list()
  title_defaults <- format_cfg$title_defaults %||% list()
  footnotes <- format_cfg$footnotes %||% list()
  page <- format_cfg$page %||% list()
  font_family <- page$font_family %||% "Courier New"
  font_size <- page$font_size %||% 9
  hdr <- format_cfg$header %||% list(bold = TRUE, align = "center")
  spans <- format_cfg$spans %||% list()
  rules <- format_cfg$rules %||% list()
  cols_cfg <- format_cfg$cols %||% list()

  # Identify data columns
  meta_cols <- c("variable", "var_label", "var_type", "stat_label",
                  "row_type", "timepoint", "baseline_category", "post_category",
                  "by_value")
  data_cols <- setdiff(names(ard), meta_cols)

  # Detect ARD shape
  has_row_type <- "row_type" %in% names(ard)
  has_timepoint <- "timepoint" %in% names(ard)
  has_shift <- "baseline_category" %in% names(ard)

  # ── Build title HTML (per-title align/bold) ──
  title_html <- if (length(titles) > 0) {
    title_divs <- lapply(titles, function(t) {
      text <- if (is.list(t)) t$text %||% "" else as.character(t)
      bold <- if (is.list(t)) isTRUE(t$bold) else FALSE
      align <- if (is.list(t)) t$align %||% title_defaults$align %||% "center" else "center"
      cls <- if (bold) "ar-preview__title ar-preview__title--bold" else "ar-preview__title"
      style <- paste0("text-align: ", align, ";")
      htmltools::tags$div(class = cls, style = style, text)
    })
    htmltools::tags$div(class = "ar-preview__titles", title_divs)
  }


  # ── Page chrome: running header ──
  ph <- format_cfg$pagehead %||% list()
  pagehead_html <- if (any(nzchar(c(ph$left, ph$center, ph$right)))) {
    htmltools::tags$div(class = "ar-preview__pagehead",
      htmltools::tags$span(class = "ar-preview__pagehead-left", ph$left %||% ""),
      htmltools::tags$span(class = "ar-preview__pagehead-center", ph$center %||% ""),
      htmltools::tags$span(class = "ar-preview__pagehead-right", ph$right %||% "")
    )
  }

  # ── Rules CSS ──
  border_style <- build_rules_css(rules)

  # ── Header styling ──
  th_style <- build_header_style(hdr)

  # ── Spanning headers ──
  span_row_html <- build_span_row(spans, data_cols, hdr)

  # ── Table header ──
  # Per-column labels from cols config
  per_col <- cols_cfg$per_col %||% list()
  header_cells <- c(
    list(htmltools::tags$th(class = "ar-preview__th ar-preview__th--stub",
      style = th_style, "")),
    lapply(data_cols, function(col) {
      pc <- per_col[[col]]
      label <- pc$label %||% col
      visible <- pc$visible %||% TRUE
      if (!visible) return(NULL)
      htmltools::tags$th(class = "ar-preview__th", style = th_style, label)
    })
  )
  header_cells <- Filter(Negate(is.null), header_cells)
  thead_rows <- list(htmltools::tags$tr(header_cells))
  if (!is.null(span_row_html)) thead_rows <- c(list(span_row_html), thead_rows)
  thead <- htmltools::tags$thead(thead_rows)

  # ── Table body ──
  body_rows <- if (has_row_type) {
    build_hierarchical_rows(ard, data_cols, per_col)
  } else if (has_timepoint) {
    build_timepoint_rows(ard, data_cols, per_col)
  } else if (has_shift) {
    build_shift_rows(ard, data_cols, per_col)
  } else {
    build_standard_rows(ard, data_cols, per_col)
  }

  tbody <- htmltools::tags$tbody(body_rows)
  tbl <- htmltools::tags$table(
    class = "ar-preview__table",
    style = border_style,
    thead, tbody
  )

  # ── Footnotes ──
  fn_sep_cls <- if (isTRUE(format_cfg$fn_separator)) {
    "ar-preview__footnotes ar-preview__footnotes--separator"
  } else "ar-preview__footnotes"

  fn_html <- if (length(footnotes) > 0) {
    fn_divs <- lapply(footnotes, function(f) {
      text <- if (is.list(f)) f$text %||% "" else as.character(f)
      htmltools::tags$div(class = "ar-preview__footnote", text)
    })
    htmltools::tags$div(class = fn_sep_cls, fn_divs)
  }


  # ── Page chrome: running footer ──
  pf <- format_cfg$pagefoot %||% list()
  pagefoot_html <- if (any(nzchar(c(pf$left, pf$center, pf$right)))) {
    htmltools::tags$div(class = "ar-preview__pagefoot",
      htmltools::tags$span(class = "ar-preview__pagefoot-left", pf$left %||% ""),
      htmltools::tags$span(class = "ar-preview__pagefoot-center", pf$center %||% ""),
      htmltools::tags$span(class = "ar-preview__pagefoot-right", pf$right %||% "")
    )
  }

  # Wrap everything
  htmltools::tags$div(
    class = "ar-preview",
    style = paste0("font-family: ", font_family, "; font-size: ", font_size, "pt;"),
    pagehead_html,
    title_html,
    tbl,
    fn_html,
    pagefoot_html
  )
}

# ── Helper: Build rules CSS for table borders ──
build_rules_css <- function(rules) {
  preset <- rules$hline_preset %||% "header"
  vpreset <- rules$vline_preset %||% "none"
  width <- switch(rules$line_width %||% "thin",
    hairline = "0.5px", thin = "1px", medium = "2px", thick = "3px", "1px")
  color <- rules$line_color %||% "#000000"
  style <- rules$line_style %||% "solid"
  border_def <- paste(width, style, color)

  css <- ""
  # Horizontal preset mapping
  if (preset == "booktabs") {
    css <- paste0(css, "border-top: ", gsub("1px", "2px", border_def), "; ",
                  "border-bottom: ", gsub("1px", "2px", border_def), "; ")
  } else if (preset == "box") {
    css <- paste0(css, "border: ", border_def, "; ")
  } else if (preset == "header") {
    css <- paste0(css, "border-collapse: collapse; ")
  } else if (preset == "void") {
    css <- paste0(css, "border: none; ")
  }

  # Vertical preset
  if (vpreset == "box") {
    css <- paste0(css, "border-left: ", border_def, "; border-right: ", border_def, "; ")
  }

  css
}

# ── Helper: Build header inline style ──
build_header_style <- function(hdr) {
  parts <- c()
  if (isTRUE(hdr$bold)) parts <- c(parts, "font-weight: 700")
  if (!is.null(hdr$align)) parts <- c(parts, paste0("text-align: ", hdr$align))
  if (!is.null(hdr$valign)) parts <- c(parts, paste0("vertical-align: ", hdr$valign))
  if (!is.null(hdr$bg) && nzchar(hdr$bg)) parts <- c(parts, paste0("background-color: ", hdr$bg))
  if (!is.null(hdr$fg) && nzchar(hdr$fg)) parts <- c(parts, paste0("color: ", hdr$fg))
  paste(parts, collapse = "; ")
}

# ── Helper: Build spanning header row ──
build_span_row <- function(spans, data_cols, hdr) {
  if (length(spans) == 0) return(NULL)

  th_style <- build_header_style(hdr)

  # Build column-to-span mapping
  col_span_map <- rep(NA_character_, length(data_cols))
  names(col_span_map) <- data_cols
  for (sp in spans) {
    for (col in sp$cols) {
      if (col %in% data_cols) col_span_map[col] <- sp$label
    }
  }

  # Build cells
  cells <- list(htmltools::tags$th(class = "ar-preview__th ar-preview__th--stub",
    style = th_style, ""))
  i <- 1
  while (i <= length(data_cols)) {
    span_label <- col_span_map[i]
    if (!is.na(span_label)) {
      # Count consecutive columns with same span
      span_width <- 1
      while (i + span_width <= length(data_cols) &&
             !is.na(col_span_map[i + span_width]) &&
             col_span_map[i + span_width] == span_label) {
        span_width <- span_width + 1
      }
      cells <- c(cells, list(
        htmltools::tags$th(
          class = "ar-preview__th ar-preview__th--span",
          style = paste0(th_style, "; border-bottom: 1px solid currentColor;"),
          colspan = span_width, span_label)
      ))
      i <- i + span_width
    } else {
      cells <- c(cells, list(htmltools::tags$th(class = "ar-preview__th", style = th_style, "")))
      i <- i + 1
    }
  }

  htmltools::tags$tr(class = "ar-preview__span-row", cells)
}

# ── Helper: filter hidden columns ──
visible_data_cols <- function(data_cols, per_col) {
  Filter(function(col) {
    pc <- per_col[[col]]
    is.null(pc$visible) || isTRUE(pc$visible)
  }, data_cols)
}

# ── Standard rows: group by variable, show var_label header + stat rows ──
build_standard_rows <- function(ard, data_cols, per_col = list()) {
  vis_cols <- visible_data_cols(data_cols, per_col)
  has_by <- "by_value" %in% names(ard)

  if (!has_by) {
    return(build_standard_rows_flat(ard, vis_cols))
  }

  by_levels <- unique(ard$by_value)
  body_rows <- list()

  for (bv in by_levels) {
    body_rows <- c(body_rows, list(
      htmltools::tags$tr(class = "ar-preview__by-header",
        htmltools::tags$td(
          class = "ar-preview__td ar-preview__td--by-label",
          colspan = length(vis_cols) + 1, bv)
      )
    ))
    by_data <- ard[ard$by_value == bv, ]
    body_rows <- c(body_rows, build_standard_rows_flat(by_data, vis_cols))
  }
  body_rows
}

build_standard_rows_flat <- function(ard, data_cols) {
  variables <- unique(ard$variable)
  body_rows <- list()

  for (v in variables) {
    var_data <- ard[ard$variable == v, ]
    var_label <- var_data$var_label[1]

    body_rows <- c(body_rows, list(
      htmltools::tags$tr(class = "ar-preview__var-header",
        htmltools::tags$td(class = "ar-preview__td ar-preview__td--var-label",
                           colspan = length(data_cols) + 1, var_label)
      )
    ))

    for (i in seq_len(nrow(var_data))) {
      stat_cells <- c(
        list(htmltools::tags$td(class = "ar-preview__td ar-preview__td--stub",
                                var_data$stat_label[i])),
        lapply(data_cols, function(col) {
          htmltools::tags$td(class = "ar-preview__td ar-preview__td--data",
                             as.character(var_data[[col]][i]))
        })
      )
      body_rows <- c(body_rows, list(htmltools::tags$tr(stat_cells)))
    }
  }
  body_rows
}

# ── Hierarchical rows: SOC/PT with indentation ──
build_hierarchical_rows <- function(ard, data_cols, per_col = list()) {
  vis_cols <- visible_data_cols(data_cols, per_col)
  body_rows <- list()

  for (i in seq_len(nrow(ard))) {
    row_type <- ard$row_type[i]
    stat_label <- ard$stat_label[i]

    stub_class <- switch(row_type %||% "child",
      any = "ar-preview__td ar-preview__td--stub ar-preview__td--any",
      parent = "ar-preview__td ar-preview__td--stub ar-preview__td--parent",
      child = "ar-preview__td ar-preview__td--stub ar-preview__td--child",
      "ar-preview__td ar-preview__td--stub"
    )

    row_class <- switch(row_type %||% "child",
      any = "ar-preview__row--any",
      parent = "ar-preview__row--parent",
      ""
    )

    cells <- c(
      list(htmltools::tags$td(class = stub_class, stat_label)),
      lapply(vis_cols, function(col) {
        htmltools::tags$td(class = "ar-preview__td ar-preview__td--data",
                           as.character(ard[[col]][i]))
      })
    )
    body_rows <- c(body_rows, list(htmltools::tags$tr(class = row_class, cells)))
  }
  body_rows
}

# ── Timepoint rows: section headers for visits ──
build_timepoint_rows <- function(ard, data_cols, per_col = list()) {
  vis_cols <- visible_data_cols(data_cols, per_col)
  body_rows <- list()
  current_var <- ""
  current_tp <- ""

  for (i in seq_len(nrow(ard))) {
    var_label <- ard$var_label[i]
    tp <- ard$timepoint[i] %||% ""

    if (ard$variable[i] != current_var) {
      current_var <- ard$variable[i]
      current_tp <- ""
    }

    if (nzchar(tp) && tp != current_tp) {
      current_tp <- tp
      body_rows <- c(body_rows, list(
        htmltools::tags$tr(class = "ar-preview__var-header",
          htmltools::tags$td(class = "ar-preview__td ar-preview__td--var-label",
                             colspan = length(vis_cols) + 1,
                             paste0(var_label, " \u2014 ", tp))
        )
      ))
    }

    cells <- c(
      list(htmltools::tags$td(class = "ar-preview__td ar-preview__td--stub",
                              ard$stat_label[i])),
      lapply(vis_cols, function(col) {
        htmltools::tags$td(class = "ar-preview__td ar-preview__td--data",
                           as.character(ard[[col]][i]))
      })
    )
    body_rows <- c(body_rows, list(htmltools::tags$tr(cells)))
  }
  body_rows
}

# ── Shift rows: cross-tabulation display ──
build_shift_rows <- function(ard, data_cols, per_col = list()) {
  vis_cols <- visible_data_cols(data_cols, per_col)
  body_rows <- list()
  current_var <- ""

  for (i in seq_len(nrow(ard))) {
    if (ard$variable[i] != current_var) {
      current_var <- ard$variable[i]
      body_rows <- c(body_rows, list(
        htmltools::tags$tr(class = "ar-preview__var-header",
          htmltools::tags$td(class = "ar-preview__td ar-preview__td--var-label",
                             colspan = length(vis_cols) + 1,
                             ard$var_label[i])
        )
      ))
    }

    cells <- c(
      list(htmltools::tags$td(class = "ar-preview__td ar-preview__td--stub",
                              ard$stat_label[i])),
      lapply(vis_cols, function(col) {
        htmltools::tags$td(class = "ar-preview__td ar-preview__td--data",
                           as.character(ard[[col]][i]))
      })
    )
    body_rows <- c(body_rows, list(htmltools::tags$tr(cells)))
  }
  body_rows
}
