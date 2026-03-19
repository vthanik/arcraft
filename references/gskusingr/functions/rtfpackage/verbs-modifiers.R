#' Add a Title to an `rtf_doc` Object
#'
#' @description
#' Adds one or more lines of title text to the document. Titles appear at the
#' top of the main content area (below the page header, if any) on every page.
#'
#' @param data An `rtf_doc` object.
#' @param ... One or more unnamed character strings. Each string is rendered
#'   as a new line in the title block.
#' @param .align `[character(1)]` Horizontal alignment for all title lines:
#'   `"center"` (default), `"left"`, or `"right"`.
#'
#' @return An `rtf_doc` object with the title information added.
#' @export
rtf_title <- function(data, ..., .align = c("center", "left", "right")) {
  rlang::check_dots_unnamed()
  util_stop_if_not_rtf_doc(data)
  align_value <- rlang::arg_match(.align)
  dots <- rlang::list2(...)

  data <- util_add_rtf_lines(
    data,
    dots = dots,
    align_value = align_value,
    target_element = "_title",
    check = is.character,
    fn_name = "rtf_title"
  )

  # Invalidate the layout cache because titles affect page height.
  util_invalidate_layout(data)
}

#' Add a Header to an `rtf_doc` Object
#'
#' @description
#' Adds content to the page header. Supports dynamic page numbering keywords:
#' `_PAGE_`, `_PAGES_`, and `_PAGEOF_`. Use [hfrow()] for multi-part lines.
#'
#' @param data An `rtf_doc` object.
#' @param ... Unnamed arguments, which can be single character strings or `hfrow()` objects.
#' @param .align `[character(1)]` Default alignment for simple string rows.
#'
#' @return An `rtf_doc` object with the header information added.
#' @export
rtf_header <- function(data, ..., .align = c("center", "left", "right")) {
  rlang::check_dots_unnamed()
  util_stop_if_not_rtf_doc(data)
  align_value <- rlang::arg_match(.align)
  dots <- rlang::list2(...)
  is_valid_hf <- function(x) {
    (is.character(x) && length(x) == 1L) || inherits(x, "hfrow_str")
  }

  data <- util_add_rtf_lines(
    data,
    dots = dots,
    align_value = align_value,
    target_element = "_header",
    check = is_valid_hf,
    fn_name = "rtf_header"
  )

  # Invalidate the layout cache because headers affect page height.
  util_invalidate_layout(data)
}

#' Add a Footer to an `rtf_doc` Object
#'
#' @description
#' Adds content to the page footer. Supports the same dynamic keywords as [rtf_header()].
#'
#' @param data An `rtf_doc` object.
#' @param ... Unnamed arguments: single character strings or `hfrow()` objects.
#' @param .align `[character(1)]` Default alignment for simple string rows.
#' @param .default_sys `[logical(1)]` Internal flag. Not for direct use.
#'
#' @return An `rtf_doc` object with the footer information added.
#' @export
rtf_footer <- function(
  data,
  ...,
  .align = c("left", "center", "right"),
  .default_sys = FALSE
) {
  rlang::check_dots_unnamed()
  util_stop_if_not_rtf_doc(data)
  align_value <- rlang::arg_match(.align)
  dots <- rlang::list2(...)
  target_el <- if (.default_sys) "_sys_footer" else "_footer"
  is_valid_hf <- function(x) {
    (is.character(x) && length(x) == 1L) || inherits(x, "hfrow_str")
  }

  data <- util_add_rtf_lines(
    data,
    dots = dots,
    align_value = align_value,
    target_element = target_el,
    check = is_valid_hf,
    fn_name = "rtf_footer"
  )

  # Invalidate the layout cache because footers affect page height.
  util_invalidate_layout(data)
}

