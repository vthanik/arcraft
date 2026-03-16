# Shared UI components — reusable "bricks"

ui_stat_chip <- function(label, value) {
  htmltools::tags$div(class = "ar-stat-chip",
    htmltools::tags$span(class = "ar-stat-chip__label", label),
    htmltools::tags$span(class = "ar-stat-chip__value", value))
}

ui_numeric_dist <- function(vals) {
  brks <- seq(min(vals), max(vals), length.out = 11)
  if (brks[1] == brks[11]) return(NULL)
  counts <- graphics::hist(vals, breaks = brks, plot = FALSE)$counts
  mc <- max(counts)
  if (mc == 0) return(NULL)
  bars <- purrr::map(counts, function(c) {
    htmltools::tags$div(class = "ar-hist-bar",
      style = sprintf("height:%dpx;", max(round(c / mc * 20), 1)))
  })
  htmltools::tags$div(class = "ar-hist-container",
    htmltools::tags$div(class = "ar-hist-bars", bars),
    htmltools::tags$div(class = "ar-hist-labels",
      htmltools::tags$span(format(min(vals), digits = 3)),
      htmltools::tags$span(format(max(vals), digits = 3))))
}

ui_categorical_dist <- function(tbl, n_row) {
  top <- utils::head(tbl, 5)
  bars <- purrr::imap(top, function(count, name) {
    pct <- round(count / n_row * 100, 1)
    disp <- if (nchar(name) > 16) paste0(substr(name, 1, 14), "\u2026") else name
    htmltools::tags$div(class = "ar-cat-bar-row",
      htmltools::tags$span(class = "ar-cat-bar-label", disp),
      htmltools::tags$div(class = "ar-cat-bar-track",
        htmltools::tags$div(class = "ar-cat-bar-fill",
          style = sprintf("width:%s%%;", min(pct, 100)))),
      htmltools::tags$span(class = "ar-cat-bar-pct", sprintf("%s%%", pct)))
  })
  htmltools::tags$div(class = "ar-cat-dist", bars)
}
