#' Create an `rtf_tbl` Object from a `gt_tbl` or `gt_group`
#'
#' @description
#' This is the main constructor and the primary entry point for the `rtfbuildr`
#' workflow for tables. It is an S3 generic method that processes either a single `gt_tbl`
#' object or a `gt_group` object (a collection of `gt_tbl`s). It extracts
#' the underlying data and styling, preparing it for conversion to an RTF table
#' by creating an `rtf_tbl` object.
#'
#' @details
#' When a `gt_group` object is provided, each `gt_tbl` within it is treated as
#' a distinct page group. A page break is automatically inserted between groups,
#' and column headers (which can be different for each group) are updated
#' accordingly. In this mode, the `page_group_col` argument is ignored.
#'
#' Control columns specified in `page_group_col` and `row_noorphan_col` are
#' used exclusively for layout logic and are **not rendered** in the final table.
#'
#' @param data A `gt_tbl` or `gt_group` object.
#' @param ... Additional arguments passed to the specific method.
#' @param page_group_col An optional bare column name (e.g., `col1`) from the
#'   original data. A page break will be forced before any row where the value
#'   in this column changes. Ignored if `data` is a `gt_group`.
#' @param page_group_label An optional expression defining the heading text to
#'   display at the top of a new page group. This is evaluated within a data mask
#'   of the source data (e.g., `paste("Region:", region)`).
#' @param row_noorphan_col An optional bare column name used to define groups of
#'   rows that should be kept together on the same page.
#' @param drop_columns An optional `tidyselect` expression (e.g.,
#'   `c(col1, starts_with("extra_"))`) specifying columns to exclude from the
#'   final RTF table.
#' @param replace_na `[logical(1)]` If `TRUE` (default), `NA` values in the
#'   table body are replaced with empty strings (`""`).
#' @param process_indent `[logical(1)]` If `TRUE` (default), leading spaces in
#'   cell content are detected and converted to RTF indentation commands.
#' @param add_default_footer `[logical(1)]` If `TRUE` (default), a standard
#'   system footer with the source file path and timestamp is added.
#'
#' @return An S3 object of class `rtf_tbl`, which also inherits from `rtf_doc`.
#' @export
#'
#' @examples
#' library(gt)
#' # --- Example with a single gt_tbl ---
#' simple_tbl <- rtf_table(
#'   gt(iris[1:5, 1:4]),
#'   page_group_col = Species,
#'   row_noorphan_col = Species,
#'   page_group_label = paste("Species:", Species)
#' )
#'
#' # --- Example with a gt_group object ---
#' # Create two separate gt tables
#' gt1 <- gt(subset(iris, Species == "setosa")[1:5, 1:2])
#' gt2 <- gt(subset(iris, Species == "versicolor")[1:5, 1:3])
#'
#' # Combine them into a gt_group
#' grouped_gt <- gt_group(gt1, gt2)
#'
#' # Create the rtf_tbl - page grouping is now automatic
#' grouped_tbl <- rtf_table(grouped_gt)
#'
rtf_table <- function(data, ...) {
  util_stop_if_not_gt_tbl(data = data)
  UseMethod("rtf_table")
}

#' @rdname rtf_table
#' @export
rtf_table.default <- function(data, ...) {
  cli::cli_abort(
    "The {.fn rtf_table} function only supports {.cls gt_tbl} and {.cls gt_group} objects."
  )
}

