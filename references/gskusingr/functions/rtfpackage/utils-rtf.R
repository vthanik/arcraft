# --- Low-Level RTF String Constructors and Helpers ---

#' Raw RTF string constructor
#' @noRd
rtf_raw <- function(...) {
  text <- paste0(..., collapse = "")
  class(text) <- "rtf_str"
  return(text)
}

#' RTF control word constructor
#' @noRd
rtf_key <- function(word, val = NULL, space = FALSE) {
  rtf_raw(paste0("\\", word, val, if (space) " "))
}

#' Create a string with an "in" (inches) suffix
#' @noRd
inch <- function(x) {
  if (!is.numeric(x)) {
    cli::cli_abort("Input to `inch()` must be numeric.")
  }
  paste0(x, "in")
}

#' Validate and return a standard alignment string
#' @noRd
align <- function(x) {
  rlang::arg_match(x, c("left", "center", "right"))
}

#' Get path of the currently executing script
#' @description A robust function to determine the path of the running R script
#' by checking multiple execution contexts (interactive, RStudio, knitr, Rscript,
#' and R CMD BATCH). It combines several common heuristics.
#' @return The normalized path to the script, or NA_character_ if not found.
#' @noRd
util_get_source_path <- function() {
  # --- 1. Check for knitr ---
  # This is the most reliable method when running in a knitr context.
  if (
    requireNamespace("knitr", quietly = TRUE) &&
      !is.null(knitr::current_input())
  ) {
    return(normalizePath(knitr::current_input(), mustWork = FALSE))
  }

  # --- 2. Check for R CMD BATCH (Canonical Method) ---
  # This is the standard way to get the input file for batch mode.
  # It is reliable for your first command example.
  infile <- Sys.getenv("R_BATCH_INFILE")
  if (nzchar(infile)) {
    return(normalizePath(infile, mustWork = FALSE))
  }

  # --- 3. Check for an active `source()` call ---
  # This inspects the call stack to find if the script was executed with source().
  for (i in sys.nframe():1) {
    frame <- sys.frame(i)
    if (exists("ofile", where = frame, inherits = FALSE)) {
      ofile <- get("ofile", envir = frame, inherits = FALSE)
      if (is.character(ofile)) {
        return(normalizePath(ofile, mustWork = FALSE))
      }
    }
  }

  # --- 4. Check for RStudio API ---
  # This works when running or sourcing within the RStudio IDE.
  if (
    requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()
  ) {
    path <- try(rstudioapi::getSourceEditorContext()$path, silent = TRUE)
    if (!inherits(path, "try-error") && !is.null(path) && nzchar(path)) {
      return(normalizePath(path, mustWork = FALSE))
    }
  }

  # --- 5. Check for command line arguments (Rscript, R --file=, R -f) ---
  # This block handles various command-line execution styles.
  cmd_args <- commandArgs(trailingOnly = FALSE)

  # A. Check for Rscript or `R --file=`
  # This is the standard for scripts run with Rscript.
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0) {
    path <- sub("^--file=", "", utils::tail(file_arg, 1))
    return(normalizePath(path, mustWork = FALSE))
  }

  # B. Check for `R -f` (Corrected Logic)
  # This is for calls like your second example. The bug in your original code
  # was using a variable `args` that wasn't defined in this scope.
  # We now correctly use `cmd_args`.
  f_index <- which(cmd_args == "-f")
  if (length(f_index) > 0 && f_index < length(cmd_args)) {
    script_path <- cmd_args[f_index + 1]
    return(normalizePath(script_path, mustWork = FALSE))
  }

  # --- 6. Fallback heuristic for non-interactive sessions ---
  # This is less reliable but can sometimes catch cases like `Rscript script.R`
  # where the `--file` argument is not automatically added.
  if (!interactive()) {
    args <- commandArgs(trailingOnly = TRUE)
    script_pattern <- "\\.[rR](md)?$"
    r_file_args <- grep(script_pattern, args, value = TRUE, ignore.case = TRUE)
    if (length(r_file_args) > 0) {
      return(normalizePath(r_file_args[1], mustWork = FALSE))
    }
  }

  # --- 7. If all else fails ---
  # Return NA if no method could determine the script path.
  return(NA_character_)
}

#' Format timestamp for footers
#' @noRd
util_format_timestamp <- function() {
  toupper(format(Sys.time(), "%d%b%Y %H:%M"))
}


# --- RTF-Specific Calculation Helpers ---

#' Get page orientation from options
#' @noRd
util_rtf_orientation <- function(data) {
  util_get_option_value(data, "page_orientation")
}

#' Calculate page margins in twips
#' @noRd
util_rtf_margin <- function(data) {
  margins <- c("left", "right", "top", "bottom")
  purrr::map_dbl(
    margins,
    ~ {
      val_str <- util_get_option_value(data, paste0("page_margin_", .x))
      util_abs_len_to_twips(util_parse_length(val_str))$value
    }
  ) |>
    stats::setNames(margins)
}

#' Calculate paper size in twips for a given orientation
#' @noRd
util_rtf_paper_size <- function(data, orientation) {
  size_name <- util_get_option_value(data, "page_paper_size")
  size_in <- rtf_paper_size_table$size[[which(
    rtf_paper_size_table$paper == size_name
  )]]
  size_twips <- purrr::map_dbl(
    size_in,
    ~ util_abs_len_to_twips(util_parse_length(.x))$value
  )
  if (orientation == "landscape") {
    c(height = size_twips[1], width = size_twips[2])
  } else {
    c(height = size_twips[2], width = size_twips[1])
  }
}

