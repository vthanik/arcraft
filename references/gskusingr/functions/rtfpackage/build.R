#' Build and Write an RTF or PDF Document
#'
#' @description
#' This function serves as the final step in the `rtfbuildr` workflow. It is an
#' S3 generic that orchestrates the entire process of converting a finalized
#' `rtf_doc` object into its RTF string representation and can optionally compile it
#' to a PDF document.
#'
#' @param data An `rtf_doc` object (`rtf_tbl` or `rtf_fig`) that has been fully prepared.
#' @param file An optional file path. If provided, the output will be
#'   written to this file. The extension (`.rtf` or `.pdf`) determines the primary output.
#' @param pdf `[logical(1)]` If `TRUE` and `file` is provided with an `.rtf`
#'   extension, a PDF will also be generated via a LaTeX intermediate.
#' @param keep_tex `[logical(1)]` If `TRUE`, the intermediate `.tex` file created
#'   during PDF generation will not be deleted.
#' @param ... Additional arguments passed to methods.
#'
#' @return If `file` is `NULL`, returns a single character string containing the
#'   complete RTF code. If a `file` path is provided, it writes the document
#'   and invisibly returns the file path.
#' @export
#' @examples
#' \dontrun{
#' library(gt)
#' library(ggplot2)
#'
#' # --- For a table ---
#' rtf_obj <- rtf_table(gt(iris[1:5, 1:4]))
#'
#' # Get RTF as a string
#' rtf_string <- build_rtf(rtf_obj, pdf = FALSE)
#'
#' # Write to RTF and also create a PDF
#' build_rtf(rtf_obj, file = "my_table.rtf")
#' }
build_rtf <- function(data, file = NULL, pdf = TRUE, keep_tex = FALSE, ...) {
  util_stop_if_not_rtf_doc(data)
  UseMethod("build_rtf")
}

