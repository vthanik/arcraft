# --- Object Type Checkers and Helpers ---

#' Check if an object is a gt_tbl or gt_group
#' @noRd
is_gt_tbl <- function(data) {
  inherits(data, c("gt_tbl", "gt_group"))
}

#' Stop execution if an object is not a gt_tbl or gt_group
#' @noRd
util_stop_if_not_gt_tbl <- function(data, call = rlang::caller_env()) {
  if (!is_gt_tbl(data = data)) {
    cli::cli_abort(
      "`data` must be a {.cls gt_tbl} or {.cls gt_group} object.",
      call = call
    )
  }
}

#' Check if an object is an rtf_tbl
#' @noRd
is_rtf_tbl <- function(data) {
  inherits(data, "rtf_tbl")
}

#' Stop execution if an object is not an rtf_tbl
#' @noRd
util_stop_if_not_rtf_tbl <- function(data, call = rlang::caller_env()) {
  if (!is_rtf_tbl(data = data)) {
    cli::cli_abort("`data` must be an {.cls rtf_tbl} object.", call = call)
  }
}

#' Check if an object is an rtf_doc (tbl or figure)
#' @noRd
is_rtf_doc <- function(data) {
  inherits(data, "rtf_doc")
}

#' Stop execution if an object is not an rtf_doc
#' @noRd
util_stop_if_not_rtf_doc <- function(data, call = rlang::caller_env()) {
  if (!is_rtf_doc(data)) {
    cli::cli_abort(
      "`data` must be an `rtf_tbl` or `rtf_figure` object.",
      call = call
    )
  }
}


# --- Internal Object Accessors ---

#' Safely get an internal component from a gt_tbl object
#' @noRd
util_gt_get <- function(data, key) {
  data[[key, exact = TRUE]]
}

#' Safely get a component from an rtf_doc list
#' @noRd
util_rtf_dt_get <- function(data, key) {
  data[[key, exact = TRUE]]
}

#' Safely set or add a component in an rtf_doc list
#' @noRd
util_rtf_dt_set <- function(data, key, value) {
  data[[key]] <- value
  return(data)
}

#' Check if an rtf_doc component exists and is not empty
#' @noRd
util_dttype_exists <- function(data, look) {
  val <- util_rtf_dt_get(data, look)
  if (inherits(val, "data.frame")) {
    return(nrow(val) > 0)
  } else {
    return(!is.null(val) && length(val) > 0)
  }
}

## MODIFIED: Now works with the new options list
#' Get a specific option value from the _options list
#' @noRd
util_get_option_value <- function(data, param_name) {
  opts <- util_rtf_dt_get(data, "_options")
  return(opts[[param_name]])
}

## MODIFIED: Now works with the new options list
#' Get all options as a named list for fast access
#' @noRd
util_options_to_list <- function(data) {
  util_rtf_dt_get(data, "_options")
}

# --- Initialization and Data Processing Helpers ---

#' Resolve a quosure to a single column name
#' @noRd
get_single_col_name <- function(
  col_quo,
  type,
  source_names,
  call = rlang::caller_env()
) {
  if (rlang::quo_is_null(col_quo)) {
    return(NULL)
  }
  selection_data <- stats::setNames(source_names, source_names)
  tryCatch(
    {
      selected_idx <- tidyselect::eval_select(
        col_quo,
        data = selection_data
      )
      if (length(selected_idx) != 1) {
        cli::cli_abort(
          "{.arg {type}} must resolve to exactly one column.",
          call = call
        )
      }
      names(selected_idx)
    },
    error = function(e) {
      cli::cli_abort(
        "Failed to select a column for {.arg {type}}.",
        parent = e,
        call = call
      )
    }
  )
}

## MODIFIED: Now takes a defaults-generating function
#' Initialize the `_options` list in a new `rtf_doc` object
#' @noRd
util_rtf_options_init <- function(data, defaults_fun) {
  util_rtf_dt_set(data, "_options", defaults_fun())
}

#' Initialize a generic component as an empty definition tibble
#' @noRd
util_rtf_component_init <- function(data, name) {
  util_rtf_dt_set(
    data,
    name,
    tibble::tibble(
      id = integer(0L),
      content = list(),
      align = character(0L)
    )
  )
}

