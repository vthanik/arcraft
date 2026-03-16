# RTF Render — pure R, uses arframe

fct_render_rtf <- function(tbl, fmt, path) {
  tc <- fmt$titles; col <- fmt$cols; pg <- fmt$page

  spec <- tbl |> arframe::fr_table()

  if (length(tc$titles) > 0) {
    spec <- do.call(arframe::fr_titles,
      c(list(spec), as.list(tc$titles),
        list(population = tc$population, .align = tc$align)))
  }
  if (length(tc$footnotes) > 0) {
    spec <- do.call(arframe::fr_footnotes, c(list(spec), as.list(tc$footnotes)))
  }

  spec <- spec |>
    arframe::fr_cols(
      param = arframe::fr_col(label = "Parameter", width = col$stub_width, align = "left"),
      .align = col$body_align) |>
    arframe::fr_header(bold = TRUE, align = "center") |>
    arframe::fr_hlines(preset = pg$hline_preset) |>
    arframe::fr_page(orientation = pg$orientation, paper = pg$paper,
      font_size = pg$font_size, font_family = pg$font_family)

  arframe::fr_render(spec, path)
}
