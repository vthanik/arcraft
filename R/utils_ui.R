# Shared UI components

ar_theme <- function() {
  bslib::bs_theme(
    version = 5,
    bootswatch = "default",
    primary = "#4a6fa5",
    "font-size-base" = "0.8125rem",
    "body-bg" = "#ffffff",
    "body-color" = "#1a1d23"
  ) |>
    bslib::bs_add_rules(
      "@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');"
    )
}

# Design token values (mirrored from app.css :root — R can't use var())
.ar_bg     <- "#ffffff"
.ar_border <- "#e2e5ea"
.ar_border_light <- "#eceef2"
.ar_fg_2   <- "#4b5563"

ar_grid_theme <- function() {
  reactable::reactableTheme(
    borderColor = .ar_border,
    headerStyle = list(
      background = .ar_bg,
      borderBottom = paste0("1px solid ", .ar_border),
      fontWeight = 600,
      fontSize = "11px",
      color = .ar_fg_2,
      padding = "4px 8px",
      verticalAlign = "bottom"
    ),
    cellStyle = list(
      padding = "2px 8px",
      fontSize = "11.5px",
      lineHeight = "1.3",
      borderBottom = paste0("1px solid ", .ar_border_light),
      verticalAlign = "top"
    ),
    paginationStyle = list(fontSize = "11px")
  )
}

ui_empty_state <- function(title, desc = NULL, icon = "fa-table", cta = NULL) {
  htmltools::tags$div(
    class = "ar-empty-state",
    htmltools::tags$div(class = "ar-empty-state__icon",
                        htmltools::tags$i(class = paste0("fa ", icon))),
    htmltools::tags$div(class = "ar-empty-state__title", title),
    if (!is.null(desc)) htmltools::tags$div(class = "ar-empty-state__desc", desc),
    if (!is.null(cta)) htmltools::tags$div(class = "ar-empty-state__cta", cta)
  )
}

ui_type_badge <- function(type) {
  cls <- switch(toupper(type),
    NUM = "ar-type-badge ar-type-badge--num",
    CHR = "ar-type-badge ar-type-badge--chr",
    DATE = "ar-type-badge ar-type-badge--date",
    FLAG = "ar-type-badge ar-type-badge--flag",
    "ar-type-badge"
  )
  htmltools::tags$span(class = cls, toupper(type))
}

# Custom JS filter: supports NA, comma-separated multi-value
# Custom filter: comma-separated multi-value match
.ar_filter_js <- reactable::JS("function(rows, columnId, filterValue) {
  var terms = filterValue.toLowerCase().split(',').map(function(s){return s.trim();}).filter(function(s){return s.length>0;});
  if (terms.length === 0) return rows;
  return rows.filter(function(row) {
    var val = row.values[columnId];
    var valStr = (val === null || val === undefined) ? '' : String(val).toLowerCase();
    return terms.some(function(t) { return valStr.indexOf(t) !== -1; });
  });
}")

ar_build_reactable <- function(data, height = "auto", row_offset = 0L) {
  wide_data <- ncol(data) > 20
  skip_rownum <- ncol(data) > 30
  measure_cols <- if (wide_data) min(10, ncol(data)) else ncol(data)

  if (skip_rownum) {
    d <- data
  } else {
    d <- dplyr::bind_cols(
      tibble::tibble(`#` = seq_len(nrow(data)) + row_offset),
      data
    )
  }

  col_defs <- list()

  # Row number column (skip for very wide data)
  if (!skip_rownum) {
    col_defs[["#"]] <- reactable::colDef(
      name = "#",
      width = 60,
      align = "right",
      style = list(color = "var(--fg-muted)", fontSize = "11px",
                   borderRight = "1px solid var(--border-light)",
                   overflow = "visible", textOverflow = "clip"),
      sortable = FALSE,
      filterable = FALSE,
      sticky = "left"
    )
  }

  # Build column defs — fast path: skip per-column width measurement
  data_col_names <- if (skip_rownum) names(d) else names(d)[-1]

  # NA cell renderer (shared)
  na_cell <- function(value) {
    if (is.na(value)) htmltools::tags$span(class = "ar-cell--na", "NA")
    else as.character(value)
  }

  for (col in data_col_names) {
    x <- d[[col]]
    lbl <- attr(x, "label")
    col_defs[[col]] <- reactable::colDef(
      name = if (!is.null(lbl) && nzchar(lbl)) paste0(col, "\n", lbl) else col,
      align = if (is.numeric(x)) "right" else "left",
      minWidth = min(200, max(80, nchar(col) * 8 + 24)),
      filterMethod = .ar_filter_js,
      cell = na_cell
    )
  }

  reactable::reactable(
    d,
    columns = col_defs,
    height = height,
    theme = ar_grid_theme(),
    pagination = TRUE,
    defaultPageSize = 50,
    showPageSizeOptions = TRUE,
    pageSizeOptions = c(25, 50, 100, 250),
    sortable = TRUE,
    filterable = TRUE,
    resizable = TRUE,
    wrap = FALSE,
    bordered = FALSE,
    striped = FALSE,
    highlight = TRUE,
    compact = TRUE,
    fullWidth = FALSE
  )
}

