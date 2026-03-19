#' (Internal) Calculate relative column widths for a specific set of columns
#'
#' @description This is the core width calculation function for PDFs. It takes a
#'   specific subset of columns (for a given page) and returns their widths as a
#'   named vector of fractions relative to `\linewidth`.
#' @param data The full `rtf_tbl` object.
#' @param page_colattr The `_rtf_colattr` tibble filtered to only the columns on
#'   the current page.
#' @return A named numeric vector where names are column `var`s and values are
#'   the relative width (e.g., `0.375`).
#' @noRd
util_pdf_calculate_relative_widths <- function(data, page_colattr) {
  if (nrow(page_colattr) == 0) {
    return(numeric(0))
  }
  opts <- util_options_to_list(data)
  is_tbl <- inherits(data, "rtf_tbl")
  font_size_pt <- if (is_tbl) {
    sub("pt", "", opts$table_font_size)
  } else {
    sub("pt", "", opts$figure_font_size)
  }

  paper_size_twips <- util_rtf_paper_size(data, opts$page_orientation)
  margin_twips <- util_rtf_margin(data)
  rtf_tbl_width_twips <- paper_size_twips[["width"]] -
    sum(margin_twips[c("left", "right")])

  widths_twips <- util_rtf_get_col_width(
    data,
    vars = page_colattr$var,
    tbl_width = rtf_tbl_width_twips
  )

  linewidth_in <- rtf_tbl_width_twips / 1440
  tabcolsep_pt <- floor(opts$cell_padding / 30)
  tabcolsep_in <- tabcolsep_pt / 72.27
  num_cols <- nrow(page_colattr)
  # overhead_in <- (num_cols - 1) * 2 * tabcolsep_in
  overhead_in <- num_cols * 2 * tabcolsep_in
  # latex_available_content_in <- linewidth_in - (overhead_in + (as.numeric(font_size_pt) * 1.2) / 72.27)
  latex_available_content_in <- linewidth_in - overhead_in

  total_rtf_based_width_twips <- sum(widths_twips)
  scaling_factor <- if (total_rtf_based_width_twips > 0) {
    (latex_available_content_in * 1440) / total_rtf_based_width_twips
  } else {
    1
  }
  final_widths_twips <- widths_twips * scaling_factor
  final_widths_in <- final_widths_twips / 1440

  relative_widths <- if (linewidth_in > 0) {
    final_widths_in / linewidth_in
  } else {
    rep(0, length(final_widths_in))
  }

  return(relative_widths)
}

#' (Internal) Process text for LaTeX output using a robust, multi-stage pipeline
#'
#' @description This is the definitive function for making text safe for LaTeX. It
#'   uses a placeholder strategy to protect macros like `_PAGE_` from being
#'   escaped, while correctly sanitizing all other literal text.
#' @param text The raw character vector to process.
#' @return A fully sanitized character vector, ready for insertion into a LaTeX document.
#' @noRd
util_process_text_for_latex <- function(text) {
  if (is.null(text) || !all(nzchar(text))) {
    return("")
  }

  # 1. Protect our internal macros by swapping them for safe, non-special placeholders.
  text <- stringi::stri_replace_all_fixed(
    str = text,
    pattern = names(LATEX_MACRO_MAP_TO_PLACEHOLDER),
    replacement = unname(LATEX_MACRO_MAP_TO_PLACEHOLDER),
    vectorize_all = FALSE
  )

  # 2. Sanitize the remaining literal text.
  # 2a. Escape basic LaTeX special characters using the predefined map.
  text <- stringi::stri_replace_all_fixed(
    text,
    pattern = names(LATEX_SPECIAL_CHARS_MAP),
    replacement = unname(LATEX_SPECIAL_CHARS_MAP),
    vectorize_all = FALSE
  )
  # 2b. Convert known Unicode characters to their specific LaTeX commands.
  text <- stringi::stri_replace_all_fixed(
    text,
    pattern = names(LATEX_UNICODE_MAP),
    replacement = unname(LATEX_UNICODE_MAP),
    vectorize_all = FALSE
  )

  # 2c. Preserve multiple spaces and tabs using a vectorized replacement.
  # Find all unique sequences of 2+ whitespace characters in the entire text vector.
  all_matches <- unlist(stringi::stri_extract_all_regex(text, "[ \t]{2,}"))

  # FIX: Filter out NA matches before processing to prevent errors.
  all_matches <- all_matches[!is.na(all_matches)]

  if (length(all_matches) > 0) {
    unique_matches <- unique(all_matches)
    # Create a corresponding vector of replacements
    replacements <- purrr::map_chr(
      unique_matches,
      ~ paste(rep("\\ ", nchar(.x)), collapse = "")
    )
    # Perform a vectorized fixed replacement
    text <- stringi::stri_replace_all_fixed(
      text,
      pattern = unique_matches,
      replacement = replacements,
      vectorize_all = FALSE
    )
  }

  # 3. Restore the final LaTeX commands from our safe placeholders.
  text <- stringi::stri_replace_all_fixed(
    str = text,
    pattern = names(LATEX_PLACEHOLDER_MAP_TO_LATEX),
    replacement = unname(LATEX_PLACEHOLDER_MAP_TO_LATEX),
    vectorize_all = FALSE
  )

  text
}

