# Column profiling for data viewer — pure R, no Shiny

fct_profile_column <- function(x, col_name, n_row) {
  n_miss <- sum(is.na(x))
  pct_miss <- if (n_row > 0) round(n_miss / n_row * 100, 1) else 0

  # R attributes
  label <- attr(x, "label") %||% ""
  format_attr <- attr(x, "format.sas") %||% attr(x, "format") %||% ""
  r_class <- paste(class(x), collapse = ", ")

  base <- list(
    name = col_name,
    label = label,
    format = format_attr,
    r_class = r_class,
    n_unique = length(unique(stats::na.omit(x))),
    n_missing = n_miss,
    pct_missing = pct_miss
  )

  if (is.numeric(x)) {
    vals <- stats::na.omit(x)
    c(base, list(
      type = "NUM",
      badge_class = "ar-type-badge--num",
      summary = if (length(vals) > 0) list(
        min = min(vals), max = max(vals),
        mean = round(mean(vals), 2),
        median = round(stats::median(vals), 2),
        sd = round(stats::sd(vals), 2),
        q1 = round(stats::quantile(vals, 0.25), 2),
        q3 = round(stats::quantile(vals, 0.75), 2)
      ) else NULL
    ))
  } else if (inherits(x, "Date") || inherits(x, "POSIXt")) {
    vals <- stats::na.omit(x)
    c(base, list(
      type = "DATE",
      badge_class = "ar-type-badge--date",
      summary = if (length(vals) > 0) list(
        min = as.character(min(vals)),
        max = as.character(max(vals))
      ) else NULL
    ))
  } else {
    vals <- stats::na.omit(x)
    freq <- if (length(vals) > 0) sort(table(vals), decreasing = TRUE) else integer(0)
    c(base, list(
      type = "CHR",
      badge_class = "ar-type-badge--chr",
      summary = if (length(freq) > 0) list(
        top_values = utils::head(freq, 5),
        n_levels = length(freq)
      ) else NULL
    ))
  }
}

fct_profile_all <- function(data) {
  n_row <- nrow(data)
  lapply(names(data), function(col) {
    fct_profile_column(data[[col]], col, n_row)
  })
}
