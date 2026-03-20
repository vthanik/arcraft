# Pipeline validation checks — pure R, no Shiny

fct_validate_pipeline <- function(store_snapshot, grp_snapshot = NULL) {
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

  # Treatment variable — read from grp_snapshot (separate reactiveValues)
  trt_var <- grp_snapshot$trt_var
  checks$trt_var <- list(
    label = "Treatment variable set",
    pass = !is.null(trt_var) && nzchar(trt_var),
    detail = trt_var %||% "Not set"
  )

  # Analysis variables — read from grp_snapshot
  n_vars <- length(grp_snapshot$analysis_vars)
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
