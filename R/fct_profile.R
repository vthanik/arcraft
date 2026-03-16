# Column profiling for Data Viewer — pure R

fct_profile_column <- function(x, col_name, n_row) {
  n_miss <- sum(is.na(x))
  n_unique <- length(unique(x[!is.na(x)]))
  pct_miss <- round(n_miss / n_row * 100, 1)
  missing_str <- if (n_miss == 0) "0" else sprintf("%d (%s%%)", n_miss, pct_miss)

  is_num <- is.numeric(x)
  is_date <- inherits(x, "Date") || inherits(x, "POSIXct")
  is_bool <- is.logical(x)

  type_label <- if (is_num) "NUM" else if (is_date) "DATE" else if (is_bool) "BOOL" else "CHR"
  badge_class <- if (is_num) "ar-type-badge--num"
    else if (is_date) "ar-type-badge--date"
    else if (is_bool) "ar-type-badge--bool"
    else "ar-type-badge--chr"

  extra_name <- NULL; extra_stat <- NULL; dist_html <- NULL

  if (is_num && n_miss < n_row) {
    vals <- x[!is.na(x)]
    extra_name <- "Range"
    extra_stat <- sprintf("%s\u2013%s", format(min(vals), big.mark = ","), format(max(vals), big.mark = ","))
    dist_html <- ui_numeric_dist(vals)
  } else if (!is_num && !is_date && n_unique > 0 && n_unique <= 30) {
    tbl <- sort(table(x[!is.na(x)]), decreasing = TRUE)
    extra_name <- "Top"
    extra_stat <- names(tbl)[1]
    if (nchar(extra_stat) > 14) extra_stat <- paste0(substr(extra_stat, 1, 12), "\u2026")
    dist_html <- ui_categorical_dist(tbl, n_row)
  } else if (!is_num && !is_date) {
    tbl <- sort(table(x[!is.na(x)]), decreasing = TRUE)
    if (length(tbl) > 0) {
      extra_name <- "Top"
      extra_stat <- names(tbl)[1]
      if (nchar(extra_stat) > 14) extra_stat <- paste0(substr(extra_stat, 1, 12), "\u2026")
    }
  }

  list(type_label = type_label, badge_class = badge_class, n_unique = n_unique,
       missing_str = missing_str, extra_name = extra_name, extra_stat = extra_stat,
       dist_html = dist_html)
}