#' Get internal grouping/stub columns from a `gt_tbl` to exclude from rendering
#' @noRd
util_gt_data_col_exclude <- function(gt_tbl) {
  boxhead <- util_gt_get(gt_tbl, "_boxhead")
  hidden_boxhead_vars <- if ("type" %in% names(boxhead)) {
    boxhead$var[boxhead$type == "hidden"]
  } else {
    character(0)
  }

  base_exclusions <- c(
    util_gt_get(gt_tbl, "_stub_df")$groupname,
    "rowname",
    "group"
  )
  gt_data_cols <- names(util_gt_get(gt_tbl, "_data"))
  tfrmt_exclusions <- gt_data_cols[startsWith(gt_data_cols, "..tfrmt_")]

  unique(c(base_exclusions, tfrmt_exclusions, hidden_boxhead_vars))
}

#' Process arguments from `...` to handle both formula and named argument syntax
#' @noRd
util_process_formula_or_named_args <- function(.list, data, calling_fn) {
  colattr <- util_rtf_dt_get(data, "_rtf_colattr")
  column_vars <- colattr$var
  selection_data <- stats::setNames(column_vars, column_vars)

  updates_list <- list()
  used_columns <- c() # Track columns that have been targeted

  for (i in seq_along(.list)) {
    item <- .list[[i]]
    item_name <- names(.list)[i]

    columns <- NULL
    value <- NULL

    if (!is.null(item_name) && nzchar(item_name)) {
      columns <- item_name
      value <- item

      if (!all(columns %in% column_vars)) {
        bad_cols <- columns[!columns %in% column_vars]
        cli::cli_abort(
          c(
            "Column{?s} {.var {bad_cols}} supplied in named arguments do not exist in the table.",
            "i" = "Available columns are: {.var {column_vars}}."
          ),
          call = rlang::caller_env(n = 3)
        )
      }
    } else if (rlang::is_formula(item)) {
      cols_expr <- rlang::f_lhs(item)

      if (is.null(cols_expr)) {
        cli::cli_abort(
          "Formula arguments to {.fn {calling_fn}} must be two-sided (e.g., `cols ~ value`).",
          call = rlang::caller_env(n = 3)
        )
      }

      if (rlang::expr_text(cols_expr) == "everything()") {
        available_cols <- setdiff(column_vars, used_columns)
        columns <- available_cols
      } else {
        columns <- column_vars[tidyselect::eval_select(
          cols_expr,
          selection_data
        )]
      }

      value <- rlang::eval_tidy(rlang::f_rhs(item))
    } else {
      cli::cli_abort(
        "All arguments to {.fn {calling_fn}} must be formulas (e.g., `col ~ val`) or named arguments (e.g., `col = val`).",
        call = rlang::caller_env(n = 3)
      )
    }

    if (length(columns) > 0) {
      updates_list[[i]] <- tibble::tibble(
        var = columns,
        value = list(value)
      )
      used_columns <- c(used_columns, columns)
    }
  }

  if (length(updates_list) == 0) {
    return(tibble::tibble(var = character(), value = list()))
  }

  dplyr::bind_rows(updates_list) |>
    dplyr::group_by(var) |>
    dplyr::slice_tail(n = 1) |>
    dplyr::ungroup()
}

#' Process the `_data` component from a `gt_tbl` for RTF conversion
#' @noRd
util_gt_data_init <- function(
  gt_tbl,
  data_override = NULL,
  replace_na,
  process_indent,
  indent_twips_per_space
) {
  gt_data <- data_override %||% util_gt_get(gt_tbl, "_data")

  excl_cols <- util_gt_data_col_exclude(gt_tbl)
  if (length(excl_cols) > 0) {
    gt_data <- gt_data |> dplyr::select(-dplyr::any_of(excl_cols))
  }

  gt_data <- gt_data |>
    dplyr::mutate(dplyr::across(
      where(is.character),
      stringi::stri_trim_right
    ))

  if (process_indent) {
    gt_data <- gt_data |>
      dplyr::mutate(dplyr::across(
        where(is.character),
        ~ purrr::map_chr(
          .x,
          util_process_multi_paragraph_string,
          indent_twips_per_space = indent_twips_per_space
        )
      ))
  }

  if (replace_na) {
    gt_data <- gt_data |>
      dplyr::mutate(dplyr::across(everything(), \(x) {
        if (is.character(x)) dplyr::if_else(is.na(x), "", x) else x
      }))
  }
  return(gt_data)
}

