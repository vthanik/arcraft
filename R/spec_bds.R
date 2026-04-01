# BDS (Basic Data Structure) template specifications
# Shared factory for vitals, lab, and ECG templates
# Each domain wrapper calls spec_bds() with domain-specific defaults

# ── Public wrappers ──

spec_vitals <- function(data = NULL) {
  spec_bds("vitals", data)
}

spec_lab <- function(data = NULL) {
  spec_bds("lab", data)
}

spec_ecg <- function(data = NULL) {
  spec_bds("ecg", data)
}

# ── Factory ──

spec_bds <- function(domain, data = NULL) {
  defaults <- .bds_domain_defaults(domain)

  available_params <- if (!is.null(data) && "PARAMCD" %in% names(data)) {
    unique(as.character(data[["PARAMCD"]]))
  } else {
    defaults$default_params
  }

  selected_params <- intersect(defaults$default_params, available_params)
  if (length(selected_params) == 0L) selected_params <- available_params[1L]

  # Detect visit pairs and analysis columns from data
  visit_pairs <- if (!is.null(data)) fct_detect_visit_pairs(data) else list()
  default_visit <- if (length(visit_pairs) > 0L) visit_pairs[[1]] else list(char = "AVISIT", num = "AVISITN")

  visits <- .sort_visits_by_pair(data, default_visit)
  param_configs <- .build_param_configs(data, available_params, selected_params)
  visit_configs <- .build_visit_configs(data, visits)

  analysis_cols_detected <- if (!is.null(data)) fct_detect_analysis_columns(data) else list()
  analysis_cols_selected <- vapply(analysis_cols_detected, function(c) {
    if (isTRUE(c$default_selected)) c$name else NA_character_
  }, character(1))
  analysis_cols_selected <- analysis_cols_selected[!is.na(analysis_cols_selected)]

  list(
    template = defaults$template_id,
    grouping = list(
      trt_var = defaults$trt_var,
      include_total = TRUE,
      total_label = "Total",
      selected_params = selected_params,
      available_params = available_params,
      selected_visits = visits,
      pop_flag = defaults$pop_flag
    ),
    param_configs = param_configs,
    stat_config = list(
      observed = c("n", "mean_sd", "median", "q1_q3", "min_max"),
      cfb = c("n", "mean_sd", "median"),
      include_cfb = "CHG" %in% analysis_cols_selected
    ),
    visit_configs = visit_configs,
    analysis_cols = list(
      available = analysis_cols_detected,
      selected = analysis_cols_selected
    ),
    visit_var = list(
      available_pairs = visit_pairs,
      selected = default_visit
    ),
    fmt = defaults$fmt
  )
}

# ── Domain defaults ──

.bds_domain_defaults <- function(domain) {
  common_fmt <- list(
    title_defaults = list(align = "center", bold = FALSE),
    cols = list(
      stub_width = 3.0,
      default_align = "center",
      n_counts = TRUE,
      n_format = "{label}\\n(N={n})"
    ),
    page = list(
      orientation = "landscape",
      paper = "letter",
      font_family = "Courier New",
      font_size = 9,
      margins = c(1, 1, 1, 1),
      col_gap = 4L
    ),
    rules = list(
      hline_preset = "header",
      vline_preset = "none"
    ),
    rows = list(
      group_by = "variable",
      page_by = NULL
    )
  )

  common_footnotes <- list(
    list(text = "Baseline = last non-missing value on or before first dose date."),
    list(text = "Change from baseline = value at visit minus baseline value.")
  )

  switch(domain,
    vitals = list(
      template_id = "vitals_summary",
      default_params = c("SYSBP", "DIABP", "PULSE", "TEMP", "RESP", "WEIGHT"),
      trt_var = "TRT01A",
      pop_flag = "SAFFL",
      adam_dataset = "advs",
      fmt = c(list(
        titles = list(
          list(text = "Table 14.3.5.1", bold = FALSE),
          list(text = "Vital Signs Results and Change from Baseline by Treatment and Visit", bold = FALSE)
        ),
        footnotes = common_footnotes,
        population = "Safety Analysis Set",
        source = "Source: ADSL, ADVS"
      ), common_fmt)
    ),
    lab = list(
      template_id = "lab_summary",
      default_params = c("ALT", "AST", "BILI", "CREAT", "ALB", "HGB", "WBC", "PLAT"),
      trt_var = "TRT01A",
      pop_flag = "SAFFL",
      adam_dataset = "adlb",
      fmt = c(list(
        titles = list(
          list(text = "Table 14.3.4.1.1", bold = FALSE),
          list(text = "Laboratory Results and Change from Baseline by Treatment and Visit", bold = FALSE)
        ),
        footnotes = common_footnotes,
        population = "Safety Analysis Set",
        source = "Source: ADSL, ADLB"
      ), common_fmt)
    ),
    ecg = list(
      template_id = "ecg_summary",
      default_params = c("QTCF", "QT", "HR", "PR", "QRS"),
      trt_var = "TRT01A",
      pop_flag = "SAFFL",
      adam_dataset = "adeg",
      fmt = c(list(
        titles = list(
          list(text = "Table 14.3.5.4", bold = FALSE),
          list(text = "ECG Results and Change from Baseline by Treatment and Visit", bold = FALSE)
        ),
        footnotes = common_footnotes,
        population = "Safety Analysis Set",
        source = "Source: ADSL, ADEG"
      ), common_fmt)
    ),
    stop(sprintf("Unknown BDS domain: '%s'", domain))
  )
}