# Helper functions should be available
is_windows <- function() .Platform$OS.type == "windows"

#' Generate LaTeX Preamble
#' @noRd
pdf_str_preamble <- function(data) {
  opts <- util_options_to_list(data)
  is_tbl <- inherits(data, "rtf_tbl")
  font_size_pt <- if (is_tbl) {
    sub("pt", "", opts$table_font_size)
  } else {
    sub("pt", "", opts$figure_font_size)
  }

  font_name <- if (is_tbl) opts$table_font_name else opts$figure_font_name
  hf_font_size_pt <- sub("pt", "", opts$hf_font_size)
  title_font_size_pt <- sub("pt", "", opts$title_font_size)

  font_row_idx <- which(purrr::map_lgl(
    rtf_font_table$f_name,
    ~ font_name %in% .x
  ))
  fftype <- if (length(font_row_idx) > 0) {
    rtf_font_table$f_family[[font_row_idx]]
  } else {
    "modern"
  }
  font_family_cmd <- switch(
    fftype,
    "modern" = "\\ttfamily",
    "roman" = "\\rmfamily",
    "swiss" = "\\sffamily",
    "\\ttfamily"
  )

  header_df <- util_rtf_dt_get(data, "_header")
  hf_font_size_pt_num <- as.numeric(hf_font_size_pt)

  num_header_lines <- if (is.null(header_df)) {
    0
  } else {
    sum(purrr::map_int(
      header_df$content,
      ~ sum(stringi::stri_count_fixed(.x, "\n")) + 1
    ))
  }

  headheight_pt <- if (num_header_lines > 0) {
    # Use the same 1.2x multiplier used for baselineskip for a more
    # accurate estimate, and add a 2pt buffer to avoid floating point issues
    # and guarantee compliance with fancyhdr's calculated requirement.
    (num_header_lines * hf_font_size_pt_num * 1.2) + 2
  } else {
    # Even with no header, a default height is needed.
    hf_font_size_pt_num * 1.2
  }

  # --- Calculate footer height and adjust bottom margin using robust layout logic ---
  all_footers_df <- dplyr::bind_rows(
    util_rtf_dt_get(data, "_footer"),
    util_rtf_dt_get(data, "_sys_footer")
  )

  num_footer_lines <- 0

  if (nrow(all_footers_df) > 0) {
    paper_size_twips <- util_rtf_paper_size(data, opts$page_orientation)
    margin_twips <- util_rtf_margin(data)
    available_width_twips <- paper_size_twips[["width"]] -
      margin_twips[["left"]] -
      margin_twips[["right"]]

    font_map_idx <- which(rtf_font_char_width_map$f_family == fftype)
    base_char_width <- if (length(font_map_idx) > 0) {
      rtf_font_char_width_map$char_width_twips[[font_map_idx]]
    } else {
      120
    }
    hf_char_width_twips <- base_char_width * (hf_font_size_pt_num / 10)

    max_chars_full_width <- floor(available_width_twips / hf_char_width_twips)
    max_chars_half_width <- floor(max_chars_full_width / 2)

    line_counts_per_row <- purrr::map_int(
      all_footers_df$content,
      function(content_item) {
        if (inherits(content_item, "hfrow_str") && length(content_item) == 2) {
          cleaned_left <- util_clean_rtf_content(content_item[[1]])
          cleaned_right <- util_clean_rtf_content(content_item[[2]])
          lines_left <- util_calculate_cell_height(
            cleaned_left,
            max_chars_half_width
          )
          lines_right <- util_calculate_cell_height(
            cleaned_right,
            max_chars_half_width
          )
          return(max(lines_left, lines_right))
        } else {
          text <- if (is.list(content_item)) content_item[[1]] else content_item
          cleaned_text <- util_clean_rtf_content(text)
          return(util_calculate_cell_height(cleaned_text, max_chars_full_width))
        }
      }
    )

    num_footer_lines <- sum(line_counts_per_row)
  }

  single_line_height_in <- (hf_font_size_pt_num * 1.2) / 72.27

  # FIX: Calculate height for OVERFLOW lines only. The first line is handled
  # by the `footskip` parameter in \geometry, so we only need to add margin
  # for any lines that come after the first.
  overflow_footer_lines <- max(0, num_footer_lines - 1)
  overflow_footer_height_in <- overflow_footer_lines * single_line_height_in

  original_bottom_margin_in <- as.numeric(sub(
    "in",
    "",
    opts$page_margin_bottom
  ))

  new_bottom_margin_in <- original_bottom_margin_in + overflow_footer_height_in
  final_bottom_margin_str <- paste0(
    format(new_bottom_margin_in, nsmall = 4),
    "in"
  )

  geo <- paste0(
    "\\geometry{\n",
    sprintf("    %spaper,\n", opts$page_paper_size),
    sprintf("    %s,\n", opts$page_orientation),
    sprintf(
      "    left=%s, right=%s,\n",
      opts$page_margin_left,
      opts$page_margin_right
    ),
    sprintf(
      "    top=%s, bottom=%s,\n",
      opts$page_margin_top,
      final_bottom_margin_str
    ),
    sprintf(
      "    headheight=%spt, headsep=0pt, footskip=%spt, includefoot\n",
      headheight_pt,
      as.numeric(hf_font_size_pt) * 1.2
    ), # footskip
    "}"
  )

  # --- Automatic, OS-Aware Font Sourcing Logic ---

  # Define base packages used in all scenarios
  base_packages <- paste(
    c(
      "\\usepackage{geometry}",
      "\\usepackage{fontspec}",
      "\\usepackage{array}",
      "\\usepackage{booktabs}",
      "\\usepackage{fancyhdr}",
      "\\usepackage{lastpage}",
      "\\usepackage{graphicx}",
      "\\usepackage[table]{xcolor}",
      "\\usepackage{ragged2e}",
      "\\usepackage{calc}",
      "\\usepackage{parskip}"
    ),
    collapse = "\n"
  )

  # Initialize variables for conditional content
  extra_font_packages <- ""
  font_definitions <- ""

  font_path_env <- Sys.getenv("PDF_FONT_PATH")

  if (nzchar(font_path_env)) {
    # --- Priority 1: Environment variable is set. Use it on any OS. ---
    safe_path <- gsub("\\\\", "/", font_path_env)
    if (!endsWith(safe_path, "/")) {
      safe_path <- paste0(safe_path, "/")
    }

    font_definitions <- sprintf(
      "
\\setmainfont{TimesNewRoman}[
  Path=%s, Extension = .ttf,
  UprightFont=*-Regular, BoldFont=*-Bold, ItalicFont=*-Italic, BoldItalicFont=*-BoldItalic
]
\\setsansfont{Arial}[
  Path=%s, Extension = .ttf,
  UprightFont=*-Regular, BoldFont=*-Bold, ItalicFont=*-Italic, BoldItalicFont=*-BoldItalic
]
\\setmonofont{CourierNew}[
  Path=%s, Extension = .ttf,
  UprightFont=*-Regular, BoldFont=*-Bold, ItalicFont=*-Italic, BoldItalicFont=*-BoldItalic
]",
      safe_path,
      safe_path,
      safe_path
    )
  } else if (is_windows()) {
    # --- Priority 2: Not set, but OS is Windows. Use system-installed names. ---
    font_definitions <- "
\\setmainfont{Times New Roman}
\\setsansfont{Arial}
\\setmonofont{Courier New}
"
  }

  # --- Assemble the Final Preamble String ---
  paste(
    sprintf("\\documentclass[%spt]{article}", font_size_pt),
    "",
    "% --- Packages ---",
    base_packages,
    extra_font_packages, # Conditionally add TeX Gyre packages here
    "",
    "% --- Font Definitions ---",
    font_definitions,
    "",
    "% --- Page Layout and Geometry ---",
    geo,
    "",
    "% --- Global Settings and Custom Commands ---",
    "\\renewcommand\\baselinestretch{0.95}",
    sprintf(
      "\\setlength{\\baselineskip}{%spt}",
      as.numeric(font_size_pt) * 1.2
    ),
    sprintf("\\setlength{\\tabcolsep}{%.1fpt}", floor(opts$cell_padding / 30)),
    "",
    "\\setlength\\CenteringRightskip{0pt plus 1fil}",
    "\\setlength\\CenteringLeftskip{0pt plus 1fil}",
    "\\setlength\\RaggedRightRightskip{0pt plus 1fil}",
    "\\setlength\\RaggedLeftLeftskip{0pt plus 1fil}",
    "",
    "% --- Style Commands ---",
    sprintf(
      "\\newcommand{\\TitleStyle}{\\fontsize{%s}{%s}\\selectfont %s}",
      title_font_size_pt,
      as.numeric(title_font_size_pt) * 1.2,
      font_family_cmd
    ),
    sprintf(
      "\\newcommand{\\HeaderStyle}{\\fontsize{%s}{%s}\\selectfont %s}",
      font_size_pt,
      as.numeric(font_size_pt) * 1.2,
      font_family_cmd
    ),
    sprintf(
      "\\newcommand{\\DataStyle}{\\fontsize{%s}{%s}\\selectfont %s}",
      font_size_pt,
      as.numeric(font_size_pt) * 1.2,
      font_family_cmd
    ),
    sprintf(
      "\\newcommand{\\HFStyle}{\\fontsize{%s}{%s}\\selectfont %s}",
      hf_font_size_pt,
      as.numeric(hf_font_size_pt) * 1.2,
      font_family_cmd
    ),
    "",
    "% --- Custom Column Types ---",
    "\\newcolumntype{L}[1]{>{\\DataStyle\\RaggedRight\\arraybackslash}p{#1}}",
    "\\newcolumntype{R}[1]{>{\\DataStyle\\RaggedLeft\\arraybackslash}p{#1}}",
    "\\newcolumntype{C}[1]{>{\\DataStyle\\Centering\\arraybackslash}p{#1}}",
    "",
    "% --- Custom Header Commands ---",
    "\\newcommand*{\\HeaderL}[2]{\\multicolumn{1}{>{\\HeaderStyle\\RaggedRight\\arraybackslash}b{#1}}{#2}}",
    "\\newcommand*{\\HeaderC}[2]{\\multicolumn{1}{>{\\HeaderStyle\\Centering\\arraybackslash}b{#1}}{#2}}",
    "\\newcommand*{\\HeaderR}[2]{\\multicolumn{1}{>{\\HeaderStyle\\RaggedLeft\\arraybackslash}b{#1}}{#2}}",
    "\\newcommand*{\\HeaderSpanner}[2]{\\multicolumn{#1}{c}{\\Centering\\HeaderStyle#2}}",
    "",
    "% --- Custom Indentation Command ---",
    "\\newcommand{\\indentval}[1]{\\hangindent=#1pt\\hangafter=0 }",
    sep = "\n"
  )
}

