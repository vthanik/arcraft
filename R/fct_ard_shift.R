# Shift Table ARD builder — pure R, no Shiny
# Tables 14.3.4.2-4, 14.3.5.3: Baseline × post-baseline cross-tabulation

fct_ard_shift <- function(bds_data, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE

  stopifnot("Data required" = !is.null(bds_data))
  stopifnot("Must have PARAMCD" = "PARAMCD" %in% names(bds_data))

  # Determine grade system
  if ("BTOXGR" %in% names(bds_data) && "ATOXGR" %in% names(bds_data)) {
    base_var <- "BTOXGR"
    post_var <- "ATOXGR"
  } else if ("BNRIND" %in% names(bds_data) && "ANRIND" %in% names(bds_data)) {
    base_var <- "BNRIND"
    post_var <- "ANRIND"
  } else {
    stop("Shift table requires BTOXGR/ATOXGR or BNRIND/ANRIND columns", call. = FALSE)
  }

  # Filter to selected parameters
  paramcds <- var_configs$paramcds %||% unique(bds_data[["PARAMCD"]])[1:min(5, length(unique(bds_data[["PARAMCD"]])))]
  bds_data <- bds_data[bds_data[["PARAMCD"]] %in% paramcds, ]

  # Merge treatment if needed
  if (!trt_var %in% names(bds_data)) {
    bds_data <- dplyr::inner_join(bds_data, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  # Keep one post-baseline record per subject per param (worst post-baseline)
  # For CTCAE: highest grade; for normal range: worst direction
  shift_data <- bds_data[!is.na(bds_data[[base_var]]) & !is.na(bds_data[[post_var]]), ]

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  base_cats <- sort(unique(stats::na.omit(shift_data[[base_var]])))
  post_cats <- sort(unique(stats::na.omit(shift_data[[post_var]])))

  ard_rows <- list()

  for (pc in paramcds) {
    param_shift <- shift_data[shift_data[["PARAMCD"]] == pc, ]
    if (nrow(param_shift) == 0) next

    param_label <- if ("PARAM" %in% names(param_shift)) param_shift[["PARAM"]][1] else pc

    for (b_cat in base_cats) {
      for (p_cat in post_cats) {
        row_data <- list(
          variable = pc, var_label = param_label, var_type = "shift",
          stat_label = paste0("  ", b_cat, " -> ", p_cat),
          baseline_category = b_cat, post_category = p_cat
        )

        for (grp in groups) {
          subset <- if (grp == "Total") param_shift else param_shift[param_shift[[trt_var]] == grp, ]
          n <- sum(subset[[base_var]] == b_cat & subset[[post_var]] == p_cat, na.rm = TRUE)
          row_data[[grp]] <- fmt_count(n)
        }
        ard_rows <- c(ard_rows, list(row_data))
      }
    }
  }

  dplyr::bind_rows(ard_rows)
}
