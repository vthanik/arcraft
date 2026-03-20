# Demographics ARD builder — pure R, no Shiny
# Supports BY variable: when grouping$by_var is set, stats are computed within
# each by-level. Adds a `group_value` column so preview/render can insert section
# headers. Treatment columns stay the same.
# Denominator: "col_n" = overall treatment N, "bygroup_n" = by-group treatment N.

fct_ard_demog <- function(adsl, grouping, var_configs, added_levels = NULL, combined_groups = NULL,
                          var_labels = NULL) {
  by_var <- grouping$by_var
  has_by <- !is.null(by_var) && nzchar(by_var %||% "") && by_var %in% names(adsl)

  if (!has_by) {
    return(fct_ard_demog_inner(adsl, grouping, var_configs, added_levels,
                                combined_groups, var_labels))
  }

  # ── BY variable path ──
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  total_label <- grouping$total_label %||% "Total"
  denominator <- grouping$denominator %||% "col_n"
  combined_groups <- combined_groups %||% grouping$combined_groups %||% list()

  # By-levels: use custom order if stored, else sorted unique
  by_levels <- grouping$by_levels %||% sort(unique(adsl[[by_var]]))

  # Overall big_n (for col_n denominator)
  overall_big_n <- adsl |>
    dplyr::count(.data[[trt_var]], name = "N") |>
    dplyr::arrange(match(.data[[trt_var]], trt_levels))
  if (include_total) {
    overall_big_n <- dplyr::bind_rows(overall_big_n,
      tibble::tibble(!!trt_var := total_label, N = nrow(adsl)))
  }
  for (cg in combined_groups) {
    pooled_n <- sum(adsl[[trt_var]] %in% cg$arms, na.rm = TRUE)
    overall_big_n <- dplyr::bind_rows(overall_big_n,
      tibble::tibble(!!trt_var := cg$label, N = pooled_n))
  }
  overall_denom <- stats::setNames(overall_big_n$N, overall_big_n[[trt_var]])

  # Build ARD per by-level, stack vertically
  by_ards <- lapply(by_levels, function(bv) {
    sub <- adsl[adsl[[by_var]] == bv, ]

    # Denominator override for col_n: pass overall N for percentages
    denom_n <- if (denominator == "col_n") overall_denom else NULL

    ard <- fct_ard_demog_inner(sub, grouping, var_configs, added_levels,
                                combined_groups, var_labels, denom_n = denom_n)

    # Tag each row with the by-level
    ard$group_value <- bv
    ard
  })

  result <- dplyr::bind_rows(by_ards)

  # Reorder: group_value FIRST, then meta, then data columns
  meta <- c("group_value", "variable", "var_label", "var_type", "stat_label")
  dcols <- setdiff(names(result), meta)
  result[, c(meta, dcols)]
}

# ── Inner builder (no BY variable) ──
fct_ard_demog_inner <- function(adsl, grouping, var_configs, added_levels = NULL,
                                 combined_groups = NULL, var_labels = NULL,
                                 denom_n = NULL) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  total_label <- grouping$total_label %||% "Total"
  analysis_vars <- grouping$analysis_vars
  combined_groups <- combined_groups %||% grouping$combined_groups %||% list()

  # Big N per treatment (from this data subset)
  big_n <- adsl |>
    dplyr::count(.data[[trt_var]], name = "N") |>
    dplyr::arrange(match(.data[[trt_var]], trt_levels))

  if (include_total) {
    big_n <- dplyr::bind_rows(big_n, tibble::tibble(!!trt_var := total_label, N = nrow(adsl)))
  }

  for (cg in combined_groups) {
    pooled_n <- sum(adsl[[trt_var]] %in% cg$arms, na.rm = TRUE)
    big_n <- dplyr::bind_rows(big_n, tibble::tibble(!!trt_var := cg$label, N = pooled_n))
  }

  # Build ARD per variable
  ard_rows <- lapply(analysis_vars, function(var) {
    config <- var_configs[[var]] %||% list()
    var_type <- config$type %||% fct_detect_var_type(adsl, var)

    if (var_type == "continuous") {
      fct_summarize_cont(adsl, var, trt_var, trt_levels, config, big_n,
        include_total, combined_groups, var_labels = var_labels,
        total_label = total_label)
    } else {
      extra_lvls <- if (!is.null(added_levels)) added_levels[[var]] else character(0)
      if (length(extra_lvls) > 0) {
        existing <- config$levels %||% {
          if (is.factor(adsl[[var]])) levels(adsl[[var]])
          else sort(unique(stats::na.omit(adsl[[var]])))
        }
        config$levels <- unique(c(existing, extra_lvls))
      }
      fct_summarize_cat(adsl, var, trt_var, trt_levels, config, big_n,
        include_total, combined_groups, var_labels = var_labels,
        denom_n = denom_n, total_label = total_label)
    }
  })

  dplyr::bind_rows(ard_rows)
}

