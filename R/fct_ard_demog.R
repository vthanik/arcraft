# Demographics ARD builder — pure R, no Shiny
# Input: filtered ADSL, grouping config, stats config
# Output: tibble in ARD wide format (param | trt1 | trt2 | ...)

fct_ard_demog <- function(adsl, grouping, stats) {
  trt_var <- grouping$trt_var
  include_total <- grouping$include_total
  vars <- grouping$analysis_vars

  if (length(vars) == 0) return(tibble::tibble())

  blocks <- purrr::map(vars, function(v) {
    if (v$type == "continuous") {
      block <- fct_summarize_cont(adsl, v$variable, trt_var, stats$cont_stats,
                                   stats$cont_dec, include_total)
    } else {
      block <- fct_summarize_cat(adsl, v$variable, trt_var, stats$cat_fmt,
                                  stats$pct_dec, include_total)
    }
    if (nrow(block) == 0) return(block)
    # Header row + indented stats
    trt_cols <- setdiff(names(block), "stat")
    header <- tibble::tibble(stat = v$label)
    for (col in trt_cols) header[[col]] <- ""
    block$stat <- paste0("  ", block$stat)
    dplyr::bind_rows(header, block)
  })

  result <- dplyr::bind_rows(blocks)
  if ("stat" %in% names(result)) result <- dplyr::rename(result, param = "stat")
  result
}

fct_summarize_cont <- function(data, var, trt_var, stats, dec, include_total) {
  df <- if (include_total) {
    dplyr::bind_rows(data, data |> dplyr::mutate(!!trt_var := "Total"))
  } else data

  r <- df |> dplyr::group_by(.data[[trt_var]]) |>
    dplyr::summarise(
      N = dplyr::n(), Mean = mean(.data[[var]], na.rm = TRUE),
      SD = stats::sd(.data[[var]], na.rm = TRUE),
      Median = stats::median(.data[[var]], na.rm = TRUE),
      Q1 = stats::quantile(.data[[var]], 0.25, na.rm = TRUE),
      Q3 = stats::quantile(.data[[var]], 0.75, na.rm = TRUE),
      Min = min(.data[[var]], na.rm = TRUE),
      Max = max(.data[[var]], na.rm = TRUE), .groups = "drop")

  fmt <- paste0("%.", dec, "f")
  fmt1 <- paste0("%.", dec + 1, "f")
  rows <- list()
  if ("n" %in% stats)       rows[["N"]] <- fmt_row(r, trt_var, "N", "%d")
  if ("mean_sd" %in% stats) rows[["Mean (SD)"]] <- fmt_mean_sd(r, trt_var, fmt, fmt1)
  if ("median" %in% stats)  rows[["Median"]] <- fmt_row(r, trt_var, "Median", fmt)
  if ("q1_q3" %in% stats)   rows[["Q1, Q3"]] <- fmt_pair(r, trt_var, "Q1", "Q3", fmt)
  if ("min_max" %in% stats) rows[["Min, Max"]] <- fmt_pair(r, trt_var, "Min", "Max", fmt)

  dplyr::bind_rows(rows) |> dplyr::mutate(stat = names(rows), .before = 1)
}

fct_summarize_cat <- function(data, var, trt_var, cat_fmt, pct_dec, include_total) {
  df <- if (include_total) {
    dplyr::bind_rows(data, data |> dplyr::mutate(!!trt_var := "Total"))
  } else data

  big_n <- df |> dplyr::count(.data[[trt_var]], name = "N")
  pf <- paste0("%.", pct_dec, "f")

  df |> dplyr::count(.data[[trt_var]], .data[[var]]) |>
    dplyr::left_join(big_n, by = trt_var) |>
    dplyr::mutate(value = switch(cat_fmt,
      npct   = sprintf(paste0("%d (", pf, "%%)"), .data$n, .data$n / .data$N * 100),
      n_only = sprintf("%d", .data$n),
      nn_pct = sprintf(paste0("%d/%d (", pf, "%%)"), .data$n, .data$N, .data$n / .data$N * 100))) |>
    dplyr::select(dplyr::all_of(c(trt_var, var)), "value") |>
    tidyr::pivot_wider(names_from = dplyr::all_of(trt_var), values_from = "value") |>
    dplyr::rename(stat = dplyr::all_of(var))
}

# Formatting helpers
fmt_row <- function(r, trt_var, col, fmt) {
  tibble::as_tibble(as.list(stats::setNames(sprintf(fmt, r[[col]]), r[[trt_var]])))
}
fmt_mean_sd <- function(r, trt_var, fmt, fmt1) {
  tibble::as_tibble(as.list(stats::setNames(
    sprintf(paste0(fmt, " (", fmt1, ")"), r$Mean, r$SD), r[[trt_var]])))
}
fmt_pair <- function(r, trt_var, c1, c2, fmt) {
  tibble::as_tibble(as.list(stats::setNames(
    sprintf(paste0(fmt, ", ", fmt), r[[c1]], r[[c2]]), r[[trt_var]])))
}
