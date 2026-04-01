# Response summary template specification
# Covers binary/categorical efficacy endpoints (ADRS: BOR, CBOR, OVRLRESP)

spec_response <- function(data = NULL) {
  available_params <- if (!is.null(data) && "PARAMCD" %in% names(data)) {
    unique(as.character(data[["PARAMCD"]]))
  } else {
    c("BOR", "CBOR", "OVRLRESP")
  }

  active_param <- .select_default_param(available_params)
  categories <- .detect_response_categories(data, active_param)

  list(
    template = "resp_summary",
    grouping = list(
      trt_var = "TRT01A",
      include_total = TRUE,
      total_label = "Total",
      active_param = active_param,
      available_params = available_params,
      pop_flag = "ITTFL"
    ),
    category_configs = list(
      categories = categories,
      visible = categories,
      labels = stats::setNames(as.list(categories), categories),
      order = categories
    ),
    format_config = list(
      display = "nn_pct",
      pct_dec = 1L,
      denominator = "big_n"
    ),
    comparison = list(
      enabled = FALSE,
      ref_group = NULL,
      tests = character(0)
    ),
    fmt = list(
      titles = list(
        list(text = "Table 14.2.2.1", bold = FALSE),
        list(text = "Best Overall Response by Treatment Group", bold = FALSE)
      ),
      footnotes = list(
        list(text = "Response assessed per RECIST v1.1 criteria."),
        list(text = "Percentages based on N in column header.")
      ),
      population = "ITT Analysis Set",
      source = "Source: ADSL, ADRS",
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
      )
    )
  )
}

# ── Helpers ──

#' Select best default PARAMCD for response table
#' Prefers BOR > CBOR > OVRLRESP > first available
.select_default_param <- function(available_params) {
  preferred <- c("BOR", "CBOR", "OVRLRESP")
  match <- intersect(preferred, available_params)
  if (length(match) > 0L) match[1L] else available_params[1L]
}

#' Detect response categories from AVALC for a given PARAMCD
#' Returns categories in standard clinical order if recognized,
#' otherwise in order of appearance
.detect_response_categories <- function(data, active_param) {
  if (is.null(data) || !"AVALC" %in% names(data)) {
    return(c("CR", "PR", "SD", "PD", "NE"))
  }

  if (!"PARAMCD" %in% names(data)) {
    vals <- unique(as.character(stats::na.omit(data[["AVALC"]])))
  } else {
    param_rows <- data[data[["PARAMCD"]] == active_param, , drop = FALSE]
    vals <- unique(as.character(stats::na.omit(param_rows[["AVALC"]])))
  }

  if (length(vals) == 0L) return(c("CR", "PR", "SD", "PD", "NE"))

  # Apply standard clinical ordering for recognized response values
  standard_order <- c("CR", "PR", "SD", "PD", "NE", "UNK",
                       "Complete Response", "Partial Response",
                       "Stable Disease", "Progressive Disease",
                       "Not Evaluable", "Unknown")
  known <- intersect(standard_order, vals)
  unknown <- setdiff(vals, standard_order)

  c(known, sort(unknown))
}
