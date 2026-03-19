#' rtfbuildr: A Robust Framework for RTF Table and Figure Generation in R
#'
#' @description
#' The `rtfbuildr` package provides a robust and flexible framework for creating
#' publication-quality RTF (Rich Text Format) documents directly from R. It is
#' designed to integrate smoothly with popular packages like 'gt' (for tables)
#' and 'ggplot2' (for figures), converting structured R objects into highly
#' customizable RTF documents. Key features include advanced pagination (both
#' vertical and horizontal for tables), custom headers, footers, titles, precise
#' column control, and robust Unicode character support. The package can now
#' intelligently handle `gt_group` objects, treating each sub-table as a distinct
#' page group with potentially unique column headers.
#'
#' @keywords internal
"_PACKAGE"

#' @importFrom bitops bitFlip
#' @importFrom dplyr arrange bind_rows filter group_by if_else lag left_join
#'   mutate pull rename row_number select summarise ungroup consecutive_id first
#'   distinct ends_with any_of coalesce slice_tail
#' @importFrom gt gt grp_pull
#' @importFrom ggplot2 ggsave ggplot_build
#' @importFrom purrr imap list_rbind map map_chr map_dbl map2_chr
#'   map_lgl pmap_chr flatten list_transpose detect_index map2
#' @importFrom rlang arg_match as_name caller_env check_dots_unnamed enquo enquos
#'   eval_tidy f_lhs f_rhs is_bare_numeric is_character is_empty is_formula
#'   is_logical is_list is_named list2 quo quo_is_null quo_text `%||%` dots_n
#'   expr sym expr_text
#' @importFrom stringi stri_c stri_count_fixed stri_detect_fixed stri_extract_first_regex
#'   stri_replace_all_fixed stri_replace_first_fixed stri_replace_first_regex
#'   stri_split_fixed stri_trim_left stri_trim_right stri_length
#' @importFrom tibble as_tibble tibble tribble
#' @importFrom tidyr fill nest replace_na
#' @importFrom tidyselect eval_select everything starts_with where
#' @importFrom stats setNames
#' @importFrom cli cli_abort cli_rule cli_text cli_h2 cli_par cli_end col_green
#'   col_silver col_cyan style_italic symbol cli_warn cli_alert_info
## usethis namespace: start
## usethis namespace: end
NULL
