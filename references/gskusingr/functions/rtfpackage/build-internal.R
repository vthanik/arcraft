#' (Internal) Build and Write a PDF Document
#'
#' @description
#' This is an un-exported helper called by `build_rtf`. It assumes that the
#' layout for the `data` object has already been calculated and cached.
#'
#' @param data A fully-prepared `rtf_doc` object (`rtf_tbl` or `rtf_fig`).
#' @param pdf_file The target file path for the PDF output.
#' @param keep_tex `[logical(1)]` Whether to keep the intermediate `.tex` file.
#'
#' @return Invisibly returns the path to the generated PDF.
#' @noRd
build_pdf_internal <- function(data, pdf_file, keep_tex = FALSE) {
  # --- 1. Pre-flight Checks ---
  if (!requireNamespace("tinytex", quietly = TRUE)) {
    cli::cli_warn(c(
      "A LaTeX distribution is required to build PDFs.",
      "i" = "The recommended method is to install the {.pkg tinytex} package and run {.fn tinytex::install_tinytex}.",
      "i" = "Attempting to compile using system LaTeX, which may fail if not installed."
    ))
  }
  if (
    inherits(data, "rtf_fig") && !requireNamespace("ggplot2", quietly = TRUE)
  ) {
    cli::cli_abort("The {.pkg ggplot2} package is required to build figures.")
  }

  # --- 2. Generate LaTeX Components ---
  preamble_comp <- pdf_str_preamble(data)
  hf_comp <- pdf_str_header_footer(data)

  # --- 3. Assemble Full Document Body ---
  doc_body_components <- vector("list")
  title_comp_str <- pdf_str_title_block(data)
  is_first_page_overall <- TRUE

  if (inherits(data, "rtf_tbl")) {
    # --- TABLE LOGIC ---
    page_info <- util_rtf_dt_get(data, "_layout")
    page_split_info <- util_rtf_dt_get(data, "_page_split")
    num_col_pages <- if (!is.null(page_split_info)) nrow(page_split_info) else 1

    if (nrow(page_info) == 0) {
      page_info <- tibble::tibble(
        row_start = 0,
        row_end = -1,
        page_heading_text = NA_character_
      )
    }

    # Loop through each vertical page chunk (defined by row pagination)
    for (i in seq_len(nrow(page_info))) {
      page_spec <- page_info[i, ]
      row_ids <- if (page_spec$row_start <= page_spec$row_end) {
        seq(page_spec$row_start, page_spec$row_end)
      } else {
        integer(0)
      }

      page_heading_text <- page_spec$page_heading_text
      page_heading_comp_str <- if (
        !is.na(page_heading_text) && nzchar(page_heading_text)
      ) {
        pdf_str_page_heading_block(data, page_heading_text)
      } else {
        ""
      }

      # Loop through each horizontal page chunk (defined by column splits)
      for (j in seq_len(num_col_pages)) {
        if (!is_first_page_overall) {
          doc_body_components <- c(doc_body_components, "\\clearpage")
        }
        is_first_page_overall <- FALSE

        if (nzchar(title_comp_str)) {
          doc_body_components <- c(doc_body_components, title_comp_str)
        }
        if (nzchar(page_heading_comp_str)) {
          doc_body_components <- c(doc_body_components, page_heading_comp_str)
        }

        current_vars <- if (num_col_pages > 1) {
          page_split_info$vars[[j]]
        } else {
          NULL
        }
        table_comp <- pdf_str_table(
          data = data,
          row_ids = row_ids,
          vars = current_vars,
          page_group_id = if (
            "..rtf_page_group_id.." %in%
              names(util_rtf_dt_get(data, "_data")) &&
              length(row_ids) > 0
          ) {
            util_rtf_dt_get(data, "_data")$..rtf_page_group_id..[row_ids[1]]
          } else {
            NULL
          },
          is_last_page_chunk = (i == nrow(page_info) && j == num_col_pages)
        )
        doc_body_components <- c(doc_body_components, table_comp)
      }
    }
  } else if (inherits(data, "rtf_fig")) {
    # --- FIGURE LOGIC ---
    plots <- util_rtf_dt_get(data, "_plots")
    plot_dims <- util_rtf_dt_get(data, "_plot_dims")
    page_layout <- util_calculate_figure_layout(data)
    temp_files <- c()
    on.exit(unlink(temp_files[file.exists(temp_files)]), add = TRUE)

    for (i in seq_along(plots)) {
      if (!is_first_page_overall) {
        doc_body_components <- c(doc_body_components, "\\clearpage")
      }
      is_first_page_overall <- FALSE

      if (nzchar(title_comp_str)) {
        doc_body_components <- c(doc_body_components, title_comp_str)
      }

      plot_obj <- plots[[i]]
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
      temp_files <- c(temp_files, temp_png)
      ggplot2::ggsave(
        filename = temp_png,
        plot = plot_obj,
        width = scaled_dims$width / 1440,
        height = scaled_dims$height / 1440,
        units = "in",
        dpi = 300,
        bg = "white"
      )

      figure_comp <- pdf_str_figure(
        file_path = temp_png,
        width_in = scaled_dims$width / 1440,
        height_in = scaled_dims$height / 1440
      )
      doc_body_components <- c(doc_body_components, figure_comp)
    }
  }

  # --- 4. Combine, Write, and Compile ---
  full_latex_doc <- paste(
    preamble_comp,
    hf_comp,
    "\\begin{document}",
    paste(unlist(doc_body_components), collapse = "\n\n"),
    "\\end{document}",
    sep = "\n\n"
  )

  tex_file <- sub("\\.pdf$", ".tex", pdf_file, ignore.case = TRUE)
  writeLines(full_latex_doc, tex_file)

  tryCatch(
    {
      tinytex::xelatex(tex_file, pdf_file = pdf_file, clean = !keep_tex)
    },
    error = function(e) {
      cli::cli_abort(
        c(
          "LaTeX compilation failed.",
          "x" = "An error occurred while running xelatex.",
          "i" = "Check the log file for details: {.file {sub('.pdf$', '.log', pdf_file, ignore.case = TRUE)}}",
          "i" = "Set `keep_tex = TRUE` in `build_rtf()` to inspect the intermediate {.file {basename(tex_file)}}."
        ),
        parent = e
      )
    }
  )

  # Final cleanup if tinytex didn't do it
  if (!keep_tex && file.exists(tex_file)) {
    base_name <- sub("\\.tex$", "", tex_file, ignore.case = TRUE)
    aux_files <- paste0(base_name, c(".aux", ".log", ".out"))
    suppressWarnings(file.remove(aux_files[file.exists(aux_files)]))
    suppressWarnings(file.remove(tex_file))
  }

  invisible(pdf_file)
}
