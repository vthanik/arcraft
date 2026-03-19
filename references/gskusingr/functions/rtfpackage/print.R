#' Print an `rtf_doc` Object
#'
#' @description Provides a concise, formatted summary of the `rtf_doc` object's
#'   contents and settings, printed to the console. This allows for quick
#'   inspection of the table or figure structure before building the final RTF document.
#'
#' @param x An `rtf_doc` object.
#' @param ... Not used.
#' @return Invisibly returns the input `rtf_doc` object `x`.
#' @export
#' @examples
#' library(gt)
#' rtf_obj <- rtf_table(gt(iris[1:5, 1:4]))
#'
#' # Printing the object shows a summary of its configuration
#' rtf_obj
print.rtf_doc <- function(x, ...) {
  UseMethod("print")
}


#' @export
print.rtf_tbl <- function(x, ...) {
  # --- 1. Get Key Information from the object ---
  colattr <- util_rtf_dt_get(x, "_rtf_colattr")
  data_dims <- if (!is.null(colattr$var)) {
    dim(util_rtf_dt_get(x, "_data")[colattr$var])
  } else {
    c(0, 0)
  }
  rows <- data_dims[1] %||% 0L
  cols <- data_dims[2] %||% 0L
  spanners <- util_rtf_dt_get(x, "_spanners") %||% data.frame()
  arrow <- cli::symbol$arrow_right

  # --- 2. Build the CLI output ---
  cli::cli_rule(
    left = "{.cls rtf_tbl} Summary",
    right = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )

  # --- Table Content ---
  cli::cli_h2("Table Content")
  cli::cli_text("{arrow} {.strong Dimensions}: {rows} rows x {cols} columns")
  cols_str <- if (!is.null(colattr$var)) {
    paste(colattr$var, collapse = ", ")
  } else {
    "<none>"
  }
  cli::cli_text("{arrow} {.strong Columns}: {cols_str}")

  if (nrow(spanners) > 0) {
    spanner_details <- purrr::pmap_chr(
      spanners,
      function(spanner_label, vars_from_gt, ...) {
        lab <- cli::style_italic(as.character(spanner_label))
        n <- if (is.null(vars_from_gt)) 0L else length(vars_from_gt)
        paste0(lab, " (", cli::col_cyan(n), " columns)")
      }
    )
    details <- paste(spanner_details, collapse = "; ")
    cli::cli_text("{arrow} {.strong Column Spanners}: {details}")
  }

  # --- Page Layout Components ---
  cli::cli_h2("Page Layout")
  n_title <- nrow(util_rtf_dt_get(x, "_title"))
  title_status <- if (n_title > 0) {
    cli::col_green(paste0(n_title, " line(s)"))
  } else {
    cli::col_silver("No")
  }
  cli::cli_text("{arrow} Title: {title_status}")

  n_header <- nrow(util_rtf_dt_get(x, "_header"))
  header_status <- if (n_header > 0) {
    cli::col_green(paste0(n_header, " line(s)"))
  } else {
    cli::col_silver("No")
  }
  cli::cli_text("{arrow} Header: {header_status}")

  n_footer <- nrow(util_rtf_dt_get(x, "_footer"))
  n_sys_footer <- nrow(util_rtf_dt_get(x, "_sys_footer"))
  if (n_footer + n_sys_footer > 0) {
    total_lines <- cli::col_green(paste0(
      n_footer + n_sys_footer,
      " line(s)"
    ))
    cli::cli_text(
      "{arrow} Footer: {total_lines} ({n_footer} user + {n_sys_footer} system)"
    )
  } else {
    cli::cli_text("{arrow} Footer: {cli::col_silver('No')}")
  }

  # --- Pagination Control ---
  cli::cli_h2("Pagination Control")
  cli::cli_par()

  # MODIFIED: Add layout status
  layout_is_stale <- x[["_layout_is_stale"]] %||% TRUE
  layout_status <- if (layout_is_stale) {
    cli::col_silver("Stale (will be recalculated on build)")
  } else {
    cli::col_green("Up-to-date")
  }
  cli::cli_text("{arrow} Layout Status: {layout_status}")

  cli::cli_text("{.strong Vertical (by row)}:")
  page_group_def <- !is.null(util_rtf_dt_get(x, "_page_group_vec"))
  page_group_val <- if (page_group_def) {
    cli::col_green("Enabled")
  } else {
    cli::col_silver("Disabled")
  }
  cli::cli_text("{arrow} Page Groups: {page_group_val}")

  heading_def <- !is.null(util_rtf_dt_get(x, "_page_group_label_vec"))
  heading_val <- if (heading_def) {
    cli::col_green(paste0(
      "Enabled (",
      util_get_option_value(x, "page_group_label_align"),
      ")"
    ))
  } else {
    cli::col_silver("Disabled")
  }
  cli::cli_text("{arrow} Page Group Labels: {heading_val}")

  orphan_def <- !is.null(util_rtf_dt_get(x, "_row_noorphan_vec"))
  orphan_val <- if (orphan_def) {
    cli::col_green("Enabled")
  } else {
    cli::col_silver("Disabled")
  }
  cli::cli_text("{arrow} Orphan Control: {orphan_val}")
  cli::cli_end()

  cli::cli_text("{.strong Horizontal (by column)}:")
  page_split_info <- util_rtf_dt_get(x, "_page_split")
  if (!is.null(page_split_info)) {
    all_vars <- page_split_info$vars
    id_vars <- if (length(all_vars) > 1) {
      Reduce(intersect, all_vars)
    } else {
      character(0)
    }
    data_vars_pp <- if (length(all_vars) > 0) {
      length(all_vars[[1]]) - length(id_vars)
    } else {
      0
    }
    id_label <- if (length(id_vars) > 0) {
      paste(cli::style_italic(id_vars), collapse = ", ")
    } else {
      cli::col_silver("<none>")
    }
    cli::cli_text(
      "{arrow} {cli::col_green('Enabled')}: Table split into {cli::col_cyan(nrow(page_split_info))} pages."
    )
    cli::cli_text(
      "{arrow} ID Column(s): {id_label}; Data Columns per page: {cli::col_cyan(data_vars_pp)}"
    )
  } else {
    cli::cli_text("{arrow} {cli::col_silver('Disabled')}")
  }

  # --- Formatting & Options ---
  cli::cli_h2("Formatting & Options")
  orientation <- util_get_option_value(x, "page_orientation")
  paper_size <- util_get_option_value(x, "page_paper_size")
  orientation_label <- if (!is.null(orientation)) {
    paste0(toupper(substr(orientation, 1, 1)), substring(orientation, 2))
  } else {
    "<unknown>"
  }
  cli::cli_text(
    "{arrow} Orientation: {cli::col_cyan(orientation_label)} ({cli::col_cyan(paper_size)})"
  )

  font <- util_get_option_value(x, "table_font_name")
  size <- util_get_option_value(x, "table_font_size")
  cli::cli_text(
    "{arrow} Font: {cli::col_cyan(font)} at {cli::col_cyan(size)}"
  )

  margins <- c(
    T = util_get_option_value(x, "page_margin_top"),
    R = util_get_option_value(x, "page_margin_right"),
    B = util_get_option_value(x, "page_margin_bottom"),
    L = util_get_option_value(x, "page_margin_left")
  )
  cli::cli_text(
    "{arrow} Margins: T:{margins['T']}, R:{margins['R']}, B:{margins['B']}, L:{margins['L']}"
  )

  custom_widths <- if (!is.null(colattr$column_width)) {
    sum(!sapply(colattr$column_width, is.null))
  } else {
    0L
  }
  if (custom_widths > 0) {
    cli::cli_text(
      "{arrow} Column Widths: {cli::col_green(custom_widths)} of {cli::col_cyan(cols)} customized"
    )
  } else {
    cli::cli_text("{arrow} Column Widths: {cli::col_silver('Default')}")
  }

  custom_align <- if (!is.null(colattr$column_align)) {
    sum(colattr$column_align != "left")
  } else {
    0L
  }
  custom_head_align <- if (!is.null(colattr$header_align)) {
    sum(colattr$header_align != "center")
  } else {
    0L
  }
  if (custom_align + custom_head_align > 0) {
    cli::cli_text(
      "{arrow} Column Alignments: {cli::col_green('Customized')}"
    )
  } else {
    cli::cli_text("{arrow} Column Alignments: {cli::col_silver('Default')}")
  }

  # --- Final Hint ---
  cli::cli_rule()
  cli::cli_alert_info(
    "Run {.fn build_rtf} to generate the final RTF document."
  )
  invisible(x)
}


