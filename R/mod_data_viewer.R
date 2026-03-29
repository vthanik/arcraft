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
      DT::dataTableOutput(ns("grid"))
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
      get_unique_levels(d[[col_name]])
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

    # Debounced pager to avoid double-render race condition when dataset changes
    col_pager_data <- shiny::reactive({
      ds <- store$active_ds
      shiny::req(ds)
      attrs <- get_col_attrs(ds)
      shiny::req(attrs)
      pg <- col_current_page()
      list(attrs = attrs, pg = pg)
    }) |> shiny::debounce(100)

    output$col_pager <- shiny::renderUI({
      pd <- col_pager_data()
      shiny::req(pd)
      n <- nrow(pd$attrs)
      total_pages <- ceiling(n / col_page_size)
      if (total_pages <= 1L) return(NULL)
      pg <- pd$pg

      htmltools::tags$div(class = "ar-flex ar-items-center ar-gap-8 ar-py-4 ar-px-8",
        htmltools::tags$button(
          class = "ar-btn-ghost ar-btn--xs",
          disabled = if (pg <= 1L) "" else NULL,
          onclick = paste0("Shiny.setInputValue('", ns("col_page_prev"),
            "', Math.random(), {priority:'event'})"),
          "\u2190"
        ),
        htmltools::tags$input(
          type = "number", class = "ar-input ar-input--xs ar-text-center ar-w-48",
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
                  class = "ar-col-expandable",
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
            htmltools::tags$span(class = "ar-val-pill", v)
          })
          args <- c(
            list(class = "ar-val-wrap"),
            list(htmltools::tags$span(class = "ar-val-count",
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

    # ── Data (DT server-side) ──
    output$grid <- DT::renderDataTable({
      d <- viewer_data()
      shiny::req(nrow(d) > 0)

      # Build column names + labels for headerCallback
      col_names <- names(d)
      col_labels <- vapply(col_names, function(nm) {
        lbl <- attr(d[[nm]], "label")
        if (!is.null(lbl) && nzchar(lbl)) lbl else ""
      }, character(1), USE.NAMES = FALSE)
      names_json <- jsonlite::toJSON(col_names, auto_unbox = FALSE)
      labels_json <- jsonlite::toJSON(col_labels, auto_unbox = FALSE)

      # Detect numeric columns for right-alignment (0-indexed, +1 for rownames col)
      num_idx <- which(vapply(d, is.numeric, logical(1)))

      # Build columnDefs
      col_defs <- list(
        list(targets = 0, className = "ar-dt-rownum", orderable = FALSE,
             searchable = FALSE, width = "50px"),
        list(targets = "_all", className = "ar-dt-cell")
      )
      if (length(num_idx) > 0) {
        col_defs <- c(col_defs, list(
          list(targets = as.list(num_idx), className = "ar-dt-cell ar-dt-num")
        ))
      }

      # NA rendering
      na_render <- DT::JS(
        "function(data, type, row, meta) {",
        "  if (data === null || data === 'NA' || data === '') {",
        "    return type === 'display' ? '<span class=\"ar-dt-na\">NA</span>' : '';",
        "  }",
        "  return data;",
        "}"
      )

      # Header callback: inject two-line headers (Name + Label)
      # Uses stored names[] array to avoid re-reading mutated DOM text
      header_cb <- DT::JS(paste0(
        "function(thead, data, start, end, display) {",
        "  var names = ", names_json, ";",
        "  var labels = ", labels_json, ";",
        "  $(thead).find('th').each(function(i) {",
        "    if (i === 0) { $(this).text('#'); return; }",
        "    var nm = names[i - 1] || '';",
        "    var lbl = labels[i - 1] || '';",
        "    var html = '<span class=\"ar-dt-hdr__name\">' + $('<span>').text(nm).html() + '</span>';",
        "    if (lbl) html += '<span class=\"ar-dt-hdr__label\">' + $('<span>').text(lbl).html() + '</span>';",
        "    $(this).html(html);",
        "  });",
        "}"
      ))

      # Convert numeric/Date columns to character so DT uses text filters (no sliders)
      d_display <- d
      for (j in seq_along(d_display)) {
        if (is.numeric(d_display[[j]]) || inherits(d_display[[j]], "Date") ||
            inherits(d_display[[j]], "POSIXt")) {
          d_display[[j]] <- as.character(d_display[[j]])
        }
      }

      DT::datatable(
        d_display,
        rownames = TRUE,
        filter = "top",
        options = list(
          pageLength = 50L,
          lengthMenu = c(50, 100, 250, 500),
          processing = TRUE,
          autoWidth = FALSE,
          dom = '<"ar-dt-top"rt><"ar-dt-bottom"lip>',
          headerCallback = header_cb,
          columnDefs = c(
            col_defs,
            list(list(targets = "_all", render = na_render))
          )
        ),
        class = "compact hover nowrap",
        selection = "none"
      )
    }, server = TRUE)

    output$csv_download <- shiny::downloadHandler(
      filename = function() paste0(store$active_ds %||% "data", "_", Sys.Date(), ".csv"),
      content = function(file) readr::write_csv(viewer_data(), file)
    )
  })
}