#' Create a Header/Footer Row with Multiple Justified Parts
#'
#' @description
#' Creates a special row object for use in [rtf_header] and [rtf_footer] to
#' place text in different horizontal positions on a single line.
#'
#' @param ... One or two unnamed character strings.
#'   - **One string:** The text is centered.
#'   - **Two strings:** The first is left-justified, the second is right-justified.
#'
#' @return An S3 object of class `hfrow_str`.
#' @export
hfrow <- function(...) {
  rlang::check_dots_unnamed()
  dots <- rlang::list2(...)
  if (length(dots) < 1 || length(dots) > 2) {
    cli::cli_abort("`hfrow()` accepts 1 or 2 unnamed string arguments.")
  }
  if (any(!purrr::map_lgl(dots, ~ is.character(.x) && length(.x) == 1L))) {
    cli::cli_abort("All arguments to `hfrow()` must be single strings.")
  }
  class(dots) <- "hfrow_str"
  dots
}

#' Set Column Widths
#' @inheritParams rtf_col_align
#' @return An `rtf_tbl` object with updated column width settings.
#' @export
rtf_col_widths <- function(data, ..., .list = rlang::list2(...)) {
  util_stop_if_not_rtf_tbl(data = data)
  if (length(.list) == 0) {
    return(data)
  }

  updates_df <- util_process_formula_or_named_args(
    .list,
    data,
    "rtf_col_widths"
  )
  if (nrow(updates_df) == 0) {
    return(data)
  }

  updates_df <- updates_df |>
    dplyr::mutate(
      value = purrr::map(
        value,
        ~ {
          val <- if (is.numeric(.x)) inch(.x) else .x
          util_validate_and_standardize_length(val, "width", "in")
        }
      )
    ) |>
    dplyr::rename(new_width = value)

  colattr <- util_rtf_dt_get(data, "_rtf_colattr")
  updated_colattr <- colattr |>
    dplyr::left_join(updates_df, by = "var") |>
    dplyr::mutate(
      column_width = purrr::map2(column_width, new_width, ~ .y %||% .x)
    ) |>
    dplyr::select(-new_width)

  data <- util_rtf_dt_set(data, "_rtf_colattr", updated_colattr)

  # Column widths fundamentally affect pagination.
  util_invalidate_layout(data)
}

#' Set Column Content Alignment
#' @param data An `rtf_tbl` object.
#' @param ... A series of two-sided formulas or named arguments.
#' @param .list An alternative to `...` for programmatic use.
#' @param .group `[character(1)]` Which part of the column to align: `"column"` or `"header"`.
#' @return An `rtf_tbl` object with updated column alignment settings.
#' @export
rtf_col_align <- function(
  data,
  ...,
  .list = rlang::list2(...),
  .group = c("column", "header")
) {
  util_stop_if_not_rtf_tbl(data = data)
  group <- rlang::arg_match(.group)
  style_target_chr <- if (group == "column") {
    "column_align"
  } else {
    "header_align"
  }
  style_target_sym <- rlang::sym(style_target_chr)

  if (length(.list) == 0) {
    return(data)
  }

  updates_df <- util_process_formula_or_named_args(
    .list,
    data,
    "rtf_col_align"
  )
  if (nrow(updates_df) == 0) {
    return(data)
  }

  updates_df <- updates_df |>
    dplyr::mutate(value = purrr::map_chr(value, align)) |>
    dplyr::rename(!!style_target_sym := value)

  colattr <- util_rtf_dt_get(data, "_rtf_colattr")
  updated_colattr <- colattr |>
    dplyr::left_join(updates_df, by = "var") |>
    dplyr::mutate(
      !!style_target_sym := dplyr::coalesce(
        .data[[paste0(style_target_chr, ".y")]],
        .data[[paste0(style_target_chr, ".x")]]
      )
    ) |>
    dplyr::select(-dplyr::ends_with(c(".x", ".y")))

  util_rtf_dt_set(data, "_rtf_colattr", updated_colattr)
}

