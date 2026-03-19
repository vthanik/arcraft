#' Create a Paginated Swimmer Plot Object
#'
#' This function generates a swimmer plot for visualizing patient treatment
#' duration and key clinical events. It automatically handles pagination, styling,
#' input validation, and non-standard evaluation for a professional and robust output.
#'
#' @param data A pre-processed data frame containing swimmer plot data.
#' @param subj_col Unquoted name of the unique subject identifier column.
#' @param bar_col Unquoted name of the column defining the swimmer bar's length in months.
#' @param group_col Unquoted name of the column used for coloring the bars (e.g., DOSGRP).
#' @param group_levels Character vector defining the order of the fill legend levels.
#' @param ongoing_col Unquoted name of the logical column flagging ongoing patients.
#' @param pr_col,cr_col,pd_col,dth_col Unquoted names of columns containing time-to-event in months.
#' @param subjects_per_page The maximum number of subjects to display on a single page.
#' @param time_by An optional numeric value for the interval between x-axis ticks.
#' @param xlab A string for the x-axis label. Default is `"Time on Treatment (Months)"`.
#' @param title String for the main plot title.
#' @param font_size The base font size for all text elements in the plot.
#' @param colors Unnamed character vector of hex codes for the bar fills.
#'
#' @return A list of `patchwork` plot objects. Each element in the list is one page.
#' @export
fig_swimmer <- function(
  data,
  subj_col,
  bar_col,
  group_col,
  group_levels,
  ongoing_col,
  pr_col,
  cr_col,
  pd_col,
  dth_col,
  subjects_per_page = 40,
  time_by = NULL,
  xlab = "Time on Treatment (Months)",
  title = "Swimmer Plot for Subject's Response to IDRX-42 Overtime",
  font_size = 10,
  colors = g_config$colors
) {
  # --- 1. Robust Input Validation and NSE Handling ---
  validate_inputs <- function(...) {
    inputs <- rlang::enquos(...)
    for (i in seq_along(inputs)) {
      if (rlang::quo_is_missing(inputs[[i]])) {
        cli::cli_abort(c(
          "Argument {.arg {names(inputs[i])}} is missing, with no default.",
          "i" = "Please provide a column name for this argument."
        ))
      }
    }
  }
  validate_inputs(
    subj_col,
    bar_col,
    group_col,
    ongoing_col,
    pr_col,
    cr_col,
    pd_col,
    dth_col,
    group_levels
  )

  subj_col <- rlang::as_name(rlang::enquo(subj_col))
  bar_col <- rlang::as_name(rlang::enquo(bar_col))
  group_col <- rlang::as_name(rlang::enquo(group_col))
  ongoing_col <- rlang::as_name(rlang::enquo(ongoing_col))
  pr_col <- rlang::as_name(rlang::enquo(pr_col))
  cr_col <- rlang::as_name(rlang::enquo(cr_col))
  pd_col <- rlang::as_name(rlang::enquo(pd_col))
  dth_col <- rlang::as_name(rlang::enquo(dth_col))

  # --- 2. Prepare Data and Plotting Parameters ---
  plot_colors <- setNames(colors[seq_along(group_levels)], group_levels)
  cr_color <- "#00A9FF"
  pr_color <- "#7C5CFF"
  pd_color <- "#F8766D"

  plot_data <- data |>
    arrange(desc(.data[[bar_col]])) |>
    mutate(
      !!subj_col := factor(.data[[subj_col]], levels = rev(.data[[subj_col]])),
      !!group_col := factor(.data[[group_col]], levels = group_levels),
      page = ceiling(row_number() / subjects_per_page)
    )

  total_pages <- max(plot_data$page)
  max_event_time <- max(
    unlist(plot_data[, c(bar_col, pr_col, cr_col, pd_col, dth_col)]),
    na.rm = TRUE
  )
  axis_breaks <- if (!is.null(time_by)) {
    scales::breaks_width(time_by)
  } else {
    waiver()
  }

  # --- 3. Corrected Event Legend with a Tight Border ---
  event_legend_data <- tribble(
    ~x  , ~label              , ~shape , ~color   ,
    1   , "Death"             ,      4 , "black"  ,
    2.5 , "First CR"          ,     17 , cr_color ,
    4   , "First PR"          ,     16 , pr_color ,
    5.5 , "PD"                ,     18 , pd_color ,
    6.5 , "Ongoing Treatment" , NA     , "black"
  )

  p_event_legend <- ggplot(event_legend_data, aes(x = x, y = 1)) +
    # Draw a rectangle annotation FIRST, so it's in the background
    annotate(
      "rect",
      xmin = 0.7,
      xmax = 8.6,
      ymin = 0.7,
      ymax = 1.3,
      fill = NA,
      color = "black",
      linewidth = 0.5
    ) +
    # Now draw the points and text on TOP of the transparent rectangle
    geom_point(
      aes(shape = shape, color = color),
      size = 3,
      stroke = 1,
      na.rm = TRUE
    ) +
    geom_text(
      aes(label = label, x = x + 0.3),
      hjust = 0,
      size = font_size * 0.3
    ) +
    annotate(
      "text",
      x = 6.5,
      y = 1,
      label = "\uf0da",
      size = 5,
      color = "black",
      family = "fontawesome-webfont"
    ) +
    scale_shape_identity() +
    scale_color_identity() +
    theme_void() +
    coord_cartesian(xlim = c(0.5, 8.8)) # Ensure all content fits

  # --- 4. Helper Function to Create One Plot Page ---
  create_page_plot <- function(page_data, page_num) {
    dynamic_size <- scales::rescale(
      nrow(page_data),
      from = c(1, subjects_per_page),
      to = c(5, 2.5)
    )

    p_main <- ggplot(page_data, aes(y = .data[[subj_col]])) +
      geom_col(
        aes(x = .data[[bar_col]], fill = .data[[group_col]]),
        width = 0.8
      ) +
      geom_text(
        data = \(df) filter(df, .data[[ongoing_col]]),
        aes(x = .data[[bar_col]], label = "\uf0da"),
        family = "fontawesome-webfont",
        size = dynamic_size * 1.5,
        color = "black",
        hjust = -0.2
      ) +
      geom_point(
        data = \(df) filter(df, !is.na(.data[[pr_col]])),
        aes(x = .data[[pr_col]]),
        shape = 16,
        size = dynamic_size,
        color = pr_color
      ) +
      geom_point(
        data = \(df) filter(df, !is.na(.data[[cr_col]])),
        aes(x = .data[[cr_col]]),
        shape = 17,
        size = dynamic_size,
        color = cr_color
      ) +
      geom_point(
        data = \(df) filter(df, !is.na(.data[[pd_col]])),
        aes(x = .data[[pd_col]]),
        shape = 18,
        size = dynamic_size,
        color = pd_color
      ) +
      geom_point(
        data = \(df) filter(df, !is.na(.data[[dth_col]])),
        aes(x = .data[[dth_col]]),
        shape = 4,
        size = dynamic_size,
        stroke = 1,
        color = "black"
      ) +

      scale_fill_manual(name = NULL, values = plot_colors, drop = TRUE) +
      scale_x_continuous(
        breaks = axis_breaks,
        limits = c(0, max_event_time * 1.05),
        expand = expansion(mult = c(0.005, 0.03))
      ) +
      labs(
        title = title,
        x = xlab,
        y = NULL
      ) +
      guides(fill = guide_legend(ncol = 1)) +
      theme_bw(base_size = font_size, base_family = "sans") +
      theme(
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_rect(colour = "black", linewidth = 0.5),
        axis.text = element_text(color = "black"),
        axis.ticks.y = element_blank(),
        plot.title = element_text(hjust = 0.5, face = "plain", size = font_size),
        legend.position = "inside",
        legend.position.inside = c(0.98, 0.02),
        legend.justification = c("right", "bottom"),
        legend.background = element_rect(
          fill = "white",
          color = "black",
          linewidth = 0.25
        )
      )

    (p_main / p_event_legend) + plot_layout(heights = c(0.92, 0.08))
  }

  # --- 5. Generate List of Plots ---
  plot_list <- plot_data |>
    group_split(page) |>
    imap(create_page_plot)

  return(plot_list)
}
