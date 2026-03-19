#' Create an `rtf_fig` Object for RTF Document Generation
#'
#' @description
#' This function is the entry point for creating figure-based RTF documents.
#' It takes one or more `ggplot` objects and prepares them for rendering by
#' storing them in a specialized `rtf_fig` object. This object can then be
#' further customized with titles, headers, and footers before being built into
#' a final RTF document.
#'
#' @param plot A single `ggplot` object or a list of `ggplot` objects. Each plot
#'   will be rendered on a separate page.
#' @param width The desired width of the plot(s) in the output document.
#'   If `NA` (default), the width will be scaled to fit the page margins.
#' @param height The desired height of the plot(s). If `NA` (default), the
#'   height will be scaled to fit the page margins while respecting the aspect
#'   ratio.
#' @param units The units for the specified `width` and `height`.
#'   Must be one of `"in"`, `"cm"`, `"mm"`, or `"px"`. Defaults to `"in"`.
#' @param add_default_footer `[logical(1)]` If `TRUE` (default), a standard
#'   system footer with the source file path and timestamp is added.
#'
#' @return An S3 object of class `rtf_fig`.
#' @export
#'
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(mpg, wt)) + geom_point()
#'
#' # Create a figure object with default sizing
#' fig_obj <- rtf_figure(p)
#'
#' # Create a multi-plot figure object with specified dimensions
#' # This will generate a two-page RTF document.
#' p2 <- ggplot(iris, aes(Sepal.Length, Petal.Length)) + geom_point()
#' fig_obj_multi <- rtf_figure(list(p, p2), width = 6, height = 4)
#'
rtf_figure <- function(
  plot,
  width = NA,
  height = NA,
  units = c("in", "cm", "mm", "px"),
  add_default_footer = TRUE
) {
  # --- 1. Input Validation and Processing ---
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort(
      "The {.pkg ggplot2} package is required to create figures."
    )
  }
  units <- rlang::arg_match(units)

  if (rlang::is_bare_list(plot)) {
    plots <- purrr::list_flatten(plot)
  } else {
    plots <- list(plot)
  }

  is_gg <- purrr::map_lgl(plots, ~ inherits(.x, "ggplot"))
  if (!all(is_gg)) {
    cli::cli_abort(
      "All items provided to `plot` must be {.cls ggplot} objects."
    )
  }

  # --- 2. Initialize the `rtf_fig` Object ---
  rtf_dt <- list()
  class(rtf_dt) <- c("rtf_fig", "rtf_doc", "list")

  rtf_dt[["_plots"]] <- plots
  rtf_dt[["_plot_dims"]] <- list(
    width = width,
    height = height,
    units = units
  )

  # --- 3. Set Up Options and Components ---
  # MODIFIED: Use the new defaults-generating function
  rtf_dt <- util_rtf_options_init(rtf_dt, defaults_fun = rtf_defaults_figure)

  rtf_dt <- util_rtf_component_init(rtf_dt, "_title")
  rtf_dt <- util_rtf_component_init(rtf_dt, "_header")
  rtf_dt <- util_rtf_component_init(rtf_dt, "_footer")
  rtf_dt <- util_rtf_component_init(rtf_dt, "_sys_footer")

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

  return(rtf_dt)
}
