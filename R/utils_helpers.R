# Utility helpers

`%||%` <- function(x, y) if (is.null(x)) y else x

# Safe evaluation of user-typed filter expressions.
# Uses rlang::eval_tidy with a data mask only — no parent env access,
# preventing system(), source(), etc.
safe_eval_filter <- function(expr_str, data) {
  if (is.null(expr_str) || !nzchar(expr_str)) return(rep(TRUE, nrow(data)))
  parsed <- tryCatch(rlang::parse_expr(expr_str), error = function(e) NULL)
  if (is.null(parsed)) return(rep(TRUE, nrow(data)))
  mask <- rlang::as_data_mask(data)
  tryCatch(
    rlang::eval_tidy(parsed, data = mask),
    error = function(e) rep(TRUE, nrow(data))
  )
}

# Resolve bundled data path — works in dev (app.R) and installed package mode
data_path <- function(filename) {
  # Try installed package first
  p <- system.file("data", filename, package = "arbuilder")
  if (nzchar(p)) return(p)
  # Dev mode: inst/data/ relative to working directory
  p <- file.path("inst", "data", filename)
  if (file.exists(p)) return(p)
  ""
}

# Read bundled data — uses parquet for large files (>500KB), readRDS for small
read_bundled <- function(path) {
  size <- file.size(path)
  if (!is.na(size) && size > 512000L) {
    pq_path <- sub("[.]rds$", ".parquet", path)
    if (file.exists(pq_path)) return(arrow::read_parquet(pq_path))
  }
  readRDS(path)
}

coalesce_list <- function(defaults, overrides) {
  out <- defaults
  for (nm in names(overrides)) {
    if (!is.null(overrides[[nm]])) out[[nm]] <- overrides[[nm]]
  }
  out
}

safe_label <- function(data, var) {
  lbl <- attr(data[[var]], "label")
  if (is.null(lbl) || !nzchar(lbl)) return(var)
  lbl
}

# Normalize format config — merge template fmt with full schema defaults
# Handles backward compat: body_align → default_align, title_align → title_defaults
normalize_fmt <- function(fmt) {
  defaults <- list(
    titles = list(), footnotes = list(), population = "", source = "",
    title_defaults = list(align = "center", bold = FALSE),
    fn_separator = FALSE, fn_placement = "every",
    cols = list(width_mode = "auto", default_align = "center",
                space_mode = "indent", split = FALSE,
                n_counts = TRUE, n_format = "{label}\\n(N={n})",
                stub_width = 2.5, stub_align = "left", per_col = list()),
    page = list(orientation = "landscape", paper = "letter",
                font_family = "Courier New", font_size = 9,
                margins = c(1, 1, 1, 1), col_gap = 4,
                continuation = "", orphan_min = 3L, widow_min = 3L),
    rules = list(hline_preset = "header", vline_preset = "none",
                 line_width = "thin", line_color = "#000000", line_style = "solid",
                 vline_cols = NULL, vline_abovepos = NULL, vline_belowpos = NULL),
    header = list(bold = TRUE, align = "center", valign = "bottom",
                  background = NULL, color = NULL, font_size = NULL, repeat_on_page = TRUE),
    spans = list(),
    rows = list(group_by = NULL, group_label = NULL, group_keep = TRUE,
                blank_after = NULL, page_by = NULL,
                page_by_visible = TRUE, indent_by = NULL,
                sort_by = NULL, suppress = NULL, wrap = FALSE),
    pagehead = list(left = "", center = "", right = "",
                    font_size = NULL, bold = NULL),
    pagefoot = list(left = "", center = "", right = "",
                    font_size = NULL, bold = NULL),
    spacing = list(titles_after = 1L, footnotes_before = 1L,
                   pagehead_after = 0L, pagefoot_before = 0L,
                   page_by_after = NULL),
    styles = list(),
    output_format = "rtf"
  )

  # Backward compat: spaces → space_mode
  if (!is.null(fmt$cols$spaces) && is.null(fmt$cols$space_mode)) {
    fmt$cols$space_mode <- fmt$cols$spaces
    fmt$cols$spaces <- NULL
  }
  # Backward compat: body_align → default_align
  if (!is.null(fmt$cols$body_align) && is.null(fmt$cols$default_align)) {
    fmt$cols$default_align <- fmt$cols$body_align
    fmt$cols$body_align <- NULL
  }
  # Backward compat: title_align → title_defaults$align
  if (!is.null(fmt$title_align) && is.null(fmt$title_defaults)) {
    fmt$title_defaults <- list(align = fmt$title_align, bold = FALSE)
    fmt$title_align <- NULL
  }

  # Deep merge: for each top-level key, if it's a named list, merge sub-keys
  # Unnamed lists (titles, footnotes, spans) are replaced wholesale
  out <- defaults
  replace_keys <- c("titles", "footnotes", "spans")
  for (nm in names(fmt)) {
    if (nm %in% replace_keys) {
      # Positional lists — replace entirely, don't merge
      out[[nm]] <- fmt[[nm]]
    } else if (nm %in% names(defaults) && is.list(defaults[[nm]]) && is.list(fmt[[nm]])) {
      out[[nm]] <- coalesce_list(defaults[[nm]], fmt[[nm]])
    } else {
      out[[nm]] <- fmt[[nm]]
    }
  }

  # Force population/source empty — removed from UI
  out$population <- ""
  out$source <- ""

  out
}