#' @export
#' @rdname build_rtf
build_rtf.rtf_tbl <- function(
  data,
  file = NULL,
  pdf = TRUE,
  keep_tex = FALSE,
  ...
) {
  # --- 1. Ensure Layout is Up-to-Date (LAZY RECALCULATION) ---
  if (is.null(data[["_layout"]]) || data[["_layout_is_stale"]]) {
    data <- recalculate_layout(data)
  }

  # --- 2. Handle PDF-only output request ---
  if (!is.null(file) && tolower(tools::file_ext(file)) == "pdf") {
    return(build_pdf_internal(data, file, keep_tex))
  }

  # --- 3. Pre-computation and Setup for RTF ---
  options_list <- util_options_to_list(data)
  opt_title_font_size <- options_list[["title_font_size"]]
  opt_title_bold <- options_list[["title_bold"]]
  opt_hf_font_size <- options_list[["hf_font_size"]]
  opt_tbl_font_size <- options_list[["table_font_size"]]
  opt_pg_label_align <- options_list[["page_group_label_align"]]
  opt_ch_bold <- options_list[["col_heading_bold"]]
  opt_ch_border <- options_list[["col_heading_border"]]
  opt_ch_border_style <- options_list[["col_heading_border_style"]]
  opt_cell_padding <- options_list[["cell_padding"]]
  opt_cell_spacing <- options_list[["cell_spacing"]]
  opt_bg_color_idx <- options_list[["table_background_color_index"]]
  opt_orientation <- options_list[["page_orientation"]]
  opt_table_border <- options_list[["table_border"]]

  has_page_groups <- "..rtf_page_group_id.." %in%
    names(util_rtf_dt_get(data, "_data"))

  margin_twips <- util_rtf_margin(data)
  paper_size_twips <- util_rtf_paper_size(data, opt_orientation)
  tbl_width_twips <- paper_size_twips[["width"]] -
    sum(margin_twips[c("left", "right")])
  fs_val_title <- util_rtf_fsize(data, opt_title_font_size)
  fs_val_hf <- util_rtf_fsize(data, opt_hf_font_size)
  fs_val_table <- util_rtf_fsize(data, opt_tbl_font_size)

  page_info <- util_rtf_dt_get(data, "_layout")
  page_split_info <- util_rtf_dt_get(data, "_page_split")
  has_page_splits <- !is.null(page_split_info)
  has_data_rows <- nrow(util_rtf_dt_get(data, "_data")) > 0
  total_data_rows <- nrow(util_rtf_dt_get(data, "_data"))
  has_footer <- util_dttype_exists(data, "_footer") ||
    util_dttype_exists(data, "_sys_footer")
  num_row_pages <- max(1, nrow(page_info))
  num_col_pages <- if (has_page_splits) nrow(page_split_info) else 1
  total_pages <- if (has_data_rows) num_row_pages * num_col_pages else 1

  # --- 4. Generate Static RTF Components ---
  setup_component <- rtf_raw(
    rtf_str_init(data),
    rtf_str_fonttbl(data),
    rtf_str_colortbl(),
    rtf_str_stylesheet(fs_val_table, margin_twips, paper_size_twips)
  )

  num_header_lines <- if (util_dttype_exists(data, "_header")) {
    nrow(util_rtf_dt_get(data, "_header"))
  } else {
    0
  }

  dynamic_headery_value <- util_rtf_dynamic_headery(
    num_header_lines = num_header_lines,
    header_fs_val = fs_val_hf,
    top_margin_twips = margin_twips[["top"]]
  )

  full_header_rtf <- if (util_dttype_exists(data, "_header")) {
    rtf_str_header_footer(
      data,
      type = "header",
      fs = fs_val_hf,
      tbl_width = tbl_width_twips
    )
  } else {
    ""
  }
  full_footer_rtf <- if (has_footer) {
    rtf_str_header_footer(
      data,
      type = "footer",
      fs = fs_val_hf,
      tbl_width = tbl_width_twips
    )
  } else {
    ""
  }

  # --- 5. Assemble and Write/Return Dynamic Page Components ---
  is_streaming <- !is.null(file)
  if (is_streaming) {
    con <- file(file, "wb")
    on.exit(close(con), add = TRUE)
    writeLines(setup_component, con, useBytes = TRUE)
  } else {
    page_components <- vector("list", total_pages)
  }

  page_counter <- 1
  if (nrow(page_info) == 0) {
    page_info <- tibble::tibble(
      row_start = 0,
      row_end = -1,
      page_heading_text = NA_character_
    )
  }

  for (i in seq_len(nrow(page_info))) {
    page_spec <- page_info[i, ]
    row_ids <- if (page_spec$row_start <= page_spec$row_end) {
      seq(page_spec$row_start, page_spec$row_end)
    } else {
      integer(0)
    }

    current_page_group_id <- if (
      has_page_groups && has_data_rows && length(row_ids) > 0
    ) {
      util_rtf_dt_get(data, "_data")$..rtf_page_group_id..[row_ids[1]]
    } else {
      NULL
    }

    for (j in seq_len(num_col_pages)) {
      current_vars <- if (has_page_splits) page_split_info$vars[[j]] else NULL
      sect_header_rtf <- if (page_counter == 1) full_header_rtf else ""
      sect_footer_rtf <- if (page_counter == 1) full_footer_rtf else ""

      section_def_comp <- rtf_str_sect_def(
        page_counter,
        sect_header_rtf,
        sect_footer_rtf,
        margin_twips,
        paper_size_twips,
        opt_orientation,
        dynamic_headery_value
      )
      bookmark_comp <- rtf_str_bookmark(
        if (page_counter == 1) "IDX" else paste0("IDX", page_counter - 1)
      )
      title_comp <- rtf_str_title_block(
        data,
        page_counter,
        total_pages,
        fs_val_title,
        opt_title_bold,
        tbl_width_twips
      )

      page_heading_text <- page_spec$page_heading_text
      page_heading_comp <- if (
        !is.na(page_heading_text) && nzchar(page_heading_text)
      ) {
        rtf_str_page_heading_block(
          data,
          page_heading_text,
          fs_val_table,
          opt_pg_label_align,
          tbl_width_twips,
          opt_cell_padding,
          opt_cell_spacing,
          opt_bg_color_idx
        )
      } else {
        ""
      }

      table_header_comp <- rtf_str_tblhdr(
        data,
        vars = current_vars,
        page_group_id = current_page_group_id,
        fs = fs_val_table,
        tbl_width = tbl_width_twips,
        is_bold = opt_ch_bold,
        border_pos = opt_ch_border,
        border_style = opt_ch_border_style,
        bg_color_idx = opt_bg_color_idx,
        table_border = opt_table_border
      )
      table_cells_comp <- rtf_str_tblcell(
        data,
        row_ids,
        current_vars,
        fs_val_table,
        tbl_width_twips,
        opt_cell_padding,
        opt_cell_spacing,
        opt_bg_color_idx,
        table_border = opt_table_border,
        total_rows = total_data_rows
      )

      current_page_rtf <- rtf_raw(
        section_def_comp,
        bookmark_comp,
        title_comp,
        "{\\pard\\par}\n",
        page_heading_comp,
        if (nzchar(page_heading_comp)) "{\\pard\\par}\n" else "",
        table_header_comp,
        table_cells_comp,
        if (i < nrow(page_info) || j < num_col_pages) {
          ""
        } else if (!has_footer) {
          "{\\pard\\par}\n"
        } else {
          ""
        }
      )

      if (is_streaming) {
        writeLines(current_page_rtf, con, useBytes = TRUE)
      } else {
        page_components[[page_counter]] <- current_page_rtf
      }
      page_counter <- page_counter + 1
    }
  }

  # --- 6. Finalize and Return RTF ---
  final_close <- "}\n"
  rtf_output <- if (is_streaming) {
    writeLines(final_close, con, useBytes = TRUE)
    invisible(file)
  } else {
    rtf_raw(setup_component, paste(page_components, collapse = ""), final_close)
  }

  # --- 7. Build PDF if requested ---
  if (pdf && !is.null(file)) {
    pdf_file <- sub("\\.rtf$", ".pdf", file, ignore.case = TRUE)
    if (pdf_file == file) {
      pdf_file <- paste0(file, ".pdf")
      cli::cli_warn(
        "Output file did not have .rtf extension. Creating PDF as: {.file {basename(pdf_file)}}"
      )
    }
    build_pdf_internal(data = data, pdf_file = pdf_file, keep_tex = keep_tex)
  } else if (pdf && !is_streaming) {
    cli::cli_warn(
      "PDF generation is skipped because no output `file` was specified."
    )
  }

  return(rtf_output)
}

