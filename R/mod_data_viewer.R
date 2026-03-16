#' Data Viewer Module — VS Code Data Wrangler-style viewer
#' Column headers show: name, label, type badge. No inline search rows.
#' Filter bar lives above profile. Clickable profile cards for detail.

mod_data_viewer_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tags$div(class = "ar-dv",

    # ── Toolbar ──
    htmltools::tags$div(class = "ar-dv__toolbar",
      htmltools::tags$div(class = "ar-dv__toolbar-left",
        shiny::selectInput(ns("ds"), NULL, choices = NULL, width = "120px"),
        htmltools::tags$div(class = "ar-dv__search-box",
          htmltools::tags$i(class = "fa fa-search ar-dv__search-icon"),
          shiny::selectizeInput(ns("search"), NULL, choices = NULL,
            multiple = FALSE, width = "100%",
            options = list(placeholder = "Search columns...",
              create = FALSE, maxOptions = 50))
        ),
        shiny::uiOutput(ns("dims"), inline = TRUE)
      ),
      htmltools::tags$div(class = "ar-dv__toolbar-right",
        htmltools::tags$button(id = ns("toggle_filter"),
          class = "ar-btn-ghost btn-sm",
          onclick = sprintf(
            "document.getElementById('%s').classList.toggle('ar-dv__filter--hidden');this.classList.toggle('active')",
            ns("filter_panel")),
          htmltools::tags$i(class = "fa fa-filter"), " Filter",
          shiny::uiOutput(ns("filter_badge"), inline = TRUE)),
        htmltools::tags$button(id = ns("toggle_profile"),
          class = "ar-btn-ghost btn-sm",
          onclick = sprintf(
            "document.getElementById('%s').classList.toggle('ar-dv__profile--hidden');this.classList.toggle('active')",
            ns("profile_panel")),
          htmltools::tags$i(class = "fa fa-chart-bar"), " Profile"),
        shiny::downloadButton(ns("dl_csv"), "CSV", class = "ar-btn-ghost btn-sm")
      )
    ),

    # ── Filter Bar (collapsible, before profile) ──
    htmltools::tags$div(id = ns("filter_panel"),
      class = "ar-dv__filter ar-dv__filter--hidden",
      shiny::uiOutput(ns("filter_rows")),
      htmltools::tags$button(class = "ar-filter-add",
        id = ns("add_filter"),
        onclick = sprintf("Shiny.setInputValue('%s', Math.random(), {priority:'event'})", ns("add_filter")),
        shiny::icon("plus"), " Add filter")
    ),

    # ── Profile Panel (collapsible) ──
    htmltools::tags$div(id = ns("profile_panel"),
      class = "ar-dv__profile ar-dv__profile--hidden",
      shiny::uiOutput(ns("profile_cards"))
    ),

    # ── Column Detail Panel (shown when profile card clicked) ──
    htmltools::tags$div(id = ns("col_detail_panel"),
      class = "ar-dv__col-detail ar-dv__col-detail--hidden",
      shiny::uiOutput(ns("col_detail"))
    ),

    # ── Data Grid ──
    htmltools::tags$div(class = "ar-dv__grid",
      reactable::reactableOutput(ns("table"), height = "100%")
    )
  )
}

