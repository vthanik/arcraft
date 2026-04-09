# Demographics ARD builder using cards package
# Drop-in replacement for fct_ard_demog() — same signature, same output shape.
# Pipeline: cards::ard_stack() → vellum::fr_wide_ard() → add meta columns
#
# Output columns: variable, var_label, var_type, stat_label, <trt1>, <trt2>, ..., [Total]
# Plus optional group_value column when by_var is set.

fct_ard_demog_cards <- function(adsl, grouping, var_configs, added_levels = NULL,
                                 combined_groups = NULL, var_labels = NULL) {
  by_var <- grouping$by_var
  has_by <- !is.null(by_var) && nzchar(by_var %||% "") && by_var %in% names(adsl)

  if (!has_by) {
    return(fct_ard_demog_cards_inner(adsl, grouping, var_configs, added_levels,
                                      combined_groups, var_labels))
  }

  # ── BY variable path ──
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  total_label <- grouping$total_label %||% "Total"
  denominator <- grouping$denominator %||% "col_n"
  combined_groups <- combined_groups %||% grouping$combined_groups %||% list()
  by_levels <- grouping$by_levels %||% sort(unique(adsl[[by_var]]))

  # Overall big_n for col_n denominator
  overall_denom <- NULL
  if (denominator == "col_n") {
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
  }

  by_ards <- lapply(by_levels, function(bv) {
    sub <- adsl[adsl[[by_var]] == bv, ]
    ard <- fct_ard_demog_cards_inner(sub, grouping, var_configs, added_levels,
                                      combined_groups, var_labels,
                                      denom_n = overall_denom)
    ard$group_value <- bv
    ard
  })

  result <- dplyr::bind_rows(by_ards)
  meta <- c("group_value", "variable", "var_label", "var_type", "stat_label")
  dcols <- setdiff(names(result), meta)
  result[, c(meta, dcols)]
}

