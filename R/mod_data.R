#' Data Module — source selector (compact, for config accordion)
#'
#' Data viewer is in the canvas (right panel) — purely exploratory.
#' @return list(datasets, filtered, active_ds)
mod_data_ui <- function(id) {
  ns <- shiny::NS(id)
  sample_path <- file.path(getwd(), "..", "adam_pilot", "data")
  sample_choices <- if (dir.exists(sample_path)) {
    gsub("\\.rds$", "", list.files(sample_path, pattern = "\\.rds$"))
  } else character(0)

  htmltools::tagList(
    htmltools::tags$div(class = "ar-data-source",
      shiny::selectInput(ns("ds"), NULL, choices = sample_choices,
        selected = intersect("adsl", sample_choices), multiple = TRUE,
        width = "100%"),
      htmltools::tags$div(class = "ar-data-source__actions",
        shiny::actionButton(ns("load"), "Load", class = "ar-btn-primary btn-sm"),
        htmltools::tags$label(class = "ar-btn-outline btn-sm ar-upload-label",
          shiny::icon("upload"), " Upload",
          shiny::fileInput(ns("files"), NULL, multiple = TRUE,
            accept = c(".csv", ".rds"))
        )
      ),
      shiny::uiOutput(ns("ds_pills"))
    ),
    shiny::uiOutput(ns("active_ds_ui"))
  )
}

mod_data_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    sample_path <- normalizePath(
      file.path(getwd(), "..", "adam_pilot", "data"), mustWork = FALSE)
    datasets <- shiny::reactiveVal(list())

    # ── Auto-load ADSL ──
    loaded_once <- FALSE
    shiny::observe({
      if (!loaded_once) {
        loaded_once <<- TRUE
        path <- file.path(sample_path, "adsl.rds")
        if (file.exists(path)) datasets(list(adsl = readRDS(path)))
      }
    })

    # ── Manual Load ──
    shiny::observeEvent(input$load, {
      shiny::req(input$ds)
      loaded <- purrr::map(input$ds, function(nm) {
        p <- file.path(sample_path, paste0(nm, ".rds"))
        if (file.exists(p)) readRDS(p) else NULL
      }) |> purrr::compact() |> stats::setNames(input$ds)
      datasets(loaded)
    })

    # ── Upload ──
    shiny::observeEvent(input$files, {
      shiny::req(input$files)
      loaded <- purrr::map(seq_len(nrow(input$files)), function(i) {
        fi <- input$files[i, ]
        ext <- tolower(tools::file_ext(fi$name))
        if (ext == "rds") readRDS(fi$datapath)
        else if (ext == "csv") readr::read_csv(fi$datapath, show_col_types = FALSE)
      }) |> stats::setNames(tools::file_path_sans_ext(input$files$name))
      current <- datasets()
      datasets(c(current, loaded))
    })

    # ── Dataset pills ──
    output$ds_pills <- shiny::renderUI({
      ds <- datasets()
      shiny::req(length(ds) > 0)
      pills <- purrr::imap(ds, function(d, nm) {
        htmltools::tags$span(class = "ar-pill ar-pill--accent",
          sprintf("%s %s\u00d7%s", toupper(nm), format(nrow(d), big.mark = ","), ncol(d)))
      })
      htmltools::tags$div(class = "ar-ds-pills", pills)
    })

    # ── Active dataset selector ──
    output$active_ds_ui <- shiny::renderUI({
      ds <- datasets()
      shiny::req(length(ds) > 1)
      shiny::selectInput(ns("active_ds"), "Active Dataset",
        choices = names(ds), selected = names(ds)[1], width = "100%")
    })

    active_ds_val <- shiny::reactive({
      ds <- datasets()
      if (length(ds) == 0) return(NULL)
      if (length(ds) == 1) return(names(ds)[1])
      input$active_ds %||% names(ds)[1]
    })

    # filtered() = raw datasets (no filtering here — viewer is exploratory only)
    list(
      datasets = datasets,
      filtered = datasets,
      active_ds = active_ds_val
    )
  })
}