#' Calculate font size in RTF half-point units
#' @noRd
util_rtf_fsize <- function(data, font_size) {
  default_opt <- if (inherits(data, "rtf_tbl")) {
    "table_font_size"
  } else if (inherits(data, "rtf_fig")) {
    "figure_font_size"
  } else {
    "hf_font_size" # Fallback for headers/footers
  }
  fs_val <- font_size %||% util_get_option_value(data, default_opt)
  util_parse_length(fs_val)$value * 2
}

#' Dynamically Calculate the RTF `\headery` Value
#'
#' @description
#' This helper calculates the optimal starting Y-position for the page header.
#' The logic ensures the header's bottom edge sits flush against the main
#' content, but never starts higher than halfway down the top margin.
#'
#' @param num_header_lines The number of lines in the header.
#' @param header_fs_val The font size of the header in RTF half-points.
#' @param top_margin_twips The page's top margin in twips.
#'
#' @return An integer representing the calculated `\headery` value in twips.
#' @noRd
util_rtf_dynamic_headery <- function(
  num_header_lines,
  header_fs_val,
  top_margin_twips
) {
  # If there's no header, return the top margin value (no effect).
  if (num_header_lines == 0) {
    return(top_margin_twips)
  }

  # 1. Dynamically calculate line height based on font size.
  header_font_size_pt <- header_fs_val / 2
  header_char_height_twips <- header_font_size_pt * 18 # approx buffer height

  # 2. Estimate full line height by adding 20% for leading.
  twips_per_header_line <- ceiling(header_char_height_twips * 1.2)

  # 3. Calculate total estimated header height.
  estimated_header_height <- num_header_lines * twips_per_header_line

  # 4. Calculate the ideal starting position for a flush-bottom fit.
  ideal_headery_value <- top_margin_twips - estimated_header_height

  # 5. Define the minimum safe start position as half of the top margin.
  minimum_headery_value <- floor(top_margin_twips / 2)

  # 6. Return the greater of the ideal position or the minimum safe position.
  # This ensures the header is never too high and doesn't have excess space below it.
  max(ideal_headery_value, minimum_headery_value)
}

#' Get column widths in twips, aware of horizontal pagination.
#' @noRd
util_rtf_get_col_width <- function(data, vars = NULL, tbl_width) {
  colattr <- if (inherits(data, "rtf_tbl")) {
    util_rtf_dt_get(data, "_rtf_colattr")
  } else {
    data
  }

  if (is.null(vars)) {
    vars <- colattr$var
  }

  page_colattr <- colattr[colattr$var %in% vars, ]
  fixed_width_df <- page_colattr |>
    dplyr::filter(purrr::map_lgl(
      column_width,
      ~ !is.null(.x) && length(.x) > 0
    ))
  variable_width_df <- page_colattr |>
    dplyr::filter(purrr::map_lgl(
      column_width,
      ~ is.null(.x) || length(.x) == 0
    ))

  fixed_width_twips <- 0
  if (nrow(fixed_width_df) > 0) {
    # All widths are pre-standardized to inches, so we can parse directly
    fixed_widths_char <- purrr::map_chr(fixed_width_df$column_width, unlist)
    fixed_width_twips <- sum(
      util_abs_len_to_twips(util_parse_length(fixed_widths_char))$value
    )
  }

  remaining_width <- tbl_width - fixed_width_twips
  num_variable_cols <- nrow(variable_width_df)
  width_per_variable_col <- if (num_variable_cols > 0) {
    max(0, floor(remaining_width / num_variable_cols))
  } else {
    0
  }

  out <- numeric(length(vars))
  names(out) <- vars
  if (nrow(fixed_width_df) > 0) {
    fixed_vals_parsed <- util_parse_length(purrr::map_chr(
      fixed_width_df$column_width,
      unlist
    ))
    out[fixed_width_df$var] <- util_abs_len_to_twips(
      fixed_vals_parsed
    )$value
  }
  if (nrow(variable_width_df) > 0) {
    out[variable_width_df$var] <- width_per_variable_col
  }

  out[vars]
}

#' Helper to get a subset of `_rtf_colattr`
#' @noRd
util_get_rtf_colattr_subset <- function(data, vars) {
  colattr <- util_rtf_dt_get(data, "_rtf_colattr")
  if (is.null(vars)) {
    return(colattr)
  } else {
    return(colattr[colattr$var %in% vars, ])
  }
}


# --- Unit Conversion, Image, and Character Escaping ---

## NEW: Helper to validate and standardize length units
#' Validate and Standardize a Length String
#'
#' @description
#' This function takes a user-provided length string (e.g., "10cm", "72pt"),
#' validates it, converts it to a standard unit (inches or points), and returns
#' it as a formatted string.
#'
#' @param length_str The user's input string.
#' @param param_name The name of the parameter for clear error messages.
#' @param target_unit The desired output unit (`"in"` or `"pt"`).
#' @return A character string with the standardized value and unit.
#' @noRd
util_validate_and_standardize_length <- function(
  length_str,
  param_name,
  target_unit
) {
  if (!rlang::is_character(length_str, 1) || !nzchar(length_str)) {
    cli::cli_abort(
      "{.arg {param_name}} must be a single character string (e.g., '1.5in', '12pt')."
    )
  }

  parsed <- util_parse_length(length_str)

  if (is.na(parsed$value) || is.na(parsed$unit)) {
    cli::cli_abort(
      "Invalid format for {.arg {param_name}}. Expected a number followed by a unit (e.g., '1.5in', '12pt')."
    )
  }

  if (!parsed$unit %in% names(twip_factors)) {
    cli::cli_abort(
      "Invalid unit '{parsed$unit}' for {.arg {param_name}}. Use one of: {names(twip_factors)}."
    )
  }

  # Convert the value to twips (the universal intermediate)
  value_in_twips <- parsed$value * twip_factors[[parsed$unit]]

  # Convert from twips to the target unit
  target_factor <- twip_factors[[target_unit]]
  final_value <- value_in_twips / target_factor

  # Format for output
  return(paste0(format(round(final_value, 2), nsmall = 1), target_unit))
}