#' @rdname rtf_table
#' @export
rtf_table.gt_tbl <- function(
  data,
  page_group_col = NULL,
  page_group_label = NULL,
  row_noorphan_col = NULL,
  drop_columns = NULL,
  replace_na = TRUE,
  process_indent = TRUE,
  add_default_footer = TRUE,
  ...
) {
  rtf_dt <- list()
  class(rtf_dt) <- c("rtf_tbl", "rtf_doc", "list")
  gt_source_data <- util_gt_get(data, "_data")
  all_source_cols <- names(gt_source_data)

  page_group_col_name <- get_single_col_name(
    rlang::enquo(page_group_col),
    "page_group_col",
    all_source_cols
  )
  row_noorphan_col_name <- get_single_col_name(
    rlang::enquo(row_noorphan_col),
    "row_noorphan_col",
    all_source_cols
  )

  rtf_dt[["_control_col_map"]] <- list(
    page_group_col = page_group_col_name,
    row_noorphan_col = row_noorphan_col_name
  )

  page_group_label_quo <- rlang::enquo(page_group_label)
  page_group_label_vars <- all.vars(rlang::quo_get_expr(page_group_label_quo))
  all_control_vars <- unique(c(
    page_group_col_name,
    row_noorphan_col_name,
    page_group_label_vars
  ))

  processed_source_data <- gt_source_data
  tfrmt_grp_lbl_vec <- if (
    "..tfrmt_row_grp_lbl" %in% names(processed_source_data)
  ) {
    processed_source_data[["..tfrmt_row_grp_lbl"]]
  } else {
    NULL
  }

  for (col in all_control_vars) {
    if (col %in% names(processed_source_data)) {
      processed_source_data[[col]] <- util_smart_fill(
        vec = processed_source_data[[col]],
        tfrmt_grp_lbl_vec = tfrmt_grp_lbl_vec
      )
    }
  }

  user_drop_col_indices <- tidyselect::eval_select(
    rlang::enquo(drop_columns),
    data = stats::setNames(all_source_cols, all_source_cols)
  )
  user_drop_col_names <- all_source_cols[user_drop_col_indices]
  all_cols_to_drop <- unique(c(
    util_gt_data_col_exclude(data),
    all_control_vars,
    user_drop_col_names
  ))

  # MODIFIED: Use the new defaults-generating function
  rtf_dt <- util_rtf_options_init(rtf_dt, defaults_fun = rtf_defaults_table)

  opt_indent_twips <- util_get_option_value(rtf_dt, "indent_twips_per_space")

  rtf_dt[["_data"]] <- util_gt_data_init(
    gt_tbl = data,
    data_override = processed_source_data,
    replace_na = replace_na,
    process_indent = process_indent,
    indent_twips_per_space = opt_indent_twips
  )

  rtf_dt <- util_rtf_colattr_init(
    rtf_dt,
    gt_tbl = data,
    exclude_cols = all_cols_to_drop
  )

  rtf_dt[["_rtf_colattr"]] <- rtf_dt[["_rtf_colattr"]] |>
    dplyr::filter(!var %in% all_control_vars)

  rtf_dt <- util_rtf_spanners_init(
    rtf_dt,
    data
  )
  rtf_dt <- util_rtf_component_init(rtf_dt, "_title")
  rtf_dt <- util_rtf_component_init(rtf_dt, "_header")
  rtf_dt <- util_rtf_component_init(rtf_dt, "_footer")
  rtf_dt <- util_rtf_component_init(rtf_dt, "_sys_footer")

  rtf_dt[["_page_group_vec"]] <- if (!is.null(page_group_col_name)) {
    processed_source_data[[page_group_col_name]]
  } else {
    NULL
  }
  rtf_dt[["_row_noorphan_vec"]] <- if (!is.null(row_noorphan_col_name)) {
    processed_source_data[[row_noorphan_col_name]]
  } else {
    NULL
  }

  if (!rlang::quo_is_null(page_group_label_quo)) {
    label_vec <- tryCatch(
      {
        selection_data <- stats::setNames(
          names(processed_source_data),
          names(processed_source_data)
        )
        selected_idx <- tidyselect::eval_select(
          page_group_label_quo,
          data = selection_data
        )
        if (length(selected_idx) == 1) {
          processed_source_data[[names(selected_idx)]]
        } else {
          stop("Not a single column selection", call. = FALSE)
        }
      },
      error = function(e) {
        rlang::eval_tidy(
          page_group_label_quo,
          data = processed_source_data
        )
      }
    )
    rtf_dt[["_page_group_label_vec"]] <- label_vec
  } else {
    rtf_dt[["_page_group_label_vec"]] <- NULL
  }

  if (add_default_footer) {
    file_path <- util_get_source_path()
    file_path_text <- if (is.na(file_path)) "" else file_path
    datetime_text <- util_format_timestamp()
    rtf_dt <- rtf_footer(
      rtf_dt,
      paste(file_path_text, datetime_text, sep = "  "),
      .default_sys = TRUE
    )
  }

  # Initialize the layout cache as empty and mark it as stale
  rtf_dt[["_layout"]] <- NULL
  rtf_dt[["_layout_is_stale"]] <- TRUE

  # Return the final object
  rtf_dt
}