#' Initialize the `_rtf_colattr` tibble from a gt object
#' @noRd
util_rtf_colattr_init <- function(
  data,
  gt_tbl,
  exclude_cols = NULL
) {
  gt_boxhead_raw <- util_gt_get(gt_tbl, "_boxhead") |>
    dplyr::filter(!var %in% exclude_cols)

  labels <- gt_boxhead_raw$column_label
  labels <- stringi::stri_replace_all_fixed(labels, "\n", "{\\line}")

  colattr_tbl <- gt_boxhead_raw |>
    dplyr::mutate(
      column_labels = purrr::map(labels, ~ stats::setNames(.x, "1")),
      column_align = "left",
      header_align = "center",
      column_width = vector("list", length = nrow(gt_boxhead_raw))
    ) |>
    dplyr::select(
      var,
      column_labels,
      column_align,
      header_align,
      column_width
    )

  util_rtf_dt_set(data, "_rtf_colattr", colattr_tbl)
}

#' Initialize the `_spanners` tibble from a gt object
#' @noRd
util_rtf_spanners_init <- function(data, gt_tbl) {
  gt_spanners <- util_gt_get(gt_tbl, "_spanners")
  if (nrow(gt_spanners) == 0) {
    return(util_rtf_dt_set(data, "_spanners", tibble::tibble()))
  }

  spanner_labels <- gt_spanners$spanner_label
  spanner_labels <- stringi::stri_replace_all_fixed(
    spanner_labels,
    "\n",
    "{\\line}"
  )

  spanners_df <- gt_spanners |>
    dplyr::mutate(spanner_label = spanner_labels) |>
    dplyr::rename(vars_from_gt = vars) |>
    dplyr::select(spanner_id, spanner_label, vars_from_gt, spanner_level)

  util_rtf_dt_set(data, "_spanners", spanners_df)
}

#' Internal worker to add lines to title/header/footer components
#' @noRd
util_add_rtf_lines <- function(
  data,
  dots,
  align_value,
  target_element,
  check,
  fn_name
) {
  if (length(dots) == 0) {
    cli::cli_abort(
      "At least one value must be provided to {.fn {fn_name}}."
    )
  }
  if (any(!purrr::map_lgl(dots, check))) {
    cli::cli_abort(
      "Invalid argument type passed to {.fn {fn_name}}. Must be a single string or an {.fn hfrow} object."
    )
  }

  existing_tbl <- util_rtf_dt_get(data, target_element)
  start_id <- if (nrow(existing_tbl) > 0) max(existing_tbl$id) + 1L else 1L
  new_lines_df <- tibble::tibble(
    id = start_id:(start_id + length(dots) - 1),
    content = dots,
    align = purrr::map_chr(
      dots,
      ~ if (inherits(.x, "hfrow_str")) "auto" else align_value
    )
  )
  util_rtf_dt_set(
    data,
    target_element,
    dplyr::bind_rows(existing_tbl, new_lines_df)
  )
}

# --- Layout, Pagination, and Content Processing ---

#' Invalidate the Cached Table Layout
#'
#' @description This helper function marks the `_layout` component of an
#'   `rtf_tbl` object as stale. It should be called by any "verb" function that
#'   modifies a property affecting pagination (e.g., fonts, margins, content height).
#' @noRd
util_invalidate_layout <- function(data) {
  if (inherits(data, "rtf_tbl")) {
    data[["_layout_is_stale"]] <- TRUE
  }
  return(data)
}

