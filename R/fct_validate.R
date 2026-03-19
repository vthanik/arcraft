# Pipeline validation checks — pure R, no Shiny

fct_validate_pipeline <- function(store_snapshot) {
  checks <- list()

  # Data loaded
  checks$data_loaded <- list(
    label = "Data loaded",
    pass = length(store_snapshot$datasets) > 0,
    detail = if (length(store_snapshot$datasets) > 0) {
      paste(names(store_snapshot$datasets), collapse = ", ")
    } else "No datasets loaded"
  )

  # Template selected
  checks$template_selected <- list(
    label = "Template selected",
    pass = !is.null(store_snapshot$template) && nzchar(store_snapshot$template),
    detail = store_snapshot$template %||% "None"
  )

  # Treatment variable
  checks$trt_var <- list(
    label = "Treatment variable set",
    pass = !is.null(store_snapshot$grouping$trt_var) && nzchar(store_snapshot$grouping$trt_var),
    detail = store_snapshot$grouping$trt_var %||% "Not set"
  )

  # Analysis variables
  n_vars <- length(store_snapshot$grouping$analysis_vars)
  checks$analysis_vars <- list(
    label = "Analysis variables selected",
    pass = n_vars > 0,
    detail = paste0(n_vars, " variable(s)")
  )

  # Titles
  n_titles <- length(store_snapshot$fmt$titles)
  checks$titles <- list(
    label = "Title(s) defined",
    pass = n_titles > 0,
    detail = paste0(n_titles, " title line(s)")
  )

  # Page layout
  checks$page <- list(
    label = "Page layout configured",
    pass = !is.null(store_snapshot$fmt$page$orientation),
    detail = paste0(
      store_snapshot$fmt$page$orientation %||% "landscape", " / ",
      store_snapshot$fmt$page$font_family %||% "Courier New", " ",
      store_snapshot$fmt$page$font_size %||% 9, "pt"
    )
  )

  checks
}
