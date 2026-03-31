# AE ARD builders — pure R, no Shiny
# Uses cards package for ARD generation, arframe for wide conversion.
# Pipeline: cards::ard_stack() / ard_stack_hierarchical() → fr_wide_ard() → add meta columns

# ── AE Overall Summary ──
# Creates subject-level flag dataset from ADAE, then uses cards for ARD.
# Output columns: category, stat_label, <trt1>, <trt2>, ..., [Total]
fct_ard_ae_overall <- function(adae, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  total_label <- grouping$total_label %||% "Total"
  filter_flag <- var_configs$filter_flag %||% "TRTEMFL"

  # ── Filter ADAE to treatment-emergent ──
  if (filter_flag %in% names(adae)) {
    adae <- adae[adae[[filter_flag]] == "Y", , drop = FALSE]
  }

  # ── Filter to requested treatment levels ──
  if (trt_var %in% names(adae)) {
    adae <- adae[adae[[trt_var]] %in% trt_levels, , drop = FALSE]
  }
  adsl <- adsl[adsl[[trt_var]] %in% trt_levels, , drop = FALSE]

  # ── Build subject-level flag dataset ──
  ae_subj <- adsl[, c("USUBJID", trt_var), drop = FALSE]

  # Build flag columns from ADAE per subject
  flag_list <- lapply(split(adae, adae$USUBJID), function(d) {
    data.frame(
      USUBJID = d$USUBJID[1],
      any_teae = TRUE,
      any_sae = any(d$AESER == "Y", na.rm = TRUE),
      any_related = any(d$AEREL %in% c("POSSIBLE", "PROBABLE", "RELATED"), na.rm = TRUE),
      any_death = any(d$AESDTH == "Y" | d$AEOUT == "FATAL", na.rm = TRUE),
      max_sev = if (all(is.na(d$AESEV))) NA_character_
                else c("MILD", "MODERATE", "SEVERE")[
                  max(match(d$AESEV, c("MILD", "MODERATE", "SEVERE")), na.rm = TRUE)
                ],
      stringsAsFactors = FALSE
    )
  })
  ae_flags_df <- do.call(rbind, flag_list)

  ae_subj <- merge(ae_subj, ae_flags_df, by = "USUBJID", all.x = TRUE)

  # Fill NA for subjects with no AEs
  ae_subj$any_teae[is.na(ae_subj$any_teae)] <- FALSE
  ae_subj$any_sae[is.na(ae_subj$any_sae)] <- FALSE
  ae_subj$any_related[is.na(ae_subj$any_related)] <- FALSE
  ae_subj$any_death[is.na(ae_subj$any_death)] <- FALSE
  ae_subj$max_sev <- factor(
    ae_subj$max_sev,
    levels = c("MILD", "MODERATE", "SEVERE")
  )

  # ── Build ARD via cards ──
  raw_ard <- rlang::eval_tidy(rlang::expr(
    cards::ard_stack(
      data = ae_subj,
      .by = dplyr::all_of(!!trt_var),
      cards::ard_dichotomous(
        variables = c(any_teae, any_sae, any_death, any_related),
        value = list(
          any_teae = TRUE, any_sae = TRUE,
          any_death = TRUE, any_related = TRUE
        )
      ),
      cards::ard_categorical(variables = "max_sev"),
      .overall = !!include_total
    )
  ))

  # ── Convert to wide via arframe ──
  overall_label <- if (include_total) total_label else NULL
  wide <- arframe::fr_wide_ard(
    raw_ard,
    statistic = list(
      dichotomous = "{n} ({p}%)",
      categorical = "{n} ({p}%)"
    ),
    column = trt_var,
    decimals = c(p = 1),
    overall = overall_label,
    label = c(
      any_teae = "Any TEAE",
      any_sae = "Any Serious AE (SAE)",
      any_death = "Any AE Leading to Death",
      any_related = "Any AE Related to Study Drug",
      max_sev = "Maximum Severity"
    )
  )

  # ── Fix stat_label for dichotomous vars ──
  # fr_wide_ard shows "TRUE" as stat_label for dichotomous — replace with variable label
  flag_vars <- c("Any TEAE", "Any Serious AE (SAE)",
                  "Any AE Leading to Death", "Any AE Related to Study Drug")
  is_flag <- wide$variable %in% flag_vars
  wide$stat_label[is_flag] <- wide$variable[is_flag]

  # ── Add category column for group_by ──
  # Flag rows get empty category, severity rows get "Maximum Severity"
  wide$category <- ifelse(is_flag, "", "Maximum Severity")

  # ── Reorder columns ──
  expected_cols <- trt_levels
  if (include_total) expected_cols <- c(expected_cols, total_label)
  present_cols <- intersect(expected_cols, names(wide))
  meta <- c("category", "variable", "stat_label")
  extra <- setdiff(names(wide), c(meta, present_cols))
  wide <- wide[, c(meta, present_cols, extra), drop = FALSE]

  # ── Attach raw ARD for QC bundle ──
  attr(wide, "raw_ard") <- raw_ard

  wide
}