#' Parse a vector of length strings into a tibble of values and units
#' @noRd
util_parse_length <- function(lengths_vec) {
  vals <- as.numeric(stringi::stri_extract_first_regex(
    lengths_vec,
    "^[0-9.-]+"
  ))
  units <- stringi::stri_extract_first_regex(lengths_vec, "(%|[a-z]+)$")
  if (any(nzchar(lengths_vec) & (is.na(vals) | is.na(units)))) {
    cli::cli_abort(
      "Invalid length values. Must be a number followed by a unit (e.g., '1.5in')."
    )
  }
  tibble::tibble(value = vals, unit = units)
}

#' Convert a data frame of absolute lengths to twips
#' @noRd
util_abs_len_to_twips <- function(lengths_df) {
  twip_factors_df <- tibble::tibble(
    unit = names(twip_factors),
    conv = unname(twip_factors)
  )
  res <- dplyr::left_join(lengths_df, twip_factors_df, by = "unit")
  to_convert <- !is.na(res$conv)
  res$value[to_convert] <- res$value[to_convert] * res$conv[to_convert]
  dplyr::select(res, "value", "unit")
}

#' Escape non-ASCII characters for RTF
#' @noRd
escape_rtf <- function(text) {
  if (length(text) < 1 || all(is.na(text))) {
    return(text)
  }
  x <- text[!is.na(text)]
  x <- vapply(
    X = x,
    FUN = escape_rtf_unicode,
    FUN.VALUE = character(1L),
    USE.NAMES = FALSE
  )
  text[!is.na(text)] <- x
  return(text)
}

#' Worker function to escape Unicode characters in a single string
#' @noRd
escape_rtf_unicode <- function(x) {
  x_utf8 <- if (Encoding(x) != "UTF-8") enc2utf8(x) else x
  codepoints <- utf8ToInt(x_utf8)
  if (all(codepoints <= 127)) {
    return(x)
  }
  needs_escape <- codepoints > 127
  cp_subset <- codepoints[needs_escape]
  cp_signed <- ifelse(
    cp_subset > 32767,
    -(bitops::bitFlip(cp_subset, 16) + 1),
    cp_subset
  )
  chars <- unlist(stringi::stri_split_boundaries(x_utf8, type = "character"))
  chars[needs_escape] <- paste0("\\u", cp_signed, "?")
  stringi::stri_c(chars, collapse = "")
}

#' Read a PNG file into a hex string for RTF embedding
#' @noRd
rtf_read_figure <- function(file) {
  raw_data <- readBin(file, what = "raw", size = 1, n = file.info(file)$size)
  util_raw_to_hex_string(raw_data)
}

#' Convert a raw vector to a collapsed hex string, split into lines
#' @noRd
util_raw_to_hex_string <- function(raw_vec) {
  hex_string <- paste(sprintf("%02x", as.integer(raw_vec)), collapse = "")
  # Split into lines of 128 chars for better RTF compatibility
  stringi::stri_c(
    strsplit(hex_string, "(?<=\\G.{128})", perl = TRUE)[[1]],
    collapse = "\n"
  )
}

#' Scale figure dimensions to fit within page constraints
#' @noRd
util_scale_figure <- function(
  plot_obj,
  user_width_twips,
  user_height_twips,
  max_width_twips,
  max_height_twips
) {
  plot_build <- ggplot2::ggplot_build(plot_obj)
  aspect_ratio <- plot_build$plot$theme$aspect.ratio

  if (is.null(aspect_ratio)) {
    aspect_ratio <- if (!is.na(user_width_twips) && !is.na(user_height_twips)) {
      user_height_twips / user_width_twips
    } else {
      4 / 6 # A sensible default (height/width)
    }
  }

  final_width <- user_width_twips
  final_height <- user_height_twips

  # Case 1: No dimensions provided by user; scale to fit page
  if (is.na(user_width_twips) && is.na(user_height_twips)) {
    if ((max_width_twips * aspect_ratio) > max_height_twips) {
      # Fit to height
      final_height <- max_height_twips
      final_width <- max_height_twips / aspect_ratio
    } else {
      # Fit to width
      final_width <- max_width_twips
      final_height <- max_width_twips * aspect_ratio
    }
  } else if (is.na(user_width_twips)) {
    # Case 2: Height is provided, calculate width
    final_width <- user_height_twips / aspect_ratio
  } else if (is.na(user_height_twips)) {
    # Case 3: Width is provided, calculate height
    final_height <- user_width_twips * aspect_ratio
  }

  # Final check: ensure the scaled plot still fits, and shrink if necessary
  scale_factor <- 1
  if (final_width > max_width_twips) {
    scale_factor <- min(scale_factor, max_width_twips / final_width)
  }
  if (final_height > max_height_twips) {
    scale_factor <- min(scale_factor, max_height_twips / final_height)
  }

  list(
    width = floor(final_width * scale_factor),
    height = floor(final_height * scale_factor)
  )
}


# --- Content Parsing and Height Calculation ---