#' @export
#' @rdname build_rtf
build_rtf.rtf_fig <- function(
  data,
  file = NULL,
  pdf = TRUE,
  keep_tex = FALSE,
  ...
) {
  # --- Handle PDF-only output request ---
  if (!is.null(file) && tolower(tools::file_ext(file)) == "pdf") {
    return(build_pdf_internal(data, file, keep_tex = keep_tex))
  }

  # --- 1. Pre-computation and Setup ---
  options_list <- util_options_to_list(data)
  opt_orientation <- options_list[["page_orientation"]]
  opt_title_font_size <- options_list[["title_font_size"]]
  opt_title_bold <- options_list[["title_bold"]]
  opt_hf_font_size <- options_list[["hf_font_size"]]

  margin_twips <- util_rtf_margin(data)
  paper_size_twips <- util_rtf_paper_size(data, opt_orientation)
  content_width_twips <- paper_size_twips[["width"]] -
    sum(margin_twips[c("left", "right")])
  fs_val_title <- util_rtf_fsize(data, opt_title_font_size)
  fs_val_hf <- util_rtf_fsize(data, opt_hf_font_size)

  has_footer <- util_dttype_exists(data, "_footer") ||
    util_dttype_exists(data, "_sys_footer")

  plots <- util_rtf_dt_get(data, "_plots")
  plot_dims <- util_rtf_dt_get(data, "_plot_dims")
  total_pages <- length(plots)

  # MODIFIED: Direct call to specific layout function
  page_layout <- util_calculate_figure_layout(data)

  # --- 2. Generate Static RTF Components ---
  setup_component <- rtf_raw(
    rtf_str_init(data),
    rtf_str_fonttbl(data),
    rtf_str_colortbl(),
    rtf_str_stylesheet(
      fs = fs_val_hf,
      margin = margin_twips,
      size = paper_size_twips
    )
  )

  num_header_lines <- if (util_dttype_exists(data, "_header")) {
    nrow(util_rtf_dt_get(data, "_header"))
  } else {
    0
  }

  dynamic_headery_value <- util_rtf_dynamic_headery(
    num_header_lines = num_header_lines,
    header_fs_val = fs_val_hf,
    top_margin_twips = margin_twips[["top"]]
  )

  full_header_rtf <- if (util_dttype_exists(data, "_header")) {
    rtf_str_header_footer(
      data,
      type = "header",
      fs = fs_val_hf,
      tbl_width = content_width_twips
    )
  } else {
    ""
  }
  full_footer_rtf <- if (has_footer) {
    rtf_str_header_footer(
      data,
      type = "footer",
      fs = fs_val_hf,
      tbl_width = content_width_twips
    )
  } else {
    ""
  }

  # --- 3. Assemble and Write/Return Page Components ---
  is_streaming <- !is.null(file)
  if (is_streaming) {
    con <- file(file, "wb")
    on.exit(close(con), add = TRUE)
    writeLines(setup_component, con, useBytes = TRUE)
  } else {
    page_components <- vector("list", total_pages)
  }

  for (i in seq_len(total_pages)) {
    plot_obj <- plots[[i]]

    # The fix is to wrap the list in tibble::tibble() so that dplyr::left_join
    # inside util_abs_len_to_twips receives a data frame, not a list.
    width_twips <- if (!is.na(plot_dims$width)) {
      util_abs_len_to_twips(tibble::tibble(
        value = plot_dims$width,
        unit = plot_dims$units
      ))$value
    } else {
      NA
    }

    height_twips <- if (!is.na(plot_dims$height)) {
      util_abs_len_to_twips(tibble::tibble(
        value = plot_dims$height,
        unit = plot_dims$units
      ))$value
    } else {
      NA
    }

    scaled_dims <- util_scale_figure(
      plot_obj,
      width_twips,
      height_twips,
      page_layout$available_width,
      page_layout$available_height
    )

    temp_png <- tempfile(fileext = ".png")
    ggplot2::ggsave(
      filename = temp_png,
      plot = plot_obj,
      width = scaled_dims$width / 1440,
      height = scaled_dims$height / 1440,
      units = "in",
      dpi = 300,
      bg = "white"
    )
    on.exit(unlink(temp_png), add = TRUE, after = FALSE)

    figure_hex <- rtf_read_figure(temp_png)

    sect_header_rtf <- if (i == 1) full_header_rtf else ""
    sect_footer_rtf <- if (i == 1) full_footer_rtf else ""

    section_def_comp <- rtf_str_sect_def(
      i,
      sect_header_rtf,
      sect_footer_rtf,
      margin_twips,
      paper_size_twips,
      opt_orientation,
      dynamic_headery_value
    )
    bookmark_comp <- rtf_str_bookmark(
      if (i == 1) "IDX" else paste0("IDX", i - 1)
    )
    title_comp <- rtf_str_title_block(
      data,
      i,
      total_pages,
      fs_val_title,
      opt_title_bold,
      content_width_twips
    )

    figure_comp <- rtf_str_figure(
      figure_hex,
      scaled_dims$width,
      scaled_dims$height
    )

    current_page_rtf <- rtf_raw(
      section_def_comp,
      bookmark_comp,
      title_comp,
      # Add a blank paragraph after the title block for spacing, if a title exists
      if (nzchar(title_comp)) "{\\pard\\par}\n" else "",
      figure_comp
    )

    if (is_streaming) {
      writeLines(current_page_rtf, con, useBytes = TRUE)
    } else {
      page_components[[i]] <- current_page_rtf
    }
  }

  # --- 4. Finalize and Return RTF ---
  final_close <- "}\n"
  rtf_output <- if (is_streaming) {
    writeLines(final_close, con, useBytes = TRUE)
    invisible(file)
  } else {
    rtf_raw(
      setup_component,
      paste(page_components, collapse = ""),
      final_close
    )
  }

  # --- 5. Build PDF if requested ---
  if (pdf && !is.null(file)) {
    pdf_file <- sub("\\.rtf$", ".pdf", file, ignore.case = TRUE)
    if (pdf_file == file) {
      pdf_file <- paste0(file, ".pdf")
      cli::cli_warn(
        "Output file did not have .rtf extension. Creating PDF as: {.file {basename(pdf_file)}}"
      )
    }
    build_pdf_internal(data = data, pdf_file = pdf_file, keep_tex = keep_tex)
  } else if (pdf && !is_streaming) {
    cli::cli_warn(
      "PDF generation is skipped because no output `file` was specified."
    )
  }

  return(rtf_output)
}