# ── AE Hierarchical (SOC/PT, HLT/PT, or N-level hierarchy) ──
# Uses cards::ard_stack_hierarchical() for proper hierarchical counting.
# Hierarchy variables taken from grouping$analysis_vars (user-controlled order).
# Output columns: <hier_var1>, <hier_var2>, ..., row_type, <trt1>, <trt2>, ..., [Total]
fct_ard_ae_hierarchy <- function(adae, adsl, grouping, var_configs) {
  trt_var <- grouping$trt_var
  trt_levels <- grouping$trt_levels
  include_total <- grouping$include_total %||% TRUE
  total_label <- grouping$total_label %||% "Total"
  filter_flag <- var_configs$filter_flag %||% "TRTEMFL"
  hierarchy_vars <- grouping$analysis_vars
  sort_order <- var_configs$sort_order %||% "frequency"
  include_overall <- var_configs$include_overall %||% TRUE
  overall_label <- var_configs$overall_label %||% "Subjects with at Least One TEAE"

  if (length(hierarchy_vars) == 0) {
    cli::cli_abort("No hierarchy variables selected.", call = NULL)
  }

  # ── Filter ADAE ──
  if (filter_flag %in% names(adae)) {
    adae <- adae[adae[[filter_flag]] == "Y", , drop = FALSE]
  }
  if (trt_var %in% names(adae)) {
    adae <- adae[adae[[trt_var]] %in% trt_levels, , drop = FALSE]
  }
  adsl <- adsl[adsl[[trt_var]] %in% trt_levels, , drop = FALSE]

  # ── Apply per-variable level filtering ──
  for (v in hierarchy_vars) {
    cfg <- var_configs[[v]]
    if (!is.null(cfg$levels) && v %in% names(adae)) {
      adae <- adae[adae[[v]] %in% cfg$levels, , drop = FALSE]
    }
  }

  # ── Build hierarchical ARD via cards (N-level) ──
  var_syms <- rlang::syms(hierarchy_vars)
  raw_ard <- rlang::eval_tidy(rlang::expr(
    cards::ard_stack_hierarchical(
      data = adae,
      variables = c(!!!var_syms),
      by = !!rlang::sym(trt_var),
      denominator = adsl,
      id = USUBJID,
      overall = !!include_total,
      over_variables = !!include_overall
    )
  ))

  # ── Apply sorting ──
  if (sort_order == "frequency") {
    raw_ard <- cards::sort_ard_hierarchical(raw_ard, sort = "descending")
  } else if (sort_order == "alpha_freq") {
    raw_ard <- cards::sort_ard_hierarchical(raw_ard, sort = "alphanumeric")
  }

  # ── Convert to wide via arframe ──
  overall_str <- if (include_total) total_label else NULL
  label_map <- character(0)
  if (include_overall) {
    label_map <- c("..ard_hierarchical_overall.." = overall_label)
  }

  wide <- arframe::fr_wide_ard(
    raw_ard,
    statistic = "{n} ({p}%)",
    column = trt_var,
    decimals = c(p = 1),
    overall = overall_str,
    label = label_map
  )

  # ── Reorder treatment columns ──
  expected_cols <- trt_levels
  if (include_total) expected_cols <- c(expected_cols, total_label)
  present_cols <- intersect(expected_cols, names(wide))
  # fr_wide_ard outputs hierarchy level columns + row_type
  # For 2-level: soc, pt. For N-level: soc, l2, ..., l(N-1), pt
  all_cols <- names(wide)
  meta <- all_cols[!all_cols %in% c(trt_levels, total_label)]
  extra <- setdiff(names(wide), c(meta, present_cols))
  wide <- wide[, c(meta, present_cols, extra), drop = FALSE]

  # ── Attach metadata for downstream use ──
  attr(wide, "raw_ard") <- raw_ard
  attr(wide, "hierarchy_vars") <- hierarchy_vars

  wide
}