#' Clean RTF-like strings to get only the renderable text content.
#' @noRd
util_clean_rtf_content <- function(content) {
  if (is.na(content) || content == "") {
    return("")
  }
  if (stringi::stri_detect_fixed(content, "_MULTI_PARAGRAPH_")) {
    stripped <- stringi::stri_replace_first_fixed(
      content,
      "_MULTI_PARAGRAPH_",
      ""
    )
    lines <- stringi::stri_split_fixed(stripped, "|")[[1]]
    text_parts <- purrr::map_chr(
      lines,
      ~ stringi::stri_split_fixed(.x, ";", n = 2)[[1]][2] %||% ""
    )
    return(stringi::stri_c(text_parts, collapse = "\n"))
  }
  if (stringi::stri_detect_fixed(content, "_INDENT_TWIPS_")) {
    return(stringi::stri_replace_first_regex(
      content,
      "_INDENT_TWIPS_\\d+_",
      ""
    ))
  }
  return(content)
}

#' Calculate wrapped height of a single cell's content
#' @noRd
util_calculate_cell_height <- function(cleaned_content, char_width) {
  if (is.na(cleaned_content) || cleaned_content == "") {
    return(1)
  }
  explicit_lines <- stringi::stri_split_fixed(cleaned_content, "\n")[[1]]
  total_lines <- 0
  for (line_text in explicit_lines) {
    if (!nzchar(line_text)) {
      total_lines <- total_lines + 1
      next
    }
    words <- stringi::stri_split_fixed(line_text, " ")[[1]]
    words <- words[nzchar(words)]
    if (length(words) == 0) {
      total_lines <- total_lines + 1
      next
    }
    lines_for_this_segment <- 1
    current_line_len <- 0
    for (word in words) {
      word_len <- nchar(word)
      if (word_len > char_width) {
        lines_for_this_segment <- lines_for_this_segment +
          floor(word_len / char_width)
        word_len <- word_len %% char_width
      }
      if (
        current_line_len > 0 &&
          (current_line_len + word_len + 1) > char_width
      ) {
        lines_for_this_segment <- lines_for_this_segment + 1
        current_line_len <- word_len
      } else {
        current_line_len <- current_line_len +
          word_len +
          (if (current_line_len > 0) 1 else 0)
      }
    }
    total_lines <- total_lines + lines_for_this_segment
  }
  return(max(1, total_lines))
}

#' Format Specially Encoded Cell Content into RTF
#' @noRd
util_format_inner_content <- function(content_str, use_unicode) {
  # Case 1: Multi-line content with varying indents per line
  if (stringi::stri_detect_fixed(content_str, "_MULTI_PARAGRAPH_")) {
    stripped_content <- stringi::stri_replace_first_fixed(
      content_str,
      "_MULTI_PARAGRAPH_",
      ""
    )
    lines <- stringi::stri_split_fixed(stripped_content, "|")[[1]]

    processed_lines <- purrr::imap_chr(
      lines,
      ~ {
        parts <- stringi::stri_split_fixed(.x, ";", n = 2)[[1]]
        indent_val <- as.numeric(parts[1])
        text <- if (length(parts) > 1) parts[2] else ""

        if (use_unicode) {
          text <- escape_rtf(text)
        }

        line_prefix <- if (.y == 1) "" else "\\par"
        indent_cmd <- if (!is.na(indent_val) && indent_val > 0) {
          rtf_key("li", indent_val, space = TRUE)
        } else {
          ""
        }

        rtf_raw(line_prefix, indent_cmd, text)
      }
    )

    return(stringi::stri_c(processed_lines, collapse = ""))
  }

  # Case 2: Single-line indented content
  if (stringi::stri_detect_fixed(content_str, "_INDENT_TWIPS_")) {
    initial_indent <- as.numeric(stringi::stri_extract_first_regex(
      content_str,
      "(?<=_INDENT_TWIPS_)\\d+"
    ))
    inner_content <- stringi::stri_replace_first_regex(
      content_str,
      "_INDENT_TWIPS_\\d+_",
      ""
    )

    if (use_unicode) {
      inner_content <- escape_rtf(inner_content)
    }

    indent_cmd <- if (!is.na(initial_indent) && initial_indent > 0) {
      rtf_key("li", initial_indent, space = TRUE)
    } else {
      ""
    }

    return(rtf_raw(indent_cmd, inner_content))
  }

  # Case 3: Normal, non-encoded content is returned as is
  if (use_unicode) {
    content_str <- escape_rtf(content_str)
  }
  return(content_str)
}


# --- Core RTF String Generation ---

#' Generate Initial RTF Document Preamble
#' @noRd
rtf_str_init <- function(data) {
  lang_code <- util_get_option_value(data, "document_language_code")
  code_page <- util_get_option_value(data, "document_codepage")

  rtf_raw(
    "{\\rtf1",
    rtf_key("ansi"),
    rtf_key("ansicpg", code_page),
    rtf_key("uc", 1),
    rtf_key("deff", 0),
    rtf_key("deflang", lang_code),
    rtf_key("deflangfe", lang_code),
    "\n"
  )
}

#' Generate RTF Font Table (`\fonttbl`)
#' @noRd
rtf_str_fonttbl <- function(data) {
  font_name_opt <- if (inherits(data, "rtf_tbl")) {
    "table_font_name"
  } else {
    "figure_font_name"
  }
  font_name <- util_get_option_value(data, font_name_opt)
  font_row_idx <- which(purrr::map_lgl(
    rtf_font_table$f_name,
    ~ font_name %in% .x
  ))
  fftype <- if (length(font_row_idx) > 0) {
    rtf_font_table$f_family[[font_row_idx]]
  } else {
    "modern"
  }

  rtf_raw(
    "{\\fonttbl",
    "{\\f1\\f",
    fftype,
    "\\fprq1\\fcharset0 ",
    font_name,
    ";}",
    "}\n"
  )
}