#' Generate LaTeX Header and Footer Commands
#' @noRd
pdf_str_header_footer <- function(data) {
  hf_style <- "\\HFStyle "

  process_hf_df <- function(df) {
    if (is.null(df) || nrow(df) == 0) {
      return(list(L = "", C = "", R = ""))
    }

    # All processing is now centralized in `util_process_text_for_latex`
    if (inherits(df$content[[1]], "hfrow_str")) {
      parts <- purrr::transpose(df$content)
      left_parts <- if (length(parts) > 0) {
        purrr::map_chr(parts[[1]], util_process_text_for_latex)
      } else {
        ""
      }
      right_parts <- if (length(parts) > 1) {
        purrr::map_chr(parts[[2]], util_process_text_for_latex)
      } else {
        ""
      }

      list(
        L = paste(left_parts[nzchar(left_parts)], collapse = " \\\\{} "),
        C = "",
        R = paste(right_parts[nzchar(right_parts)], collapse = " \\\\{} ")
      )
    } else {
      align <- df$align[[1]]
      final_string <- paste(
        util_process_text_for_latex(unlist(df$content)),
        collapse = " \\\\{} "
      )
      switch(
        align,
        left = list(L = final_string, C = "", R = ""),
        center = list(L = "", C = final_string, R = ""),
        right = list(L = "", C = "", R = final_string),
        list(L = "", C = "", R = "")
      )
    }
  }

  h_content_df <- util_rtf_dt_get(data, "_header")
  f_content_df <- util_rtf_dt_get(data, "_footer")
  s_content_df <- util_rtf_dt_get(data, "_sys_footer")

  header_parts <- process_hf_df(h_content_df)
  footer_parts <- process_hf_df(f_content_df)
  sys_footer_parts <- process_hf_df(s_content_df)

  final_header_L <- paste(
    header_parts$L[nzchar(header_parts$L)],
    collapse = " \\\\ "
  )
  final_header_C <- paste(
    header_parts$C[nzchar(header_parts$C)],
    collapse = " \\\\ "
  )
  final_header_R <- paste(
    header_parts$R[nzchar(header_parts$R)],
    collapse = " \\\\ "
  )

  final_footer_L <- paste(
    c(footer_parts$L, sys_footer_parts$L)[nzchar(c(
      footer_parts$L,
      sys_footer_parts$L
    ))],
    collapse = " \\\\{} "
  )
  final_footer_C <- paste(
    c(footer_parts$C, sys_footer_parts$C)[nzchar(c(
      footer_parts$C,
      sys_footer_parts$C
    ))],
    collapse = " \\\\{} "
  )
  final_footer_R <- paste(
    c(footer_parts$R, sys_footer_parts$R)[nzchar(c(
      footer_parts$R,
      sys_footer_parts$R
    ))],
    collapse = " \\\\{} "
  )

  paste(
    "\\pagestyle{fancy}",
    "\\fancyhf{}",
    "\\renewcommand{\\headrulewidth}{0pt}",
    "\\renewcommand{\\footrulewidth}{0pt}",
    "",
    "% --- Header Content ---",
    if (nzchar(final_header_L)) {
      sprintf("\\fancyhead[L]{%s%s}", hf_style, final_header_L)
    },
    if (nzchar(final_header_C)) {
      sprintf("\\fancyhead[C]{%s%s}", hf_style, final_header_C)
    },
    if (nzchar(final_header_R)) {
      sprintf("\\fancyhead[R]{%s%s}", hf_style, final_header_R)
    },
    "",
    "% --- Footer Content ---",
    if (nzchar(final_footer_L)) {
      sprintf("\\fancyfoot[L]{%s%s}", hf_style, final_footer_L)
    },
    if (nzchar(final_footer_C)) {
      sprintf("\\fancyfoot[C]{%s%s}", hf_style, final_footer_C)
    },
    if (nzchar(final_footer_R)) {
      sprintf("\\fancyfoot[R]{%s%s}", hf_style, final_footer_R)
    },
    sep = "\n"
  )
}