#' @export
print.rtf_fig <- function(x, ...) {
  # --- 1. Get Key Information from the object ---
  plots <- util_rtf_dt_get(x, "_plots")
  plot_dims <- util_rtf_dt_get(x, "_plot_dims")
  arrow <- cli::symbol$arrow_right

  # --- 2. Build the CLI output ---
  cli::cli_rule(
    left = "{.cls rtf_fig} Summary",
    right = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )

  # --- Figure Content ---
  cli::cli_h2("Figure Content")
  cli::cli_text(
    "{arrow} {.strong Number of Plots}: {length(plots)} (1 per page)"
  )

  dims_str <- if (!is.na(plot_dims$width) || !is.na(plot_dims$height)) {
    width_str <- if (!is.na(plot_dims$width)) {
      paste0(plot_dims$width, plot_dims$units)
    } else {
      "Auto"
    }
    height_str <- if (!is.na(plot_dims$height)) {
      paste0(plot_dims$height, plot_dims$units)
    } else {
      "Auto"
    }
    paste0(width_str, " x ", height_str)
  } else {
    "Auto-scaled to fit page"
  }
  cli::cli_text("{arrow} {.strong Dimensions}: {cli::col_cyan(dims_str)}")

  # --- Page Layout Components ---
  cli::cli_h2("Page Layout")
  n_title <- nrow(util_rtf_dt_get(x, "_title"))
  title_status <- if (n_title > 0) {
    cli::col_green(paste0(n_title, " line(s)"))
  } else {
    cli::col_silver("No")
  }
  cli::cli_text("{arrow} Title: {title_status}")

  n_header <- nrow(util_rtf_dt_get(x, "_header"))
  header_status <- if (n_header > 0) {
    cli::col_green(paste0(n_header, " line(s)"))
  } else {
    cli::col_silver("No")
  }
  cli::cli_text("{arrow} Header: {header_status}")

  n_footer <- nrow(util_rtf_dt_get(x, "_footer"))
  n_sys_footer <- nrow(util_rtf_dt_get(x, "_sys_footer"))
  if (n_footer + n_sys_footer > 0) {
    total_lines <- cli::col_green(paste0(
      n_footer + n_sys_footer,
      " line(s)"
    ))
    cli::cli_text(
      "{arrow} Footer: {total_lines} ({n_footer} user + {n_sys_footer} system)"
    )
  } else {
    cli::cli_text("{arrow} Footer: {cli::col_silver('No')}")
  }

  # --- Formatting & Options ---
  cli::cli_h2("Formatting & Options")
  orientation <- util_get_option_value(x, "page_orientation")
  paper_size <- util_get_option_value(x, "page_paper_size")
  orientation_label <- paste0(
    toupper(substr(orientation, 1, 1)),
    substring(orientation, 2)
  )
  cli::cli_text(
    "{arrow} Orientation: {cli::col_cyan(orientation_label)} ({cli::col_cyan(paper_size)})"
  )

  font <- util_get_option_value(x, "figure_font_name")
  size <- util_get_option_value(x, "figure_font_size")
  cli::cli_text(
    "{arrow} Font (Titles/Footers): {cli::col_cyan(font)} at {cli::col_cyan(size)}"
  )

  margins <- c(
    T = util_get_option_value(x, "page_margin_top"),
    R = util_get_option_value(x, "page_margin_right"),
    B = util_get_option_value(x, "page_margin_bottom"),
    L = util_get_option_value(x, "page_margin_left")
  )
  cli::cli_text(
    "{arrow} Margins: T:{margins['T']}, R:{margins['R']}, B:{margins['B']}, L:{margins['L']}"
  )

  # --- Final Hint ---
  cli::cli_rule()
  cli::cli_alert_info(
    "Run {.fn build_rtf} to generate the final RTF document."
  )
  invisible(x)
}