#' @rdname rtf_table
#' @export
rtf_table.gt_group <- function(
  data,
  page_group_col = NULL,
  page_group_label = NULL,
  row_noorphan_col = NULL,
  drop_columns = NULL,
  replace_na = TRUE,
  process_indent = TRUE,
  add_default_footer = TRUE,
  ...
) {
  n_groups <- nrow(data[["gt_tbls"]])
  gt_list <- purrr::map(seq_len(n_groups), ~ gt::grp_pull(data, which = .x))

  dynamic_col_pattern <- "\\s*\\(N\\s*=\\s*\\d+\\)"

  processed_groups_list <- purrr::imap(gt_list, function(gt_obj, group_id) {
    data_df <- util_gt_get(gt_obj, "_data")
    boxhead_df <- util_gt_get(gt_obj, "_boxhead")
    spanners_df <- util_gt_get(gt_obj, "_spanners")

    dynamic_cols <- boxhead_df |>
      dplyr::filter(stringi::stri_detect_regex(var, dynamic_col_pattern))

    headers_for_group <- boxhead_df |>
      dplyr::select(var, column_label) |>
      dplyr::mutate(page_group_id = as.character(group_id))

    spanners_for_group <- spanners_df |> dplyr::rename(vars_from_gt = vars)

    if (nrow(dynamic_cols) > 0) {
      dynamic_cols <- dynamic_cols |>
        dplyr::mutate(
          generic_var = stringi::stri_replace_all_regex(
            var,
            dynamic_col_pattern,
            ""
          )
        )
      rename_map <- stats::setNames(
        dynamic_cols$var,
        dynamic_cols$generic_var
      )
      data_df <- data_df |> dplyr::rename(!!!rename_map)

      header_rename_map <- stats::setNames(
        dynamic_cols$generic_var,
        dynamic_cols$var
      )
      headers_for_group <- headers_for_group |>
        dplyr::mutate(var = dplyr::recode(var, !!!header_rename_map))

      if (nrow(spanners_for_group) > 0) {
        spanners_for_group$vars_from_gt <- purrr::map(
          spanners_for_group$vars_from_gt,
          ~ dplyr::recode(.x, !!!header_rename_map)
        )
      }
    }
    list(
      data = data_df,
      headers = headers_for_group,
      spanners = spanners_for_group
    )
  })

  transposed_processed <- purrr::list_transpose(processed_groups_list)
  all_data <- transposed_processed$data |>
    purrr::imap(~ dplyr::mutate(.x, ..rtf_page_group_id.. = .y)) |>
    purrr::list_rbind()
  all_headers <- transposed_processed$headers |> purrr::list_rbind()
  all_spanners <- transposed_processed$spanners |>
    purrr::list_rbind() |>
    dplyr::distinct()

  rtf_dt <- list()
  class(rtf_dt) <- c("rtf_tbl", "rtf_doc", "list")
  # MODIFIED: Use the new defaults-generating function
  rtf_dt <- util_rtf_options_init(rtf_dt, defaults_fun = rtf_defaults_table)

  all_headers$column_label <- stringi::stri_replace_all_fixed(
    all_headers$column_label,
    "\n",
    "{\\line}"
  )
  if (nrow(all_spanners) > 0) {
    all_spanners$spanner_label <- stringi::stri_replace_all_fixed(
      all_spanners$spanner_label,
      "\n",
      "{\\line}"
    )
  }

  rtf_colattr <- all_headers |>
    dplyr::group_by(var) |>
    tidyr::nest() |>
    dplyr::mutate(
      column_labels = purrr::map(
        data,
        ~ stats::setNames(.x$column_label, .x$page_group_id)
      )
    ) |>
    dplyr::select(var, column_labels) |>
    dplyr::mutate(
      column_align = "left",
      header_align = "center",
      column_width = vector("list", n())
    )

  if (!rlang::quo_is_null(rlang::enquo(page_group_col))) {
    cli::cli_warn(c(
      "The {.arg page_group_col} argument is ignored when the input is a {.cls gt_group}.",
      "i" = "Page grouping is automatically determined by the structure of the {.cls gt_group} object."
    ))
  }

  page_group_col_name <- "..rtf_page_group_id.."
  row_noorphan_col_name <- get_single_col_name(
    rlang::enquo(row_noorphan_col),
    "row_noorphan_col",
    names(all_data)
  )

  rtf_dt[["_control_col_map"]] <- list(
    page_group_col = page_group_col_name,
    row_noorphan_col = row_noorphan_col_name
  )

  page_group_label_quo <- rlang::enquo(page_group_label)
  page_group_label_vars <- all.vars(rlang::quo_get_expr(page_group_label_quo))
  all_control_vars <- unique(c(
    page_group_col_name,
    row_noorphan_col_name,
    page_group_label_vars
  ))

  processed_source_data <- all_data
  tfrmt_grp_lbl_vec <- if (
    "..tfrmt_row_grp_lbl" %in% names(processed_source_data)
  ) {
    processed_source_data[["..tfrmt_row_grp_lbl"]]
  } else {
    NULL
  }

  for (col in all_control_vars) {
    if (col %in% names(processed_source_data)) {
      processed_source_data[[col]] <- util_smart_fill(
        vec = processed_source_data[[col]],
        tfrmt_grp_lbl_vec = tfrmt_grp_lbl_vec
      )
    }
  }

  user_drop_col_indices <- tidyselect::eval_select(
    rlang::enquo(drop_columns),
    data = stats::setNames(names(all_data), names(all_data))
  )
  user_drop_col_names <- names(all_data)[user_drop_col_indices]
  all_cols_to_drop <- unique(c(
    util_gt_data_col_exclude(gt_list[[1]]),
    all_control_vars,
    user_drop_col_names
  ))

  opt_indent_twips <- util_get_option_value(rtf_dt, "indent_twips_per_space")

  rtf_dt[["_data"]] <- util_gt_data_init(
    gt_tbl = gt_list[[1]],
    data_override = processed_source_data,
    replace_na = replace_na,
    process_indent = process_indent,
    indent_twips_per_space = opt_indent_twips
  )

  rtf_dt[["_rtf_colattr"]] <- rtf_colattr |>
    dplyr::filter(!var %in% all_cols_to_drop)
  rtf_dt[["_spanners"]] <- all_spanners

  rtf_dt <- util_rtf_component_init(rtf_dt, "_title")
  rtf_dt <- util_rtf_component_init(rtf_dt, "_header")
  rtf_dt <- util_rtf_component_init(rtf_dt, "_footer")
  rtf_dt <- util_rtf_component_init(rtf_dt, "_sys_footer")

  rtf_dt[["_page_group_vec"]] <- processed_source_data[[page_group_col_name]]
  rtf_dt[["_row_noorphan_vec"]] <- if (!is.null(row_noorphan_col_name)) {
    processed_source_data[[row_noorphan_col_name]]
  } else {
    NULL
  }

  if (!rlang::quo_is_null(page_group_label_quo)) {
    label_vec <- tryCatch(
      {
        selection_data <- stats::setNames(
          names(processed_source_data),
          names(processed_source_data)
        )
        selected_idx <- tidyselect::eval_select(
          page_group_label_quo,
          data = selection_data
        )
        if (length(selected_idx) == 1) {
          processed_source_data[[names(selected_idx)]]
        } else {
          stop("Not a single column selection", call. = FALSE)
        }
      },
      error = function(e) {
        rlang::eval_tidy(
          page_group_label_quo,
          data = processed_source_data
        )
      }
    )
    rtf_dt[["_page_group_label_vec"]] <- label_vec
  } else {
    rtf_dt[["_page_group_label_vec"]] <- NULL
  }

  if (add_default_footer) {
    file_path <- util_get_source_path()
    file_path_text <- if (is.na(file_path)) "" else file_path
    datetime_text <- util_format_timestamp()
    rtf_dt <- rtf_footer(
      rtf_dt,
      paste(file_path_text, datetime_text, sep = "  "),
      .default_sys = TRUE
    )
  }

  # Initialize the layout cache as empty and mark it as stale
  rtf_dt[["_layout"]] <- NULL
  rtf_dt[["_layout_is_stale"]] <- TRUE

  # Return the final object
  rtf_dt
}