# Read _arframe.yml company config
# Search order: working directory, then home directory
# Returns NULL if not found
read_arframe_yml <- function() {
  paths <- c("_arframe.yml", file.path(Sys.getenv("HOME"), "_arframe.yml"))
  for (p in paths) {
    if (file.exists(p)) {
      tryCatch({
        yml <- yaml::read_yaml(p)
        return(yml)
      }, error = function(e) NULL)
    }
  }
  NULL
}

# Get format defaults: hardcoded → _arframe.yml overlay
# Convert literal \n (typed by user in text inputs) to actual newline
resolve_newlines <- function(x) {
  if (is.null(x) || !is.character(x)) return(x)
  gsub("\\\\n", "\n", x)
}

# Apply population flag filter (SAFFL/ITTFL/etc.)
apply_pop_filter <- function(d, pop_flag) {
  if (!is.null(pop_flag) && nzchar(pop_flag) && pop_flag %in% names(d)) {
    d[d[[pop_flag]] == "Y", ]
  } else {
    d
  }
}

# Get sorted unique non-NA levels of a column
get_unique_levels <- function(x) {
  sort(unique(x[!is.na(x)]))
}

# Get per-stat decimal from config
get_stat_dec <- function(config, stat_name, fallback = 1) {
  decs <- config$decimals
  if (is.list(decs)) decs[[stat_name]] %||% fallback
  else decs %||% fallback
}

# Cards stat format mapping (arbuilder stat name -> fr_wide_ard format string)
CARDS_STAT_FORMAT_MAP <- list(
  n = "{N}", mean = "{mean}", sd = "{sd}",
  mean_sd = "{mean} ({sd})", median = "{median}",
  q1 = "{p25}", q3 = "{p75}", q1_q3 = "{p25}, {p75}",
  min = "{min}", max = "{max}", min_max = "{min}, {max}",
  geo_mean = "{mean}", cv = "{sd}", geo_mean_cv = "{mean} ({sd})"
)

# Cards decimal name mapping (arbuilder stat name -> cards stat name)
CARDS_DECIMAL_MAP <- list(
  mean = "mean", sd = "sd", median = "median",
  q1 = "p25", q3 = "p75", min = "min", max = "max",
  geo_mean = "mean", cv = "sd", n = "N"
)

# ── Shared stat-format and decimals builders ──
# Used by both fct_ard_demog_cards.R (runtime) and fct_codegen.R (code generation)

# Build statistic format list for fr_wide_ard from var_configs
build_stat_format_from_config <- function(var_configs, analysis_vars) {
  fmt <- list()
  for (v in analysis_vars) {
    cfg <- var_configs[[v]] %||% list()
    vtype <- cfg$type %||% "categorical"

    if (vtype == "continuous") {
      stats <- cfg$stats %||% c("n", "mean_sd", "median", "q1_q3", "min_max")
      stat_labels <- cfg$stat_labels %||% list()
      spec <- character(0)
      for (s in stats) {
        lbl <- stat_labels[[s]] %||% STAT_LABELS[[s]] %||% s
        fs <- CARDS_STAT_FORMAT_MAP[[s]] %||% "{N}"
        spec[[lbl]] <- fs
      }
      fmt[[v]] <- spec
    } else {
      cat_format <- cfg$cat_format %||% "npct"
      fmt[[v]] <- switch(cat_format,
        npct = "{n} ({p}%)",
        n = "{n}",
        nn_pct = "{n}/{N} ({p}%)",
        "{n} ({p}%)"
      )
    }
  }
  fmt
}

# Build decimals map for fr_wide_ard from var_configs
build_decimals_from_config <- function(var_configs, analysis_vars) {
  dec <- list()
  for (v in analysis_vars) {
    cfg <- var_configs[[v]] %||% list()
    if (!is.null(cfg$decimals) && is.list(cfg$decimals)) {
      d <- list()
      for (nm in names(cfg$decimals)) {
        cards_nm <- CARDS_DECIMAL_MAP[[nm]] %||% nm
        d[[cards_nm]] <- cfg$decimals[[nm]]
      }
      if (length(d) > 0) dec[[v]] <- d
    }
    if (!is.null(cfg$pct_dec)) {
      dec[[v]] <- c(dec[[v]] %||% list(), list(p = cfg$pct_dec))
    }
  }
  dec
}

# Centralized stat labels — single source of truth
STAT_LABELS <- list(
  n = "n", mean = "Mean", sd = "SD", mean_sd = "Mean (SD)",
  median = "Median", q1 = "Q1", q3 = "Q3", q1_q3 = "Q1, Q3",
  min = "Min", max = "Max", min_max = "Min, Max",
  geo_mean = "Geometric Mean", cv = "CV%", geo_mean_cv = "Geometric Mean (CV%)"
)

# Default decimals per stat
STAT_DECIMALS <- list(
  n = 0, mean = 1, sd = 2, median = 1, q1 = 1, q3 = 1,
  min = 0, max = 0, geo_mean = 2, cv = 1
)

