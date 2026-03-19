#' Create a Paginated Waterfall Plot Object
#'
#' This function generates a multi-page waterfall plot for visualizing the best
#' percentage change in tumor size, with options to mark discontinued subjects
#' and intelligent axis scaling.
#'
#' @param data A data frame containing one row per subject with their best response.
#' @param subj_col Unquoted name of the unique subject identifier column.
#' @param pchg_col Unquoted name of the column with the best percentage change.
#' @param group_col Unquoted name of the column for coloring bars (e.g., DOSGRP).
#' @param group_levels Character vector defining the order of the fill legend levels.
#' @param discont_col Optional unquoted name of the logical column flagging
#'   discontinued subjects (e.g., DISCFL). Default is `NULL`.
#' @param include_subj_labels A logical value. If `TRUE`, adds subject IDs to the x-axis.
#' @param subjects_per_page The maximum number of subjects to display on a single page.
#' @param pr_threshold A numeric value for the partial response threshold line.
#' @param pd_threshold A numeric value for the progressive disease threshold line.
#' @param xlab A string for the x-axis label.
#' @param ylab A string for the y-axis label.
#' @param title An optional string for the main plot title.
#' @param font_size The base font size for all text elements in the plot.
#' @param colors Unnamed character vector of hex codes for the bar fills.
#'
#' @return A list of `ggplot` objects. Each element in the list is one page.
#' @export
fig_waterfall <- function(
    data,
    subj_col,
    pchg_col,
    group_col,
    group_levels,
    discont_col = NULL,
    include_subj_labels = FALSE,
    subjects_per_page = 50,
    pr_threshold = -30,
    pd_threshold = 20,
    xlab = "Subjects",
    ylab = "Best Change from Baseline (%)",
    title = "Waterfall Plot for Best Percentage Change of Target Lesion from Baseline",
    font_size = 10,
    colors = g_config$colors
) {
  # --- 1. Robust Input Validation and NSE Handling ---
  subj_col <- rlang::as_name(rlang::enquo(subj_col))
  pchg_col <- rlang::as_name(rlang::enquo(pchg_col))
  group_col <- rlang::as_name(rlang::enquo(group_col))
  discont_col <- rlang::enquo(discont_col)
  
  req_cols <- c(subj_col, pchg_col, group_col)
  if (!all(req_cols %in% names(data))) {
    cli::cli_abort("One or more required columns are missing from `data`.")
  }
  
  # --- 2. Prepare Data and Global Plotting Parameters ---
  plot_colors <- setNames(colors[seq_along(group_levels)], group_levels)
  
  plot_data <- data |>
    dplyr::mutate(!!pchg_col := as.numeric(.data[[pchg_col]])) |>
    dplyr::filter(!is.na(.data[[pchg_col]])) |>
    dplyr::arrange(dplyr::desc(.data[[pchg_col]])) |>
    dplyr::mutate(page = ceiling(dplyr::row_number() / subjects_per_page))
  
  if (nrow(plot_data) == 0) {
    cli::cli_abort("No valid, non-NA data found in `{pchg_col}` to plot.")
  }
  
  # --- 3. Intelligent Y-Axis Limit Calculation ---
  y_range <- range(plot_data[[pchg_col]], na.rm = TRUE)
  min_y <- y_range[1]
  max_y <- y_range[2]
  
  # Lower limit is always 15% below the minimum value.
  y_lower <- min_y * 1.15
  
  # Upper limit logic:
  if (max_y <= 0) {
    # If all values are negative, ensure the axis reaches the PD line + a buffer.
    y_upper <- pd_threshold + 10
  } else {
    # Otherwise, ensure the axis accommodates the max data point AND the PD line.
    y_upper <- max(max_y, pd_threshold, na.rm = TRUE) * 1.15
  }
  y_limits <- c(y_lower, y_upper)
  
  # --- 4. Helper Function to Create One Plot Page ---
  create_page_plot <- function(page_data, page_num) {
    page_data <- page_data |>
      dplyr::mutate(
        !!subj_col := factor(.data[[subj_col]], levels = .data[[subj_col]]),
        !!group_col := factor(.data[[group_col]], levels = group_levels)
      )
    
    p_page <- ggplot(
      page_data,
      aes(x = .data[[subj_col]], y = .data[[pchg_col]], fill = .data[[group_col]])
    ) +
      geom_col(width = 0.9, color = "black", linewidth = 0.25) +
      geom_hline(yintercept = 0, color = "black", linewidth = 0.5)
    
    if (!is.null(pr_threshold)) {
      p_page <- p_page + geom_hline(yintercept = pr_threshold, color = "grey40", linetype = "dashed")
    }
    if (!is.null(pd_threshold)) {
      p_page <- p_page + geom_hline(yintercept = pd_threshold, color = "grey40", linetype = "dashed")
    }
    
    if (!rlang::quo_is_null(discont_col)) {
      discont_data <- page_data |> dplyr::filter(!!discont_col)
      if (nrow(discont_data) > 0) {
        p_page <- p_page +
          geom_point(
            data = discont_data,
            shape = 4, color = "black", stroke = 1, size = 2,
            show.legend = FALSE
          )
      }
    }
    
    plot_margin_setting <- if (include_subj_labels) {
      ggplot2::margin(t = 5, r = 20, b = 40, l = 5)
    } else {
      ggplot2::margin(t = 5, r = 15, b = 5, l = 5)
    }
    
    p_page <- p_page +
      scale_fill_manual(name = NULL, values = plot_colors, drop = TRUE) +
      scale_y_continuous(breaks = scales::breaks_pretty(n = 8)) +
      coord_cartesian(ylim = y_limits) +
      labs(title = title, x = xlab, y = ylab) +
      guides(fill = guide_legend(nrow = 1)) +
      theme_bw(base_size = font_size, base_family = "sans") +
      theme(
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_rect(colour = "black", linewidth = 0.5),
        axis.text.y = element_text(color = "black"),
        axis.title = element_text(color = "black", face = "plain"),
        plot.title = element_text(hjust = 0.5, face = "plain", size = font_size),
        legend.position = "bottom",
        legend.background = element_rect(color = "black", linewidth = 0.5),
        plot.margin = plot_margin_setting
      )
    
    if (include_subj_labels) {
      if (nrow(page_data) > 8) {
        p_page <- p_page +
          theme(axis.text.x = element_text(angle = -45, hjust = 0, vjust = 1, color = "black"))  
      } else {
        p_page <- p_page +
          theme(axis.text.x = element_text(angle = 0, hjust = 0.5, vjust = 1, color = "black"))
      }
    } else {
      p_page <- p_page +
        theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
    }
    
    return(p_page)
  }
  
  # --- 5. Generate List of Plots ---
  plot_list <- plot_data |>
    dplyr::group_split(page) |>
    purrr::imap(create_page_plot)
  
  return(plot_list)
}