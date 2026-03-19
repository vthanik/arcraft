# Kaplan-Meier Plot builder — pure R, returns ggplot object

fct_fig_km <- function(adtte, adsl, grouping, fig_configs) {
  trt_var <- grouping$trt_var
  paramcd <- fig_configs$paramcd %||% "OS"
  show_ci <- fig_configs$show_ci %||% TRUE
  show_risk_table <- fig_configs$show_risk_table %||% TRUE
  show_censoring <- fig_configs$show_censoring %||% TRUE
  time_unit <- fig_configs$time_unit %||% "months"

  stopifnot("ADTTE required" = !is.null(adtte))

  # Filter to parameter
  tte_data <- adtte[adtte[["PARAMCD"]] == paramcd, ]

  # Merge treatment if needed
  if (!trt_var %in% names(tte_data)) {
    tte_data <- dplyr::inner_join(tte_data, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  # Build survival data frame from survfit
  km_fit <- survival::survfit(
    survival::Surv(AVAL, 1 - CNSR) ~ get(trt_var),
    data = tte_data
  )

  # Extract plot data
  km_df <- data.frame(
    time = km_fit$time,
    surv = km_fit$surv,
    lower = km_fit$lower,
    upper = km_fit$upper,
    n.censor = km_fit$n.censor,
    strata = rep(names(km_fit$strata), km_fit$strata)
  )
  # Clean strata names
  km_df$strata <- gsub("get\\(trt_var\\)=", "", km_df$strata)

  # Add time=0 rows
  strata_names <- unique(km_df$strata)
  time0 <- data.frame(
    time = 0, surv = 1, lower = 1, upper = 1, n.censor = 0,
    strata = strata_names
  )
  km_df <- rbind(time0, km_df)

  # Main KM curve
  p <- ggplot2::ggplot(km_df, ggplot2::aes(x = .data$time, y = .data$surv,
                                             color = .data$strata, fill = .data$strata)) +
    ggplot2::geom_step(linewidth = 0.8)

  # CI bands
  if (show_ci) {
    p <- p + ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$lower, ymax = .data$upper),
      alpha = 0.15, linetype = 0
    )
  }

  # Censoring marks
  if (show_censoring) {
    cens_df <- km_df[km_df$n.censor > 0, ]
    if (nrow(cens_df) > 0) {
      p <- p + ggplot2::geom_point(
        data = cens_df, shape = 3, size = 2, stroke = 0.8
      )
    }
  }

  # Median reference lines
  for (s in strata_names) {
    s_data <- km_df[km_df$strata == s, ]
    med_idx <- which(s_data$surv <= 0.5)
    if (length(med_idx) > 0) {
      med_time <- s_data$time[med_idx[1]]
      p <- p + ggplot2::geom_segment(
        x = med_time, xend = med_time, y = 0, yend = 0.5,
        linetype = "dashed", color = "grey60", linewidth = 0.4
      )
    }
  }

  p <- p +
    ggplot2::geom_hline(yintercept = 0.5, linetype = "dashed", color = "grey60", linewidth = 0.3) +
    ggplot2::scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                                 limits = c(0, 1), expand = c(0.02, 0)) +
    ggplot2::labs(
      x = paste0("Time (", time_unit, ")"),
      y = "Survival Probability",
      color = trt_var, fill = trt_var
    ) +
    ggplot2::theme_minimal(base_size = 11, base_family = "Inter") +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 13)
    )

  # Risk table (if patchwork available)
  if (show_risk_table && requireNamespace("patchwork", quietly = TRUE)) {
    # Build risk table data
    time_breaks <- pretty(km_df$time, n = 6)
    risk_df <- expand.grid(time = time_breaks, strata = strata_names, stringsAsFactors = FALSE)
    risk_df$n_risk <- vapply(seq_len(nrow(risk_df)), function(i) {
      s_data <- tte_data[tte_data[[trt_var]] == risk_df$strata[i], ]
      sum(s_data[["AVAL"]] >= risk_df$time[i])
    }, integer(1))

    p_risk <- ggplot2::ggplot(risk_df, ggplot2::aes(x = .data$time, y = .data$strata,
                                                      label = .data$n_risk)) +
      ggplot2::geom_text(size = 3) +
      ggplot2::labs(x = NULL, y = NULL) +
      ggplot2::theme_minimal(base_size = 9) +
      ggplot2::theme(
        panel.grid = ggplot2::element_blank(),
        axis.text.x = ggplot2::element_blank(),
        plot.margin = ggplot2::margin(0, 5.5, 5.5, 5.5)
      )

    p <- p / p_risk + patchwork::plot_layout(heights = c(4, 1))
  }

  p
}
