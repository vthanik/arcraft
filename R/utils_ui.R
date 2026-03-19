# Shared UI components

ar_theme <- function() {
  bslib::bs_theme(
    version = 5,
    bootswatch = "default",
    primary = "#4a6fa5",
    "font-size-base" = "0.8125rem",
    "body-bg" = "#ffffff",
    "body-color" = "#1a1918"
  ) |>
    bslib::bs_add_rules(
      "@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');"
    )
}

ar_grid_theme <- function() {
  reactable::reactableTheme(
    borderColor = "#e5e4e2",
    headerStyle = list(
      background = "#f8f8f7",
      borderBottom = "1px solid #e5e4e2",
      fontWeight = 600,
      fontSize = "11px",
      color = "#57534e",
      padding = "4px 8px",
      verticalAlign = "bottom"
    ),
    cellStyle = list(
      padding = "2px 8px",
      fontSize = "11.5px",
      lineHeight = "1.3",
      borderBottom = "1px solid #f3f2f1",
      verticalAlign = "top"
    ),
    paginationStyle = list(fontSize = "11px")
  )
}

ui_stat_chip <- function(label, value) {
  htmltools::tags$span(
    class = "ar-stat-chip",
    htmltools::tags$span(class = "ar-stat-chip__label", label),
    htmltools::tags$span(class = "ar-stat-chip__value", value)
  )
}

ui_empty_state <- function(title, desc = NULL, icon = "fa-table", cta = NULL) {
  htmltools::tags$div(
    class = "ar-empty-state",
    htmltools::tags$div(class = "ar-empty-state__icon",
                        htmltools::tags$i(class = paste0("fa ", icon))),
    htmltools::tags$div(class = "ar-empty-state__title", title),
    if (!is.null(desc)) htmltools::tags$div(class = "ar-empty-state__desc", desc),
    if (!is.null(cta)) htmltools::tags$div(class = "ar-empty-state__cta", cta)
  )
}

ui_type_badge <- function(type) {
  cls <- switch(toupper(type),
    NUM = "ar-type-badge ar-type-badge--num",
    CHR = "ar-type-badge ar-type-badge--chr",
    DATE = "ar-type-badge ar-type-badge--date",
    FLAG = "ar-type-badge ar-type-badge--flag",
    "ar-type-badge"
  )
  htmltools::tags$span(class = cls, toupper(type))
}

ui_pill <- function(label, active = FALSE, removable = FALSE, ns_remove_id = NULL) {
  cls <- paste0("ar-pill", if (active) " ar-pill--active" else "")
  htmltools::tags$span(
    class = cls,
    label,
    if (removable && !is.null(ns_remove_id)) {
      htmltools::tags$span(
        class = "ar-pill__remove",
        onclick = paste0("Shiny.setInputValue('", ns_remove_id, "', '", label, "', {priority: 'event'})"),
        htmltools::HTML("&times;")
      )
    }
  )
}

ar_build_reactable <- function(data, height = "calc(100vh - 180px)") {
  d <- dplyr::bind_cols(
    tibble::tibble(`#` = seq_len(nrow(data))),
    data
  )

  col_defs <- list()

  # Row number column
  col_defs[["#"]] <- reactable::colDef(
    name = "#",
    width = 60,
    align = "right",
    style = list(color = "var(--fg-muted)", fontSize = "11px",
                 borderRight = "1px solid var(--border-light)",
                 overflow = "visible", textOverflow = "clip"),
    sortable = FALSE,
    filterable = FALSE,
    sticky = "left"
  )

  for (col in names(d)[-1]) {
    x <- d[[col]]
    lbl <- attr(x, "label")
    align <- if (is.numeric(x)) "right" else "left"

    # Measure header width
    header_chars <- nchar(col)
    if (!is.null(lbl) && nzchar(lbl)) header_chars <- max(header_chars, nchar(lbl))
    header_width <- header_chars * 7.5 + 24

    # Measure content width from sample
    sample_vals <- utils::head(stats::na.omit(x), 200)
    content_width <- if (length(sample_vals) > 0) {
      if (is.numeric(x)) {
        formatted <- formatC(as.numeric(sample_vals), format = "f",
                             digits = if (all(sample_vals == floor(sample_vals), na.rm = TRUE)) 0 else 1,
                             big.mark = ",")
        max(nchar(formatted), na.rm = TRUE) * 7.5 + 24
      } else {
        max(nchar(as.character(sample_vals)), na.rm = TRUE) * 7 + 24
      }
    } else 80

    width <- min(350, max(80, max(header_width, content_width)))

    col_defs[[col]] <- reactable::colDef(
      name = col,
      header = function(value) {
        col_name <- value
        col_data <- d[[col_name]]
        col_lbl <- attr(col_data, "label")
        htmltools::tags$div(
          htmltools::tags$div(style = "font-weight: 600; font-size: 11.5px;", col_name),
          if (!is.null(col_lbl) && nzchar(col_lbl)) {
            htmltools::tags$div(style = "font-size: 10px; color: var(--fg-muted); font-weight: 400;", col_lbl)
          }
        )
      },
      align = align,
      minWidth = width,
      cell = function(value) {
        if (is.na(value)) {
          htmltools::tags$span(style = "color: var(--fg-muted); font-style: italic;", "NA")
        } else {
          as.character(value)
        }
      }
    )
  }

  reactable::reactable(
    d,
    columns = col_defs,
    height = height,
    theme = ar_grid_theme(),
    pagination = TRUE,
    defaultPageSize = 50,
    showPageSizeOptions = TRUE,
    pageSizeOptions = c(25, 50, 100, 250),
    resizable = TRUE,
    wrap = FALSE,
    bordered = FALSE,
    striped = FALSE,
    highlight = TRUE,
    compact = TRUE,
    fullWidth = TRUE
  )
}