#' Generate Full RTF Color Table (`\colortbl`)
#' @noRd
rtf_str_colortbl <- function() {
  rtf_raw(
    "{\\colortbl;\n",
    "\\red0\\green0\\blue0;\n",
    "\\red0\\green0\\blue255;\n",
    "\\red0\\green255\\blue255;\n",
    "\\red0\\green255\\blue0;\n",
    "\\red255\\green0\\blue255;\n",
    "\\red255\\green0\\blue0;\n",
    "\\red255\\green255\\blue0;\n",
    "\\red255\\green255\\blue255;\n",
    "\\red0\\green0\\blue128;\n",
    "\\red0\\green128\\blue128;\n",
    "\\red0\\green128\\blue0;\n",
    "\\red128\\green0\\blue128;\n",
    "\\red128\\green0\\blue0;\n",
    "\\red128\\green128\\blue0;\n",
    "\\red128\\green128\\blue128;\n",
    "\\red192\\green192\\blue192;\n",
    "}\n"
  )
}

#' Generate RTF Stylesheet and Global Document Properties
#' @noRd
rtf_str_stylesheet <- function(fs, margin, size) {
  rtf_raw(
    "{\\stylesheet{\\widctlpar\\adjustright\\fs",
    fs,
    "\\cgrid\\snext0 Normal;}\n",
    "{\\*\\cs10\\additive Default Paragraph Font;}}\n",
    "\\widowctrl\\ftnbj\\aenddoc\\formshade\\viewkind1\\viewscale100\\pgbrdrhead\\pgbrdrfoot\\fet0\n",
    rtf_key("paperw", size[["width"]]),
    rtf_key("paperh", size[["height"]]),
    rtf_key("margl", margin[["left"]]),
    rtf_key("margr", margin[["right"]]),
    rtf_key("margt", margin[["top"]]),
    rtf_key("margb", margin[["bottom"]]),
    "\n"
  )
}

#' Generate RTF Section Definition for Each Page (`\sectd`)
#' @noRd
rtf_str_sect_def <- function(
  page_num,
  header_rtf,
  footer_rtf,
  margin,
  size,
  orientation,
  headery_val
) {
  rtf_raw(
    if (page_num > 1) "\\pard\\sect" else "",
    "\\sectd\\linex0\\endnhere",
    rtf_key("pgwsxn", size[["width"]]),
    rtf_key("pghsxn", size[["height"]]),
    if (orientation == "landscape") rtf_key("lndscpsxn"),
    "\n",
    rtf_key("headery", headery_val),
    rtf_key("footery", margin[["bottom"]]),
    rtf_key("marglsxn", margin[["left"]]),
    rtf_key("margrsxn", margin[["right"]]),
    rtf_key("margtsxn", margin[["top"]]),
    rtf_key("margbsxn", margin[["bottom"]]),
    "\n",
    header_rtf,
    footer_rtf
  )
}

#' Generate RTF for a bookmark
#' @noRd
rtf_str_bookmark <- function(name) {
  rtf_raw("{\\*\\bkmkstart ", name, "}{\\*\\bkmkend ", name, "}\n")
}

#' Generate a fixed empty RTF table row
#' @noRd
rtf_str_fixed_empty_row <- function(fs_val, cell_spacing) {
  rtf_raw(
    "\\trowd\\trkeep\\trqc\\trgaph0\n",
    "\\pard\\plain\\intbl",
    rtf_key("sb", cell_spacing),
    rtf_key("sa", cell_spacing),
    "\\fs",
    fs_val,
    "\\cf1\\qc\\f1{\\cell}",
    "\\cltxlrtb\\clvertalt\\cellx10\n",
    "{\\row}\n"
  )
}

#' Generate RTF for the Title Block
#' @noRd
rtf_str_title_block <- function(
  data,
  page_num,
  total_pages,
  fs_val,
  is_bold,
  content_width
) {
  if (!util_dttype_exists(data, "_title")) {
    return("")
  }
  title_df <- util_rtf_dt_get(data, "_title")

  cell_padding <- util_get_option_value(data, "cell_padding")
  cell_spacing <- util_get_option_value(data, "cell_spacing")
  bg_color <- util_get_option_value(data, "title_background_color_index")

  title_lines <- purrr::pmap_chr(
    title_df,
    ~ rtf_str_hf_row(
      data,
      ..2,
      ..3,
      page_num,
      total_pages,
      fs_val,
      is_bold,
      content_width,
      cell_padding,
      cell_spacing,
      bg_color
    )
  )

  stringi::stri_c(title_lines, collapse = "")
}

