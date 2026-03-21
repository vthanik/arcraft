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
      shiny::uiOutput(ns("col_pager")),
      reactable::reactableOutput(ns("col_attrs"))
    ),
    # Data panel (visually hidden by default, still renders)
    htmltools::tags$div(id = ns("panel_data"), class = "ar-dv__panel ar-dv__hide",
      shiny::uiOutput(ns("grid_pager")),
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

    # Lazy metadata — only compute for the active dataset when first viewed
    get_col_attrs <- function(nm) {
      if (!is.null(col_attrs_cache[[nm]])) return(col_attrs_cache[[nm]])
      d <- store$datasets[[nm]]
      if (is.null(d)) return(NULL)
      classes <- vapply(d, function(x) class(x)[1L], character(1))
      n <- nrow(d)
      attrs <- data.frame(
        No = seq_len(ncol(d)),
        Name = names(d),
        Type = ifelse(classes %in% c("numeric", "integer", "double"), "NUM",
                 ifelse(classes %in% c("Date", "POSIXct", "POSIXlt"), "DATE", "CHR")),
        Label = vapply(d, function(x) attr(x, "label") %||% "", character(1)),
        Unique = as.integer(collapse::fndistinct(d)),
        Missing = as.integer(n - collapse::fnobs(d)),
        stringsAsFactors = FALSE
      )
      rownames(attrs) <- NULL
      col_attrs_cache[[nm]] <- attrs
      attrs
    }

    # Lazy unique values — computed on-demand per column when row is expanded
    get_col_uniques <- function(ds_name, col_name, type, n_unique) {
      if (type != "CHR" || n_unique > 50L) return(NULL)
      d <- store$datasets[[ds_name]]
      if (is.null(d) || !col_name %in% names(d)) return(NULL)
      sort(unique(d[[col_name]][!is.na(d[[col_name]])]))
    }

    output$active_ds_name <- shiny::renderText({
      ds <- store$active_ds
      if (is.null(ds) || !nzchar(ds)) "No dataset" else toupper(ds)
    })

    output$viewer_dims <- shiny::renderText({
      d <- viewer_data()
      paste0(format(nrow(d), big.mark = ","), " rows \u00d7 ", ncol(d), " cols")
    })

    # ── Columns (server-side pagination) ──
    col_page_size <- 200L
    col_current_page <- shiny::reactiveVal(1L)

    # Reset to page 1 when dataset changes
    shiny::observeEvent(store$active_ds, { col_current_page(1L) })

    shiny::observeEvent(input$col_page_prev, {
      col_current_page(max(1L, col_current_page() - 1L))
    })
    shiny::observeEvent(input$col_page_next, {
      ds <- store$active_ds
      shiny::req(ds)
      attrs <- get_col_attrs(ds)
      shiny::req(attrs)
      total <- ceiling(nrow(attrs) / col_page_size)
      col_current_page(min(total, col_current_page() + 1L))
    })
    shiny::observeEvent(input$col_page_jump, {
      pg <- suppressWarnings(as.integer(input$col_page_jump))
      if (is.na(pg)) return()
      ds <- store$active_ds
      shiny::req(ds)
      attrs <- get_col_attrs(ds)
      shiny::req(attrs)
      total <- ceiling(nrow(attrs) / col_page_size)
      col_current_page(max(1L, min(total, pg)))
    })

    output$col_pager <- shiny::renderUI({
      ds <- store$active_ds
      shiny::req(ds)
      attrs <- get_col_attrs(ds)
      shiny::req(attrs)
      n <- nrow(attrs)
      total_pages <- ceiling(n / col_page_size)
      if (total_pages <= 1L) return(NULL)
      pg <- col_current_page()

      htmltools::tags$div(class = "ar-flex ar-items-center ar-gap-8 ar-py-4 ar-px-8",
        htmltools::tags$button(
          class = "ar-btn-ghost ar-btn--xs",
          disabled = if (pg <= 1L) "" else NULL,
          onclick = paste0("Shiny.setInputValue('", ns("col_page_prev"),
            "', Math.random(), {priority:'event'})"),
          "\u2190"
        ),
        htmltools::tags$input(
          type = "number", class = "ar-input ar-input--xs ar-text-center",
          style = "width:48px;",
          value = pg, min = 1L, max = total_pages,
          onchange = paste0("Shiny.setInputValue('", ns("col_page_jump"),
            "', this.value, {priority:'event'})")
        ),
        htmltools::tags$span(class = "ar-text-xs ar-text-muted",
          paste0("of ", format(total_pages, big.mark = ","),
                 " \u00b7 ", format(n, big.mark = ","), " cols")),
        htmltools::tags$button(
          class = "ar-btn-ghost ar-btn--xs",
          disabled = if (pg >= total_pages) "" else NULL,
          onclick = paste0("Shiny.setInputValue('", ns("col_page_next"),
            "', Math.random(), {priority:'event'})"),
          "\u2192"
        )
      )
    })

    output$col_attrs <- reactable::renderReactable({
      ds <- store$active_ds
      shiny::req(ds)
      attrs <- get_col_attrs(ds)
      shiny::req(attrs)

      # Server-side page slice
      pg <- col_current_page()
      start <- (pg - 1L) * col_page_size + 1L
      end <- min(pg * col_page_size, nrow(attrs))
      page_attrs <- attrs[start:end, , drop = FALSE]

      reactable::reactable(
        page_attrs,
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
            cell = function(value, index) {
              col_name <- page_attrs$Name[index]
              col_type <- page_attrs$Type[index]
              expandable <- col_type == "CHR" && value <= 50L
              if (expandable) {
                htmltools::tags$span(
                  style = "cursor: pointer; color: var(--accent); text-decoration: underline;",
                  title = "Click row to expand values",
                  as.character(value))
              } else {
                as.character(value)
              }
            },
            style = list(fontFamily = "var(--font-mono)", fontSize = "11px")),
          Missing = reactable::colDef(width = 55, align = "right",
            cell = function(value) if (value == 0) "\u2014" else as.character(value),
            style = list(fontFamily = "var(--font-mono)", fontSize = "11px"))
        ),
        details = function(index) {
          col_name <- page_attrs$Name[index]
          vals <- get_col_uniques(ds, col_name, page_attrs$Type[index], page_attrs$Unique[index])
          if (is.null(vals)) return(NULL)
          pill_tags <- lapply(vals, function(v) {
            htmltools::tags$span(
              style = "display:inline-block;padding:2px 10px;margin:3px;border-radius:4px;font-size:10.5px;font-family:var(--font-mono);background:var(--bg-2);color:var(--fg-2);border:1px solid #ddd;white-space:nowrap;",
              v)
          })
          args <- c(
            list(style = "padding:8px 12px;"),
            list(htmltools::tags$span(
              style = "font-size:11px;color:var(--fg-muted);",
              paste0(length(vals), " values: "))),
            pill_tags
          )
          do.call(htmltools::tags$div, args)
        },
        theme = ar_grid_theme(),
        sortable = TRUE, filterable = TRUE, pagination = FALSE, compact = TRUE,
        highlight = TRUE, fullWidth = FALSE
      )
    })

    # ── Data (server-side pagination) ──
    page_size <- 100L
    current_page <- shiny::reactiveVal(1L)

    # Reset to page 1 when dataset changes
    shiny::observeEvent(viewer_data(), { current_page(1L) })

    shiny::observeEvent(input$page_prev, {
      current_page(max(1L, current_page() - 1L))
    })
    shiny::observeEvent(input$page_next, {
      total <- ceiling(nrow(viewer_data()) / page_size)
      current_page(min(total, current_page() + 1L))
    })
    shiny::observeEvent(input$page_jump, {
      pg <- suppressWarnings(as.integer(input$page_jump))
      if (is.na(pg)) return()
      total <- ceiling(nrow(viewer_data()) / page_size)
      current_page(max(1L, min(total, pg)))
    })

    output$grid_pager <- shiny::renderUI({
      d <- viewer_data()
      n <- nrow(d)
      total_pages <- ceiling(n / page_size)
      if (total_pages <= 1L) return(NULL)
      pg <- current_page()

      htmltools::tags$div(class = "ar-flex ar-items-center ar-gap-8 ar-py-4 ar-px-8",
        htmltools::tags$button(
          class = "ar-btn-ghost ar-btn--xs",
          disabled = if (pg <= 1L) "" else NULL,
          onclick = paste0("Shiny.setInputValue('", ns("page_prev"),
            "', Math.random(), {priority:'event'})"),
          "\u2190"
        ),
        htmltools::tags$input(
          type = "number", class = "ar-input ar-input--xs ar-text-center",
          style = "width:48px;",
          value = pg, min = 1L, max = total_pages,
          onchange = paste0("Shiny.setInputValue('", ns("page_jump"),
            "', this.value, {priority:'event'})")
        ),
        htmltools::tags$span(class = "ar-text-xs ar-text-muted",
          paste0("of ", format(total_pages, big.mark = ","),
                 " \u00b7 ", format(n, big.mark = ","), " rows")),
        htmltools::tags$button(
          class = "ar-btn-ghost ar-btn--xs",
          disabled = if (pg >= total_pages) "" else NULL,
          onclick = paste0("Shiny.setInputValue('", ns("page_next"),
            "', Math.random(), {priority:'event'})"),
          "\u2192"
        )
      )
    })

    output$grid <- reactable::renderReactable({
      d <- viewer_data()
      shiny::req(nrow(d) > 0)
      pg <- current_page()
      start <- (pg - 1L) * page_size + 1L
      end <- min(pg * page_size, nrow(d))
      page_data <- d[start:end, , drop = FALSE]
      ar_build_reactable(page_data, row_offset = start - 1L)
    })

    output$csv_download <- shiny::downloadHandler(
      filename = function() paste0(store$active_ds %||% "data", "_", Sys.Date(), ".csv"),
      content = function(file) readr::write_csv(viewer_data(), file)
    )
  })
}