# Helper: get per-stat decimal from config
get_stat_dec <- function(config, stat_name, fallback = 1) {
  decs <- config$decimals
  if (is.list(decs)) decs[[stat_name]] %||% fallback
  else decs %||% fallback
}

fct_summarize_cont <- function(data, var, trt_var, trt_levels, config, big_n,
                                include_total, combined_groups = list(),
                                var_labels = NULL, total_label = "Total") {
  stats <- config$stats %||% c("n", "mean_sd", "median", "q1_q3", "min_max")
  label <- if (!is.null(var_labels[[var]]) && nzchar(var_labels[[var]])) var_labels[[var]] else safe_label(data, var)
  stat_labels <- config$stat_labels %||% list()

  groups <- trt_levels
  if (include_total) groups <- c(groups, total_label)
  for (cg in combined_groups) groups <- c(groups, cg$label)

  rows <- lapply(stats, function(stat) {
    vals <- vapply(groups, function(grp) {
      if (grp == total_label) {
        x <- data[[var]]
      } else {
        cg_match <- Filter(function(cg) cg$label == grp, combined_groups)
        if (length(cg_match) > 0) {
          x <- data[[var]][data[[trt_var]] %in% cg_match[[1]]$arms]
        } else {
          x <- data[[var]][data[[trt_var]] == grp]
        }
      }
      x <- stats::na.omit(x)
      n <- length(x)

      switch(stat,
        n = fmt_count(n),
        mean = if (n > 0) formatC(mean(x), format = "f",
          digits = get_stat_dec(config, "mean", 1)) else "",
        sd = if (n > 0) formatC(stats::sd(x), format = "f",
          digits = get_stat_dec(config, "sd", 2)) else "",
        mean_sd = if (n > 0) {
          fmt_mean_sd(mean(x), stats::sd(x),
            mean_dec = get_stat_dec(config, "mean", 1),
            sd_dec = get_stat_dec(config, "sd", 2))
        } else "",
        median = if (n > 0) fmt_median_only(stats::median(x), get_stat_dec(config, "median", 1)) else "",
        q1 = if (n > 0) formatC(stats::quantile(x, 0.25), format = "f",
          digits = get_stat_dec(config, "q1", 1)) else "",
        q3 = if (n > 0) formatC(stats::quantile(x, 0.75), format = "f",
          digits = get_stat_dec(config, "q3", 1)) else "",
        q1_q3 = if (n > 0) fmt_q1_q3(stats::quantile(x, 0.25), stats::quantile(x, 0.75),
          q1_dec = get_stat_dec(config, "q1", 1),
          q3_dec = get_stat_dec(config, "q3", 1)) else "",
        min = if (n > 0) formatC(min(x), format = "f",
          digits = get_stat_dec(config, "min", 0)) else "",
        max = if (n > 0) formatC(max(x), format = "f",
          digits = get_stat_dec(config, "max", 0)) else "",
        min_max = if (n > 0) fmt_min_max(min(x), max(x),
          min_dec = get_stat_dec(config, "min", 0),
          max_dec = get_stat_dec(config, "max", 0)) else "",
        geo_mean = {
          if (n > 0 && all(x > 0)) {
            formatC(exp(mean(log(x))), format = "f",
              digits = get_stat_dec(config, "geo_mean", 2))
          } else ""
        },
        cv = {
          if (n > 0 && mean(x) != 0) {
            formatC(stats::sd(x) / mean(x) * 100, format = "f",
              digits = get_stat_dec(config, "cv", 1))
          } else ""
        },
        geo_mean_cv = {
          if (n > 0 && all(x > 0)) {
            gm <- exp(mean(log(x)))
            cv <- stats::sd(x) / mean(x) * 100
            fmt_geo_mean_cv(gm, cv,
              gm_dec = get_stat_dec(config, "geo_mean", 2),
              cv_dec = get_stat_dec(config, "cv", 1))
          } else ""
        },
        ""
      )
    }, character(1))

    default_label <- STAT_LABELS[[stat]] %||% stat
    stat_label <- stat_labels[[stat]] %||% default_label

    c(list(variable = var, var_label = label, var_type = "continuous",
           stat_label = paste0("  ", stat_label)), stats::setNames(as.list(vals), groups))
  })

  dplyr::bind_rows(rows)
}

