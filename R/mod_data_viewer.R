# Module: Data Viewer — Toggle between Columns and Data views

mod_data_viewer_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tags$div(class = "ar-dv",
    # Toolbar
    htmltools::tags$div(class = "ar-dv__toolbar",
      htmltools::tags$span(class = "ar-dv__toolbar-label",
        shiny::textOutput(ns("active_ds_name"), inline = TRUE)
      ),
      # Toggle buttons
      htmltools::tags$div(class = "ar-dv__view-toggle",
        htmltools::tags$button(
          id = ns("view_cols"),
          class = "ar-btn-ghost ar-btn--xs ar-dv__tab ar-dv__tab--active",
          onclick = paste0(
            "document.getElementById('", ns("panel_cols"), "').classList.remove('ar-dv__hide');",
            "document.getElementById('", ns("panel_data"), "').classList.add('ar-dv__hide');",
            "this.classList.add('ar-dv__tab--active');",
            "document.getElementById('", ns("view_data"), "').classList.remove('ar-dv__tab--active');"),
          "Columns"
        ),
        htmltools::tags$button(
          id = ns("view_data"),
          class = "ar-btn-ghost ar-btn--xs ar-dv__tab",
          onclick = paste0(
            "document.getElementById('", ns("panel_data"), "').classList.remove('ar-dv__hide');",
            "document.getElementById('", ns("panel_cols"), "').classList.add('ar-dv__hide');",
            "this.classList.add('ar-dv__tab--active');",
            "document.getElementById('", ns("view_cols"), "').classList.remove('ar-dv__tab--active');"),
          "Data"
        )
      ),
      # Clear filters button
      htmltools::tags$button(
        class = "ar-btn-ghost ar-btn--xs",
        onclick = paste0(
          "if(window.Reactable){Reactable.setAllFilters('", ns("grid"), "',[]);}",
          "else{document.querySelectorAll('#", ns("grid"), " .rt-th input').forEach(function(i){",
          "var s=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;",
          "s.call(i,'');i.dispatchEvent(new Event('input',{bubbles:true}));});}"),
        "Clear Filters"
      ),
      htmltools::tags$div(class = "ar-dv__dims",
        shiny::textOutput(ns("viewer_dims"), inline = TRUE)
      ),
      shiny::downloadButton(ns("csv_download"), label = NULL,
        class = "ar-btn-ghost",
        icon = htmltools::tags$i(class = "fa fa-download")
      )
    ),
    # Columns panel (default visible)
    htmltools::tags$div(id = ns("panel_cols"), class = "ar-dv__panel",
      reactable::reactableOutput(ns("col_attrs"))
    ),
    # Data panel (visually hidden by default, still renders)
    htmltools::tags$div(id = ns("panel_data"), class = "ar-dv__panel ar-dv__hide",
      reactable::reactableOutput(ns("grid"))
    )
  )
}

mod_data_viewer_server <- function(id, store) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    col_attrs_cache <- shiny::reactiveValues()

    viewer_data <- shiny::reactive({
      ds <- store$active_ds
      shiny::req(ds, store$datasets[[ds]])
      store$datasets[[ds]]
    })

    shiny::observe({
      for (nm in names(store$datasets)) {
        if (!is.null(col_attrs_cache[[nm]])) next
        d <- store$datasets[[nm]]
        attrs <- data.frame(
          No = seq_len(ncol(d)),
          Name = names(d),
          Type = vapply(d, function(x) {
            if (is.numeric(x)) "NUM"
            else if (inherits(x, "Date") || inherits(x, "POSIXt")) "DATE"
            else "CHR"
          }, character(1)),
          Label = vapply(d, function(x) attr(x, "label") %||% "", character(1)),
          Unique = vapply(d, function(x) length(unique(stats::na.omit(x))), integer(1)),
          Missing = vapply(d, function(x) sum(is.na(x)), integer(1)),
          stringsAsFactors = FALSE
        )
        rownames(attrs) <- NULL
        col_attrs_cache[[nm]] <- attrs
      }
    })

    output$active_ds_name <- shiny::renderText({
      ds <- store$active_ds
      if (is.null(ds) || !nzchar(ds)) "No dataset" else toupper(ds)
    })

    output$viewer_dims <- shiny::renderText({
      d <- viewer_data()
      paste0(format(nrow(d), big.mark = ","), " rows \u00d7 ", ncol(d), " cols")
    })

    # ── Columns ──
    output$col_attrs <- reactable::renderReactable({
      ds <- store$active_ds
      shiny::req(ds)
      attrs <- col_attrs_cache[[ds]]
      shiny::req(attrs)

      reactable::reactable(
        attrs,
        columns = list(
          No = reactable::colDef(name = "#", width = 36, align = "right",
            style = list(color = "var(--fg-muted)", fontSize = "10px")),
          Name = reactable::colDef(width = 120,
            style = list(fontWeight = 500, fontFamily = "var(--font-mono)", fontSize = "11.5px")),
          Type = reactable::colDef(width = 55, align = "center",
            cell = function(value) ui_type_badge(value)),
          Label = reactable::colDef(width = 200,
            style = list(color = "var(--fg-3)", fontSize = "11px")),
          Unique = reactable::colDef(width = 55, align = "right",
            style = list(fontFamily = "var(--font-mono)", fontSize = "11px")),
          Missing = reactable::colDef(width = 55, align = "right",
            cell = function(value) if (value == 0) "\u2014" else as.character(value),
            style = list(fontFamily = "var(--font-mono)", fontSize = "11px"))
        ),
        theme = ar_grid_theme(),
        sortable = TRUE, filterable = TRUE, pagination = FALSE, compact = TRUE,
        highlight = TRUE, fullWidth = FALSE
      )
    })

    # ── Data ──
    output$grid <- reactable::renderReactable({
      d <- viewer_data()
      shiny::req(nrow(d) > 0)
      ar_build_reactable(d)
    })

    output$csv_download <- shiny::downloadHandler(
      filename = function() paste0(store$active_ds %||% "data", "_", Sys.Date(), ".csv"),
      content = function(file) readr::write_csv(viewer_data(), file)
    )
  })
}