#' Smartly fill a vector with missing values based on context
#' @noRd
util_smart_fill <- function(vec, tfrmt_grp_lbl_vec = NULL) {
  if (is.null(vec) || all(is.na(vec))) {
    return(vec)
  }

  direction <- if (!is.null(tfrmt_grp_lbl_vec)) {
    if (any(tfrmt_grp_lbl_vec, na.rm = TRUE)) "up" else "down"
  } else {
    if (is.na(vec[1])) "up" else "down"
  }

  tibble::tibble(value = vec) |>
    tidyr::fill(value, .direction = direction) |>
    dplyr::pull(value)
}

#' Process multi-line, indented strings into a special format
#' @noRd
util_process_multi_paragraph_string <- function(
  cell_content,
  indent_twips_per_space
) {
  if (
    !is.character(cell_content) || is.na(cell_content) || cell_content == ""
  ) {
    return(as.character(cell_content))
  }

  lines <- stringi::stri_split_fixed(cell_content, "\n")[[1]]

  if (length(lines) == 1) {
    leading_spaces <- stringi::stri_extract_first_regex(lines, "^\\s*") %||%
      ""
    num_spaces <- nchar(leading_spaces)
    if (num_spaces > 0) {
      indent_twips <- indent_twips_per_space * num_spaces
      trimmed_content <- stringi::stri_trim_left(lines)
      return(paste0("_INDENT_TWIPS_", indent_twips, "_", trimmed_content))
    } else {
      return(lines)
    }
  }

  processed_lines <- purrr::map_chr(
    lines,
    ~ {
      leading_spaces <- stringi::stri_extract_first_regex(
        .x,
        "^\\s*"
      ) %||%
        ""
      num_spaces <- nchar(leading_spaces)
      indent_twips <- indent_twips_per_space * num_spaces
      trimmed_content <- stringi::stri_trim_left(.x)
      paste(indent_twips, trimmed_content, sep = ";")
    }
  )

  paste0("_MULTI_PARAGRAPH_", paste(processed_lines, collapse = "|"))
}

#' Calculate available page space for a figure
#' @noRd
util_calculate_figure_layout <- function(data) {
  options_list <- util_options_to_list(data)
  margin_twips <- util_rtf_margin(data)
  paper_size_twips <- util_rtf_paper_size(data, options_list$page_orientation)

  # Get options needed for calculations
  opt_cell_padding <- options_list[["cell_padding"]]
  opt_cell_spacing <- options_list[["cell_spacing"]]
  fs_val_title <- util_rtf_fsize(data, options_list$title_font_size)
  fs_val_hf <- util_rtf_fsize(data, options_list$hf_font_size)

  # Use a more realistic 1.5x line height multiplier for base font height
  base_title_line_h <- (fs_val_title / 2) * 20 * 1.5
  base_hf_line_h <- (fs_val_hf / 2) * 20 * 1.5

  # Titles, Headers, and Footers are built as tables, so add cell padding/spacing
  title_row_h <- base_title_line_h +
    (2 * opt_cell_spacing) +
    (2 * opt_cell_padding)
  hf_row_h <- base_hf_line_h + (2 * opt_cell_spacing) + (2 * opt_cell_padding)

  # --- Calculate height of all non-figure components ---

  # 1. Title Block Height
  title_df <- util_rtf_dt_get(data, "_title")
  title_block_h <- 0
  if (nrow(title_df) > 0) {
    num_title_lines <- sum(
      stringi::stri_count_fixed(unlist(title_df$content), "\n") + 1
    )
    title_block_h <- num_title_lines * title_row_h
    # Add space for the blank line that follows the title table
    title_block_h <- title_block_h + base_hf_line_h
  }

  # 2. Header and Footer Overflow Height
  header_df <- util_rtf_dt_get(data, "_header")
  header_h <- max(0, nrow(header_df) - HF_LINES_IN_MARGIN) * hf_row_h

  footer_df <- dplyr::bind_rows(
    util_rtf_dt_get(data, "_footer"),
    util_rtf_dt_get(data, "_sys_footer")
  )
  footer_h <- max(0, nrow(footer_df) - HF_LINES_IN_MARGIN) * hf_row_h

  # 3. Spacing before the figure
  # rtf_str_figure adds a `{\pard\qc\par}\n`, which is one blank line.
  # Its height is based on the default paragraph font (hf font).
  figure_spacing_h <- base_hf_line_h

  # --- Calculate available space ---
  total_used_height <- title_block_h + header_h + footer_h + figure_spacing_h

  available_height <- paper_size_twips[["height"]] -
    margin_twips[["top"]] -
    margin_twips[["bottom"]] -
    total_used_height

  available_width <- paper_size_twips[["width"]] -
    margin_twips[["left"]] -
    margin_twips[["right"]]

  return(list(
    available_width = available_width,
    available_height = max(0, available_height)
  ))
}


