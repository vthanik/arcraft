# Listing builder — pure R, no Shiny
# Formats raw data for subject-level listings (16.2.x)

fct_build_listing <- function(data, listing_config) {
  stopifnot("Data required" = !is.null(data))

  cols <- listing_config$columns %||% names(data)
  sort_by <- listing_config$sort_by %||% "USUBJID"
  col_labels <- listing_config$col_labels %||% list()
  max_rows <- listing_config$max_rows %||% Inf

  # Select and order columns
  available_cols <- intersect(cols, names(data))
  if (length(available_cols) == 0) available_cols <- names(data)[1:min(5, ncol(data))]

  listing <- data[, available_cols, drop = FALSE]

  # Apply sorting
  sort_cols <- intersect(sort_by, names(listing))
  if (length(sort_cols) > 0) {
    order_args <- lapply(sort_cols, function(col) listing[[col]])
    listing <- listing[do.call(order, order_args), ]
  }

  # Apply row limit
  if (nrow(listing) > max_rows) {
    listing <- listing[seq_len(max_rows), ]
  }

  # Apply column labels
  for (col in names(col_labels)) {
    if (col %in% names(listing)) {
      attr(listing[[col]], "label") <- col_labels[[col]]
    }
  }

  # Format all columns as character for consistent display
  for (col in names(listing)) {
    if (is.numeric(listing[[col]])) {
      listing[[col]] <- format(listing[[col]], nsmall = 0)
    } else if (inherits(listing[[col]], "Date")) {
      listing[[col]] <- format(listing[[col]], "%Y-%m-%d")
    } else {
      listing[[col]] <- as.character(listing[[col]])
    }
  }

  listing
}

# Render listing as RTF via arframe
fct_render_listing <- function(listing, format_cfg, path) {
  spec <- listing |> arframe::fr_table()

  # Titles
  titles <- format_cfg$titles
  if (length(titles) > 0) {
    title_texts <- vapply(titles, function(t) t$text %||% as.character(t), character(1))
    spec <- do.call(arframe::fr_titles, c(list(spec), as.list(title_texts)))
  }

  # Page — listings need smaller font for more columns
  page <- format_cfg$page %||% list()
  spec <- arframe::fr_page(spec,
    orientation = page$orientation %||% "landscape",
    paper = page$paper %||% "letter",
    font_family = page$font_family %||% "Courier New",
    font_size = page$font_size %||% 8,
    margins = page$margins %||% c(0.75, 0.75, 0.75, 0.75)
  )

  # Header
  spec <- arframe::fr_header(spec, bold = TRUE, align = "left")

  # Rules — listings use header rules only
  spec <- arframe::fr_hlines(spec, "header")

  # Footnotes
  footnotes <- format_cfg$footnotes
  if (length(footnotes) > 0) {
    fn_texts <- vapply(footnotes, function(f) f$text %||% as.character(f), character(1))
    spec <- do.call(arframe::fr_footnotes, c(list(spec), as.list(fn_texts)))
  }

  arframe::fr_render(spec, path)
  path
}
