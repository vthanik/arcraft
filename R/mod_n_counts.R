# Module: N Counts — Foldable treatment + group variable counts
# Both sections are collapsible <details> disclosures.

n_counts_ui <- function(id) {
  ns <- shiny::NS(id)
  htmltools::tags$div(class = "ar-n-counts-wrap",
    shiny::uiOutput(ns("n_counts_display"))
  )
}

n_counts_server <- function(id, store, grp) {
  shiny::moduleServer(id, function(input, output, session) {

    output$n_counts_display <- shiny::renderUI({
      req(store$datasets)
      ds_name <- names(store$datasets)[1]
      req(ds_name)
      d <- store$datasets[[ds_name]]

      trt_var <- grp$trt_var
      if (is.null(trt_var) || !trt_var %in% names(d)) {
        return(htmltools::tags$div(class = "ar-text-xs ar-text-muted ar-py-4",
          "Select a treatment variable to view N counts"))
      }

      # Apply pop filter
      pop <- store$pipeline_filters$pop_flag
      if (!is.null(pop) && nzchar(pop) && pop %in% names(d)) {
        d <- d[d[[pop]] == "Y", ]
      }

      trt_lvls <- grp$trt_levels %||% sort(unique(d[[trt_var]]))
      counts <- table(d[[trt_var]])
      n_total <- nrow(d)
      include_total <- grp$include_total %||% TRUE
      total_label <- grp$total_label %||% "Total"

      # ── Treatment Arms table (foldable) ──
      trt_rows <- lapply(trt_lvls, function(lv) {
        n <- as.integer(counts[lv])
        if (is.na(n)) n <- 0L
        pct <- sprintf("%.1f%%", 100 * n / n_total)
        htmltools::tags$tr(
          htmltools::tags$td(class = "ar-nc__cell", lv),
          htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", n),
          htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", pct)
        )
      })

      total_row <- if (isTRUE(include_total)) {
        htmltools::tags$tr(class = "ar-nc__total",
          htmltools::tags$td(class = "ar-nc__cell", total_label),
          htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", n_total),
          htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", "100.0%")
        )
      }

      n_arms <- length(trt_lvls)
      trt_section <- htmltools::tags$details(class = "ar-disclosure",
        htmltools::tags$summary(class = "ar-disclosure__summary",
          paste0("Treatment Arms (", n_arms, ")")),
        htmltools::tags$div(class = "ar-disclosure__body",
          htmltools::tags$table(class = "ar-nc__table",
            htmltools::tags$thead(
              htmltools::tags$tr(
                htmltools::tags$th(class = "ar-nc__th", "Arm"),
                htmltools::tags$th(class = "ar-nc__th ar-nc__th--num", "N"),
                htmltools::tags$th(class = "ar-nc__th ar-nc__th--num", "%")
              )
            ),
            htmltools::tags$tbody(trt_rows, total_row)
          )
        )
      )

      # ── Group Variable section (foldable, if selected) ──
      by_var <- grp$by_var
      by_section <- NULL
      if (!is.null(by_var) && nzchar(by_var) && by_var %in% names(d)) {
        by_lvls <- grp$by_levels %||% sort(unique(d[[by_var]]))

        by_blocks <- lapply(by_lvls, function(bv) {
          sub <- d[d[[by_var]] == bv, ]
          trt_counts <- table(sub[[trt_var]])
          n_by_total <- nrow(sub)

          rows <- lapply(trt_lvls, function(tv) {
            n <- as.integer(trt_counts[tv])
            if (is.na(n)) n <- 0L
            pct <- if (n_by_total > 0) sprintf("%.1f%%", 100 * n / n_by_total) else "0.0%"
            htmltools::tags$tr(
              htmltools::tags$td(class = "ar-nc__cell", tv),
              htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", n),
              htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", pct)
            )
          })

          t_row <- if (isTRUE(include_total)) {
            htmltools::tags$tr(class = "ar-nc__total",
              htmltools::tags$td(class = "ar-nc__cell", total_label),
              htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", n_by_total),
              htmltools::tags$td(class = "ar-nc__cell ar-nc__cell--num", "100.0%")
            )
          }

          htmltools::tags$div(class = "ar-n-counts__by-block",
            htmltools::tags$h5(class = "ar-n-counts__by-label", bv),
            htmltools::tags$table(class = "ar-nc__table",
              htmltools::tags$thead(
                htmltools::tags$tr(
                  htmltools::tags$th(class = "ar-nc__th", "Arm"),
                  htmltools::tags$th(class = "ar-nc__th ar-nc__th--num", "N"),
                  htmltools::tags$th(class = "ar-nc__th ar-nc__th--num", "%")
                )
              ),
              htmltools::tags$tbody(rows, t_row)
            )
          )
        })

        n_grp_lvls <- length(by_lvls)
        by_section <- htmltools::tags$details(class = "ar-disclosure",
          htmltools::tags$summary(class = "ar-disclosure__summary",
            paste0("Group Variable: ", by_var, " (", n_grp_lvls, " levels)")),
          htmltools::tags$div(class = "ar-disclosure__body",
            htmltools::tagList(by_blocks)
          )
        )
      }

      htmltools::tags$div(class = "ar-n-counts", trt_section, by_section)
    })

  })
}