#' Recalculate and Cache Table Pagination
#'
#' @description This is the core pagination calculation function. It calculates
#' a single, consistent data budget that applies to every page, assuming that
#' all headers, titles, and footers are repeated. It includes a configurable
#' line-spacing buffer for realistic height calculations.
#' @noRd
recalculate_layout <- function(data) {
  util_stop_if_not_rtf_tbl(data)
  options_list <- util_options_to_list(data)
  total_data_rows <- nrow(util_rtf_dt_get(data, "_data"))

  if (total_data_rows == 0) {
    page_layout <- tibble::tibble(
      page = integer(),
      row_start = integer(),
      row_end = integer(),
      page_heading_text = character()
    )
    data[["_layout"]] <- page_layout
    data[["_layout_is_stale"]] <- FALSE
    return(data)
  }

  page_line_limit_opt <- if (options_list$page_orientation == "landscape") {
    "page_line_size_landscape"
  } else {
    "page_line_size_portrait"
  }
  page_line_limit <- options_list[[page_line_limit_opt]]

  line_spacing_factor <- options_list$line_spacing_multiplier

  data_budget_lines <- if (!is.na(page_line_limit)) {
    # --- LEGACY MODE: User has provided a manual line count ---
    header_df <- util_rtf_dt_get(data, "_header")
    footer_df <- dplyr::bind_rows(
      util_rtf_dt_get(data, "_footer"),
      util_rtf_dt_get(data, "_sys_footer")
    )
    header_row_adjustment <- max(0, nrow(header_df) - HF_LINES_IN_MARGIN)
    footer_row_adjustment <- max(0, nrow(footer_df) - HF_LINES_IN_MARGIN)

    title_df <- util_rtf_dt_get(data, "_title")
    title_height_lines <- if (nrow(title_df) > 0) {
      sum(stringi::stri_count_fixed(unlist(title_df$content), "\n") + 1) + 1
    } else {
      0
    }

    spanners_df <- util_rtf_dt_get(data, "_spanners")
    spanner_height_lines <- if (nrow(spanners_df) > 0) {
      spanners_df |>
        dplyr::mutate(
          n_lines = stringi::stri_count_fixed(spanner_label, "{\\line}") + 1
        ) |>
        dplyr::group_by(spanner_level) |>
        dplyr::summarise(level_height = max(n_lines), .groups = "drop") |>
        dplyr::pull(level_height) |>
        sum()
    } else {
      0
    }

    colattr <- util_rtf_dt_get(data, "_rtf_colattr")
    col_header_height_lines <- if (
      nrow(colattr) > 0 && "column_labels" %in% names(colattr)
    ) {
      max(purrr::map_int(
        colattr$column_labels,
        ~ max(stringi::stri_count_fixed(.x, "{\\line}"))
      )) +
        1
    } else {
      0
    }

    table_header_cost <- spanner_height_lines + col_header_height_lines

    page_line_limit -
      header_row_adjustment -
      footer_row_adjustment -
      title_height_lines -
      table_header_cost
  } else {
    # --- AUTOMATIC MODE: Calculate budget based on twips with buffer ---
    margin_twips <- util_rtf_margin(data)
    paper_size_twips <- util_rtf_paper_size(data, options_list$page_orientation)

    tbl_fs_pt <- util_parse_length(options_list$table_font_size)$value
    base_tbl_line_h <- (tbl_fs_pt * 20) + (options_list$cell_spacing * 2)
    STD_LINE_H_TWIPS <- base_tbl_line_h * line_spacing_factor

    total_content_h_twips <- paper_size_twips[["height"]] -
      sum(margin_twips[c("top", "bottom")])
    TOTAL_PAGE_EFFECTIVE_LINES <- total_content_h_twips / STD_LINE_H_TWIPS

    title_df <- util_rtf_dt_get(data, "_title")
    title_block_cost <- if (nrow(title_df) > 0) {
      title_fs_pt <- util_parse_length(options_list$title_font_size)$value
      base_title_line_h <- (title_fs_pt * 20) + (options_list$cell_spacing * 2)
      title_line_h_twips <- base_title_line_h * line_spacing_factor

      num_title_lines <- sum(
        stringi::stri_count_fixed(unlist(title_df$content), "\n") + 1
      )
      blank_line_twips <- (12 * 20) * line_spacing_factor

      ((num_title_lines * title_line_h_twips) + blank_line_twips) /
        STD_LINE_H_TWIPS
    } else {
      0
    }

    hf_fs_pt <- util_parse_length(options_list$hf_font_size)$value
    base_hf_line_h <- (hf_fs_pt * 20) + (options_list$cell_spacing * 2)
    hf_line_h_twips <- base_hf_line_h * line_spacing_factor

    header_df <- util_rtf_dt_get(data, "_header")
    header_overflow_cost <- (max(0, nrow(header_df) - HF_LINES_IN_MARGIN) *
      hf_line_h_twips) /
      STD_LINE_H_TWIPS

    footer_df <- dplyr::bind_rows(
      util_rtf_dt_get(data, "_footer"),
      util_rtf_dt_get(data, "_sys_footer")
    )
    footer_overflow_cost <- (max(0, nrow(footer_df) - HF_LINES_IN_MARGIN) *
      hf_line_h_twips) /
      STD_LINE_H_TWIPS

    footer_blank_line_cost <- if (nrow(footer_df) > 0) {
      blank_line_twips <- (hf_fs_pt * 20) * line_spacing_factor
      blank_line_twips / STD_LINE_H_TWIPS
    } else {
      0
    }

    spanners_df <- util_rtf_dt_get(data, "_spanners")
    spanner_lines <- if (nrow(spanners_df) > 0) {
      spanners_df |>
        dplyr::mutate(
          n_lines = stringi::stri_count_fixed(spanner_label, "{\\line}") + 1
        ) |>
        dplyr::group_by(spanner_level) |>
        dplyr::summarise(level_height = max(n_lines), .groups = "drop") |>
        dplyr::pull(level_height) |>
        sum()
    } else {
      0
    }

    colattr <- util_rtf_dt_get(data, "_rtf_colattr")
    col_header_lines <- if (
      nrow(colattr) > 0 && "column_labels" %in% names(colattr)
    ) {
      max(purrr::map_int(
        colattr$column_labels,
        ~ max(stringi::stri_count_fixed(.x, "{\\line}"))
      )) +
        1
    } else {
      0
    }

    table_header_cost <- spanner_lines + col_header_lines

    TOTAL_PAGE_EFFECTIVE_LINES -
      header_overflow_cost -
      title_block_cost -
      table_header_cost -
      footer_overflow_cost -
      footer_blank_line_cost
  }

  row_heights_in_lines <- get_row_heights_in_lines(data)
  page_assignments <- run_pagination_loop(
    total_data_rows = total_data_rows,
    data = data,
    row_heights = row_heights_in_lines,
    data_budget = data_budget_lines,
    page_heading_cost = PAGE_HEADING_HEIGHT_LINES
  )

  row_info <- tibble::tibble(
    row_num = seq_len(total_data_rows),
    page_group_label = util_rtf_dt_get(data, "_page_group_label_vec") %||%
      NA_character_
  )
  row_info$final_page_num <- page_assignments

  page_layout <- row_info |>
    dplyr::group_by(final_page_num) |>
    dplyr::summarise(
      row_start = min(row_num),
      row_end = max(row_num),
      page_heading_text = dplyr::first(page_group_label),
      .groups = "drop"
    ) |>
    dplyr::rename(page = final_page_num)

  data[["_layout"]] <- page_layout
  data[["_layout_is_stale"]] <- FALSE

  return(data)
}

