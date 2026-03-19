# Spider Plot builder — pure R, returns ggplot object
# Individual tumor trajectories: % change from baseline over time

fct_fig_spider <- function(adtr, adsl, grouping, fig_configs) {
  trt_var <- grouping$trt_var
  max_subjects <- fig_configs$max_subjects %||% 100

  stopifnot("Tumor data required" = !is.null(adtr))

  # Determine value column (% change)
  pchg_var <- if ("PCHG" %in% names(adtr)) "PCHG"
              else if ("CHG" %in% names(adtr)) "CHG"
              else "AVAL"

  time_var <- if ("AVISIT" %in% names(adtr)) "ADY"
              else if ("ADY" %in% names(adtr)) "ADY"
              else "AVISIT"

  # Merge treatment if needed
  if (!trt_var %in% names(adtr)) {
    adtr <- dplyr::inner_join(adtr, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  # Limit subjects
  subjects <- unique(adtr[["USUBJID"]])
  if (length(subjects) > max_subjects) {
    subjects <- subjects[seq_len(max_subjects)]
    adtr <- adtr[adtr[["USUBJID"]] %in% subjects, ]
  }

  p <- ggplot2::ggplot(adtr, ggplot2::aes(
    x = .data[[time_var]], y = .data[[pchg_var]],
    group = .data[["USUBJID"]], color = .data[[trt_var]]
  )) +
    ggplot2::geom_line(alpha = 0.5, linewidth = 0.5) +
    ggplot2::geom_point(size = 1, alpha = 0.5) +
    ggplot2::geom_hline(yintercept = 0, color = "grey50", linewidth = 0.3) +
    ggplot2::geom_hline(yintercept = -30, linetype = "dashed", color = "#22c55e", linewidth = 0.4) +
    ggplot2::geom_hline(yintercept = 20, linetype = "dashed", color = "#ef4444", linewidth = 0.4) +
    ggplot2::labs(
      x = "Time", y = "% Change from Baseline",
      color = trt_var
    ) +
    ggplot2::theme_minimal(base_size = 11, base_family = "Inter") +
    ggplot2::theme(legend.position = "bottom")

  p
}