#' Generate RTF Header and Footer blocks (`\header` or `\footer`)
#' @noRd
rtf_str_header_footer <- function(data, type = "header", fs, tbl_width) {
  block_key <- if (type == "header") "header" else "footer"
  all_content_df <- if (type == "header") {
    util_rtf_dt_get(data, "_header")
  } else {
    dplyr::bind_rows(
      util_rtf_dt_get(data, "_footer"),
      util_rtf_dt_get(data, "_sys_footer")
    )
  }

  if (is.null(all_content_df) || nrow(all_content_df) == 0) {
    return("")
  }

  cell_padding <- util_get_option_value(data, "cell_padding")
  cell_spacing <- util_get_option_value(data, "cell_spacing")
  bg_color <- util_get_option_value(data, "hf_background_color_index")

  hf_lines <- purrr::pmap_chr(
    all_content_df,
    ~ rtf_str_hf_row(
      data,
      ..2,
      ..3,
      1,
      1,
      fs,
      FALSE,
      tbl_width,
      cell_padding,
      cell_spacing,
      bg_color
    )
  )

  rtf_raw(
    "{\\",
    block_key,
    "\\pard\\plain\\qc{\n",
    if (type == "footer") "{\\pard\\par}\n",
    stringi::stri_c(hf_lines, collapse = ""),
    "\\pard}}\n"
  )
}

#' Generate a single RTF table row for a header, footer, or title line
#' @noRd
rtf_str_hf_row <- function(
  data,
  content,
  align,
  page_num,
  total_pages,
  fs,
  is_bold,
  tbl_width,
  cell_padding,
  cell_spacing,
  bg_color_idx
) {
  page_field <- "{\\field{\\*\\fldinst { PAGE }}}"
  numpages_field <- "{\\field{\\*\\fldinst { NUMPAGES }}}"

  replace_keywords <- function(text) {
    text |>
      stringi::stri_replace_all_fixed(
        "_PAGEOF_",
        paste0(page_field, "{ of }", numpages_field)
      ) |>
      stringi::stri_replace_all_fixed("_PAGE_", page_field) |>
      stringi::stri_replace_all_fixed("_PAGES_", numpages_field)
  }

  processed_content <- if (inherits(content, "hfrow_str")) {
    purrr::map(content, replace_keywords) |> `class<-`("hfrow_str")
  } else {
    replace_keywords(content)
  }

  row_def <- "\\trowd\\trkeep\\trqc\\trgaph0\n"

  cell_defs <- if (inherits(processed_content, "hfrow_str")) {
    if (length(processed_content) == 1) {
      util_rtf_cell_def(
        data,
        content = processed_content[[1]],
        align_char = "c",
        fs = fs,
        is_bold = is_bold,
        cellx_pos = tbl_width,
        use_keepn = FALSE,
        header = TRUE,
        sb_val = cell_spacing,
        sa_val = cell_spacing,
        clpad_val = cell_padding,
        bg_color_idx = bg_color_idx
      )
    } else {
      rtf_raw(
        util_rtf_cell_def(
          data,
          content = processed_content[[1]],
          align_char = "l",
          fs = fs,
          is_bold = is_bold,
          cellx_pos = floor(tbl_width / 2),
          use_keepn = FALSE,
          header = TRUE,
          sb_val = cell_spacing,
          sa_val = cell_spacing,
          clpad_val = cell_padding,
          bg_color_idx = bg_color_idx
        ),
        util_rtf_cell_def(
          data,
          content = processed_content[[2]],
          align_char = "r",
          fs = fs,
          is_bold = is_bold,
          cellx_pos = tbl_width,
          use_keepn = FALSE,
          header = TRUE,
          sb_val = cell_spacing,
          sa_val = cell_spacing,
          clpad_val = cell_padding,
          bg_color_idx = bg_color_idx
        )
      )
    }
  } else {
    util_rtf_cell_def(
      data,
      content = processed_content,
      align_char = substr(align, 1, 1),
      fs = fs,
      is_bold = is_bold,
      cellx_pos = tbl_width,
      use_keepn = FALSE,
      header = TRUE,
      sb_val = cell_spacing,
      sa_val = cell_spacing,
      clpad_val = cell_padding,
      bg_color_idx = bg_color_idx
    )
  }

  rtf_raw(row_def, cell_defs, "{\\row}\n")
}

#' Generate RTF for the Page Heading block
#' @noRd
rtf_str_page_heading_block <- function(
  data,
  text,
  fs,
  align,
  tbl_width,
  cell_padding,
  cell_spacing,
  bg_color_idx = 8
) {
  row_def <- "\\trowd\\trkeep\\trqc\\trgaph0\n"
  cell_def <- util_rtf_cell_def(
    data,
    content = text,
    align_char = substr(align, 1, 1),
    fs = fs,
    is_bold = FALSE,
    cellx_pos = tbl_width,
    sb_val = cell_spacing,
    sa_val = cell_spacing,
    clpad_val = cell_padding,
    header = TRUE,
    bg_color_idx = bg_color_idx
  )
  rtf_raw(row_def, cell_def, "{\\row}\n")
}

