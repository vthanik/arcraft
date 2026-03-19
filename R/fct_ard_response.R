# Response ARD builder — pure R, no Shiny
# Tables 14.2.2.1-6: BOR distribution, ORR, CBR with CIs

fct_ard_response <- function(adrs, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  paramcd <- var_configs$paramcd %||% "BOR"

  stopifnot("ADRS required" = !is.null(adrs))
  stopifnot("Treatment var must exist in ADSL" = trt_var %in% names(adsl))

  # Filter to BOR parameter
  rs_data <- if ("PARAMCD" %in% names(adrs)) {
    adrs[adrs[["PARAMCD"]] == paramcd, ]
  } else adrs

  # Merge treatment if needed
  if (!trt_var %in% names(rs_data)) {
    rs_data <- dplyr::inner_join(rs_data, adsl[, c("USUBJID", trt_var), drop = FALSE], by = "USUBJID")
  }

  groups <- trt_levels
  if (include_total) groups <- c(groups, "Total")

  # Response categories in standard order
  resp_var <- if ("AVALC" %in% names(rs_data)) "AVALC" else "RSSTRESC"
  all_cats <- c("CR", "PR", "SD", "PD", "NE")
  present_cats <- intersect(all_cats, unique(rs_data[[resp_var]]))
  # Add any non-standard categories
  other_cats <- setdiff(unique(stats::na.omit(rs_data[[resp_var]])), all_cats)
  response_cats <- c(present_cats, sort(other_cats))

  ard_rows <- list()

  # N per group
  n_row <- list(variable = "RESPONSE", var_label = "Best Overall Response",
                var_type = "response", stat_label = "  N")
  for (grp in groups) {
    subset <- if (grp == "Total") rs_data else rs_data[rs_data[[trt_var]] == grp, ]
    n_row[[grp]] <- fmt_count(nrow(subset))
  }
  ard_rows <- c(ard_rows, list(n_row))

  # Response categories
  for (cat in response_cats) {
    row_data <- list(variable = "RESPONSE", var_label = "Best Overall Response",
                     var_type = "response", stat_label = paste0("  ", cat))
    for (grp in groups) {
      subset <- if (grp == "Total") rs_data else rs_data[rs_data[[trt_var]] == grp, ]
      n <- sum(subset[[resp_var]] == cat, na.rm = TRUE)
      N <- nrow(subset)
      row_data[[grp]] <- fmt_npct(n, N, "A", 1)
    }
    ard_rows <- c(ard_rows, list(row_data))
  }

  # ORR = CR + PR
  orr_row <- list(variable = "ORR", var_label = "Objective Response Rate",
                  var_type = "response", stat_label = "  ORR (CR+PR)")
  for (grp in groups) {
    subset <- if (grp == "Total") rs_data else rs_data[rs_data[[trt_var]] == grp, ]
    responders <- sum(subset[[resp_var]] %in% c("CR", "PR"), na.rm = TRUE)
    N <- nrow(subset)
    rate <- if (N > 0) responders / N * 100 else 0

    # Clopper-Pearson 95% CI
    ci <- if (N > 0) {
      tryCatch({
        bt <- stats::binom.test(responders, N)
        bt$conf.int * 100
      }, error = function(e) c(NA, NA))
    } else c(NA, NA)

    orr_row[[grp]] <- fmt_response_rate(responders, N, rate, ci[1], ci[2])
  }
  ard_rows <- c(ard_rows, list(orr_row))

  # CBR = CR + PR + SD
  cbr_row <- list(variable = "CBR", var_label = "Clinical Benefit Rate",
                  var_type = "response", stat_label = "  CBR (CR+PR+SD)")
  for (grp in groups) {
    subset <- if (grp == "Total") rs_data else rs_data[rs_data[[trt_var]] == grp, ]
    benefiters <- sum(subset[[resp_var]] %in% c("CR", "PR", "SD"), na.rm = TRUE)
    N <- nrow(subset)
    rate <- if (N > 0) benefiters / N * 100 else 0

    ci <- if (N > 0) {
      tryCatch({
        bt <- stats::binom.test(benefiters, N)
        bt$conf.int * 100
      }, error = function(e) c(NA, NA))
    } else c(NA, NA)

    cbr_row[[grp]] <- fmt_response_rate(benefiters, N, rate, ci[1], ci[2])
  }
  ard_rows <- c(ard_rows, list(cbr_row))

  dplyr::bind_rows(ard_rows)
}