#' [FINAL CORRECTED VERSION] Helper to calculate row heights, correctly accounting for indentation.
#' @noRd
get_row_heights_in_lines <- function(data) {
  options_list <- util_options_to_list(data)
  margin_twips <- util_rtf_margin(data)
  paper_size_twips <- util_rtf_paper_size(data, options_list$page_orientation)
  tbl_width <- paper_size_twips[["width"]] -
    sum(margin_twips[c("left", "right")])
  total_data_rows <- nrow(util_rtf_dt_get(data, "_data"))
  colattr <- util_rtf_dt_get(data, "_rtf_colattr")
  page_split_info <- util_rtf_dt_get(data, "_page_split")

  width_calc_vars <- if (
    !is.null(page_split_info) && nrow(page_split_info) > 0
  ) {
    widest_vars_idx <- which.max(purrr::map_int(page_split_info$vars, length))
    page_split_info$vars[[widest_vars_idx]]
  } else {
    colattr$var
  }

  opt_font_name <- options_list$table_font_name
  font_row_idx <- which(purrr::map_lgl(
    rtf_font_table$f_name,
    ~ opt_font_name %in% .x
  ))
  font_family <- if (length(font_row_idx) > 0) {
    rtf_font_table$f_family[[font_row_idx]]
  } else {
    "modern"
  }

  width_row_idx <- which(rtf_font_char_width_map$f_family == font_family)
  char_width_twips <- if (length(width_row_idx) > 0) {
    rtf_font_char_width_map$char_width_twips[[width_row_idx]]
  } else {
    120
  }

  col_widths_twips <- util_rtf_get_col_width(
    data,
    vars = width_calc_vars,
    tbl_width = tbl_width
  )
  cell_padding_twips <- options_list$cell_padding * 2

  # This is the total character width for each column, accounting for padding.
  col_widths_chars <- floor(
    (col_widths_twips - cell_padding_twips) / char_width_twips
  )
  col_widths_chars[col_widths_chars < 1] <- 1
  data_cols_for_height_calc <- names(col_widths_chars)

  vapply(
    seq_len(total_data_rows),
    function(i) {
      # Get the raw data for the row, which contains the "_INDENT_TWIPS_" markers
      raw_row_data <- util_rtf_dt_get(data, "_data")[
        i,
        data_cols_for_height_calc,
        drop = FALSE
      ]

      # --- THIS IS THE NEW, CORRECTED LOGIC ---

      # 1. For each cell in the raw row, extract its indentation in twips.
      indent_twips_vec <- purrr::map_dbl(raw_row_data, function(cell_content) {
        if (
          is.na(cell_content) ||
            !stringi::stri_detect_fixed(cell_content, "_INDENT_TWIPS_")
        ) {
          return(0)
        }
        indent_val_str <- stringi::stri_extract_first_regex(
          cell_content,
          "(?<=_INDENT_TWIPS_)\\d+"
        )
        if (is.na(indent_val_str)) {
          return(0)
        }
        return(as.numeric(indent_val_str))
      })

      # 2. Convert the indentation from twips to a character count cost.
      indent_chars_cost <- floor(indent_twips_vec / char_width_twips)

      # 3. Calculate the *net* available character width for each cell in this row.
      net_col_widths_chars <- col_widths_chars - indent_chars_cost
      net_col_widths_chars[net_col_widths_chars < 1] <- 1

      # --- END OF NEW LOGIC ---

      # Get the cleaned data (without indent markers) to pass to the wrapper.
      cleaned_row_data <- dplyr::mutate(
        raw_row_data,
        dplyr::across(everything(), util_clean_rtf_content)
      )

      # Use mapply with the NEWLY CALCULATED net widths.
      cell_heights <- mapply(
        util_calculate_cell_height,
        cleaned_row_data,
        net_col_widths_chars
      )

      max(1, max(cell_heights, na.rm = TRUE))
    },
    FUN.VALUE = numeric(1)
  )
}
#' [FINAL FIX] Calculate wrapped height of a single cell's content using stringi::stri_wrap.
#' @noRd
util_calculate_cell_height <- function(cleaned_content, char_width) {
  if (is.na(cleaned_content) || cleaned_content == "") {
    return(1)
  }

  # Handle pre-existing newlines by splitting the string first
  explicit_lines <- stringi::stri_split_fixed(cleaned_content, "\n")[[1]]

  total_lines <- 0
  for (line_text in explicit_lines) {
    if (!nzchar(line_text)) {
      # An empty string between newlines still counts as one line
      total_lines <- total_lines + 1
      next
    }
    # Use the robust stringi::stri_wrap function to wrap the text
    wrapped_text <- stringi::stri_wrap(
      str = line_text,
      width = char_width,
      cost_exponent = 0, # Use the simple, fast greedy algorithm
      simplify = TRUE
    )
    # Count the number of resulting lines by counting the newlines it adds
    lines_for_this_segment <- stringi::stri_count_fixed(wrapped_text, "\n") + 1
    total_lines <- total_lines + lines_for_this_segment
  }

  return(max(1, total_lines))
}