# ── Helpers ──

#' Detect decimal precision from AVAL for each PARAMCD
#' @return Named list: paramcd -> list(label, decimals)
.build_param_configs <- function(data, available_params, selected_params) {
  configs <- list()

  for (pc in available_params) {
    label <- pc
    data_dec <- 0L

    if (!is.null(data) && "PARAMCD" %in% names(data)) {
      pc_rows <- data[data[["PARAMCD"]] == pc, , drop = FALSE]

      if ("PARAM" %in% names(pc_rows) && nrow(pc_rows) > 0L) {
        label <- as.character(pc_rows[["PARAM"]][1L])
      }

      if ("AVAL" %in% names(pc_rows) && nrow(pc_rows) > 0L) {
        data_dec <- .detect_decimal_places(pc_rows[["AVAL"]])
      }
    }

    configs[[pc]] <- list(
      label = label,
      selected = pc %in% selected_params,
      data_dec = data_dec,
      decimals = list(
        observed = .decimal_schema(data_dec),
        cfb = .decimal_schema(data_dec)
      )
    )
  }

  configs
}

#' Standard decimal schema: mean/median = data+1, sd = data+2, min/max = data
.decimal_schema <- function(data_dec) {
  list(
    n = 0L,
    mean = data_dec + 1L,
    sd = data_dec + 2L,
    median = data_dec + 1L,
    q1 = data_dec + 1L,
    q3 = data_dec + 1L,
    min = data_dec,
    max = data_dec
  )
}

#' Detect decimal places from a numeric vector
#' Returns the most common non-zero decimal count, or 0 if all integers
.detect_decimal_places <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0L) return(0L)

  # Convert to character, count digits after decimal point
  chars <- as.character(x)
  has_dot <- grepl(".", chars, fixed = TRUE)
  if (!any(has_dot)) return(0L)

  dec_parts <- sub("^[^.]*[.]?", "", chars[has_dot])
  dec_counts <- nchar(sub("0+$", "", dec_parts))
  dec_counts <- dec_counts[dec_counts > 0L]
  if (length(dec_counts) == 0L) return(0L)

  # Use median of observed decimal counts
  as.integer(stats::median(dec_counts))
}

#' Sort visits from data by numeric counterpart
#' @param visit_pair list(char = "AVISIT", num = "AVISITN")
#' @return Character vector of visit values sorted by numeric counterpart
.sort_visits <- function(data) {
  .sort_visits_by_pair(data, list(char = "AVISIT", num = "AVISITN"))
}

.sort_visits_by_pair <- function(data, visit_pair) {
  if (is.null(data)) return(character(0))
  char_col <- visit_pair$char
  num_col <- visit_pair$num
  if (!all(c(char_col, num_col) %in% names(data))) return(character(0))

  visit_df <- unique(data[, c(char_col, num_col), drop = FALSE])
  visit_df <- visit_df[!is.na(visit_df[[char_col]]) & nzchar(as.character(visit_df[[char_col]])), ]
  if (nrow(visit_df) == 0L) return(character(0))

  visit_df <- visit_df[order(visit_df[[num_col]]), ]
  as.character(visit_df[[char_col]])
}

#' Build visit configs from data
#' @return Named list: visit_label -> list(avisitn, selected)
.build_visit_configs <- function(data, visits) {
  if (length(visits) == 0L) return(list())

  configs <- list()
  for (v in visits) {
    avisitn <- NA_real_
    if (!is.null(data) && all(c("AVISIT", "AVISITN") %in% names(data))) {
      match_rows <- data[data[["AVISIT"]] == v & !is.na(data[["AVISIT"]]), , drop = FALSE]
      if (nrow(match_rows) > 0L) {
        avisitn <- match_rows[["AVISITN"]][1L]
      }
    }

    configs[[v]] <- list(
      avisitn = avisitn,
      label = v,
      selected = TRUE
    )
  }

  configs
}
