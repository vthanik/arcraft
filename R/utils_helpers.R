# Utility helpers

`%||%` <- function(x, y) if (is.null(x)) y else x

is_truthy <- function(x) {

  if (is.null(x)) return(FALSE)
  if (length(x) == 0) return(FALSE)
  if (is.logical(x) && length(x) == 1) return(!is.na(x) && x)
  if (is.character(x) && length(x) == 1) return(nzchar(x))
  TRUE
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
                n_counts = TRUE, n_format = "(N={n})",
                stub_width = 2.5, stub_align = "left", per_col = list()),
    page = list(orientation = "landscape", paper = "letter",
                font_family = "Courier New", font_size = 9,
                margins = c(1, 1, 1, 1), col_gap = 4,
                continuation = "", orphan_min = 3L, widow_min = 3L),
    rules = list(hline_preset = "header", vline_preset = "none",
                 line_width = "thin", line_color = "#000000", line_style = "solid"),
    header = list(bold = TRUE, align = "center", valign = "bottom", bg = NULL, fg = NULL),
    spans = list(),
    rows = list(group_by = NULL, blank_after = NULL, page_by = NULL,
                page_by_bold = FALSE, indent_by = NULL,
                repeat_cols = NULL, wrap = FALSE),
    pagehead = list(left = "", center = "", right = ""),
    pagefoot = list(left = "", center = "", right = ""),
    spacing = list(titles_after = 1L, footnotes_before = 1L,
                   pagehead_after = 0L, pagefoot_before = 0L)
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

  # Deep merge: for each top-level key, if it's a list, merge sub-keys
  out <- defaults
  for (nm in names(fmt)) {
    if (nm %in% names(defaults) && is.list(defaults[[nm]]) && is.list(fmt[[nm]])) {
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
get_format_defaults <- function() {
  base <- normalize_fmt(list())
  yml <- read_arframe_yml()
  if (!is.null(yml)) {
    for (section in names(yml)) {
      if (section %in% names(base) && is.list(base[[section]]) && is.list(yml[[section]])) {
        base[[section]] <- coalesce_list(base[[section]], yml[[section]])
      } else if (section %in% names(base)) {
        base[[section]] <- yml[[section]]
      }
    }
  }
  base
}
