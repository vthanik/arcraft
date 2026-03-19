# Forest Plot builder — pure R, returns ggplot object

fct_fig_forest <- function(adtte, adsl, grouping, fig_configs) {
  trt_var <- grouping$trt_var
  paramcd <- fig_configs$paramcd %||% "OS"
  subgroup_vars <- fig_configs$subgroup_vars %||% c("SEX", "AGEGR1", "RACE")
  scale_type <- fig_configs$scale %||% "log"

  stopifnot("ADTTE required" = !is.null(adtte))
  stopifnot("ADSL required" = !is.null(adsl))

  # Filter to parameter
  tte_data <- adtte[adtte[["PARAMCD"]] == paramcd, ]

  # Merge ADSL variables
  merge_cols <- c("USUBJID", trt_var, intersect(subgroup_vars, names(adsl)))
  tte_merged <- dplyr::inner_join(tte_data, adsl[, merge_cols, drop = FALSE], by = "USUBJID")

  # Overall HR
  forest_rows <- list()
  tryCatch({
    overall_fit <- survival::coxph(
      survival::Surv(AVAL, 1 - CNSR) ~ factor(get(trt_var)),
      data = tte_merged
    )
    overall_tidy <- broom::tidy(overall_fit, conf.int = TRUE, exponentiate = TRUE)
    if (nrow(overall_tidy) > 0) {
      forest_rows <- c(forest_rows, list(data.frame(
        subgroup = "Overall", level = "All subjects",
        hr = overall_tidy$estimate[1],
        ci_lo = overall_tidy$conf.low[1],
        ci_hi = overall_tidy$conf.high[1],
        n = nrow(tte_merged),
        stringsAsFactors = FALSE
      )))
    }
  }, error = function(e) NULL)

  # Subgroup HRs
  for (sg_var in subgroup_vars) {
    if (!sg_var %in% names(tte_merged)) next
    sg_levels <- unique(stats::na.omit(tte_merged[[sg_var]]))

    for (lv in sg_levels) {
      sg_data <- tte_merged[tte_merged[[sg_var]] == lv, ]
      if (nrow(sg_data) < 10) next  # Skip small subgroups

      tryCatch({
        sg_fit <- survival::coxph(
          survival::Surv(AVAL, 1 - CNSR) ~ factor(get(trt_var)),
          data = sg_data
        )
        sg_tidy <- broom::tidy(sg_fit, conf.int = TRUE, exponentiate = TRUE)
        if (nrow(sg_tidy) > 0) {
          forest_rows <- c(forest_rows, list(data.frame(
            subgroup = sg_var, level = as.character(lv),
            hr = sg_tidy$estimate[1],
            ci_lo = sg_tidy$conf.low[1],
            ci_hi = sg_tidy$conf.high[1],
            n = nrow(sg_data),
            stringsAsFactors = FALSE
          )))
        }
      }, error = function(e) NULL)
    }
  }

  if (length(forest_rows) == 0) {
    return(ggplot2::ggplot() + ggplot2::annotate("text", x = 0.5, y = 0.5, label = "Insufficient data") +
             ggplot2::theme_void())
  }

  forest_df <- dplyr::bind_rows(forest_rows)
  forest_df$label <- ifelse(forest_df$subgroup == "Overall",
                             "Overall", paste0("  ", forest_df$level))
  forest_df$label <- factor(forest_df$label, levels = rev(forest_df$label))

  # Annotation column
  forest_df$hr_text <- sprintf("%.2f (%.2f, %.2f)", forest_df$hr, forest_df$ci_lo, forest_df$ci_hi)
  forest_df$n_text <- paste0("N=", forest_df$n)

  p <- ggplot2::ggplot(forest_df, ggplot2::aes(x = .data$hr, y = .data$label)) +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = .data$ci_lo, xmax = .data$ci_hi), height = 0.25) +
    ggplot2::geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
    ggplot2::geom_text(ggplot2::aes(label = .data$hr_text), hjust = -0.2, size = 3, nudge_x = 0.05) +
    ggplot2::geom_text(ggplot2::aes(label = .data$n_text), x = min(forest_df$ci_lo, na.rm = TRUE) * 0.7,
                        hjust = 1, size = 2.8, color = "grey50")

  if (scale_type == "log") {
    p <- p + ggplot2::scale_x_log10()
  }

  p <- p +
    ggplot2::labs(x = "Hazard Ratio (95% CI)", y = NULL) +
    ggplot2::theme_minimal(base_size = 11, base_family = "Inter") +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    )

  p
}
