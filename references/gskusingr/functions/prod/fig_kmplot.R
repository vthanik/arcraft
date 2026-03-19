#' Create a Robust and Modular Kaplan-Meier Survival Plot
#'
#' This function generates a Kaplan-Meier survival plot as a `patchwork` object.
#' It includes robust error handling, automatically manages single-stratum cases,
#' and is designed for modular use in analysis pipelines.
#'
#' @param data A data frame containing the survival data for a single plot.
#' @param time_col Unquoted name of the time-to-event column (e.g., AVAL).
#' @param censor_col Unquoted name of the censor status column (1=event, 0=censored).
#' @param trt_col Unquoted name of the treatment/stratification column (e.g., DOSGRP).
#' @param trt_levels A character vector defining the order of the treatment levels.
#' @param time_by A numeric value for the interval between x-axis ticks. Default is 3.
#' @param xlab A string for the x-axis label. Default is `"Time (Months)"`.
#' @param ylab A string for the y-axis label. Default is `"Probability of Survival"`.
#' @param title An optional string for the main plot title. Default is `NULL`.
#' @param font_size The base font size for all text elements. Default is 10.
#' @param colors An unnamed character vector of hex codes. Defaults to `g_config$colors`.
#' @param legend_pos A string specifying the legend position. One of `"inside"`,
#'   `"outside"`, or `"bottom"`. Default is `"inside"`.
#' @param include_risk_table A logical value. If `TRUE`, a risk table is added.
#' @param risk_table_title A string for the risk table title.
#'
#' @return A `ggplot` or `patchwork` object.
#' @export
fig_kmplot <- function(
    data,
    time_col,
    censor_col,
    trt_col,
    trt_levels,
    time_by = 3,
    xlab = "Time (Months)",
    ylab = "Probability of Survival",
    title = NULL,
    font_size = 10,
    colors = g_config$colors,
    legend_pos = "inside",
    include_risk_table = TRUE,
    risk_table_title = "Number of Subjects at Risk"
) {
  # --- 0. Internal Helper to Handle Single-Stratum Case ---
  # When only one treatment group is present, survfit summary/tidy omits the
  # 'strata' column. This helper function adds it back in a consistent format.
  ensure_strata_column <- function(df, trt_col_name, original_data) {
    if (!"strata" %in% names(df)) {
      single_level <- as.character(unique(original_data[[trt_col_name]]))[1]
      df$strata <- glue::glue("{trt_col_name}={single_level}")
    }
    return(df)
  }
  
  # --- 1. Validate Inputs ---
  time_col <- rlang::as_name(rlang::enquo(time_col))
  censor_col <- rlang::as_name(rlang::enquo(censor_col))
  trt_col <- rlang::as_name(rlang::enquo(trt_col))
  
  legend_pos <- match.arg(legend_pos, c("inside", "outside", "bottom"))
  
  # Check for essential conditions
  if (nrow(data) == 0) cli::cli_abort("Input `data` must not be empty.")
  required_cols <- c(time_col, censor_col, trt_col)
  if (!all(required_cols %in% names(data))) {
    cli::cli_abort("One or more specified columns are not in `data`.")
  }
  if (length(colors) < length(trt_levels)) {
    cli::cli_abort("Insufficient `colors` provided for the number of `trt_levels`.")
  }
  
  plot_colors <- setNames(colors[seq_along(trt_levels)], trt_levels)
  
  # --- 2. Fit Survival Model ---
  surv_formula <- as.formula(glue::glue(
    "Surv({time_col}, 1 - {censor_col}) ~ {trt_col}"
  ))
  surv_fit <- survival::survfit(surv_formula, data = data) |>
    survival::survfit0() # survfit0 ensures t=0 is included
  
  # --- 3. Prepare Tidy Data for Main Plot ---
  surv_fit_tidy <- broom::tidy(surv_fit) |>
    ensure_strata_column(trt_col, data) |>
    mutate(strata = str_remove(strata, ".*=") |> factor(levels = trt_levels))
  
  # --- 4. Define Plotting Parameters ---
  # Ensure max_time is at least 0, even if data is empty or all events are at t=0
  max_time <- ceiling(max(c(0, surv_fit_tidy$time), na.rm = TRUE))
  final_xlim <- c(0, max_time)
  times <- seq(from = 0, to = final_xlim[2], by = time_by)
  
  # Prepare data for censor marks, handling cases with no censored points
  censor_points_data <- surv_fit_tidy |> filter(n.censor > 0)
  
  # --- 5. Prepare Dynamic Legend Labels ---
  # Creates labels like "Treatment A (Events: 50/100)"
  legend_df <- surv_fit_tidy |>
    group_by(strata) |>
    summarise(
      total_events = sum(n.event),
      initial_risk = first(n.risk),
      .groups = 'drop'
    ) |>
    mutate(
      new_label = glue::glue("{strata} (Events: {total_events}/{initial_risk})")
    )
  legend_labels <- stats::setNames(legend_df$new_label, legend_df$strata)
  
  # --- 6. Create the Main Survival Plot ---
  p_survival <- ggplot(
    data = surv_fit_tidy,
    aes(x = time, y = estimate, color = strata)
  ) +
    geom_step(linewidth = 0.5) +
    geom_point(data = censor_points_data, shape = 3, size = 2.5, stroke = 0.8) +
    annotate(
      geom = "label", x = 0, y = 0, label = "+ Censored", hjust = 0,
      vjust = -0.2, size = font_size * 0.30, fill = "white",
      label.r = unit(0, "lines")
    ) +
    scale_color_manual(name = NULL, labels = legend_labels, values = plot_colors) +
    scale_x_continuous(breaks = times) +
    scale_y_continuous(
      breaks = seq(0, 1, by = 0.2),
      labels = scales::number_format(accuracy = 0.1)
    ) +
    coord_cartesian(xlim = final_xlim, ylim = c(0, 1), expand = TRUE) +
    labs(title = title, x = xlab, y = ylab) +
    theme_bw(base_size = font_size, base_family = "sans") +
    theme(
      panel.grid = element_blank(),
      panel.border = element_rect(colour = "black", linewidth = 0.5),
      axis.text = element_text(color = "black"),
      axis.title = element_text(color = "black"),
      plot.margin = margin(t = 5, r = 15, b = 5, l = 5),
      plot.title = element_text(hjust = 0.5, face = "bold")
    )
  
  # --- 7. Create Risk Table (if requested) ---
  p_risk_table <- NULL
  if (include_risk_table) {
    risk_table_data <- summary(surv_fit, times = times, data.frame = TRUE) |>
      ensure_strata_column(trt_col, data) |>
      group_by(strata) |>
      # Ensure all time points exist for each stratum
      complete(time = times) |>
      arrange(time) |>
      mutate(
        strata = str_remove(strata, ".*=") |> factor(levels = trt_levels),
        # Replace NA n.risk (from complete) with last known value or 0
        n.risk = coalesce(n.risk, 0),
        risktable_label = as.character(n.risk)
      ) |>
      filter(time %in% times) |>
      select(time, strata, risktable_label) |>
      ungroup()
    
    p_risk_table <- ggplot(
      risk_table_data,
      aes(x = time, y = fct_rev(strata), label = risktable_label)
    ) +
      geom_text(size = font_size * 0.30, hjust = 0.5, color = "black") +
      scale_x_continuous(breaks = times) +
      coord_cartesian(xlim = final_xlim, expand = TRUE) +
      labs(title = risk_table_title, x = NULL, y = NULL) +
      theme_minimal(base_size = font_size, base_family = "sans") +
      theme(
        panel.grid = element_blank(),
        axis.text.y = element_text(hjust = 1, color = "black"),
        axis.text.x = element_blank(),
        axis.ticks = element_blank(),
        plot.title = element_text(hjust = 0, face = "plain", size = font_size),
        plot.margin = margin(t = 5, r = 15, b = 5, l = 5)
      )
  }
  
  # --- 8. Assemble Final Plot Based on Legend Position ---
  final_plot <- switch(
    legend_pos,
    "inside" = {
      p_survival <- p_survival +
        theme(
          legend.position = "inside",
          legend.position.inside = c(0.98, 0.98),
          legend.justification = c("right", "top"),
          legend.background = element_rect(fill = "transparent")
        )
      if (include_risk_table) {
        p_survival / p_risk_table + plot_layout(heights = c(1 - length(trt_levels)/28, length(trt_levels)/28))
      } else { p_survival }
    },
    "outside" = {
      p_survival <- p_survival + theme(legend.position = "right")
      if (include_risk_table) {
        p_survival / p_risk_table + plot_layout(heights = c(0.75, 0.25))
      } else { p_survival }
    },
    "bottom" = {
      if (include_risk_table) {
        (p_survival / p_risk_table) +
          plot_layout(heights = c(0.7, 0.2), guides = 'collect') &
          theme(legend.position = "bottom")
      } else {
        p_survival + theme(legend.position = "bottom")
      }
    }
  )
  
  return(final_plot)
}
