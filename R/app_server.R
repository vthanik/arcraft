#' App Server
app_server <- function(input, output, session) {

 # ── Data Layer ──────────────────────────────────────
 data_out <- mod_data_server("data")

 # ── Analysis Layer ──────────────────────────────────
 analysis   <- mod_analysis_server("analysis", data_out$datasets)
 grouping   <- mod_grouping_server("grouping", data_out, analysis)
 stats_cfg  <- mod_stats_server("stats", analysis)

 # ── ARD (computed on Generate Preview) ──────────────
 ard <- shiny::reactive({
   fd <- data_out$filtered()
   g <- grouping()
   s <- stats_cfg()
   shiny::req(fd, g, s, length(g$analysis_vars) > 0)
   adsl <- get_adsl(fd)
   shiny::req(adsl)
   fct_ard_demog(adsl, g, s)
 }) |> shiny::bindEvent(input$preview_btn, ignoreNULL = TRUE)

 # ── Format Layer ────────────────────────────────────
 titles_cfg <- mod_titles_server("titles")
 cols_cfg   <- mod_columns_server("cols")
 page_cfg   <- mod_page_server("page")

 fmt <- shiny::reactive({
   list(titles = titles_cfg(), cols = cols_cfg(), page = page_cfg())
 })

 # ── Table Preview (canvas) ──────────────────────────
 mod_preview_server("preview", ard, fmt)

 # ── ARD Data (canvas tab) ───────────────────────────
 output$ard_view <- shiny::renderUI({
   tbl <- tryCatch(ard(), error = function(e) NULL)
   if (is.null(tbl) || nrow(tbl) == 0) {
     return(htmltools::tags$div(class = "ar-empty",
       htmltools::tags$div(class = "ar-empty__title", "No ARD data yet"),
       htmltools::tags$div(class = "ar-empty__desc",
         "Press Generate Preview to compute the analysis results.")))
   }
   htmltools::tags$div(class = "ar-fade-in",
     htmltools::tags$div(class = "d-flex align-items-center gap-2 mb-2",
       htmltools::tags$span(class = "ar-pill ar-pill--accent",
         sprintf("%d rows \u00d7 %d cols", nrow(tbl), ncol(tbl)))),
     reactable::reactable(tbl, compact = TRUE, bordered = TRUE, striped = TRUE,
       defaultPageSize = 50, highlight = TRUE, wrap = FALSE,
       theme = reactable::reactableTheme(
         headerStyle = list(fontSize = "12px", fontWeight = 600,
           borderBottom = "2px solid #e5e4e2"),
         cellStyle = list(fontSize = "12px",
           fontFamily = "'JetBrains Mono', monospace"))))
 })

 # ── Canvas Data Viewer (full wrangler) ─
 mod_data_viewer_server("data_viewer", data_out)

 # ── Code ────────────────────────────────────────────
 code_text <- shiny::reactive({
   fd <- data_out$filtered()
   g <- grouping()
   s <- stats_cfg()
   f <- fmt()
   shiny::req(fd, g, s, f)
   pop <- list(datasets = fd, flag_var = "SAFFL", flag_val = "Y")
   fct_codegen(pop, g, s, f)
 }) |> shiny::bindEvent(input$preview_btn, ignoreNULL = TRUE)

 mod_code_server("code", code_text)

 # ── Downloads ───────────────────────────────────────
 output$export_rtf <- shiny::downloadHandler(
   filename = function() paste0("table_", format(Sys.Date(), "%Y%m%d"), ".rtf"),
   content = function(file) {
     tbl <- ard()
     f <- fmt()
     shiny::req(tbl, nrow(tbl) > 0, f)
     fct_render_rtf(tbl, f, file)
   }
 )

 output$dl_script <- shiny::downloadHandler(
   filename = function() paste0("pipeline_", format(Sys.Date(), "%Y%m%d"), ".R"),
   content = function(file) {
     script <- code_text()
     shiny::req(script)
     writeLines(script, file)
   }
 )
}

#' Extract ADSL from dataset list
get_adsl <- function(datasets) {
  nm <- intersect(c("adsl", "ADSL"), names(datasets))
  if (length(nm) > 0) datasets[[nm[1]]] else NULL
}
