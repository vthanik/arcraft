# Marked Abnormality ARD builder — pure R, no Shiny
# Tables 14.3.4.5-6, 14.3.5.2: Subjects with marked lab/vitals abnormalities

fct_ard_marked_abnorm <- function(bds_data, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE

  stopifnot("Data required" = !is.null(bds_data))
  stopifnot("Must have PARAMCD" = "PARAMCD" %in% names(bds_data))
  stopifnot("Must have AVAL" = "AVAL" %in% names(bds_data))

  # Merge treatment if needed
  if (!trt_var %in% names(bds_data)) {
    bds_data <- dplyr::inner_join(bds_data, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  paramcds <- var_configs$paramcds %||% unique(bds_data[["PARAMCD"]])
  bds_data <- bds_data[bds_data[["PARAMCD"]] %in% paramcds, ]

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  big_n <- vapply(groups, function(grp) {
    if (grp == "Total") nrow(adsl) else sum(adsl[[trt_var]] == grp)
  }, integer(1))

  # Marked abnormality criteria
  # High: AVAL > 2 × ANRHI (if available) or ANRIND == "HIGH"
  # Low: AVAL < 0.5 × ANRLO (if available) or ANRIND == "LOW"
  has_range <- "ANRHI" %in% names(bds_data) && "ANRLO" %in% names(bds_data)
  has_indicator <- "ANRIND" %in% names(bds_data)

  ard_rows <- list()

  for (pc in paramcds) {
    param_data <- bds_data[bds_data[["PARAMCD"]] == pc, ]
    if (nrow(param_data) == 0) next

    param_label <- if ("PARAM" %in% names(param_data)) param_data[["PARAM"]][1] else pc

    # Marked HIGH
    for (direction in c("High", "Low")) {
      row_data <- list(
        variable = pc, var_label = param_label, var_type = "marked_abnorm",
        stat_label = paste0("  Marked ", direction)
      )

      for (grp in groups) {
        subset <- if (grp == "Total") param_data else param_data[param_data[[trt_var]] == grp, ]

        if (has_range) {
          if (direction == "High") {
            marked <- subset[!is.na(subset[["AVAL"]]) & !is.na(subset[["ANRHI"]]) &
                              subset[["ANRHI"]] > 0 &
                              subset[["AVAL"]] > 2 * subset[["ANRHI"]], ]
          } else {
            marked <- subset[!is.na(subset[["AVAL"]]) & !is.na(subset[["ANRLO"]]) &
                              subset[["ANRLO"]] > 0 &
                              subset[["AVAL"]] < 0.5 * subset[["ANRLO"]], ]
          }
        } else if (has_indicator) {
          marked <- subset[subset[["ANRIND"]] == toupper(direction), ]
        } else {
          marked <- subset[0, ]
        }

        n <- length(unique(marked[["USUBJID"]]))
        N <- big_n[grp]
        row_data[[grp]] <- fmt_npct(n, N, "A", 1)
      }
      ard_rows <- c(ard_rows, list(row_data))
    }
  }

  dplyr::bind_rows(ard_rows)
}