#' Generate LaTeX for the Title Block
#' @noRd
pdf_str_title_block <- function(data) {
  title_df <- util_rtf_dt_get(data, "_title")
  if (nrow(title_df) == 0) {
    return("")
  }
  content_str <- paste(
    util_process_text_for_latex(unlist(title_df$content)),
    collapse = " \\\\ "
  )
  paste0(
    "\\begin{center}\n",
    "{\\TitleStyle\n",
    content_str,
    "\n}\n",
    "\\end{center}"
  )
}

#' Generate LaTeX for a Page Heading (Group Label)
#' @noRd
pdf_str_page_heading_block <- function(data, text) {
  opts <- util_options_to_list(data)
  align <- opts$page_group_label_align
  align_cmd <- switch(
    align,
    "left" = "\\RaggedRight",
    "center" = "\\Centering",
    "right" = "\\RaggedLeft"
  )
  sprintf(
    "{%s \\DataStyle %s\\par}",
    align_cmd,
    util_process_text_for_latex(text)
  )
}

#' Generate a full LaTeX table environment
#' @noRd
pdf_str_table <- function(
  data,
  row_ids,
  vars,
  page_group_id,
  is_last_page_chunk
) {
  if (length(row_ids) == 0 && is.null(vars)) {
    return("")
  }

  colattr <- util_get_rtf_colattr_subset(data, vars)
  opts <- util_options_to_list(data)

  relative_widths <- util_pdf_calculate_relative_widths(data, colattr)

  col_defs <- purrr::map_chr(seq_along(colattr$var), function(i) {
    align_char <- toupper(substr(colattr$column_align[i], 1, 1))
    width_val <- relative_widths[i]
    sprintf("%s{%.6f\\linewidth}", align_char, width_val)
  })

  col_defs_str <- paste0("  ", col_defs, collapse = "\n")
  tabular_preamble <- paste0("\\begin{tabular}{\n", col_defs_str, "\n}")

  spanner_row <- pdf_str_spanner_hdr(data, colattr, relative_widths)
  header_row <- pdf_str_tblhdr(data, colattr, page_group_id, relative_widths)

  top_rule <- if (opts$table_border %in% c("top-bottom")) "\\toprule" else ""
  data_rows <- pdf_str_tblcell(data, row_ids, colattr$var)
  bottom_rule <- if (
    opts$table_border %in% c("bottom", "top-bottom") && is_last_page_chunk
  ) {
    "\\bottomrule"
  } else {
    ""
  }

  paste(
    "\\begin{table*}[!htbp]",
    "\\centering",
    tabular_preamble,
    top_rule,
    spanner_row,
    header_row,
    data_rows,
    bottom_rule,
    "\\end{tabular}",
    "\\end{table*}",
    sep = "\n\n"
  )
}