#' Paginate a Wide Table Across Multiple Pages Horizontally
#' @param data An `rtf_tbl` object.
#' @param id_columns A `tidyselect` expression for repeated columns.
#' @param split_at `[integer(1)]` The number of non-ID columns per page.
#' @return An `rtf_tbl` object with page split configuration.
#' @export
rtf_paginate_cols <- function(data, id_columns, split_at) {
  util_stop_if_not_rtf_tbl(data = data)
  colattr <- util_rtf_dt_get(data, "_rtf_colattr")
  selection_data <- stats::setNames(colattr$var, colattr$var)

  id_cols_quo <- rlang::enquo(id_columns)
  id_cols_idx <- tidyselect::eval_select(id_cols_quo, selection_data)
  id_vars <- colattr$var[id_cols_idx]
  data_vars <- base::setdiff(colattr$var, id_vars)

  if (
    !rlang::is_bare_numeric(split_at, 1) ||
      split_at < 1 ||
      split_at != round(split_at)
  ) {
    cli::cli_abort("{.arg split_at} must be a single positive integer.")
  }

  data_col_chunks <- split(
    data_vars,
    ceiling(seq_along(data_vars) / split_at)
  )

  page_splits <- purrr::imap(
    data_col_chunks,
    ~ tibble::tibble(
      page_split_num = as.integer(.y),
      vars = list(c(id_vars, .x))
    )
  ) |>
    purrr::list_rbind() |>
    dplyr::arrange(page_split_num)

  data <- util_rtf_dt_set(data, "_page_split", page_splits)

  # Horizontal pagination changes the layout.
  util_invalidate_layout(data)
}

#' Pad Columns with Non-Breaking Spaces
#' @param data An `rtf_tbl` object.
#' @param ... A `tidyselect` expression for columns to pad.
#' @param .n_spaces `[integer(1)]` Number of spaces to add.
#' @param .side `[character(1)]` The side to pad.
#' @return An `rtf_tbl` object with padding applied.
#' @export
rtf_col_pad <- function(
  data,
  ...,
  .n_spaces = 2,
  .side = c("left", "right", "both")
) {
  util_stop_if_not_rtf_tbl(data = data)
  if (!rlang::is_bare_numeric(.n_spaces, 1) || .n_spaces < 0) {
    cli::cli_abort(
      "{.arg .n_spaces} must be a single non-negative integer."
    )
  }
  side <- rlang::arg_match(.side)
  cols_quos <- rlang::enquos(...)
  if (rlang::is_empty(cols_quos)) {
    cli::cli_abort("Argument {.arg ...} must not be empty.")
  }

  data_tbl <- util_rtf_dt_get(data, "_data")
  if (ncol(data_tbl) == 0) {
    return(data)
  }

  cols_to_pad_idx <- tidyselect::eval_select(
    rlang::expr(c(!!!cols_quos)),
    data_tbl
  )
  if (length(cols_to_pad_idx) == 0) {
    return(data)
  }

  rtf_nbsp <- "\\~"

  for (col_idx in cols_to_pad_idx) {
    original_vec <- data_tbl[[col_idx]]
    if (!is.character(original_vec)) {
      next
    }

    temp_df <- tibble::tibble(original = original_vec) |>
      dplyr::mutate(
        prefix = stringi::stri_extract_first_regex(
          original,
          "^_INDENT_TWIPS_\\d+_"
        ) |>
          tidyr::replace_na(""),
        visible_text = stringi::stri_replace_first_regex(
          original,
          "^_INDENT_TWIPS_\\d+_",
          ""
        )
      )

    pad_mask <- !is.na(temp_df$visible_text) &
      nzchar(trimws(temp_df$visible_text))
    if (!any(pad_mask)) {
      next
    }

    if (side == "left") {
      padding_str <- strrep(rtf_nbsp, .n_spaces)
      temp_df$visible_text[pad_mask] <- stringi::stri_c(
        padding_str,
        temp_df$visible_text[pad_mask]
      )
    } else {
      visible_subset <- temp_df$visible_text[pad_mask]
      max_width <- max(stringi::stri_length(visible_subset))
      target_width <- max_width + .n_spaces
      pads_to_add <- target_width - stringi::stri_length(visible_subset)

      padded_subset <- purrr::map2_chr(
        visible_subset,
        pads_to_add,
        ~ {
          if (.y <= 0) {
            return(.x)
          }
          padding_str <- strrep(rtf_nbsp, .y)
          if (side == "right") {
            return(stringi::stri_c(.x, padding_str))
          }
          left_pad <- strrep(rtf_nbsp, floor(.y / 2))
          right_pad <- strrep(rtf_nbsp, ceiling(.y / 2))
          stringi::stri_c(left_pad, .x, right_pad)
        }
      )
      temp_df$visible_text[pad_mask] <- padded_subset
    }
    data_tbl[[col_idx]] <- stringi::stri_c(
      temp_df$prefix,
      temp_df$visible_text
    )
  }
  util_rtf_dt_set(data, "_data", data_tbl)
}

