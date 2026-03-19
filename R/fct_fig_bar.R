# Bar Chart builder — generic grouped bar chart, returns ggplot object

fct_fig_bar <- function(data, adsl, grouping, fig_configs) {
  trt_var <- grouping$trt_var
  x_var <- fig_configs$x_var %||% grouping$analysis_vars[1]
  y_var <- fig_configs$y_var %||% "n"
  fill_var <- fig_configs$fill_var %||% trt_var

  stopifnot("Data required" = !is.null(data))

  # Merge treatment if needed
  if (!trt_var %in% names(data) && "USUBJID" %in% names(data)) {
    data <- dplyr::inner_join(data, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  # If y_var is "n", compute counts
  if (y_var == "n") {
    plot_data <- data |>
      dplyr::count(.data[[fill_var]], .data[[x_var]], name = "n")
    y_var <- "n"
    y_label <- "Count"
  } else {
    plot_data <- data
    y_label <- safe_label(data, y_var)
  }

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(
    x = .data[[x_var]], y = .data[[y_var]], fill = .data[[fill_var]]
  )) +
    ggplot2::geom_col(position = "dodge", width = 0.7) +
    ggplot2::labs(
      x = safe_label(data, x_var),
      y = y_label,
      fill = trt_var
    ) +
    ggplot2::theme_minimal(base_size = 11, base_family = "Inter") +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.major.x = ggplot2::element_blank()
    )

  p
}
