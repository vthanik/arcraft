#' Generate Default RTF Table Options List
#'
#' @description Creates a named list of all default options for an `rtf_tbl`
#'   object, with each option having its native data type.
#' @noRd
rtf_defaults_table <- function() {
  list(
    # Page Layout
    page_orientation = "landscape",
    page_paper_size = "letter",
    page_margin_left = "1.0in",
    page_margin_right = "1.0in",
    page_margin_top = "1.0in",
    page_margin_bottom = "1.0in",
    # Spacing and Padding
    cell_padding = 60L,
    cell_spacing = 0L,
    # Title Block
    title_font_size = "10pt",
    title_bold = FALSE,
    title_background_color_index = 8L,
    # Header & Footer
    hf_font_size = "10pt",
    hf_background_color_index = 8L,
    # Table Body & Font
    table_font_name = "Courier",
    table_font_size = "10pt",
    table_background_color_index = 8L,
    indent_twips_per_space = 120L,
    # Table Borders
    table_border = "none",
    # Column Headers
    col_heading_border = "bottom",
    col_heading_border_style = "single",
    col_heading_bold = FALSE,
    # Pagination
    page_line_size_landscape = NA_integer_,
    page_line_size_portrait = NA_integer_,
    page_group_label_align = "left",
    # Make the line spacing buffer a configurable option
    line_spacing_multiplier = 1.18,
    # Document-Level
    unicode_conversion = TRUE,
    document_language_code = 1033L,
    document_codepage = 1252L
  )
}

#' Generate Default RTF Figure Options List
#'
#' @description Creates a named list of all default options for an `rtf_fig`
#'   object, with each option having its native data type.
#' @noRd
rtf_defaults_figure <- function() {
  list(
    # Page Layout
    page_orientation = "landscape",
    page_paper_size = "letter",
    page_margin_left = "1.0in",
    page_margin_right = "1.0in",
    page_margin_top = "1.0in",
    page_margin_bottom = "1.0in",
    # Spacing and Padding
    cell_padding = 60L,
    cell_spacing = 0L,
    # Title Block
    title_font_size = "10pt",
    title_bold = FALSE,
    title_background_color_index = 8L,
    # Header & Footer
    hf_font_size = "10pt",
    hf_background_color_index = 8L,
    # Figure-specific Font
    figure_font_name = "Arial",
    figure_font_size = "10pt",
    # Document-Level
    unicode_conversion = TRUE,
    document_language_code = 1033L,
    document_codepage = 1252L
  )
}


#' RTF Font Information Table
#' @noRd
rtf_font_table <- tibble::tibble(
  f_name = list(
    c("Courier", "Courier New"),
    c("Times", "Times New Roman"),
    "Arial"
  ),
  f_family = c("modern", "roman", "swiss")
)

#' RTF Font Family to Character Width Map
#' @noRd
rtf_font_char_width_map <- tibble::tribble(
  ~f_family , ~char_width_twips ,
  "modern"  ,               120 ,
  "roman"   ,                90 ,
  "swiss"   ,               100
)

#' RTF Border Style Map
#' @noRd
rtf_brdr_map <- c("single" = "s", "thick" = "th", "double" = "db")

#' RTF Paper Size Table
#' @noRd
rtf_paper_size_table <- tibble::tibble(
  paper = c("letter", "a4"),
  size = list(c("8.5in", "11in"), c("8.27in", "11.69in"))
)

#' Twip Conversion Factors
#' @noRd
twip_factors <- c(
  `in` = 1440,
  `pt` = 20,
  `px` = 15,
  `cm` = 566.9291,
  `mm` = 56.69291
)

#' Internal constants for pagination height calculations.
#' @noRd
PAGE_HEADING_HEIGHT_LINES <- 2L
HF_LINES_IN_MARGIN <- 1L
