# Swimmer Plot builder — pure R, returns ggplot object

fct_fig_swimmer <- function(adtte, adrs, adsl, grouping, fig_configs) {
  trt_var <- grouping$trt_var
  paramcd <- fig_configs$paramcd %||% "OS"
  max_subjects <- fig_configs$max_subjects %||% 50
  sort_by <- fig_configs$sort_by %||% "duration"

  stopifnot("ADTTE required" = !is.null(adtte))

  # Get duration per subject
  dur_data <- adtte[adtte[["PARAMCD"]] == paramcd, ]
  if (!trt_var %in% names(dur_data)) {
    dur_data <- dplyr::inner_join(dur_data, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  # Keep one row per subject
  dur_data <- dur_data |>
    dplyr::group_by(.data[["USUBJID"]]) |>
    dplyr::slice_max(.data[["AVAL"]], n = 1, with_ties = FALSE) |>
    dplyr::ungroup()

  # Sort and limit
  dur_data <- dur_data[order(dur_data[["AVAL"]]), ]
  if (nrow(dur_data) > max_subjects) {
    dur_data <- utils::tail(dur_data, max_subjects)
  }

  dur_data$.rank <- seq_len(nrow(dur_data))
  dur_data$.ongoing <- dur_data[["CNSR"]] == 1

  # Build swimmer bars
  p <- ggplot2::ggplot(dur_data) +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = 0, xend = .data[["AVAL"]],
        y = stats::reorder(.data[["USUBJID"]], .data[["AVAL"]]),
        yend = stats::reorder(.data[["USUBJID"]], .data[["AVAL"]]),
        color = .data[[trt_var]]
      ),
      linewidth = 3
    )

  # Ongoing arrows for censored subjects
  ongoing <- dur_data[dur_data$.ongoing, ]
  if (nrow(ongoing) > 0) {
    p <- p + ggplot2::geom_point(
      data = ongoing,
      ggplot2::aes(x = .data[["AVAL"]], y = stats::reorder(.data[["USUBJID"]], .data[["AVAL"]])),
      shape = 17, size = 2.5, color = "#22c55e"
    )
  }

  # Response events from ADRS if available
  if (!is.null(adrs) && "PARAMCD" %in% names(adrs)) {
    resp_events <- adrs[adrs[["PARAMCD"]] %in% c("BOR", "OVRLRESP") &
                          adrs[["AVALC"]] %in% c("CR", "PR", "PD"), ]
    if (nrow(resp_events) > 0 && "ADT" %in% names(resp_events)) {
      resp_events <- resp_events[resp_events[["USUBJID"]] %in% dur_data[["USUBJID"]], ]
      if (nrow(resp_events) > 0) {
        # Approximate time — would need proper RFSTDTC calculation
        resp_shapes <- c(CR = 16, PR = 15, PD = 4)
        p <- p + ggplot2::geom_point(
          data = resp_events,
          ggplot2::aes(x = .data[["AVAL"]], y = .data[["USUBJID"]], shape = .data[["AVALC"]]),
          size = 2
        )
      }
    }
  }

  p <- p +
    ggplot2::labs(x = "Time (months)", y = "Subject", color = trt_var) +
    ggplot2::theme_minimal(base_size = 11, base_family = "Inter") +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      legend.position = "bottom",
      panel.grid.major.y = ggplot2::element_blank()
    )

  p
}
