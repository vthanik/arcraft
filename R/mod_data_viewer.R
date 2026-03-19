# Module: Data Viewer — VS Code Data Wrangler-style grid

mod_data_viewer_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tags$div(class = "ar-dv",
    # Toolbar
    htmltools::tags$div(class = "ar-dv__toolbar",
      htmltools::tags$span(class = "ar-dv__toolbar-label",
        shiny::textOutput(ns("active_ds_name"), inline = TRUE)
      ),
      htmltools::tags$input(
        type = "text", class = "ar-dv__search",
        id = ns("col_search"),
        placeholder = "Search columns...",
        oninput = paste0("Shiny.setInputValue('", ns("col_search"), "', this.value, {priority: 'event'})")
      ),
      htmltools::tags$div(class = "ar-dv__dims",
        shiny::textOutput(ns("viewer_dims"), inline = TRUE)
      ),
      shiny::downloadButton(ns("csv_download"), label = NULL,
        class = "ar-btn-ghost",
        icon = htmltools::tags$i(class = "fa fa-download")
      )
    ),
    # Grid
    htmltools::tags$div(class = "ar-dv__grid",
      reactable::reactableOutput(ns("grid"))
    )
  )
}

mod_data_viewer_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Show active dataset name in toolbar
    output$active_ds_name <- shiny::renderText({
      ds <- store$active_ds
      if (is.null(ds) || !nzchar(ds)) "No dataset" else toupper(ds)
    })

    # Reactive data for the grid — uses store$active_ds + explore_filters
    viewer_data <- shiny::reactive({
      ds <- store$active_ds
      shiny::req(ds, store$datasets[[ds]])
      d <- store$datasets[[ds]]

      # Apply explore filters
      filts <- store$explore_filters
      if (length(filts) > 0) {
        for (col in names(filts)) {
          if (!col %in% names(d)) next
          f <- filts[[col]]
          if (f$type == "range") {
            d <- d[!is.na(d[[col]]) & d[[col]] >= f$min & d[[col]] <= f$max, , drop = FALSE]
          } else if (f$type == "date_range") {
            d <- d[!is.na(d[[col]]) & d[[col]] >= as.Date(f$min) & d[[col]] <= as.Date(f$max), , drop = FALSE]
          } else if (f$type == "checkbox") {
            d <- d[as.character(d[[col]]) %in% f$selected, , drop = FALSE]
          }
        }
      }
      d
    })

    # Scroll to column on search (instead of filtering)
    shiny::observeEvent(input$col_search, {
      search <- input$col_search
      if (!is.null(search) && nzchar(search)) {
        session$sendCustomMessage("ar_scroll_to_col", list(col = search))
      }
    })

    # Dimensions — show filtered indicator
    output$viewer_dims <- shiny::renderText({
      d <- viewer_data()
      n_shown <- nrow(d)
      ds <- store$active_ds
      n_total <- if (!is.null(ds) && !is.null(store$datasets[[ds]])) nrow(store$datasets[[ds]]) else n_shown
      filts <- store$explore_filters
      suffix <- if (length(filts) > 0 && n_shown < n_total) " (filtered)" else ""
      paste0(format(n_shown, big.mark = ","), " rows \u00d7 ", ncol(d), " cols", suffix)
    })

    # Reactable grid
    output$grid <- reactable::renderReactable({
      d <- viewer_data()
      shiny::req(nrow(d) > 0)
      ar_build_reactable(d)
    })

    # CSV download
    output$csv_download <- shiny::downloadHandler(
      filename = function() {
        paste0(store$active_ds %||% "data", "_", Sys.Date(), ".csv")
      },
      content = function(file) {
        d <- viewer_data()
        readr::write_csv(d, file)
      }
    )
  })
}