#' Generate RTF for Spanner Headers
#' @noRd
rtf_str_spanner_hdr <- function(
  data,
  colattr,
  vars,
  fs,
  tbl_width,
  border_pos,
  border_style,
  bg_color_idx,
  table_border
) {
  spanners_df <- util_rtf_dt_get(data, "_spanners")
  if (is.null(spanners_df) || nrow(spanners_df) == 0) {
    return("")
  }

  spanners_df <- spanners_df |>
    dplyr::mutate(
      vars_on_page = purrr::map(vars_from_gt, ~ intersect(.x, vars)),
      has_vars_on_page = purrr::map_lgl(vars_on_page, ~ length(.x) > 0)
    ) |>
    dplyr::filter(has_vars_on_page) |>
    dplyr::select(-has_vars_on_page)

  if (nrow(spanners_df) == 0) {
    return("")
  }

  col_widths_twips <- util_rtf_get_col_width(
    colattr,
    vars = vars,
    tbl_width = tbl_width
  )

  sb_sa_val <- util_get_option_value(data, "cell_spacing")
  clpad_val <- util_get_option_value(data, "cell_padding")

  generated_level_rtfs <- list()

  for (current_level in sort(
    unique(spanners_df$spanner_level),
    decreasing = TRUE
  )) {
    level_spanners <- spanners_df |>
      dplyr::filter(spanner_level == current_level)
    brdr_key <- rtf_brdr_map[border_style]

    top_border_def <- if (
      table_border == "top-bottom" &&
        current_level == max(spanners_df$spanner_level)
    ) {
      rtf_raw("\\clbrdrt\\brdr", brdr_key, "\\brdrw1\\brdrcf1")
    } else {
      ""
    }
    bottom_border_def <- rtf_raw(
      "\\clbrdrb\\brdr",
      brdr_key,
      "\\brdrw1\\brdrcf1"
    )
    spanner_border_def <- paste0(top_border_def, bottom_border_def)

    processed_cols <- c()
    cell_definitions <- list()

    while (length(processed_cols) < length(vars)) {
      current_col <- setdiff(vars, processed_cols)[1]
      spanner_idx <- purrr::detect_index(
        level_spanners$vars_on_page,
        ~ current_col %in% .x
      )

      if (spanner_idx > 0) {
        spanner_info <- level_spanners[spanner_idx, ]
        spanner_cols_ordered <- vars[
          vars %in% spanner_info$vars_on_page[[1]]
        ]
        cumulative_width <- sum(col_widths_twips[c(
          processed_cols,
          spanner_cols_ordered
        )])
        cell_definitions <- c(
          cell_definitions,
          list(util_rtf_cell_def(
            data,
            content = spanner_info$spanner_label,
            align_char = "c",
            fs = fs,
            is_bold = FALSE,
            border_def = spanner_border_def,
            cellx_pos = cumulative_width,
            header = TRUE,
            sb_val = sb_sa_val,
            sa_val = sb_sa_val,
            clpad_val = clpad_val,
            bg_color_idx = bg_color_idx
          ))
        )
        processed_cols <- c(processed_cols, spanner_cols_ordered)
      } else {
        cumulative_width <- sum(col_widths_twips[c(
          processed_cols,
          current_col
        )])
        cell_definitions <- c(
          cell_definitions,
          list(util_rtf_cell_def(
            data,
            content = "",
            align_char = "c",
            fs = fs,
            is_bold = FALSE,
            border_def = top_border_def,
            cellx_pos = cumulative_width,
            header = TRUE,
            sb_val = sb_sa_val,
            sa_val = sb_sa_val,
            clpad_val = clpad_val,
            bg_color_idx = bg_color_idx
          ))
        )
        processed_cols <- c(processed_cols, current_col)
      }
    }
    generated_level_rtfs[[as.character(current_level)]] <- rtf_raw(
      "\\trowd\\trkeep\\trhdr\\trqc\\trgaph0\n",
      stringi::stri_c(cell_definitions, collapse = ""),
      "{\\row}\n"
    )
  }

  stringi::stri_c(generated_level_rtfs, collapse = "")
}

#' Generate RTF for the main Table Column Header row (`\trowd`)
#' @noRd
rtf_str_tblhdr <- function(
  data,
  vars = NULL,
  page_group_id = NULL,
  fs,
  tbl_width,
  is_bold,
  border_pos,
  border_style,
  bg_color_idx,
  table_border
) {
  colattr <- util_get_rtf_colattr_subset(data, vars)

  pg_id_char <- as.character(page_group_id %||% "1")

  final_labels <- purrr::map_chr(colattr$column_labels, function(label_list) {
    label_list[[pg_id_char]] %||% label_list[[1]]
  })

  colattr$column_label <- final_labels

  final_vars <- colattr$var

  spanner_component <- rtf_str_spanner_hdr(
    data,
    colattr = colattr,
    vars = final_vars,
    fs = fs,
    tbl_width = tbl_width,
    border_pos = border_pos,
    border_style = border_style,
    bg_color_idx = bg_color_idx,
    table_border = table_border
  )

  col_header_component <- rtf_str_trowd(
    data,
    colattr = colattr,
    header = TRUE,
    vars = final_vars,
    fs = fs,
    tbl_width = tbl_width,
    is_bold = is_bold,
    border_pos = border_pos,
    border_style = border_style,
    bg_color_idx = bg_color_idx,
    table_border = table_border
  )

  rtf_raw(spanner_component, col_header_component)
}

#' Generate RTF for a generic table row (used for Column Headers)
#' @noRd
rtf_str_trowd <- function(
  data,
  colattr,
  header = FALSE,
  vars = NULL,
  fs,
  tbl_width,
  is_bold = FALSE,
  border_pos = "none",
  border_style = "single",
  bg_color_idx,
  table_border = "none"
) {
  widths <- util_rtf_get_col_width(
    colattr,
    vars = colattr$var,
    tbl_width = tbl_width
  )
  cumulative_widths <- cumsum(widths)

  brdr_key <- rtf_brdr_map[border_style]
  has_spanners <- util_dttype_exists(data, "_spanners")

  border_def <- if (header) {
    top_border <- if (!has_spanners && table_border == "top-bottom") {
      rtf_raw("\\clbrdrt\\brdr", brdr_key, "\\brdrw1\\brdrcf1")
    } else {
      ""
    }
    bottom_border <- if (border_pos == "bottom") {
      rtf_raw("\\clbrdrb\\brdr", brdr_key, "\\brdrw1\\brdrcf1")
    } else {
      ""
    }
    paste0(top_border, bottom_border)
  } else {
    ""
  }

  align <- if (header) substr(colattr[["header_align"]], 1, 1) else ""
  content <- if (header) colattr[["column_label"]] else ""
  sb_sa_val <- util_get_option_value(data, "cell_spacing")
  clpad_val <- util_get_option_value(data, "cell_padding")

  cell_defs <- vapply(
    seq_len(nrow(colattr)),
    function(i) {
      util_rtf_cell_def(
        data,
        content = content[[i]],
        align_char = align[[i]],
        fs = fs,
        is_bold = is_bold,
        border_def = border_def,
        cellx_pos = cumulative_widths[i],
        header = TRUE,
        sb_val = sb_sa_val,
        sa_val = sb_sa_val,
        clpad_val = clpad_val,
        bg_color_idx = bg_color_idx
      )
    },
    FUN.VALUE = character(1L)
  ) |>
    paste(collapse = "")

  row_def <- rtf_raw(
    "\\trowd\\trkeep",
    if (header) "\\trhdr" else "",
    "\\trqc\\trgaph0\n"
  )
  rtf_raw(row_def, cell_defs, "{\\row}\n")
}

