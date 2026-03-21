# Demographics template specification — defaults

spec_demog <- function(data = NULL) {
  # Default analysis variables
  default_vars <- c("AGE", "AGEGR1", "SEX", "RACE", "ETHNIC")

  # If data provided, intersect with available columns
  avail_vars <- if (!is.null(data)) {
    intersect(default_vars, names(data))
  } else {
    default_vars
  }

  # Detect variable types from data
  var_types <- if (!is.null(data)) {
    stats::setNames(
      vapply(avail_vars, function(v) fct_detect_var_type(data, v), character(1)),
      avail_vars
    )
  } else {
    stats::setNames(
      c("continuous", "categorical", "categorical", "categorical", "categorical"),
      default_vars
    )
  }

  # Default per-variable configs
  var_configs <- list()
  for (v in avail_vars) {
    if (var_types[v] == "continuous") {
      var_configs[[v]] <- list(
        type = "continuous",
        stats = c("n", "mean_sd", "median", "q1_q3", "min_max"),
        decimals = list(n = 0, mean = 1, sd = 2, median = 1, q1 = 1, q3 = 1, min = 0, max = 0),
        custom_labels = NULL
      )
    } else {
      var_configs[[v]] <- list(
        type = "categorical",
        cat_format = "npct",
        zero_style = "A",
        pct_dec = 1,
        denominator = "big_n",
        levels = if (!is.null(data) && v %in% names(data)) {
          if (is.factor(data[[v]])) levels(data[[v]])
          else get_unique_levels(data[[v]])
        }
      )
    }
  }

  list(
    template = "demog",
    grouping = list(
      trt_var = "TRT01A",
      include_total = TRUE,
      analysis_vars = avail_vars
    ),
    var_configs = var_configs,
    fmt = list(
      titles = list(
        list(text = "Table 14.1.1", bold = FALSE),
        list(text = "Summary of Demographics and Baseline Characteristics", bold = FALSE)
      ),
      footnotes = list(
        list(text = "Percentages based on N in column header.")
      ),
      population = "Safety Analysis Set",
      source = "Source: ADSL",
      title_align = "center",
      cols = list(
        stub_width = 2.5,
        body_align = "center",
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