fct_summarize_cat <- function(data, var, trt_var, trt_levels, config, big_n,
                               include_total, combined_groups = list(),
                               var_labels = NULL, denom_n = NULL,
                               total_label = "Total") {
  dec <- config$pct_dec %||% 1
  fmt <- config$cat_format %||% "npct"
  style <- config$zero_style %||% "A"
  label <- if (!is.null(var_labels[[var]]) && nzchar(var_labels[[var]])) var_labels[[var]] else safe_label(data, var)

  levels_order <- if (!is.null(config$levels)) {
    config$levels
  } else if (is.factor(data[[var]])) {
    levels(data[[var]])
  } else {
    sort(unique(stats::na.omit(data[[var]])))
  }

  groups <- trt_levels
  if (include_total) groups <- c(groups, total_label)
  for (cg in combined_groups) groups <- c(groups, cg$label)

  show_n <- config$show_n %||% TRUE

  # N row: total non-missing count per treatment group
  n_vals <- vapply(groups, function(grp) {
    if (grp == total_label) {
      x <- data[[var]]
    } else {
      cg_match <- Filter(function(cg) cg$label == grp, combined_groups)
      if (length(cg_match) > 0) {
        x <- data[[var]][data[[trt_var]] %in% cg_match[[1]]$arms]
      } else {
        x <- data[[var]][data[[trt_var]] == grp]
      }
    }
    fmt_count(sum(!is.na(x)))
  }, character(1))

  n_row <- c(list(variable = var, var_label = label, var_type = "categorical",
                   stat_label = "  n"), stats::setNames(as.list(n_vals), groups))

  # Level rows: n(%) for each category
  rows <- lapply(levels_order, function(lev) {
    vals <- vapply(groups, function(grp) {
      if (grp == total_label) {
        x <- data[[var]]
        N <- if (!is.null(denom_n) && total_label %in% names(denom_n)) {
          as.integer(denom_n[[total_label]])
        } else {
          nrow(data)
        }
      } else {
        cg_match <- Filter(function(cg) cg$label == grp, combined_groups)
        if (length(cg_match) > 0) {
          mask <- data[[trt_var]] %in% cg_match[[1]]$arms
        } else {
          mask <- data[[trt_var]] == grp
        }
        x <- data[[var]][mask]
        N <- if (!is.null(denom_n) && grp %in% names(denom_n)) {
          as.integer(denom_n[[grp]])
        } else {
          sum(mask)
        }
      }
      n <- sum(x == lev, na.rm = TRUE)

      switch(fmt,
        npct = fmt_npct(n, N, style, dec),
        n = fmt_count(n),
        nn_pct = fmt_nn_pct(n, N, style, dec),
        fmt_npct(n, N, style, dec)
      )
    }, character(1))

    c(list(variable = var, var_label = label, var_type = "categorical",
           stat_label = paste0("  ", lev)), stats::setNames(as.list(vals), groups))
  })

  if (isTRUE(show_n)) {
    dplyr::bind_rows(c(list(n_row), rows))
  } else {
    dplyr::bind_rows(rows)
  }
}