#' Generate RTF for Table Body Cells for a given set of rows
#' @noRd
rtf_str_tblcell <- function(
  data,
  rowids,
  vars = NULL,
  fs,
  tbl_width,
  cell_padding,
  cell_spacing,
  bg_color_idx,
  table_border,
  total_rows
) {
  if (length(rowids) == 0) {
    return("")
  }

  colattr <- util_get_rtf_colattr_subset(data, vars)
  widths <- util_rtf_get_col_width(
    data,
    vars = colattr$var,
    tbl_width = tbl_width
  )
  cumulative_widths <- cumsum(widths)
  align_chars <- substr(colattr[["column_align"]], 1, 1)

  page_data <- util_rtf_dt_get(data, "_data")[
    rowids,
    colattr$var,
    drop = FALSE
  ]

  row_list <- lapply(seq_len(nrow(page_data)), function(row_index) {
    current_row_id <- rowids[row_index]
    border_def <- if (
      table_border %in%
        c("bottom", "top-bottom") &&
        current_row_id == total_rows
    ) {
      "\\clbrdrb\\brdrs\\brdrw1\\brdrcf1"
    } else {
      ""
    }

    row_content <- page_data[row_index, , drop = FALSE]
    cell_strings <- vapply(
      seq_along(colattr$var),
      function(col_index) {
        content_val <- row_content[[col_index]]
        if (is.na(content_val)) {
          content_val <- ""
        }
        util_rtf_cell_def(
          data,
          content = as.character(content_val),
          align_char = align_chars[[col_index]],
          fs = fs,
          is_bold = FALSE,
          border_def = border_def,
          cellx_pos = cumulative_widths[[col_index]],
          header = FALSE,
          sb_val = cell_spacing,
          sa_val = cell_spacing,
          clpad_val = cell_padding,
          bg_color_idx = bg_color_idx
        )
      },
      FUN.VALUE = character(1L)
    )
    rtf_raw(
      "\\trowd\\trkeep\\trqc\\trgaph0\n",
      paste(cell_strings, collapse = ""),
      "{\\row}\n"
    )
  })

  paste(row_list, collapse = "")
}

#' Generate the RTF for a single, fully-defined table cell
#' @noRd
util_rtf_cell_def <- function(
  data,
  content,
  align_char = "l",
  fs = 20,
  font_num = 1,
  is_bold = FALSE,
  border_def = "",
  cellx_pos,
  use_keepn = TRUE,
  header = FALSE,
  sb_val = 0, # space before paragraph
  sa_val = 0, # space after paragraph
  clpad_val = 0, # cell padding
  bg_color_idx = 8
) {
  use_unicode <- util_get_option_value(data, "unicode_conversion")
  inner_content <- util_format_inner_content(as.character(content), use_unicode)

  para_def <- rtf_raw(
    "\\pard\\plain\\intbl",
    if (use_keepn) "\\keepn",
    rtf_key("sb", sb_val),
    rtf_key("sa", sa_val),
    "\\fs",
    fs,
    "\\cf1\\f",
    font_num,
    "\\q",
    align_char,
    if (is_bold) "\\b " else ""
  )

  content_block <- rtf_raw("{", inner_content, "\\cell}", "\n")

  padding_str <- rtf_raw(
    "\\clpadt",
    clpad_val,
    "\\clpadft3", # Left padding
    "\\clpadr",
    clpad_val,
    "\\clpadfr3" # Right padding
  )

  base_props <- if (header) {
    rtf_raw("\\cltxlrtb\\clvertalb")
  } else {
    rtf_raw("\\cltxlrtb\\clvertalt")
  }

  cell_props <- rtf_raw(
    border_def,
    base_props,
    "\\clcbpat",
    bg_color_idx %||% 8, # Default to white if NULL
    padding_str,
    rtf_key("cellx", round(cellx_pos)),
    "\n"
  )

  rtf_raw(para_def, content_block, cell_props)
}


#' Generate RTF code for a figure
#' @description This function creates the `{\pict...}` block for embedding a PNG.
#' @noRd
rtf_str_figure <- function(hex_data, width_twips, height_twips) {
  rtf_raw(
    # Start a new paragraph, reset to defaults, center it, and insert the picture
    "{\\pard\\qc ",
    "{\\*\\shppict{\\pict",
    "\\pngblip",
    rtf_key("picwgoal", width_twips),
    rtf_key("pichgoal", height_twips),
    "\n",
    hex_data,
    "}}",
    # End the paragraph that contains the picture
    "\\par}\n"
  )
}
