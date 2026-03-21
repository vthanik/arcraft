# Utility helpers

`%||%` <- function(x, y) if (is.null(x)) y else x

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
                spaces = "indent", split = FALSE,
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
                  bg = NULL, fg = NULL, font_size = NULL, repeat_on_page = TRUE),
    spans = list(),
    rows = list(group_by = NULL, group_label = NULL, group_keep = TRUE,
                group_bold = FALSE, blank_after = NULL, page_by = NULL,
                page_by_bold = FALSE, page_by_align = "left",
                page_by_visible = TRUE, indent_by = NULL,
                sort_by = NULL, repeat_cols = NULL, wrap = FALSE),
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

