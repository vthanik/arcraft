# Adverse Event ARD builders — pure R, no Shiny
# Covers: AE Summary (14.3.1.2), SOC/PT (14.3.1.3), all filtered variants

# ── AE Summary: overview counts (subjects with any TEAE, serious, related, etc.) ──
fct_ard_ae_summary <- function(adae, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE

  stopifnot("ADAE required" = !is.null(adae))
  stopifnot("Treatment var must exist in ADSL" = trt_var %in% names(adsl))

  # Merge treatment if needed
  if (!trt_var %in% names(adae)) {
    adae <- dplyr::inner_join(adae, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  big_n <- vapply(groups, function(grp) {
    if (grp == "Total") nrow(adsl) else sum(adsl[[trt_var]] == grp)
  }, integer(1))

  # Define summary categories
  categories <- list(
    list(label = "Any TEAE", filter_fn = function(d) d),
    list(label = "Any serious AE", filter_fn = function(d) {
      if ("AESER" %in% names(d)) d[d[["AESER"]] == "Y", ] else d[0, ]
    }),
    list(label = "Any related TEAE", filter_fn = function(d) {
      if ("AEREL" %in% names(d)) {
        d[d[["AEREL"]] %in% c("RELATED", "PROBABLE", "POSSIBLE", "DEFINITELY RELATED", "Y"), ]
      } else d[0, ]
    }),
    list(label = "AE leading to discontinuation", filter_fn = function(d) {
      if ("AEACN" %in% names(d)) d[d[["AEACN"]] == "DRUG WITHDRAWN", ] else d[0, ]
    }),
    list(label = "AE leading to dose reduction", filter_fn = function(d) {
      if ("AEACN" %in% names(d)) d[d[["AEACN"]] == "DOSE REDUCED", ] else d[0, ]
    }),
    list(label = "AE leading to dose interruption", filter_fn = function(d) {
      if ("AEACN" %in% names(d)) d[d[["AEACN"]] == "DRUG INTERRUPTED", ] else d[0, ]
    }),
    list(label = "Deaths", filter_fn = function(d) {
      death_mask <- rep(FALSE, nrow(d))
      if ("AEOUT" %in% names(d)) death_mask <- death_mask | d[["AEOUT"]] == "FATAL"
      if ("AESDTH" %in% names(d)) death_mask <- death_mask | d[["AESDTH"]] == "Y"
      d[death_mask, ]
    })
  )

  ard_rows <- list()
  for (cat in categories) {
    filtered <- cat$filter_fn(adae)
    vals <- vapply(groups, function(grp) {
      subset <- if (grp == "Total") filtered else filtered[filtered[[trt_var]] == grp, ]
      n <- length(unique(subset[["USUBJID"]]))
      N <- big_n[grp]
      fmt_npct(n, N, "A", 1)
    }, character(1))

    ard_rows <- c(ard_rows, list(c(
      list(variable = "AE_SUMMARY", var_label = "Adverse Event Summary",
           var_type = "categorical", stat_label = paste0("  ", cat$label)),
      stats::setNames(as.list(vals), groups)
    )))
  }

  dplyr::bind_rows(ard_rows)
}

# ── AE by SOC/PT: hierarchical counts ──
fct_ard_ae_socpt <- function(adae, adsl, grouping, var_configs, sort_by_freq = FALSE) {
  trt_var <- grouping$trt_var

  stopifnot("ADAE must have AEBODSYS" = "AEBODSYS" %in% names(adae))
  stopifnot("ADAE must have AEDECOD" = "AEDECOD" %in% names(adae))

  # Merge treatment if needed
  if (!trt_var %in% names(adae)) {
    adae <- dplyr::inner_join(adae, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  ard <- fct_ard_hierarchical(
    adae, adsl, grouping, var_configs,
    parent_var = "AEBODSYS", child_var = "AEDECOD"
  )

  # Sort by frequency if requested (for Table 14.3.1.9)
  if (sort_by_freq && "Total" %in% names(ard)) {
    # Extract numeric n from "n (pct)" format for sorting
    ard$.sort_n <- suppressWarnings(as.numeric(gsub(" .*", "", ard[["Total"]])))
    ard$.sort_n[is.na(ard$.sort_n)] <- 0

    # Keep "any" row first, then sort parents by freq, children by freq within parent
    any_row <- ard[ard$row_type == "any", ]
    parent_rows <- ard[ard$row_type == "parent", ]
    child_rows <- ard[ard$row_type == "child", ]

    parent_order <- parent_rows$stat_label[order(-parent_rows$.sort_n)]

    sorted <- list(any_row)
    for (p in parent_order) {
      sorted <- c(sorted, list(parent_rows[parent_rows$stat_label == p, ]))
      p_children <- child_rows[child_rows$variable == "AEDECOD", ]
      # Match by preceding parent — approximate via position
      sorted <- c(sorted, list(p_children[order(-p_children$.sort_n), ]))
    }
    ard <- dplyr::bind_rows(sorted)
    ard$.sort_n <- NULL
  }

  ard
}

# ── AE filtered: generic filter + SOC/PT hierarchy ──
fct_ard_ae_filtered <- function(adae, adsl, grouping, var_configs, filter_expr = NULL) {
  if (!is.null(filter_expr)) {
    # Safely evaluate the filter expression
    tryCatch({
      adae <- adae[eval(filter_expr, adae), ]
    }, error = function(e) {
      # If filter fails (e.g., missing column), return empty
      adae <- adae[0, ]
    })
  }

  if (nrow(adae) == 0) {
    return(tibble::tibble(
      variable = character(), var_label = character(),
      var_type = character(), stat_label = character()
    ))
  }

  fct_ard_ae_socpt(adae, adsl, grouping, var_configs)
}

# ── AE by severity/grade ──
fct_ard_ae_by_severity <- function(adae, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE

  # Merge treatment if needed
  if (!trt_var %in% names(adae)) {
    adae <- dplyr::inner_join(adae, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  big_n <- vapply(groups, function(grp) {
    if (grp == "Total") nrow(adsl) else sum(adsl[[trt_var]] == grp)
  }, integer(1))

  # Determine severity variable
  sev_var <- if ("AETOXGR" %in% names(adae)) "AETOXGR"
             else if ("AESEV" %in% names(adae)) "AESEV"
             else "AESEV"

  # Max severity per subject per SOC/PT
  max_sev <- adae |>
    dplyr::group_by(.data[["USUBJID"]], .data[[trt_var]],
                     .data[["AEBODSYS"]], .data[["AEDECOD"]]) |>
    dplyr::summarise(max_grade = max(.data[[sev_var]], na.rm = TRUE), .groups = "drop")

  grades <- sort(unique(stats::na.omit(max_sev[["max_grade"]])))

  ard_rows <- list()

  # SOC/PT hierarchy with grade columns
  socs <- sort(unique(stats::na.omit(adae[["AEBODSYS"]])))

  for (soc in socs) {
    soc_data <- max_sev[max_sev[["AEBODSYS"]] == soc, ]

    # SOC header
    vals <- vapply(groups, function(grp) {
      subset <- if (grp == "Total") soc_data else soc_data[soc_data[[trt_var]] == grp, ]
      n <- length(unique(subset[["USUBJID"]]))
      N <- big_n[grp]
      fmt_npct(n, N, "A", 1)
    }, character(1))

    ard_rows <- c(ard_rows, list(c(
      list(variable = "AEBODSYS", var_label = "System Organ Class",
           var_type = "hierarchical", stat_label = soc, row_type = "parent"),
      stats::setNames(as.list(vals), groups)
    )))

    # PTs within SOC
    pts <- sort(unique(stats::na.omit(soc_data[["AEDECOD"]])))
    for (pt in pts) {
      pt_data <- soc_data[soc_data[["AEDECOD"]] == pt, ]

      vals <- vapply(groups, function(grp) {
        subset <- if (grp == "Total") pt_data else pt_data[pt_data[[trt_var]] == grp, ]
        n <- length(unique(subset[["USUBJID"]]))
        N <- big_n[grp]
        fmt_npct(n, N, "A", 1)
      }, character(1))

      ard_rows <- c(ard_rows, list(c(
        list(variable = "AEDECOD", var_label = "Preferred Term",
             var_type = "hierarchical", stat_label = paste0("  ", pt), row_type = "child"),
        stats::setNames(as.list(vals), groups)
      )))
    }
  }

  dplyr::bind_rows(ard_rows)
}