mod_data_viewer_server <- function(id, data_out) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    filters <- shiny::reactiveVal(list(list(id = 1L)))
    filter_counter <- shiny::reactiveVal(1L)

    # Update dataset selector
    shiny::observe({
      ds <- data_out$datasets()
      shiny::req(length(ds) > 0)
      nms <- names(ds)
      sel <- data_out$active_ds() %||% nms[1]
      shiny::updateSelectInput(session, "ds", choices = nms, selected = sel)
    })

    # Raw dataset (before local filters)
    raw_data <- shiny::reactive({
      ds <- data_out$datasets()
      nm <- input$ds
      shiny::req(ds, nm, nm %in% names(ds))
      ds[[nm]]
    })

    # Update column search choices
    shiny::observe({
      d <- raw_data(); shiny::req(d)
      cols <- names(d)
      labels <- purrr::map_chr(cols, function(cn) {
        lbl <- attr(d[[cn]], "label")
        if (!is.null(lbl) && nzchar(lbl)) paste0(cn, " \u2014 ", lbl) else cn
      })
      choices <- stats::setNames(cols, labels)
      all_choices <- c("", choices)
      names(all_choices)[1] <- ""
      shiny::updateSelectizeInput(session, "search", choices = all_choices,
        selected = "", server = TRUE)
    })

    # Scroll to column when selected
    shiny::observeEvent(input$search, {
      col <- input$search
      if (!is.null(col) && nzchar(col)) {
        session$sendCustomMessage("ar_scroll_to_col", col)
      }
    })

    # ── Local filters (exploratory only) ──
    shiny::observeEvent(input$add_filter, {
      n <- filter_counter() + 1L
      filter_counter(n)
      fl <- filters()
      fl[[length(fl) + 1]] <- list(id = n)
      filters(fl)
    })

    shiny::observeEvent(input$remove_filter, {
      rid <- input$remove_filter
      fl <- filters()
      fl <- purrr::discard(fl, function(f) f$id == rid)
      if (length(fl) == 0) {
        n <- filter_counter() + 1L
        filter_counter(n)
        fl <- list(list(id = n))
      }
      filters(fl)
    })

    output$filter_rows <- shiny::renderUI({
      fl <- filters()
      d <- raw_data()
      if (is.null(d)) return(NULL)
      cols <- names(d)
      purrr::map(fl, function(f) {
        fid <- f$id
        htmltools::tags$div(class = "ar-filter-row",
          shiny::selectizeInput(ns(paste0("fvar_", fid)), NULL,
            choices = c(Choose = "", cols), width = "130px",
            options = list(placeholder = "Column")),
          shiny::selectInput(ns(paste0("fop_", fid)), NULL,
            choices = c("==" = "==", "!=" = "!=", ">" = ">", "<" = "<",
                        ">=" = ">=", "<=" = "<="),
            width = "60px"),
          shiny::selectizeInput(ns(paste0("fval_", fid)), NULL,
            choices = NULL, width = "150px", multiple = TRUE,
            options = list(placeholder = "Value", create = TRUE)),
          htmltools::tags$button(class = "ar-filter-remove",
            onclick = sprintf("Shiny.setInputValue('%s', %d, {priority:'event'})",
              ns("remove_filter"), fid),
            shiny::icon("xmark"))
        )
      })
    })

    # Update filter value choices
    shiny::observe({
      fl <- filters()
      d <- raw_data()
      shiny::req(d)
      purrr::walk(fl, function(f) {
        var_input <- input[[paste0("fvar_", f$id)]]
        if (!is.null(var_input) && nzchar(var_input) && var_input %in% names(d)) {
          vals <- sort(unique(as.character(d[[var_input]])))
          vals <- vals[!is.na(vals)]
          shiny::updateSelectizeInput(session, paste0("fval_", f$id),
            choices = vals, server = TRUE)
        }
      })
    })

    # Filter badge count
    output$filter_badge <- shiny::renderUI({
      fl <- filters()
      active <- sum(purrr::map_lgl(fl, function(f) {
        var <- input[[paste0("fvar_", f$id)]]
        val <- input[[paste0("fval_", f$id)]]
        !is.null(var) && nzchar(var) && !is.null(val) && length(val) > 0
      }))
      if (active > 0) {
        htmltools::tags$span(class = "ar-pill ar-pill--accent", style = "margin-left:4px;",
          active)
      }
    })

    # Apply local filters
    display_data <- shiny::reactive({
      d <- raw_data()
      shiny::req(d)
      fl <- filters()
      conditions <- purrr::compact(purrr::map(fl, function(f) {
        var <- input[[paste0("fvar_", f$id)]]
        op <- input[[paste0("fop_", f$id)]]
        val <- input[[paste0("fval_", f$id)]]
        if (is.null(var) || !nzchar(var) || is.null(val) || length(val) == 0) return(NULL)
        list(var = var, op = op, val = val)
      }))
      if (length(conditions) == 0) return(d)
      for (cond in conditions) {
        if (!(cond$var %in% names(d))) next
        col_vals <- d[[cond$var]]
        fvals <- if (is.numeric(col_vals)) suppressWarnings(as.numeric(cond$val)) else cond$val
        keep <- switch(cond$op,
          "==" = col_vals %in% fvals, "!=" = !(col_vals %in% fvals),
          ">"  = col_vals > fvals[1], "<"  = col_vals < fvals[1],
          ">=" = col_vals >= fvals[1], "<=" = col_vals <= fvals[1],
          rep(TRUE, length(col_vals)))
        keep[is.na(keep)] <- FALSE
        d <- d[keep, , drop = FALSE]
      }
      d
    })

    # ── Dimensions badge ──
    output$dims <- shiny::renderUI({
      d <- display_data()
      shiny::req(d)
      full <- raw_data()
      filtered <- nrow(d) < nrow(full)
      htmltools::tags$div(class = "ar-dv__dims",
        htmltools::tags$span(class = "ar-pill ar-pill--accent",
          sprintf("%s rows", format(nrow(d), big.mark = ","))),
        htmltools::tags$span(class = "ar-pill ar-pill--accent",
          sprintf("%d cols", ncol(d))),
        if (filtered) htmltools::tags$span(class = "ar-pill ar-pill--warning",
          sprintf("of %s", format(nrow(full), big.mark = ",")))
      )
    })

    # ── Profile Panel ──
    output$profile_cards <- shiny::renderUI({
      d <- raw_data()
      shiny::req(d, ncol(d) > 0)
      nr <- nrow(d)
      cards <- purrr::map(names(d), function(col) {
        prof <- fct_profile_column(d[[col]], col, nr)
        htmltools::tags$div(class = "ar-profile-card",
          onclick = sprintf("Shiny.setInputValue('%s', '%s', {priority:'event'})",
            ns("profile_click"), col),
          htmltools::tags$div(class = "ar-profile-card__header",
            htmltools::tags$span(class = paste("ar-type-badge", prof$badge_class),
              prof$type_label),
            htmltools::tags$span(class = "ar-profile-card__name", col)
          ),
          htmltools::tags$div(class = "ar-profile-card__stats",
            ui_stat_chip("Unique", prof$n_unique),
            ui_stat_chip("Missing", prof$missing_str),
            if (!is.null(prof$extra_name))
              ui_stat_chip(prof$extra_name, prof$extra_stat)
          ),
          if (!is.null(prof$dist_html)) prof$dist_html
        )
      })
      htmltools::tags$div(class = "ar-profile-grid ar-fade-in", cards)
    })

    # ── Column Detail (on profile card click) ──
    shiny::observeEvent(input$profile_click, {
      session$sendCustomMessage("ar_show_col_detail", TRUE)
    })

    output$col_detail <- shiny::renderUI({
      col <- input$profile_click
      shiny::req(col)
      d <- raw_data()
      shiny::req(d, col %in% names(d))
      x <- d[[col]]
      nr <- nrow(d)
      lbl <- attr(x, "label")
      lbl_text <- if (!is.null(lbl) && nzchar(lbl)) lbl else "\u2014"

      # Type
      type_str <- if (inherits(x, "POSIXct")) "datetime"
        else if (inherits(x, "Date")) "date"
        else if (is.numeric(x)) "numeric"
        else if (is.logical(x)) "logical"
        else "character"

      n_miss <- sum(is.na(x))
      n_unique <- length(unique(x[!is.na(x)]))
      pct_miss <- if (nr > 0) round(n_miss / nr * 100, 1) else 0

      # Stats section
      stats_ui <- if (is.numeric(x) && n_miss < nr) {
        vals <- x[!is.na(x)]
        htmltools::tagList(
          htmltools::tags$div(class = "ar-detail__stats-grid",
            ui_stat_chip("Min", format(min(vals), big.mark = ",")),
            ui_stat_chip("Q1", format(stats::quantile(vals, 0.25), big.mark = ",")),
            ui_stat_chip("Median", format(stats::median(vals), big.mark = ",")),
            ui_stat_chip("Mean", sprintf("%.2f", mean(vals))),
            ui_stat_chip("Q3", format(stats::quantile(vals, 0.75), big.mark = ",")),
            ui_stat_chip("Max", format(max(vals), big.mark = ",")),
            ui_stat_chip("SD", sprintf("%.2f", stats::sd(vals)))
          ),
          ui_numeric_dist(vals)
        )
      } else if (!is.numeric(x) && n_unique > 0 && n_unique <= 50) {
        tbl <- sort(table(x[!is.na(x)]), decreasing = TRUE)
        ui_categorical_dist(tbl, nr)
      }

      # Top values for character
      top_vals_ui <- if (!is.numeric(x) && n_unique > 0) {
        tbl <- sort(table(x[!is.na(x)]), decreasing = TRUE)
        top <- utils::head(tbl, 10)
        rows <- purrr::imap(top, function(cnt, val) {
          htmltools::tags$div(class = "ar-detail__val-row",
            htmltools::tags$span(class = "ar-detail__val-name",
              if (nchar(val) > 30) paste0(substr(val, 1, 28), "\u2026") else val),
            htmltools::tags$span(class = "ar-detail__val-count", cnt))
        })
        htmltools::tags$div(class = "ar-detail__val-list", rows)
      }

      htmltools::tags$div(class = "ar-detail ar-fade-in",
        htmltools::tags$div(class = "ar-detail__header",
          htmltools::tags$div(class = "ar-detail__title",
            htmltools::tags$span(class = "ar-detail__col-name", col),
            htmltools::tags$span(class = paste("ar-type-badge",
              switch(type_str, numeric = "ar-type-badge--num",
                date = "ar-type-badge--date", datetime = "ar-type-badge--date",
                logical = "ar-type-badge--bool", "ar-type-badge--chr")),
              toupper(type_str))
          ),
          htmltools::tags$button(class = "ar-filter-remove",
            onclick = sprintf("document.getElementById('%s').classList.add('ar-dv__col-detail--hidden')",
              ns("col_detail_panel")),
            shiny::icon("xmark"))
        ),
        if (lbl_text != "\u2014") htmltools::tags$div(class = "ar-detail__label", lbl_text),
        htmltools::tags$div(class = "ar-detail__stats-grid",
          ui_stat_chip("Rows", format(nr, big.mark = ",")),
          ui_stat_chip("Unique", format(n_unique, big.mark = ",")),
          ui_stat_chip("Missing", sprintf("%d (%.1f%%)", n_miss, pct_miss))
        ),
        stats_ui,
        top_vals_ui
      )
    })

    # ── Data Grid (reactable) — no filterable, show label + type in header ──
    output$table <- reactable::renderReactable({
      d <- display_data()
      shiny::req(d, nrow(d) > 0)
      raw <- raw_data()

      display <- d
      for (col in names(display)) {
        if (inherits(display[[col]], "Date") || inherits(display[[col]], "POSIXct"))
          display[[col]] <- as.character(display[[col]])
        if (is.factor(display[[col]]))
          display[[col]] <- as.character(display[[col]])
      }

      col_defs <- purrr::map(names(display), function(cn) {
        is_num <- is.numeric(d[[cn]])
        is_date <- inherits(d[[cn]], "Date") || inherits(d[[cn]], "POSIXct")
        is_dttm <- inherits(d[[cn]], "POSIXct")

        type_lbl <- if (is_dttm) "dttm" else if (is_date) "date" else if (is_num) "num" else "chr"
        type_cls <- if (is_num) "ar-type-badge--num"
          else if (is_date) "ar-type-badge--date"
          else "ar-type-badge--chr"

        col_label <- attr(raw[[cn]], "label")
        has_label <- !is.null(col_label) && nzchar(col_label)

        header_js <- sprintf(
          "function(col) {
            var name = React.createElement('span', {style:{fontWeight:600,fontSize:'11px',letterSpacing:'0.02em'}}, '%s');
            var badge = React.createElement('span', {className:'ar-type-badge %s', style:{marginLeft:'4px'}}, '%s');
            var top = React.createElement('div', {style:{display:'flex',alignItems:'center',gap:'2px'}}, name, badge);
            %s
            return React.createElement('div', {style:{lineHeight:'1.3'}}, top%s);
          }",
          cn, type_cls, type_lbl,
          if (has_label) sprintf(
            "var lbl = React.createElement('div', {style:{fontSize:'9px',color:'#78716c',fontWeight:400,whiteSpace:'nowrap',overflow:'hidden',textOverflow:'ellipsis',maxWidth:'140px'}}, '%s');",
            gsub("'", "\\\\'", col_label))
          else "",
          if (has_label) ", lbl" else ""
        )

        reactable::colDef(
          header = reactable::JS(header_js),
          sortable = TRUE,
          filterable = FALSE,
          align = if (is_num) "right" else "left",
          headerStyle = list(
            padding = "6px 8px", background = "#f8f8f7",
            borderBottom = "2px solid #e5e4e2", verticalAlign = "bottom"
          ),
          style = list(
            fontFamily = "'JetBrains Mono', monospace", fontSize = "12px"
          )
        )
      }) |> stats::setNames(names(display))

      reactable::reactable(
        display,
        columns = col_defs,
        compact = TRUE,
        bordered = TRUE,
        sortable = TRUE,
        filterable = FALSE,
        resizable = TRUE,
        highlight = TRUE,
        defaultPageSize = 50,
        showPageSizeOptions = TRUE,
        pageSizeOptions = c(25, 50, 100, 250),
        paginationType = "jump",
        theme = reactable::reactableTheme(
          color = "#1a1918",
          backgroundColor = "#fff",
          borderColor = "#e5e4e2",
          highlightColor = "#f0efed",
          cellPadding = "4px 8px",
          style = list(fontFamily = "'JetBrains Mono', monospace", fontSize = "12px"),
          pageButtonStyle = list(fontSize = "12px"),
          paginationStyle = list(fontSize = "12px")
        )
      )
    })

    # ── CSV Download ──
    output$dl_csv <- shiny::downloadHandler(
      filename = function() {
        nm <- input$ds %||% "data"
        paste0(nm, "_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        d <- display_data()
        shiny::req(d)
        readr::write_csv(d, file)
      }
    )
  })
}