#' Modify Column Labels
#' @param data An `rtf_tbl` object.
#' @param ... Formulas or named arguments to set new labels.
#' @return An `rtf_tbl` object with updated labels.
#' @export
rtf_col_label <- function(data, ..., .list = rlang::list2(...)) {
  util_stop_if_not_rtf_tbl(data = data)
  if (length(.list) == 0) {
    return(data)
  }

  updates_df <- util_process_formula_or_named_args(
    .list,
    data,
    "rtf_col_label"
  )
  if (nrow(updates_df) == 0) {
    return(data)
  }

  process_label <- function(label) {
    stringi::stri_replace_all_fixed(label, "\n", "{\\line}")
  }

  updates_df <- updates_df |>
    dplyr::mutate(value = purrr::map_chr(value, process_label)) |>
    dplyr::rename(new_label = value)

  colattr <- util_rtf_dt_get(data, "_rtf_colattr")
  updated_colattr <- colattr |>
    dplyr::left_join(updates_df, by = "var") |>
    dplyr::mutate(
      column_labels = purrr::map2(
        column_labels,
        new_label,
        ~ if (!is.na(.y)) {
          stats::setNames(rep(.y, length(.x)), names(.x))
        } else {
          .x
        }
      )
    ) |>
    dplyr::select(-new_label)

  data <- util_rtf_dt_set(data, "_rtf_colattr", updated_colattr)

  # Column labels can have newlines, affecting height.
  util_invalidate_layout(data)
}

#' Add a Column Spanner
#' @param data An `rtf_tbl` object.
#' @param label The text for the spanner label.
#' @param columns A `tidyselect` expression for columns to span.
#' @param level The hierarchical level for the spanner.
#' @return An `rtf_tbl` object with the new spanner.
#' @export
rtf_col_spanner <- function(data, label, columns, level = NULL) {
  util_stop_if_not_rtf_tbl(data = data)

  columns_quo <- rlang::enquo(columns)
  colattr <- util_rtf_dt_get(data, "_rtf_colattr")
  selection_data <- stats::setNames(colattr$var, colattr$var)

  selected_cols_idx <- tidyselect::eval_select(
    columns_quo,
    data = selection_data
  )

  if (length(selected_cols_idx) == 0) {
    cli::cli_warn("No columns selected. Spanner not added.")
    return(data)
  }

  selected_vars <- names(selection_data)[selected_cols_idx]

  processed_label <- stringi::stri_replace_all_fixed(label, "\n", "{\\line}")

  spanners_df <- util_rtf_dt_get(data, "_spanners")

  target_level <- if (is.null(level)) {
    if (nrow(spanners_df) > 0) max(spanners_df$spanner_level) else 1L
  } else {
    if (
      !rlang::is_bare_numeric(level, 1) ||
        level < 1 ||
        level != round(level)
    ) {
      cli::cli_abort("`level` must be a single positive integer.")
    }
    level
  }

  new_id <- if (nrow(spanners_df) > 0) {
    max(as.integer(spanners_df$spanner_id)) + 1L
  } else {
    1L
  }

  new_spanner <- tibble::tibble(
    spanner_id = as.character(new_id),
    spanner_label = processed_label,
    vars_from_gt = list(selected_vars),
    spanner_level = target_level
  )

  updated_spanners <- dplyr::bind_rows(spanners_df, new_spanner)
  data <- util_rtf_dt_set(data, "_spanners", updated_spanners)

  # Spanners add vertical space.
  util_invalidate_layout(data)
}