#' Simplified pagination loop that works with a single, consistent page budget
#' @noRd
run_pagination_loop <- function(
  total_data_rows,
  data,
  row_heights,
  data_budget,
  page_heading_cost
) {
  row_info <- tibble::tibble(
    row_num = seq_len(total_data_rows),
    row_height = row_heights,
    primary_group = util_rtf_dt_get(data, "_page_group_vec") %||% 1,
    secondary_group = util_rtf_dt_get(data, "_row_noorphan_vec") %||%
      seq_len(total_data_rows),
    page_group_label = util_rtf_dt_get(data, "_page_group_label_vec") %||%
      NA_character_
  ) |>
    dplyr::mutate(sub_group_id = dplyr::consecutive_id(secondary_group))

  page_assignments <- integer(total_data_rows)
  current_page <- 1
  current_page_height <- 0

  primary_sections <- row_info |>
    dplyr::group_by(primary_group) |>
    tidyr::nest()

  for (sec_idx in seq_len(nrow(primary_sections))) {
    section_data <- primary_sections$data[[sec_idx]]

    if (sec_idx > 1 && current_page_height > 0) {
      current_page <- current_page + 1
      current_page_height <- 0
    }

    sub_group_heights <- section_data |>
      dplyr::group_by(sub_group_id) |>
      dplyr::summarise(group_total_height = sum(row_height), .groups = "drop")

    for (sub_group_id_val in unique(section_data$sub_group_id)) {
      current_sub_group_info <- dplyr::filter(
        section_data,
        sub_group_id == sub_group_id_val
      )
      group_height <- sub_group_heights$group_total_height[
        sub_group_heights$sub_group_id == sub_group_id_val
      ]

      heading_height <- if (
        any(
          !is.na(current_sub_group_info$page_group_label) &
            nzchar(current_sub_group_info$page_group_label)
        )
      ) {
        page_heading_cost
      } else {
        0
      }

      # The available budget for this group's data is the total budget minus the heading.
      current_budget <- data_budget - heading_height
      remaining_height <- current_budget - current_page_height

      if (group_height <= remaining_height) {
        page_assignments[current_sub_group_info$row_num] <- current_page
        current_page_height <- current_page_height + group_height
      } else {
        is_page_half_full <- if (current_budget > 0) {
          (current_page_height / current_budget) >= 0.5
        } else {
          TRUE
        }
        group_fits_on_new_page <- group_height <= current_budget

        if (
          current_page_height > 0 && is_page_half_full && group_fits_on_new_page
        ) {
          current_page <- current_page + 1
          current_page_height <- 0

          page_assignments[current_sub_group_info$row_num] <- current_page
          current_page_height <- current_page_height + group_height
        } else {
          for (r_idx in seq_len(nrow(current_sub_group_info))) {
            row <- current_sub_group_info[r_idx, ]
            if (
              current_page_height + row$row_height > current_budget &&
                current_page_height > 0
            ) {
              current_page <- current_page + 1
              current_page_height <- 0
            }
            page_assignments[row$row_num] <- current_page
            current_page_height <- current_page_height + row$row_height
          }
        }
      }
    }
  }
  return(page_assignments)
}
