# Hierarchical ARD builder — generic SOC/PT-style nested counts
# Reusable for: Medical History (14.1.7), Prior Meds (14.1.8), ConMeds (14.1.9), AE SOC/PT

fct_ard_hierarchical <- function(data, adsl, grouping, var_configs,
                                  parent_var = "AEBODSYS",
                                  child_var = "AEDECOD") {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE

  stopifnot("Parent variable must exist in data" = parent_var %in% names(data))
  stopifnot("Child variable must exist in data" = child_var %in% names(data))
  stopifnot("Treatment var must exist in ADSL" = trt_var %in% names(adsl))

  # Merge treatment from ADSL if not in data
  if (!trt_var %in% names(data) && "USUBJID" %in% names(data)) {
    data <- dplyr::inner_join(
      data,
      adsl[, c("USUBJID", trt_var), drop = FALSE],
      by = "USUBJID"
    )
  }

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  big_n <- vapply(groups, function(grp) {
    if (grp == "Total") nrow(adsl) else sum(adsl[[trt_var]] == grp)
  }, integer(1))

  ard_rows <- list()

  # "Any" row — subjects with at least one record
  any_vals <- vapply(groups, function(grp) {
    subset <- if (grp == "Total") data else data[data[[trt_var]] == grp, ]
    n <- length(unique(subset[["USUBJID"]]))
    N <- big_n[grp]
    fmt_npct(n, N, "A", 1)
  }, character(1))

  parent_label <- safe_label(data, parent_var)
  ard_rows <- c(ard_rows, list(c(
    list(variable = "ANY", var_label = parent_label, var_type = "hierarchical",
         stat_label = "Any event", row_type = "any"),
    stats::setNames(as.list(any_vals), groups)
  )))

  # Parent categories
  parents <- sort(unique(stats::na.omit(data[[parent_var]])))

  for (p in parents) {
    parent_data <- data[data[[parent_var]] == p, ]

    # Parent row
    parent_vals <- vapply(groups, function(grp) {
      subset <- if (grp == "Total") parent_data else parent_data[parent_data[[trt_var]] == grp, ]
      n <- length(unique(subset[["USUBJID"]]))
      N <- big_n[grp]
      fmt_npct(n, N, "A", 1)
    }, character(1))

    ard_rows <- c(ard_rows, list(c(
      list(variable = parent_var, var_label = parent_label, var_type = "hierarchical",
           stat_label = p, row_type = "parent"),
      stats::setNames(as.list(parent_vals), groups)
    )))

    # Child rows
    children <- sort(unique(stats::na.omit(parent_data[[child_var]])))
    for (ch in children) {
      child_data <- parent_data[parent_data[[child_var]] == ch, ]

      child_vals <- vapply(groups, function(grp) {
        subset <- if (grp == "Total") child_data else child_data[child_data[[trt_var]] == grp, ]
        n <- length(unique(subset[["USUBJID"]]))
        N <- big_n[grp]
        fmt_npct(n, N, "A", 1)
      }, character(1))

      ard_rows <- c(ard_rows, list(c(
        list(variable = child_var, var_label = child_var, var_type = "hierarchical",
             stat_label = paste0("  ", ch), row_type = "child"),
        stats::setNames(as.list(child_vals), groups)
      )))
    }
  }

  dplyr::bind_rows(ard_rows)
}
