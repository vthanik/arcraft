#' Set Global Document Options
#'
#' @description
#' Modifies the global options of an `rtf_doc` object to control document-level
#' properties.
#'
#' @param data An `rtf_doc` object (`rtf_tbl` or `rtf_fig`).
#' @param ... A series of name-value pairs. Any valid option can be set. For
#'   length values (margins, font sizes), units like 'in', 'cm', 'mm', 'pt' can be used.
#'
#' @return An object of the same class as `data` with options updated.
#' @export
#' @examples
#' library(gt)
#' tbl <- rtf_table(gt(iris[1:5, 1:4])) |>
#'   rtf_options(
#'     page_orientation = "portrait",
#'     table_font_size = "9pt",
#'     page_margin_left = "2.5cm"
#'   )
rtf_options <- function(data, ...) {
  util_stop_if_not_rtf_doc(data = data)

  user_args <- rlang::list2(...)

  if (rlang::is_empty(user_args)) {
    return(data)
  }

  current_opts <- util_options_to_list(data)
  valid_params <- names(current_opts)

  # Validate and standardize user arguments before merging
  for (param_name in names(user_args)) {
    if (!param_name %in% valid_params) {
      user_args[[param_name]] <- NULL # Silently ignore invalid options
      next
    }

    param_value <- user_args[[param_name]]

    validated_value <- switch(
      param_name,
      # Enums
      page_orientation = rlang::arg_match(
        param_value,
        c("landscape", "portrait")
      ),
      page_paper_size = rlang::arg_match(param_value, c("letter", "a4")),
      table_border = rlang::arg_match(
        param_value,
        c("none", "bottom", "top-bottom")
      ),
      col_heading_border = rlang::arg_match(
        param_value,
        c("none", "bottom")
      ),
      page_group_label_align = rlang::arg_match(
        param_value,
        c("left", "center", "right")
      ),
      table_font_name = rlang::arg_match(
        param_value,
        c("Courier", "Times New Roman", "Arial")
      ),
      figure_font_name = rlang::arg_match(
        param_value,
        c("Arial", "Times New Roman", "Courier")
      ),
      col_heading_border_style = rlang::arg_match(
        param_value,
        c("single", "double", "thick")
      ),

      # Logicals
      title_bold = ,
      col_heading_bold = ,
      unicode_conversion = {
        if (!rlang::is_logical(param_value, 1)) {
          cli::cli_abort("{.arg {param_name}} must be TRUE or FALSE.")
        }
        param_value
      },

      # Lengths (standardized to inches)
      page_margin_left = ,
      page_margin_right = ,
      page_margin_top = ,
      page_margin_bottom = util_validate_and_standardize_length(
        param_value,
        param_name,
        "in"
      ),

      # Lengths (standardized to points)
      title_font_size = ,
      hf_font_size = ,
      table_font_size = ,
      figure_font_size = util_validate_and_standardize_length(
        param_value,
        param_name,
        "pt"
      ),

      # NEW CASE for pdf_tabcolsep_pt
      pdf_tabcolsep_pt = {
        if (!rlang::is_bare_numeric(param_value, 1) || param_value < 0) {
          cli::cli_abort(
            "{.arg {param_name}} must be a single non-negative number."
          )
        }
        as.integer(param_value)
      },

      # Default case for all other (numeric) options
      {
        if (!rlang::is_bare_numeric(param_value, 1) || param_value < 0) {
          cli::cli_abort(
            "{.arg {param_name}} must be a single non-negative number."
          )
        }
        # Coerce to integer if it's a whole number for consistency
        if (param_value == as.integer(param_value)) {
          as.integer(param_value)
        } else {
          param_value
        }
      }
    )
    user_args[[param_name]] <- validated_value
  }

  new_opts <- utils::modifyList(current_opts, user_args)
  data <- util_rtf_dt_set(data, "_options", new_opts)

  layout_affecting_options <- c(
    "page_orientation",
    "page_paper_size",
    "page_margin_left",
    "page_margin_right",
    "page_margin_top",
    "page_margin_bottom",
    "page_line_size_landscape",
    "page_line_size_portrait",
    "title_font_size",
    "hf_font_size",
    "table_font_name",
    "table_font_size",
    "indent_twips_per_space"
  )

  if (any(names(user_args) %in% layout_affecting_options)) {
    data <- util_invalidate_layout(data)
  }

  return(data)
}