ui_var_card_header <- function(ns, var, label, type, summary = "", modified = FALSE) {
  htmltools::tags$div(
    class = "ar-var-card__header",
    onclick = paste0("arToggleVarCard('", ns(paste0("card_", var)), "')"),
    htmltools::tags$span(class = "ar-var-card__drag", htmltools::HTML("&#8942;&#8942;")),
    htmltools::tags$span(class = "ar-var-card__name", var),
    ui_type_badge(if (type == "continuous") "NUM" else "CHR"),
    htmltools::tags$span(class = "ar-var-card__label", label),
    htmltools::tags$span(class = "ar-var-card__summary", summary),
    if (modified) htmltools::tags$span(class = "ar-var-card__modified"),
    htmltools::tags$span(class = "ar-var-card__chevron", htmltools::HTML("&#9656;"))
  )
}

ui_var_card_cont <- function(ns, var, config) {
  stats_choices <- c(
    "n" = "N",
    "mean_sd" = "Mean (SD)",
    "median" = "Median",
    "q1_q3" = "Q1, Q3",
    "min_max" = "Min, Max",
    "geo_mean_cv" = "Geometric Mean (CV%)"
  )
  selected_stats <- config$stats %||% c("n", "mean_sd", "median", "q1_q3", "min_max")
  dec <- config$decimals %||% 1

  htmltools::tags$div(
    class = "ar-var-card__content",
    htmltools::tags$div(
      class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Statistics"),
      shiny::checkboxGroupInput(
        ns(paste0("stats_", var)), NULL,
        choices = stats_choices,
        selected = selected_stats,
        inline = FALSE
      )
    ),
    htmltools::tags$div(
      class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Decimal places"),
      shiny::numericInput(ns(paste0("dec_", var)), NULL, value = dec, min = 0, max = 6, step = 1, width = "80px")
    ),
    htmltools::tags$div(
      class = "ar-var-card__actions",
      htmltools::tags$button(
        class = "ar-btn-ghost",
        onclick = paste0("Shiny.setInputValue('", ns(paste0("reset_", var)), "', Math.random(), {priority: 'event'})"),
        "Reset to Default"
      )
    )
  )
}

ui_var_card_cat <- function(ns, var, config, levels = NULL) {
  fmt <- config$cat_format %||% "npct"
  dec <- config$pct_dec %||% 1
  style <- config$zero_style %||% "A"

  htmltools::tags$div(
    class = "ar-var-card__content",
    htmltools::tags$div(
      class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Display format"),
      shiny::radioButtons(
        ns(paste0("catfmt_", var)), NULL,
        choices = c("n (%)" = "npct", "n only" = "n", "n/N (%)" = "nn_pct"),
        selected = fmt, inline = TRUE
      )
    ),
    htmltools::tags$div(
      class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Percent decimals"),
      shiny::numericInput(ns(paste0("catdec_", var)), NULL, value = dec, min = 0, max = 3, step = 1, width = "80px")
    ),
    htmltools::tags$div(
      class = "ar-form-group",
      htmltools::tags$label(class = "ar-form-label", "Zero display"),
      shiny::radioButtons(
        ns(paste0("zero_", var)), NULL,
        choices = c("0" = "A", "0 (0.0)" = "D"),
        selected = style, inline = TRUE
      )
    ),
    if (!is.null(levels) && length(levels) > 0) {
      htmltools::tags$div(
        class = "ar-form-group ar-mt-8",
        htmltools::tags$label(class = "ar-form-label", paste0("Levels (", length(levels), ")")),
        htmltools::tags$div(class = "ar-text-sm ar-text-muted",
                            paste(levels, collapse = ", "))
      )
    },
    htmltools::tags$div(
      class = "ar-var-card__actions",
      htmltools::tags$button(
        class = "ar-btn-ghost",
        onclick = paste0("Shiny.setInputValue('", ns(paste0("reset_", var)), "', Math.random(), {priority: 'event'})"),
        "Reset to Default"
      )
    )
  )
}