#' Generate LaTeX for Spanner Headers
#' @noRd
pdf_str_spanner_hdr <- function(data, colattr, relative_widths) {
  spanners_df <- util_rtf_dt_get(data, "_spanners")
  if (is.null(spanners_df) || nrow(spanners_df) == 0) {
    return("")
  }
  page_vars <- colattr$var
  spanners_on_page <- spanners_df |>
    dplyr::mutate(
      vars_on_page = purrr::map(vars_from_gt, ~ intersect(.x, page_vars)),
      span_width = purrr::map_int(vars_on_page, length)
    ) |>
    dplyr::filter(span_width > 0)
  if (nrow(spanners_on_page) == 0) {
    return("")
  }

  spanners_on_page <- spanners_on_page |>
    dplyr::arrange(match(purrr::map_chr(vars_on_page, 1), page_vars))
  spanner_cells <- purrr::pmap_chr(
    spanners_on_page,
    function(spanner_label, span_width, ...) {
      sprintf(
        "\\HeaderSpanner{%d}{%s}",
        span_width,
        util_process_text_for_latex(spanner_label)
      )
    }
  )

  start_idx <- 1
  rules <- purrr::map_chr(spanners_on_page$span_width, function(width) {
    end_idx <- start_idx + width - 1
    rule <- sprintf("\\cmidrule(lr){%d-%d}", start_idx, end_idx)
    start_idx <<- end_idx + 1
    rule
  })

  spanner_cells_str <- paste(spanner_cells, collapse = "\n  & ")

  paste(
    paste0(spanner_cells_str, " \\\\"),
    paste(rules, collapse = " "),
    sep = "\n"
  )
}