# ── Inner builder (no BY variable) ──
fct_ard_demog_cards_inner <- function(adsl, grouping, var_configs, added_levels = NULL,
                                       combined_groups = NULL, var_labels = NULL,
                                       denom_n = NULL) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  total_label <- grouping$total_label %||% "Total"
  analysis_vars <- grouping$analysis_vars
  combined_groups <- combined_groups %||% grouping$combined_groups %||% list()

  # ── Filter to requested treatment levels only ──
  adsl <- adsl[adsl[[trt_var]] %in% trt_levels, , drop = FALSE]

  # ── Classify variables ──
  cont_vars <- character(0)
  cat_vars <- character(0)
  for (v in analysis_vars) {
    cfg <- var_configs[[v]] %||% list()
    vtype <- cfg$type %||% fct_detect_var_type(adsl, v)
    if (vtype == "continuous") cont_vars <- c(cont_vars, v)
    else cat_vars <- c(cat_vars, v)
  }

  # ── Pre-factor categoricals with added_levels ──
  for (v in cat_vars) {
    cfg <- var_configs[[v]] %||% list()
    extra <- if (!is.null(added_levels)) added_levels[[v]] else character(0)
    lvls <- cfg$levels %||% {
      if (is.factor(adsl[[v]])) levels(adsl[[v]])
      else get_unique_levels(adsl[[v]])
    }
    if (length(extra) > 0) lvls <- unique(c(lvls, extra))
    adsl[[v]] <- factor(adsl[[v]], levels = lvls)
  }

  # ── Build raw ARD via cards ──
  ard_calls <- list()
  if (length(cont_vars) > 0) {
    ard_calls[[length(ard_calls) + 1L]] <-
      rlang::expr(cards::ard_continuous(variables = dplyr::all_of(!!cont_vars)))
  }
  if (length(cat_vars) > 0) {
    ard_calls[[length(ard_calls) + 1L]] <-
      rlang::expr(cards::ard_categorical(variables = dplyr::all_of(!!cat_vars)))
  }

  raw_ard <- rlang::eval_tidy(rlang::expr(
    cards::ard_stack(
      adsl,
      !!!ard_calls,
      .by = dplyr::all_of(!!trt_var),
      .overall = !!include_total,
      .total_n = TRUE
    )
  ))

  # ── Handle combined groups ──
  if (length(combined_groups) > 0) {
    for (cg in combined_groups) {
      pooled <- adsl[adsl[[trt_var]] %in% cg$arms, ]
      pooled[[trt_var]] <- cg$label

      cg_calls <- list()
      if (length(cont_vars) > 0) {
        cg_calls[[length(cg_calls) + 1L]] <-
          rlang::expr(cards::ard_continuous(variables = dplyr::all_of(!!cont_vars)))
      }
      if (length(cat_vars) > 0) {
        cg_calls[[length(cg_calls) + 1L]] <-
          rlang::expr(cards::ard_categorical(variables = dplyr::all_of(!!cat_vars)))
      }

      cg_ard <- rlang::eval_tidy(rlang::expr(
        cards::ard_stack(
          pooled,
          !!!cg_calls,
          .by = dplyr::all_of(!!trt_var),
          .total_n = TRUE
        )
      ))
      raw_ard <- cards::bind_ard(raw_ard, cg_ard, .distinct = TRUE)
    }
  }

  # ── Build statistic format + decimals for fr_wide_ard ──
  stat_fmt <- build_cards_stat_format(var_configs, analysis_vars)
  dec_map <- build_cards_decimals(var_configs, analysis_vars)
  label_map <- build_cards_labels(adsl, analysis_vars, var_labels)

  # ── Convert to wide via vellum ──
  # Don't pass label= so `variable` keeps original var names (AGE, SEX, etc.)
  overall_label <- if (include_total) total_label else NULL
  wide <- vellum::fr_wide_ard(
    raw_ard,
    statistic = stat_fmt,
    column = trt_var,
    overall = overall_label,
    decimals = if (length(dec_map) > 0) dec_map else NULL
  )

  # ── Reorder treatment columns to match trt_levels ──
  expected_cols <- trt_levels
  if (include_total) expected_cols <- c(expected_cols, total_label)
  for (cg in combined_groups) expected_cols <- c(expected_cols, cg$label)
  present_cols <- intersect(expected_cols, names(wide))
  meta_cols <- intersect(c("variable", "stat_label"), names(wide))
  extra_cols <- setdiff(names(wide), c(meta_cols, present_cols))
  wide <- wide[, c(meta_cols, present_cols, extra_cols), drop = FALSE]

  # ── Add var_label and var_type for meta_hidden compatibility ──
  # fr_wide_ard may have applied labels to `variable` column already,
  # so match on both the original var name and the label
  wide$var_label <- NA_character_
  wide$var_type <- NA_character_
  for (v in analysis_vars) {
    cfg <- var_configs[[v]] %||% list()
    vtype <- cfg$type %||% fct_detect_var_type(adsl, v)
    lbl <- label_map[[v]] %||% safe_label(adsl, v)
    mask <- wide$variable == v | wide$variable == lbl
    wide$var_label[mask] <- lbl
    wide$var_type[mask] <- vtype
    # Normalize variable column to original var name (for meta_hidden)
    wide$variable[mask] <- v
  }

  # ── Insert categorical n rows (matching old builder output) ──
  # The old builder produces an "n" row per categorical variable showing
  # non-missing count. fr_wide_ard doesn't generate this, so we add it.
  if (length(cat_vars) > 0) {
    # Use actual treatment columns from the wide output
    meta_names <- c("variable", "var_label", "var_type", "stat_label")
    trt_cols <- setdiff(names(wide), meta_names)
    n_rows <- list()
    for (v in cat_vars) {
      # Count non-missing per arm directly from data
      n_vals <- vapply(trt_cols, function(arm) {
        if (arm == total_label) {
          as.character(sum(!is.na(adsl[[v]])))
        } else {
          cg_match <- Filter(function(cg) cg$label == arm, combined_groups)
          if (length(cg_match) > 0) {
            as.character(sum(!is.na(adsl[[v]][adsl[[trt_var]] %in% cg_match[[1]]$arms])))
          } else {
            as.character(sum(!is.na(adsl[[v]][adsl[[trt_var]] == arm])))
          }
        }
      }, character(1))

      lbl <- label_map[[v]] %||% safe_label(adsl, v)
      n_row <- as.data.frame(
        c(list(variable = v, var_label = lbl, var_type = "categorical",
               stat_label = "  n"), stats::setNames(as.list(n_vals), trt_cols)),
        stringsAsFactors = FALSE, check.names = FALSE
      )
      n_rows[[v]] <- n_row
    }

    # Insert n rows before each variable's level rows
    result_parts <- list()
    for (v in analysis_vars) {
      var_rows <- wide[wide$variable == v, , drop = FALSE]
      if (v %in% cat_vars && !is.null(n_rows[[v]])) {
        # Ensure n_row has same columns
        for (col in setdiff(names(wide), names(n_rows[[v]])))
          n_rows[[v]][[col]] <- NA_character_
        result_parts[[length(result_parts) + 1L]] <- n_rows[[v]][, names(wide), drop = FALSE]
      }
      result_parts[[length(result_parts) + 1L]] <- var_rows
    }
    wide <- dplyr::bind_rows(result_parts)
  }

  # ── Reorder columns: meta first, then treatment columns ──
  meta <- c("variable", "var_label", "var_type", "stat_label")
  dcols <- setdiff(names(wide), meta)
  wide <- wide[, c(meta, dcols), drop = FALSE]

  # ── Apply level exclusions + renames from var_configs ──
  wide <- apply_level_configs(wide, var_configs, cat_vars)

  # ── Attach raw ARD for QC bundle ──
  attr(wide, "raw_ard") <- raw_ard

  wide
}

# ── Helpers ──

# Delegates to shared helpers in utils_helpers.R
build_cards_stat_format <- function(var_configs, analysis_vars) {
  build_stat_format_from_config(var_configs, analysis_vars)
}

build_cards_decimals <- function(var_configs, analysis_vars) {
  build_decimals_from_config(var_configs, analysis_vars)
}

# Build label map from data attributes + var_labels overrides
build_cards_labels <- function(adsl, analysis_vars, var_labels = NULL) {
  labels <- list()
  for (v in analysis_vars) {
    lbl <- if (!is.null(var_labels[[v]]) && nzchar(var_labels[[v]])) {
      var_labels[[v]]
    } else {
      safe_label(adsl, v)
    }
    if (lbl != v) labels[[v]] <- lbl
  }
  labels
}
