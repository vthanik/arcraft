#' Launch arbuilder
#'
#' @param port Port number. NULL for random.
#' @param launch.browser Open browser? Default TRUE.
#' @export
launch <- function(port = NULL, launch.browser = TRUE) {
  shiny::addResourcePath("www", system.file("app/www", package = "arbuilder"))
  app <- shiny::shinyApp(ui = app_ui(), server = app_server)
  args <- list(appDir = app, launch.browser = launch.browser)
  if (!is.null(port)) args$port <- port
  do.call(shiny::runApp, args)
}
