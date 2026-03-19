# Waterfall Plot builder — pure R, returns ggplot object

fct_fig_waterfall <- function(adrs, adsl, grouping, fig_configs) {
  trt_var <- grouping$trt_var
  threshold_lower <- fig_configs$threshold_lower %||% -30
  threshold_upper <- fig_configs$threshold_upper %||% 20

  stopifnot("ADRS required" = !is.null(adrs))

  # Determine best % change variable
  if ("PCHG" %in% names(adrs)) {
    pchg_var <- "PCHG"
  } else if ("AVAL" %in% names(adrs)) {
    pchg_var <- "AVAL"
  } else {
    stop("Need PCHG or AVAL column in response data", call. = FALSE)
  }

  # Filter to BOR if available
  if ("PARAMCD" %in% names(adrs)) {
    wf_data <- adrs[adrs[["PARAMCD"]] %in% c("OVRLRESP", "BOR", "BESTPCHG"), ]
    if (nrow(wf_data) == 0) wf_data <- adrs
  } else {
    wf_data <- adrs
  }

  # Merge treatment if needed
  if (!trt_var %in% names(wf_data)) {
    wf_data <- dplyr::inner_join(wf_data, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  # Determine BOR for coloring
  bor_var <- if ("AVALC" %in% names(wf_data)) "AVALC" else if ("RSSTRESC" %in% names(wf_data)) "RSSTRESC" else NULL

  wf_data <- wf_data[!is.na(wf_data[[pchg_var]]), ]
  wf_data <- wf_data[order(wf_data[[pchg_var]]), ]
  wf_data$.rank <- seq_len(nrow(wf_data))

  # Build plot
  if (!is.null(bor_var)) {
    p <- ggplot2::ggplot(wf_data, ggplot2::aes(
      x = stats::reorder(.data[["USUBJID"]], .data[[pchg_var]]),
      y = .data[[pchg_var]], fill = .data[[bor_var]]
    ))
  } else {
    p <- ggplot2::ggplot(wf_data, ggplot2::aes(
      x = stats::reorder(.data[["USUBJID"]], .data[[pchg_var]]),
      y = .data[[pchg_var]]
    ))
  }

  p <- p +
    ggplot2::geom_col(width = 0.8) +
    ggplot2::geom_hline(yintercept = threshold_lower, linetype = "dashed", color = "#22c55e", linewidth = 0.5) +
    ggplot2::geom_hline(yintercept = threshold_upper, linetype = "dashed", color = "#ef4444", linewidth = 0.5) +
    ggplot2::labs(
      x = "Subject", y = "Best % Change from Baseline",
      fill = if (!is.null(bor_var)) "Best Overall Response" else NULL
    ) +
    ggplot2::theme_minimal(base_size = 11, base_family = "Inter") +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      legend.position = "bottom",
      panel.grid.major.x = ggplot2::element_blank()
    )

  # BOR color scale
  if (!is.null(bor_var)) {
    bor_colors <- c(CR = "#2563eb", PR = "#60a5fa", SD = "#fbbf24", PD = "#ef4444", NE = "#9ca3af")
    present <- intersect(names(bor_colors), unique(wf_data[[bor_var]]))
    p <- p + ggplot2::scale_fill_manual(values = bor_colors[present], na.value = "#d1d5db")
  }

  p
}