#' Generate LaTeX for the main Table Column Header row
#' @noRd
pdf_str_tblhdr <- function(data, colattr, page_group_id, relative_widths) {
  opts <- util_options_to_list(data)
  pg_id_char <- as.character(page_group_id %||% "1")
  labels <- purrr::map_chr(
    colattr$column_labels,
    ~ .x[[pg_id_char]] %||% .x[[1]]
  )

  header_cells <- purrr::map_chr(seq_along(colattr$var), function(i) {
    align <- toupper(substr(colattr$header_align[i], 1, 1))
    width_val <- relative_widths[i]
    label <- util_process_text_for_latex(labels[i])
    sprintf("\\Header%s{%.6f\\linewidth}{%s}", align, width_val, label)
  })

  bottom_rule <- if (opts$col_heading_border == "bottom") "\n\\hline" else ""

  formatted_header_row <- paste(header_cells, collapse = "\n  & ")

  paste0(formatted_header_row, " \\\\", bottom_rule)
}

#' Generate LaTeX for Table Body Cells with Dynamic Indentation
#' @noRd
pdf_str_tblcell <- function(data, rowids, vars) {
  if (length(rowids) == 0) {
    return("")
  }

  page_data <- util_rtf_dt_get(data, "_data")[rowids, vars, drop = FALSE]

  process_cell <- function(content_str) {
    if (is.na(content_str) || !nzchar(content_str)) {
      return("")
    }
    content_str <- as.character(content_str)

    if (stringi::stri_detect_fixed(content_str, "_MULTI_PARAGRAPH_")) {
      stripped <- stringi::stri_replace_first_fixed(
        content_str,
        "_MULTI_PARAGRAPH_",
        ""
      )
      lines <- stringi::stri_split_fixed(stripped, "|")[[1]]

      processed_lines <- purrr::map_chr(lines, function(line) {
        parts <- stringi::stri_split_fixed(line, ";", n = 2)[[1]]
        indent_twips <- as.numeric(parts[1])
        text <- if (length(parts) > 1) parts[2] else ""

        indent_pt <- if (!is.na(indent_twips)) indent_twips / 20 else 0
        indent_cmd <- if (indent_pt > 0) {
          sprintf("\\indentval{%.0f}", indent_pt)
        } else {
          ""
        }

        paste0(indent_cmd, util_process_text_for_latex(text))
      })
      return(paste(processed_lines, collapse = "\\par "))
    }

    if (stringi::stri_detect_fixed(content_str, "_INDENT_TWIPS_")) {
      indent_twips <- as.numeric(stringi::stri_extract_first_regex(
        content_str,
        "(?<=_INDENT_TWIPS_)\\d+"
      ))
      text <- stringi::stri_replace_first_regex(
        content_str,
        "_INDENT_TWIPS_\\d+_",
        ""
      )

      indent_pt <- if (!is.na(indent_twips)) indent_twips / 20 else 0
      indent_cmd <- if (indent_pt > 0) {
        sprintf("\\indentval{%.0f} ", indent_pt)
      } else {
        ""
      }

      return(paste0(indent_cmd, util_process_text_for_latex(text)))
    }

    util_process_text_for_latex(content_str)
  }

  row_list <- lapply(1:nrow(page_data), function(i) {
    cell_strings <- purrr::map_chr(page_data[i, ], process_cell)
    paste(cell_strings, collapse = "\n  & ")
  })

  paste(paste0(row_list, " \\\\"), collapse = "\n\n")
}

#' Generate LaTeX for a Figure
#' @description This function creates the LaTeX code for embedding a figure.
#' @param file_path The path to the image file.
#' @param width_in The target width in inches.
#' @param height_in The target height in inches.
#' @return A string containing the LaTeX code.
#' @noRd
pdf_str_figure <- function(file_path, width_in, height_in) {
  safe_path <- gsub("\\\\", "/", file_path)
  paste(
    "{\\centering",
    sprintf(
      "\\includegraphics[width=%.4fin, height=%.4fin]{%s}\n",
      width_in,
      height_in,
      safe_path
    ),
    "}",
    sep = "\n"
  )
}
