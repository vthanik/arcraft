# Shiny Development Notes — 4 Books Combined

Comprehensive reference notes for building arbuilder, extracted from the four essential Shiny books.

| # | Book | Author | URL |
|---|------|--------|-----|
| 1 | Engineering Production-Grade Shiny Apps | Colin Fay et al (ThinkR) | engineering-shiny.org |
| 2 | Mastering Shiny | Hadley Wickham | mastering-shiny.org |
| 3 | JavaScript for Shiny | Colin Fay (ThinkR) | connect.thinkr.fr/js4shinyfieldnotes |
| 4 | Outstanding User Interfaces with Shiny | David Granjon | unleash-shiny.rinterface.com |

**Total: ~7,000 lines of notes with code examples.**

---

---

# Book 1: Engineering Production-Grade Shiny Apps

# Engineering Production-Grade Shiny Apps — Comprehensive Notes

**Source:** Colin Fay, Sebastien Rochette, Vincent Guyader, Cervan Girard (ThinkR)
**URL:** <https://engineering-shiny.org/>
**Purpose:** Reference for building arbuilder as a production-grade Shiny application.

---

## 1. The golem Framework — Package Structure

The central thesis of the book: **a production Shiny app should be an R package.** golem
is an opinionated framework that enforces this. Every Shiny app lives inside a standard
R package skeleton, which gives you `DESCRIPTION`, `NAMESPACE`, `R/`, `man/`, `tests/`,
and the full `devtools`/`roxygen2` toolchain for free.

### 1.1 Directory Layout

```
myapp/
+-- DESCRIPTION
+-- NAMESPACE
+-- R/
|   +-- app_config.R        # golem config helpers
|   +-- app_server.R         # top-level server function
|   +-- app_ui.R             # top-level UI function
|   +-- run_app.R            # the exported runApp() wrapper
|   +-- mod_data.R           # a module
|   +-- mod_analysis.R       # another module
|   +-- fct_helpers.R        # business-logic functions
|   +-- utils_formatting.R   # small utility functions
+-- inst/
|   +-- app/
|   |   +-- www/             # static assets (CSS, JS, images)
|   +-- golem-config.yml     # environment-specific config
+-- tests/
|   +-- testthat/
|   +-- testthat.R
+-- dev/
|   +-- 01_start.R           # project setup script
|   +-- 02_dev.R             # development helpers
|   +-- 03_deploy.R          # deployment helpers
+-- man/
```

### 1.2 File Naming Conventions

golem enforces a strict prefix system for files in `R/`:

| Prefix   | Purpose                            | Example                     |
|----------|------------------------------------|-----------------------------|
| `mod_`   | Shiny modules (UI + server)        | `mod_data.R`                |
| `fct_`   | Feature functions (business logic) | `fct_ard_builder.R`         |
| `utils_` | Small utility/helper functions     | `utils_formatting.R`        |

**Why this matters:** When you open `R/` and see 40 files, the prefix tells you instantly
what each file does. Modules contain UI + server pairs. `fct_` files contain
non-reactive R functions that do the actual work (and are independently testable).
`utils_` files contain small shared helpers.

```r
# --- R/mod_data.R ---
# Module for data upload and selection

#' Data Module UI
#' @param id Module namespace id
#' @export
mod_data_ui <- function(id) {

  ns <- NS(id)
  tagList(
    fileInput(ns("file"), "Upload ADaM dataset (.sas7bdat, .csv, .rds)"),
    selectInput(ns("dataset"), "Select dataset", choices = NULL),
    verbatimTextOutput(ns("summary"))
  )
}

#' Data Module Server
#' @param id Module namespace id
#' @export
mod_data_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # module logic here
  })
}
```

```r
# --- R/fct_ard_builder.R ---
# Pure R function — no Shiny dependency, fully testable

#' Build ARD from ADSL for demographics
#' @param adsl A data.frame of ADSL data
#' @param groupvar Character, the grouping variable (e.g. "TRT01P")
#' @param vars Character vector of analysis variables
#' @return A tibble in ARD-wide format
build_demog_ard <- function(adsl, groupvar, vars) {
  # pure dplyr — no reactives, no input$, no output$
  adsl |>
    dplyr::group_by(.data[[groupvar]]) |>
    dplyr::summarise(
      across(all_of(vars), list(
        n    = ~sum(!is.na(.)),
        mean = ~mean(., na.rm = TRUE),
        sd   = ~sd(., na.rm = TRUE)
      )),
      .groups = "drop"
    )
}
```

```r
# --- R/utils_formatting.R ---

#' Format a number to N decimal places with trailing zeros
#' @param x Numeric vector
#' @param digits Integer, number of decimal places
#' @return Character vector
fmt_num <- function(x, digits = 1) {
  formatC(x, format = "f", digits = digits)
}

#' Combine n (%) into a single string
fmt_n_pct <- function(n, pct, digits = 1) {
  paste0(n, " (", fmt_num(pct, digits), ")")
}
```

### 1.3 Creating a golem App

```r
golem::create_golem("arbuilder")

# Then use the dev scripts:
# dev/01_start.R — fill in DESCRIPTION, add dependencies
# dev/02_dev.R   — add modules, fct_, utils_ files
# dev/03_deploy.R — build for deployment

# Adding a new module:
golem::add_module(name = "data")
# Creates R/mod_data.R with UI and server stubs

# Adding business logic:
golem::add_fct("ard_builder")
# Creates R/fct_ard_builder.R

# Adding utilities:
golem::add_utils("formatting")
# Creates R/utils_formatting.R
```

### 1.4 The run_app() Pattern

```r
# R/run_app.R
#' Run the Shiny Application
#' @param ... arguments passed to golem_opts
#' @export
run_app <- function(
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL,
  uiPattern = "/",
  ...
) {
  with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(...)
  )
}
```

This means your app is launched with `myapp::run_app()` — just like any other
package function. No `shiny::runApp(".")` in production.

---

## 2. Planning Ahead — Wireframes, shinipsum, MVP Framing

### 2.1 The "Before You Code" Phase

The book stresses that **most Shiny app failures are planning failures, not coding
failures.** Before writing a single line of R:

1. **Define the target users** — who will use this app and what do they need?
2. **List the features** — what must version 1.0 do? What can wait?
3. **Draw wireframes** — sketch every screen on paper or with a tool.
4. **Define the data flow** — what goes in, what comes out, what transforms happen?

### 2.2 shinipsum — Prototyping with Fake Outputs

`shinipsum` lets you build a working UI prototype with random placeholder outputs
so stakeholders can click around and give feedback before you write real logic.

```r
# install.packages("shinipsum")
library(shiny)
library(shinipsum)

ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      selectInput("dataset", "Dataset", choices = c("ADSL", "ADAE", "ADVS")),
      actionButton("go", "Generate Table")
    ),
    mainPanel(
      # These will show random placeholder content
      tableOutput("demog_table"),
      plotOutput("forest_plot"),
      verbatimTextOutput("summary_text")
    )
  )
)

server <- function(input, output, session) {
  output$demog_table  <- render_table(random_table(ncol = 5, nrow = 10))
  output$forest_plot  <- render_plot(random_ggplot(type = "bar"))
  output$summary_text <- render_text(random_text(nwords = 50))
}

shinyApp(ui, server)
```

This is invaluable for getting buy-in on layout before investing in real logic.

### 2.3 MVP Framing

> "If you try to build everything at once, you'll ship nothing."

The book recommends defining a Minimum Viable Product (MVP) that is:

- **Complete enough** to be useful on its own
- **Small enough** to ship quickly
- **Extensible** so you can add features later without rewriting

For arbuilder, the MVP is the demographics table flow:
ADSL upload -> variable selection -> stat configuration -> preview -> RTF export.

### 2.4 User Stories

Write user stories to drive the feature list:

```
As a biostatistician,
I want to upload an ADSL dataset and select demographic variables,
so that I can generate a formatted demographics table without writing R code.

As a programmer,
I want to export the generated R script,
so that I can reproduce the table outside the app and include it in my pipeline.
```

---

## 3. The "Comb Strategy" — Module Wiring

### 3.1 The Problem

When modules call each other directly, you get spaghetti dependencies:

```
mod_A <-> mod_B <-> mod_C
  ^                   |
  +-------------------+
```

This is unmaintainable. Testing is impossible because you can't instantiate
mod_A without mod_B without mod_C.

### 3.2 The Comb Pattern

The book advocates the "comb" strategy: **the parent (app_server) wires modules
together. Modules never know about each other.**

```
         app_server (the "spine" of the comb)
        /     |      |       \
     mod_A  mod_B  mod_C   mod_D    (the "teeth")
```

Each module:
- Receives its inputs as **arguments** (reactive values passed from the parent)
- Returns its outputs as a **list of reactives** (returned to the parent)
- Has **zero knowledge** of sibling modules

The parent (`app_server`) is the only place where data flows between modules.

### 3.3 Implementation

```r
# R/app_server.R — the wiring hub
app_server <- function(input, output, session) {

  # Module 1: Data upload — returns reactive dataset

  data_out <- mod_data_server("data")

  # Module 2: Analysis config — receives dataset, returns ARD
  analysis_out <- mod_analysis_server("analysis",
    dataset = data_out$dataset   # pass reactive from mod_data
  )

  # Module 3: Preview — receives ARD, returns nothing
  mod_preview_server("preview",
    ard = analysis_out$ard       # pass reactive from mod_analysis
  )

  # Module 4: Export — receives ARD + config
  mod_export_server("export",
    ard    = analysis_out$ard,
    config = analysis_out$config
  )
}
```

```r
# R/mod_data.R — returns a list of reactives
mod_data_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    dataset <- reactive({
      req(input$file)
      ext <- tools::file_ext(input$file$datapath)
      switch(ext,
        csv = readr::read_csv(input$file$datapath),
        rds = readRDS(input$file$datapath),
        validate("Unsupported file type")
      )
    })

    # RETURN a named list of reactives — this is the module's API
    list(
      dataset = dataset,
      filename = reactive(input$file$name)
    )
  })
}
```

```r
# R/mod_analysis.R — receives reactive, returns reactive
mod_analysis_server <- function(id, dataset) {
  moduleServer(id, function(input, output, session) {

    # dataset is a reactive passed from the parent
    # Access it by calling dataset() inside reactive contexts

    ard <- reactive({
      req(dataset())
      build_demog_ard(
        adsl    = dataset(),
        groupvar = input$groupvar,
        vars     = input$vars
      )
    })

    config <- reactive({
      list(
        groupvar = input$groupvar,
        vars     = input$vars,
        stats    = input$stats
      )
    })

    list(
      ard    = ard,
      config = config
    )
  })
}
```

### 3.4 Why This Works

- **Testability:** You can test `mod_analysis_server` by passing it a fake
  `reactive(data.frame(...))` — no need to spin up `mod_data`.
- **Reusability:** Modules are self-contained. You can reuse `mod_data` in a
  different app.
- **Readability:** Open `app_server.R` and you see the entire data flow at a glance.

---

## 4. Module Communication — Patterns in Detail

### 4.1 Pattern A: Return a List of Reactives (Preferred)

This is the primary pattern. Each module returns a named list of reactive
expressions.

```r
mod_filter_server <- function(id, dataset) {
  moduleServer(id, function(input, output, session) {

    filtered <- reactive({
      req(dataset())
      d <- dataset()
      if (!is.null(input$age_range)) {
        d <- d |> dplyr::filter(
          AGE >= input$age_range[1],
          AGE <= input$age_range[2]
        )
      }
      d
    })

    # Return list of reactives
    list(
      filtered_data = filtered,
      n_rows = reactive(nrow(filtered())),
      is_filtered = reactive(!is.null(input$age_range))
    )
  })
}

# In app_server:
filter_out <- mod_filter_server("filter", dataset = data_out$dataset)
# Use: filter_out$filtered_data()  inside a reactive context
```

### 4.2 Pattern B: reactiveValues for Mutable Shared State

When multiple modules need to read AND write to the same state, use
`reactiveValues`. The parent creates the shared state and passes it to each module.

```r
# R/app_server.R
app_server <- function(input, output, session) {

  # Shared mutable state — created by the parent
  shared <- reactiveValues(
    dataset  = NULL,
    ard      = NULL,
    titles   = list(title = "", subtitle = "", footnote = ""),
    columns  = NULL
  )

  # Each module receives `shared` and can read/write to it

mod_data_server("data", shared = shared)
  mod_titles_server("titles", shared = shared)
  mod_preview_server("preview", shared = shared)
}
```

```r
# R/mod_data.R — writes to shared state
mod_data_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$file, {
      shared$dataset <- readRDS(input$file$datapath)
    })

  })
}

# R/mod_titles.R — writes to shared state
mod_titles_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {

    observe({
      shared$titles$title    <- input$title
      shared$titles$subtitle <- input$subtitle
      shared$titles$footnote <- input$footnote
    })

  })
}

# R/mod_preview.R — reads from shared state
mod_preview_server <- function(id, shared) {
  moduleServer(id, function(input, output, session) {

    output$table <- renderUI({
      req(shared$ard)
      # render the table using shared$ard and shared$titles
    })

  })
}
```

**Trade-off:** `reactiveValues` is more convenient for complex state but harder to
trace (any module can mutate it). The book recommends the list-of-reactives pattern
when possible and `reactiveValues` only when shared mutable state is genuinely needed.

### 4.3 Pattern C: session$userData for App-Wide Singletons

`session$userData` is an environment attached to the session. It survives across
modules and is useful for storing non-reactive objects that need to be shared
(database connections, config objects, loggers).

```r
# R/app_server.R
app_server <- function(input, output, session) {

  # Store a database connection in session$userData
  session$userData$db_conn <- DBI::dbConnect(
    RSQLite::SQLite(), "mydata.sqlite"
  )

  # Store app-wide config
  session$userData$config <- list(
    max_upload_mb = 50,
    default_format = "RTF"
  )

  onStop(function() {
    DBI::dbDisconnect(session$userData$db_conn)
  })

  mod_data_server("data")
}

# Any module can access it via session$userData
mod_data_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Access parent session's userData
    config <- session$userData$config
    conn   <- session$userData$db_conn
  })
}
```

### 4.4 Pattern D: Trigger Events Across Modules

Use a shared `reactiveVal` as a trigger counter:

```r
# In app_server:
refresh_trigger <- reactiveVal(0)

mod_data_server("data", trigger_refresh = refresh_trigger)
mod_preview_server("preview", refresh_trigger = refresh_trigger)

# In mod_data, when data changes:
observeEvent(input$upload, {
  # ... process upload ...
  trigger_refresh(trigger_refresh() + 1)  # bump the counter
})

# In mod_preview, respond to the trigger:
observeEvent(refresh_trigger(), {
  # re-render preview
}, ignoreInit = TRUE)
```

---

## 5. Testing Pyramid

### 5.1 The Three Levels

```
        /  E2E Tests  \        <- shinytest2 (slow, brittle, few)
       / Module Tests   \      <- testServer() (medium speed, more)
      / Unit Tests (fct_) \    <- testthat (fast, many, the foundation)
     /_____________________\
```

The book is emphatic: **most of your tests should be unit tests on `fct_` functions.**
These are fast, reliable, and test the actual business logic.

### 5.2 Unit Tests for fct_* Functions

```r
# tests/testthat/test-fct_ard_builder.R

test_that("build_demog_ard returns expected columns", {
  adsl <- data.frame(
    USUBJID = paste0("SUBJ", 1:10),
    TRT01P  = rep(c("Placebo", "Drug"), each = 5),
    AGE     = c(55, 60, 45, 70, 65, 50, 58, 62, 48, 72),
    SEX     = c("M","F","M","F","M","F","M","F","M","F")
  )

  result <- build_demog_ard(adsl, groupvar = "TRT01P", vars = "AGE")

  expect_s3_class(result, "tbl_df")
  expect_true("TRT01P" %in% names(result))
  expect_true("AGE_n" %in% names(result))
  expect_true("AGE_mean" %in% names(result))
  expect_equal(nrow(result), 2)  # two treatment groups
})

test_that("build_demog_ard handles missing values", {
  adsl <- data.frame(
    USUBJID = paste0("SUBJ", 1:4),
    TRT01P  = rep(c("A", "B"), each = 2),
    AGE     = c(55, NA, 60, 45)
  )

  result <- build_demog_ard(adsl, groupvar = "TRT01P", vars = "AGE")

  # Group A: n should be 1 (one NA excluded)
  a_row <- result |> dplyr::filter(TRT01P == "A")
  expect_equal(a_row$AGE_n, 1)
})

test_that("fmt_n_pct formats correctly", {
  expect_equal(fmt_n_pct(15, 30.0), "15 (30.0)")
  expect_equal(fmt_n_pct(0, 0, digits = 1), "0 (0.0)")
})
```

### 5.3 Module Tests with testServer()

`testServer()` lets you test module server logic without a browser. You can set
inputs, flush reactives, and check outputs.

```r
# tests/testthat/test-mod_filter.R

test_that("mod_filter_server filters by age range", {

  # Create a fake dataset reactive to pass in
  fake_data <- reactiveVal(data.frame(
    USUBJID = paste0("S", 1:5),
    AGE = c(20, 30, 40, 50, 60),
    SEX = c("M", "F", "M", "F", "M")
  ))

  testServer(mod_filter_server, args = list(dataset = fake_data), {

    # Set the age range input
    session$setInputs(age_range = c(25, 55))

    # Flush reactives and check the returned reactive
    result <- session$getReturned()

    expect_equal(nrow(result$filtered_data()), 3)  # ages 30, 40, 50
    expect_equal(result$n_rows(), 3)
    expect_true(result$is_filtered())
  })
})

test_that("mod_data_server reads CSV files", {

  # Create a temp CSV
  tmp <- tempfile(fileext = ".csv")
  write.csv(data.frame(X = 1:3, Y = letters[1:3]), tmp, row.names = FALSE)

  testServer(mod_data_server, {

    # Simulate file upload
    session$setInputs(file = list(
      datapath = tmp,
      name = "test.csv"
    ))

    result <- session$getReturned()
    expect_equal(nrow(result$dataset()), 3)
    expect_equal(result$filename(), "test.csv")
  })

  unlink(tmp)
})
```

### 5.4 End-to-End Tests with shinytest2

These test the full app in a real browser. They are slow and brittle but catch
integration issues that unit tests miss.

```r
# tests/testthat/test-app-e2e.R

library(shinytest2)

test_that("Full demographics workflow", {
  app <- AppDriver$new(
    app_dir = system.file("app", package = "arbuilder"),
    name = "demog-workflow",
    height = 800,
    width = 1200
  )

  # Upload a file
  app$upload_file(`data-file` = test_path("fixtures", "adsl_test.csv"))

  # Wait for the dataset selector to populate
  app$wait_for_idle()

  # Select variables
  app$set_inputs(`analysis-groupvar` = "TRT01P")
  app$set_inputs(`analysis-vars` = c("AGE", "SEX"))

  # Click generate
  app$click("analysis-generate")
  app$wait_for_idle()

  # Check that the preview panel has content
  preview <- app$get_html("#preview-table")
  expect_true(nchar(preview) > 0)

  # Take a snapshot for visual regression

  app$expect_screenshot()

  app$stop()
})
```

### 5.5 Test Fixtures

Keep test data in `tests/testthat/fixtures/`:

```
tests/
+-- testthat/
|   +-- fixtures/
|   |   +-- adsl_test.csv
|   |   +-- adsl_test.rds
|   |   +-- expected_ard.rds
|   +-- test-fct_ard_builder.R
|   +-- test-mod_filter.R
```

---

## 6. UX Principles

### 6.1 Progressive Disclosure

Don't show everything at once. Reveal complexity as the user needs it.

```r
# Use accordion panels — only the relevant section is open
ui <- page_sidebar(
  sidebar = sidebar(
    accordion(
      accordion_panel("1. Data", icon = bsicons::bs_icon("upload"),
        mod_data_ui("data")
      ),
      accordion_panel("2. Analysis", icon = bsicons::bs_icon("bar-chart"),
        mod_analysis_ui("analysis")
      ),
      accordion_panel("3. Format", icon = bsicons::bs_icon("palette"),
        mod_titles_ui("titles")
      ),
      accordion_panel("4. Export", icon = bsicons::bs_icon("download"),
        mod_export_ui("export")
      )
    )
  ),
  mod_preview_ui("preview")
)
```

Use `conditionalPanel()` or `shinyjs::toggle()` to show controls only when relevant:

```r
# Only show variable selectors after data is uploaded
conditionalPanel(
  condition = "output['data-has_data']",
  ns = ns,
  selectInput(ns("groupvar"), "Grouping variable", choices = NULL),
  selectizeInput(ns("vars"), "Analysis variables", choices = NULL, multiple = TRUE)
)

# In server:
output$has_data <- reactive(!is.null(dataset()))
outputOptions(output, "has_data", suspendWhenHidden = FALSE)
```

### 6.2 Sensible Defaults

Pre-fill inputs with smart defaults so the user can click "Generate" immediately:

```r
observe({
  req(dataset())
  d <- dataset()

  # Auto-detect treatment variable
  trt_candidates <- c("TRT01P", "TRT01A", "TRTA", "TRTP", "ARM")
  trt_var <- intersect(trt_candidates, names(d))[1]
  if (!is.na(trt_var)) {
    updateSelectInput(session, "groupvar", selected = trt_var)
  }

  # Auto-detect demographic variables
  demog_candidates <- c("AGE", "SEX", "RACE", "ETHNIC", "COUNTRY")
  demog_vars <- intersect(demog_candidates, names(d))
  updateSelectizeInput(session, "vars", selected = demog_vars)
})
```

### 6.3 Feedback

Always tell the user what's happening. Never leave them staring at a silent screen.

```r
# Show a spinner during computation
library(shinybusy)

observeEvent(input$generate, {
  show_modal_spinner(text = "Building ARD...")
  result <- build_demog_ard(dataset(), input$groupvar, input$vars)
  ard(result)
  remove_modal_spinner()
})

# Show notifications for success/failure
observeEvent(input$export, {
  tryCatch({
    export_rtf(ard(), config(), output_path)
    showNotification("RTF exported successfully", type = "message")
  }, error = function(e) {
    showNotification(paste("Export failed:", e$message), type = "error")
  })
})
```

### 6.4 validate() and need()

These are Shiny's built-in way to show user-friendly messages instead of errors
or blank outputs.

```r
output$table <- renderTable({
  # validate() stops rendering and shows the message in the output area
  validate(
    need(input$file, "Please upload a dataset to begin."),
    need(input$groupvar, "Please select a grouping variable."),
    need(length(input$vars) > 0, "Please select at least one analysis variable.")
  )

  build_demog_ard(dataset(), input$groupvar, input$vars)
})
```

`validate(need(...))` replaces the output with a grey, styled message. It does
NOT throw an error. It does NOT produce a red error trace. This is what users
should see — not R stack traces.

### 6.5 Disabling Controls

Disable buttons when preconditions aren't met:

```r
library(shinyjs)

observe({
  if (is.null(dataset())) {
    shinyjs::disable("generate")
    shinyjs::disable("export")
  } else {
    shinyjs::enable("generate")
    shinyjs::enable("export")
  }
})
```

---

## 7. CSS/JS Integration

### 7.1 The www/ Directory

Static files go in `inst/app/www/`. In a golem app, `golem::add_resource_path()`
automatically makes this directory available at `/www/` in the browser.

```
inst/
+-- app/
    +-- www/
        +-- custom.css
        +-- custom.js
        +-- logo.png
```

### 7.2 Adding CSS

```r
# R/app_ui.R — reference CSS in the UI
app_ui <- function(request) {
  tagList(
    golem_add_external_resources(),  # loads www/ assets
    page_sidebar(
      title = "arbuilder",
      theme = bs_theme(
        version = 5,
        bootswatch = "flatly",
        primary = "#0054AD"
      ),
      # ... rest of UI
    )
  )
}
```

```r
# In golem, external resources are added via:
golem_add_external_resources <- function() {
  tags$head(
    # Favicon
    favicon(),
    # Add custom CSS
    tags$link(rel = "stylesheet", type = "text/css",
              href = "www/custom.css"),
    # Add custom JS
    tags$script(src = "www/custom.js")
  )
}
```

### 7.3 CSS Scoping by Module

Since modules have namespaced IDs, you can scope CSS to specific modules:

```css
/* inst/app/www/custom.css */

/* === Global styles === */
.sidebar .accordion-button {
  font-weight: 600;
  font-size: 0.95rem;
}

/* === Module-specific styles === */

/* Data module — scope by the module's namespace prefix */
#data-file_progress .progress-bar {
  background-color: #0054AD;
}

/* Preview module */
#preview-table_wrapper {
  font-family: "Courier New", monospace;
  font-size: 0.85rem;
}

#preview-table_wrapper th {
  background-color: #f8f9fa;
  border-bottom: 2px solid #333;
  text-align: center;
}

#preview-table_wrapper td {
  padding: 4px 12px;
  white-space: nowrap;
}

/* Export module */
#export-download_btn {
  width: 100%;
  margin-top: 1rem;
}

/* === RTF-preview styling === */
.rtf-preview {
  background: white;
  border: 1px solid #dee2e6;
  padding: 1in;
  margin: 0 auto;
  max-width: 10in;
  min-height: 7in;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  font-family: "Courier New", monospace;
  font-size: 9pt;
  line-height: 1.3;
}

.rtf-preview .tfl-title {
  text-align: center;
  font-weight: bold;
  margin-bottom: 0.5em;
}

.rtf-preview .tfl-footnote {
  font-size: 8pt;
  border-top: 1px solid #333;
  padding-top: 0.3em;
  margin-top: 1em;
}
```

### 7.4 htmlDependency for Bundled Assets

If you're building a reusable component, use `htmltools::htmlDependency()` to
bundle CSS/JS so it's only included once even if the component appears multiple times:

```r
tfl_preview_deps <- function() {
  htmltools::htmlDependency(
    name = "tfl-preview",
    version = "0.1.0",
    src = system.file("app/www", package = "arbuilder"),
    stylesheet = "tfl-preview.css",
    script = "tfl-preview.js"
  )
}

# Use in a UI function:
tfl_preview_output <- function(id) {
  ns <- NS(id)
  tagList(
    tfl_preview_deps(),
    div(class = "rtf-preview",
      uiOutput(ns("rendered_table"))
    )
  )
}
```

### 7.5 Custom JavaScript

```js
// inst/app/www/custom.js

// Scroll to preview when table is generated
Shiny.addCustomMessageHandler('scroll-to-preview', function(message) {
  var el = document.getElementById(message.id);
  if (el) {
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
});

// Copy generated code to clipboard
Shiny.addCustomMessageHandler('copy-to-clipboard', function(message) {
  navigator.clipboard.writeText(message.text).then(function() {
    Shiny.setInputValue('clipboard_success', true, {priority: 'event'});
  });
});
```

```r
# In server — send a message to JS:
observeEvent(ard(), {
  session$sendCustomMessage("scroll-to-preview", list(id = "preview-table"))
})
```

---

## 8. Performance

### 8.1 Profiling with profvis

Before optimizing, **measure.** Never guess at bottlenecks.

```r
library(profvis)

profvis({
  # Profile the ARD building function
  result <- build_demog_ard(adsl, groupvar = "TRT01P",
                            vars = c("AGE", "SEX", "RACE"))
})

# For Shiny apps, use the profvis recording:
# 1. Start recording: profvis::profvis({ shiny::runApp() })
# 2. Interact with the app
# 3. Stop the app — profvis output appears
```

### 8.2 bindCache — Built-in Caching

`bindCache()` (Shiny 1.6+) caches reactive outputs by their input keys. If the
same inputs are seen again, the cached result is returned instantly.

```r
# Cache the ARD computation by its inputs
ard <- reactive({
  req(dataset())
  build_demog_ard(dataset(), input$groupvar, input$vars)
}) |>
  bindCache(input$groupvar, input$vars, dataset())

# Cache a rendered plot
output$summary_plot <- renderPlot({
  req(ard())
  plot_summary(ard())
}) |>
  bindCache(input$groupvar, input$vars, input$plot_type)
```

### 8.3 memoise — Function-Level Caching

For expensive pure functions that don't depend on reactive inputs:

```r
library(memoise)

# Memoise the file-reading function (cache in memory)
read_adam_cached <- memoise::memoise(function(path) {
  haven::read_sas(path)
}, cache = cachem::cache_mem(max_size = 512 * 1024^2))  # 512 MB limit

# Memoise with disk cache (survives app restarts)
read_adam_disk <- memoise::memoise(function(path) {
  haven::read_sas(path)
}, cache = cachem::cache_disk(dir = tempdir()))

# Use in a module:
dataset <- reactive({
  req(input$file)
  read_adam_cached(input$file$datapath)
})
```

### 8.4 Server-Side DataTable (DT)

For large datasets, always use server-side processing:

```r
output$data_preview <- DT::renderDataTable({
  req(dataset())
  DT::datatable(
    dataset(),
    server = TRUE,           # THIS IS THE KEY — server-side processing
    options = list(
      pageLength = 25,
      scrollX = TRUE,
      scrollY = "400px",
      dom = "frtip",         # filter, records, table, info, pagination
      deferRender = TRUE,    # only render visible rows
      scroller = TRUE        # virtual scrolling
    ),
    filter = "top",
    rownames = FALSE
  )
})
```

**Without `server = TRUE`**, DT sends the entire dataset to the browser as JSON.
For a 10,000-row ADaM dataset, this is slow and wastes memory. With server-side
mode, only the visible rows are sent.

### 8.5 Async with promises/future

For truly long-running operations (seconds to minutes), use async to avoid
blocking other users (relevant for multi-user deployments):

```r
library(promises)
library(future)
plan(multisession, workers = 2)

output$heavy_table <- renderTable({
  req(dataset())

  future_promise({
    # This runs in a background R process
    heavy_computation(dataset())
  }) %...>% (function(result) {
    result
  }) %...!% (function(error) {
    showNotification(paste("Error:", error$message), type = "error")
    NULL
  })
})
```

### 8.6 Reactive Graph Optimization

```r
# BAD: One reactive that does everything — recalculates all when anything changes
everything <- reactive({
  data <- read_data(input$file)
  filtered <- filter_data(data, input$filters)
  ard <- build_ard(filtered, input$vars)
  formatted <- format_ard(ard, input$format)
  formatted
})

# GOOD: Chain of small reactives — only downstream nodes recalculate
raw_data <- reactive({ read_data(input$file) })
filtered_data <- reactive({ filter_data(raw_data(), input$filters) })
ard <- reactive({ build_ard(filtered_data(), input$vars) })
formatted <- reactive({ format_ard(ard(), input$format) })
# Changing input$format only re-runs format_ard, not the whole pipeline
```

---

## 9. Error Handling

### 9.1 tryCatch in Shiny

Wrap any operation that can fail (file I/O, data processing, export):

```r
observeEvent(input$upload, {
  tryCatch({
    d <- haven::read_sas(input$file$datapath)
    dataset(d)
    showNotification(
      paste("Loaded", nrow(d), "rows,", ncol(d), "columns"),
      type = "message"
    )
  },
  error = function(e) {
    showNotification(
      paste("Failed to read file:", e$message),
      type = "error",
      duration = 10
    )
    dataset(NULL)
  },
  warning = function(w) {
    showNotification(
      paste("Warning:", w$message),
      type = "warning"
    )
    invokeRestart("muffleWarning")
  })
})
```

### 9.2 validate/need for Rendering

Use `validate(need(...))` in every render function that depends on user input:

```r
output$preview <- renderUI({
  validate(
    need(dataset(), "Upload a dataset to begin."),
    need(nrow(dataset()) > 0, "Dataset is empty."),
    need(input$groupvar %in% names(dataset()),
         paste0("Variable '", input$groupvar, "' not found in the dataset.")),
    need(all(input$vars %in% names(dataset())),
         "One or more selected variables not found in the dataset.")
  )

  # Safe to proceed — all preconditions validated
  ard <- build_demog_ard(dataset(), input$groupvar, input$vars)
  render_tfl(ard)
})
```

### 9.3 Logging

For production apps, log events so you can debug issues after the fact:

```r
# Simple logging with the logger package
library(logger)

# Set log level based on environment
if (golem::app_prod()) {
  log_threshold(WARN)
} else {
  log_threshold(DEBUG)
}

# In modules:
mod_data_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    observeEvent(input$file, {
      log_info("File uploaded: {input$file$name}, size: {input$file$size}")

      tryCatch({
        d <- read_data(input$file$datapath)
        log_info("Dataset loaded: {nrow(d)} rows x {ncol(d)} cols")
        dataset(d)
      }, error = function(e) {
        log_error("Failed to load file: {e$message}")
        showNotification("Could not read file", type = "error")
      })
    })
  })
}
```

### 9.4 Graceful Degradation

```r
# Instead of crashing, show a fallback
safe_render_tfl <- function(ard, config) {
  tryCatch(
    render_tfl(ard, config),
    error = function(e) {
      tags$div(
        class = "alert alert-warning",
        tags$strong("Preview unavailable"),
        tags$p("Could not render the table. Error: ", e$message),
        tags$p("Try adjusting your configuration and regenerating.")
      )
    }
  )
}
```

---

## 10. Deployment

### 10.1 App-as-Package

Since golem apps are R packages, deployment means installing the package:

```r
# Install and run
remotes::install_github("yourorg/arbuilder")
arbuilder::run_app()

# Or from a local directory
remotes::install_local("path/to/arbuilder")
arbuilder::run_app()
```

### 10.2 Docker

The book recommends Docker for reproducible deployment. golem provides a
Dockerfile generator:

```r
golem::add_dockerfile()         # basic Dockerfile
golem::add_dockerfile_shinyproxy()  # for ShinyProxy
golem::add_dockerfile_heroku()      # for Heroku
```

Example Dockerfile:

```dockerfile
FROM rocker/verse:4.3.1

# System dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R package dependencies
RUN install2.r --error --skipinstalled \
    shiny bslib DT shinyAce htmltools shinyjs \
    dplyr tidyr purrr stringr tibble readr forcats glue \
    haven

# Copy and install the app package
COPY . /app
RUN R CMD INSTALL /app

# Expose port and run
EXPOSE 3838
CMD ["R", "-e", "arbuilder::run_app(host='0.0.0.0', port=3838)"]
```

```bash
# Build and run
docker build -t arbuilder .
docker run -p 3838:3838 arbuilder
```

### 10.3 RStudio Connect / Posit Connect

```r
# Generate the app.R file that Connect expects
golem::add_rstudioconnect_file()
# Creates app.R with:
#   pkgload::load_all()
#   arbuilder::run_app()

# Or use the manifest approach
rsconnect::writeManifest()
rsconnect::deployApp()
```

### 10.4 ShinyProxy (Enterprise)

For multi-user enterprise deployment, ShinyProxy launches a fresh Docker
container per user session:

```yaml
# application.yml for ShinyProxy
specs:
  - id: arbuilder
    display-name: ARBuilder
    container-image: arbuilder:latest
    container-cmd: ["R", "-e", "arbuilder::run_app(host='0.0.0.0', port=3838)"]
    port: 3838
```

### 10.5 Local Desktop (arbuilder's Primary Mode)

For arbuilder specifically (runs on a laptop, no server):

```r
# In R/run_app.R — optimized for local use
run_app <- function(port = 3838, launch.browser = TRUE, ...) {
  shinyApp(
    ui = app_ui,
    server = app_server,
    options = list(
      port = port,
      launch.browser = launch.browser,
      host = "127.0.0.1"   # local only, no external access
    )
  )
}
```

---

## 11. Configuration — golem-config.yml

### 11.1 Environment-Specific Settings

golem uses `config::get()` backed by a YAML file to manage settings across
environments:

```yaml
# inst/golem-config.yml

default:
  golem_name: arbuilder
  golem_version: 0.1.0
  app_prod: no
  max_upload_mb: 100
  default_output_format: RTF
  log_level: DEBUG
  data_dir: "."

production:
  app_prod: yes
  max_upload_mb: 50
  log_level: WARN
  data_dir: "/data/adam"

staging:
  app_prod: no
  max_upload_mb: 200
  log_level: INFO
  data_dir: "/data/adam_staging"
```

### 11.2 Accessing Config in Code

```r
# R/app_config.R (generated by golem)

#' Access configuration
#' @param value Name of the config value to retrieve
#' @param config Name of the configuration (default, production, staging)
#' @param use_parent Logical, use parent directory's config
#' @export
get_golem_config <- function(
  value,
  config = Sys.getenv("R_CONFIG_ACTIVE", Sys.getenv("GOLEM_CONFIG_ACTIVE", "default")),
  use_parent = TRUE
) {
  config::get(
    value = value,
    config = config,
    file = app_sys("golem-config.yml"),
    use_parent = use_parent
  )
}
```

```r
# Using config in server code:
mod_data_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    max_mb <- get_golem_config("max_upload_mb")

    # Set upload limit
    options(shiny.maxRequestSize = max_mb * 1024^2)

    # Use configured data directory
    data_dir <- get_golem_config("data_dir")

    observeEvent(input$browse_server, {
      files <- list.files(data_dir, pattern = "\\.(sas7bdat|csv|rds)$")
      updateSelectInput(session, "server_file", choices = files)
    })
  })
}
```

### 11.3 Switching Environments

```bash
# Set the active config via environment variable
R_CONFIG_ACTIVE=production Rscript -e "arbuilder::run_app()"

# Or in .Renviron
echo "R_CONFIG_ACTIVE=production" >> .Renviron

# Or in Docker
docker run -e R_CONFIG_ACTIVE=production -p 3838:3838 arbuilder
```

### 11.4 golem Options (Runtime)

golem also supports runtime options passed through `run_app()`:

```r
# Pass runtime options
arbuilder::run_app(
  data_path = "/custom/path/to/adam",
  output_dir = "/custom/output"
)

# Access in server:
app_server <- function(input, output, session) {
  data_path  <- golem::get_golem_options("data_path")
  output_dir <- golem::get_golem_options("output_dir")

  mod_data_server("data", data_path = data_path)
  mod_export_server("export", output_dir = output_dir)
}
```

---

## Summary of Key Takeaways for arbuilder

1. **Structure the app as a package** even if not using golem. Use `mod_`, `fct_`,
   `utils_` prefixes consistently.

2. **Use the comb strategy.** `app_server.R` is the spine. Modules are the teeth.
   All wiring happens in `app_server.R`.

3. **Put business logic in `fct_` functions.** `ard_demog.R`, formatting functions,
   data validation — all plain R, no reactives, fully testable.

4. **Return list of reactives from modules.** This is the standard API contract.
   Use `reactiveValues` only for genuinely shared mutable state.

5. **Test the pyramid.** Many unit tests on `fct_*` functions. Some `testServer()`
   tests on modules. A few E2E tests for critical workflows.

6. **validate/need everywhere.** Never let users see R error traces. Every
   `render*` function should validate its preconditions.

7. **Profile before optimizing.** Use `profvis`. Then apply `bindCache`,
   server-side DT, and reactive chain splitting as needed.

8. **Use config for environment differences.** Keep dev/prod settings in
   `golem-config.yml`, not hardcoded in R files.

---

# Book 2: Mastering Shiny

# Mastering Shiny — Comprehensive Notes

Notes from "Mastering Shiny" by Hadley Wickham (https://mastering-shiny.org/).
Focused on patterns relevant to building complex, multi-module production Shiny apps.

---

## 1. Reactive Programming Patterns

### 1.1 The Reactive Graph

Shiny's execution model is **reactive**, not imperative. You don't tell Shiny
*when* to run code — you declare *relationships* between inputs, reactive
expressions, and outputs. Shiny builds a **reactive graph** and uses it to
determine what to re-execute when an input changes.

Three fundamental building blocks:

- **Reactive sources** (`input$x`) — values that change due to user action.
- **Reactive conductors** (`reactive()`) — intermediate computations that
  depend on sources and are depended upon by endpoints.
- **Reactive endpoints** (`output$x`, `observe()`) — side effects that
  consume reactive values.

The graph is **directed and acyclic** (DAG). Shiny traces it at runtime
to know exactly which outputs need re-execution when an input changes.

### 1.2 Reactive Expressions (`reactive()`)

```r
data_filtered <- reactive({
  df %>% filter(group == input$group)
})
```

Key properties:
- **Lazy**: only runs when someone reads its value via `data_filtered()`.
- **Cached**: runs once per invalidation, caches the result, returns the
  cached result for subsequent reads in the same flush cycle.
- **No side effects**: should be a pure computation. Never do file I/O,
  database writes, or print inside a `reactive()`.

A reactive expression is both a **consumer** (it reads reactive sources) and
a **producer** (other reactives/outputs can read it). This is what makes it a
"conductor" in the graph.

**Use `reactive()` to factor out shared computations.** If two outputs both
need filtered data, put the filtering in a `reactive()` so it runs once, not
twice.

### 1.3 Observers (`observe()` and `observeEvent()`)

```r
observeEvent(input$save, {
  write.csv(data(), "output.csv")
  showNotification("Saved!")
})
```

Key properties:
- **Eager**: run as soon as their dependencies invalidate (at the end of the
  flush cycle). You never call an observer — it calls itself.
- **Side-effect-oriented**: the whole point is to *do something* — write a
  file, show a notification, update an input.
- **No return value**: the result of an observer is discarded. Never try to
  "read" an observer's output.

`observe()` runs whenever *any* reactive dependency inside it changes.
`observeEvent()` runs only when a specific trigger (first argument) fires,
ignoring changes to other reactive values read in the handler body.

**`observeEvent()` vs `observe()`:**
- Use `observeEvent(input$button, { ... })` when you want to react to a
  specific event (button click, etc.).
- Use `observe({ ... })` when you want to react to *any* change in the
  reactive values read inside the expression. This is rarer and more
  dangerous — easy to create infinite loops if you update an input that
  you're also reading.

### 1.4 `reactiveVal()` and `reactiveValues()`

```r
# Single reactive value (like a reactive variable)
count <- reactiveVal(0)
observeEvent(input$increment, {
  count(count() + 1)
})

# Named list of reactive values
rv <- reactiveValues(data = NULL, filter = "all")
observeEvent(input$upload, {
  rv$data <- read.csv(input$upload$datapath)
})
```

- `reactiveVal()` — single mutable reactive value. Read with `count()`, write
  with `count(new_value)`.
- `reactiveValues()` — named list of reactive values. Read/write with `rv$name`.
- Both are **reactive sources** — reading them creates a dependency, writing
  to them triggers invalidation.
- Essential for state that changes programmatically (not just from UI inputs).

### 1.5 Invalidation and the Flush Cycle

When an input changes:
1. Shiny marks the input as **invalidated**.
2. All reactive expressions and observers that depend on it are also
   marked invalidated (transitively through the graph).
3. At the end of the flush cycle, Shiny re-executes all invalidated
   endpoints (outputs and observers).
4. When an endpoint runs, it reads reactive expressions, which triggers
   their re-execution (lazy evaluation).
5. Fresh values propagate through the graph.

**Key insight:** Invalidation propagates *eagerly* (immediately marks
everything downstream), but re-execution is *lazy* (only runs when pulled
or when observers flush).

### 1.6 `isolate()`

```r
output$text <- renderText({
  # React to button click, but read input$n without creating a dependency
  input$go
  isolate(paste("Value:", input$n))
})
```

`isolate()` reads a reactive value **without taking a dependency** on it.
The expression inside `isolate()` evaluates to the current value, but changes
to that value won't trigger re-execution.

`observeEvent(trigger, handler)` is essentially syntactic sugar for:
```r
observe({
  trigger  # take dependency
  isolate(handler)  # read other values without dependency
})
```

### 1.7 `req()` — Requiring Values

```r
data <- reactive({
  req(input$file)
  read.csv(input$file$datapath)
})
```

`req()` checks that its arguments are "truthy" (not NULL, not empty string,
not FALSE, not NA). If they fail, it **silently stops** execution of the
current reactive/output — no error message, the output just stays blank or
shows its previous value.

Critical for preventing cascading errors when upstream inputs haven't been
set yet (e.g., file upload is NULL on app load).

`req(input$x, cancelOutput = TRUE)` preserves the previous output value
instead of clearing it.

### 1.8 `bindEvent()` / `eventReactive()`

```r
# Modern style (Shiny 1.7+)
data <- reactive({ read.csv(input$file$datapath) }) |> bindEvent(input$go)

# Older style (still works fine)
data <- eventReactive(input$go, {
  read.csv(input$file$datapath)
})
```

Creates a reactive expression that only re-executes when a specific event
fires, not when its other dependencies change. The body can read any
reactive values, but only the event trigger causes re-execution.

### 1.9 Timed Invalidation

```r
reactive({
  invalidateLater(5000)  # re-run every 5 seconds
  read.csv("live_data.csv")
})
```

`invalidateLater(millis)` inside a reactive or observer causes it to
automatically re-execute after the specified number of milliseconds.
Useful for polling data sources.

### 1.10 `on.exit()` and `onFlush()` / `onFlushed()`

- `session$onFlush(callback)` — runs callback just before outputs are sent
  to the client.
- `session$onFlushed(callback)` — runs callback just after outputs are sent.
- `session$onSessionEnded(callback)` — cleanup when a session closes.

---

## 2. Module Patterns

### 2.1 Why Modules?

As Shiny apps grow, the server function becomes unmanageable. Modules solve
three problems:
1. **Namespace isolation** — IDs don't collide between modules.
2. **Encapsulation** — internal logic is hidden; modules communicate through
   defined interfaces (arguments and return values).
3. **Reusability** — the same module can be used multiple times in one app
   or across apps.

### 2.2 Module Structure

Every module has exactly two functions:

```r
# UI function
my_module_ui <- function(id) {
  ns <- NS(id)
  tagList(
    selectInput(ns("var"), "Variable", choices = NULL),
    plotOutput(ns("plot"))
  )
}

# Server function
my_module_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    observe({
      updateSelectInput(session, "var", choices = names(data()))
    })
    output$plot <- renderPlot({
      req(input$var)
      hist(data()[[input$var]])
    })
  })
}
```

### 2.3 Namespacing (`NS()`)

`NS(id)` creates a **namespace function**. `ns("var")` produces `"id-var"`.
This is how Shiny keeps IDs unique when the same module is used multiple times.

Rules:
- **UI function**: wrap every `inputId` and `outputId` with `ns()`.
- **Server function**: do NOT namespace. Inside `moduleServer()`, `input$var`
  automatically resolves to the namespaced ID.
- **Nested modules**: when calling a child module's UI from a parent module's
  UI, wrap the child's `id` with the parent's `ns()`:
  ```r
  parent_ui <- function(id) {
    ns <- NS(id)
    tagList(
      child_ui(ns("child1"))
    )
  }
  ```

### 2.4 Module Communication

**Inputs to modules** — pass data via arguments to the server function:
```r
# In the parent:
mod_plot_server("plot1", data = filtered_data)

# In the module:
mod_plot_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    # data is a reactive — call it with data()
  })
}
```

**CRITICAL CONVENTION**: Pass reactives, not reactive *values*:
```r
# CORRECT — pass the reactive itself (without parentheses)
mod_plot_server("plot1", data = filtered_data)

# WRONG — passes a snapshot, not reactive. Module won't update.
mod_plot_server("plot1", data = filtered_data())
```

**Return values from modules** — return reactive(s) from the server function:
```r
mod_filter_server <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    filtered <- reactive({
      data() %>% filter(group == input$group)
    })
    # Return the reactive
    filtered
  })
}

# In the parent:
filtered_data <- mod_filter_server("filter1", data = raw_data)
# Now filtered_data is a reactive, use filtered_data() to read it.
```

For modules that return multiple values, return a **named list of reactives**:
```r
mod_config_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    list(
      selected_var = reactive(input$var),
      n_bins = reactive(input$bins),
      show_title = reactive(input$show_title)
    )
  })
}

# In the parent:
config <- mod_config_server("config1")
# Use: config$selected_var(), config$n_bins(), etc.
```

### 2.5 Nested Modules

Modules can contain other modules. This is how you build a hierarchy:

```r
parent_ui <- function(id) {
  ns <- NS(id)
  tagList(
    child_a_ui(ns("child_a")),
    child_b_ui(ns("child_b"))
  )
}

parent_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result_a <- child_a_server("child_a")
    child_b_server("child_b", data = result_a)
  })
}
```

The namespaces compose: if parent is "parent" and child is "child_a",
input IDs in the child become "parent-child_a-var".

### 2.6 Module Testing

Modules can be tested with `testServer()`:
```r
testServer(mod_filter_server, args = list(data = reactive(mtcars)), {
  session$setInputs(group = "4")
  expect_equal(nrow(filtered()), 11)
})
```

Or tested in isolation by wrapping in a minimal app:
```r
# For manual testing / visual QA
mod_demo <- function() {
  ui <- fluidPage(mod_filter_ui("test"))
  server <- function(input, output, session) {
    mod_filter_server("test", data = reactive(mtcars))
  }
  shinyApp(ui, server)
}
```

### 2.7 Common Module Anti-Patterns

- **Don't use `session$userData` for inter-module communication.** Pass
  reactives explicitly. Shared mutable state is hard to debug.
- **Don't access parent's `input` from a child module.** Everything the
  child needs should be passed as an argument.
- **Don't return non-reactive values** from modules if the data can change.
  Always return `reactive()` or `reactiveVal()`.
- **Don't overuse modules.** If a piece of UI/logic is only used once and
  is small, keeping it in the main app is fine.

---

## 3. Dynamic UI

### 3.1 `update*` Functions (Preferred for Simple Cases)

Every input widget has a corresponding `update*` function:
```r
updateSelectInput(session, "var", choices = names(data()))
updateSliderInput(session, "n", min = 1, max = nrow(data()))
updateTextInput(session, "label", value = "New label")
updateNumericInput(session, "bins", value = 30, min = 1, max = 100)
updateCheckboxInput(session, "show", value = TRUE)
updateRadioButtons(session, "type", selected = "bar")
updateTabsetPanel(session, "tabs", selected = "Results")
```

**Key points:**
- Called from the server, not the UI.
- Only sends the *changes* to the browser — much more efficient than
  re-rendering the entire widget.
- Use inside `observe()` or `observeEvent()`.
- The `session` argument is the session from the enclosing server function
  (or `moduleServer`).
- `inputId` is NOT namespaced in `update*` calls inside a module — the
  session handles namespacing automatically.

### 3.2 Conditional UI with `conditionalPanel()`

```r
conditionalPanel(
  condition = "input.show_options == true",
  sliderInput("n", "N", 1, 100, 50)
)
```

- The condition is a **JavaScript expression** (not R).
- Evaluated client-side — no round-trip to the server.
- Use `input.name` (dot notation, not dollar sign).
- Good for simple show/hide. Not suitable for complex logic.

**In modules**, namespace the input reference in the JS condition:
```r
conditionalPanel(
  condition = paste0("input['", ns("show_options"), "']"),
  sliderInput(ns("n"), "N", 1, 100, 50)
)
```

### 3.3 `renderUI()` / `uiOutput()` (Server-Side Dynamic UI)

```r
# UI
uiOutput("dynamic_controls")

# Server
output$dynamic_controls <- renderUI({
  req(input$type)
  if (input$type == "histogram") {
    sliderInput("bins", "Bins", 1, 100, 30)
  } else {
    selectInput("color", "Color", c("red", "blue", "green"))
  }
})
```

**Key points:**
- Most flexible approach — can generate any UI.
- The UI is rendered server-side and sent to the client as HTML.
- **Problem: input values reset** every time `renderUI()` re-executes.
  The browser destroys the old widget and creates a new one, losing user state.
- **Problem: brief NULL period.** When `renderUI()` re-executes, there's a
  moment where the dynamically-created inputs don't exist yet, so
  `input$bins` is NULL. Use `req()` downstream.
- **Problem: timing.** The new inputs created by `renderUI()` aren't
  available in `input` until the next flush cycle. If you try to read them
  in the same reactive chain that created them, they'll be NULL.

**In modules**, wrap dynamic input IDs with `ns()`:
```r
output$dynamic <- renderUI({
  ns <- session$ns  # get the namespace function inside the server
  sliderInput(ns("bins"), "Bins", 1, 100, 30)
})
```

### 3.4 `insertUI()` / `removeUI()`

```r
observeEvent(input$add, {
  id <- paste0("item_", input$add)
  insertUI(
    selector = "#placeholder",
    where = "afterEnd",
    ui = textInput(id, paste("Item", input$add))
  )
})

observeEvent(input$remove, {
  removeUI(selector = paste0("#item_", input$remove))
})
```

- More surgical than `renderUI()` — adds/removes specific elements without
  touching the rest.
- `selector` is a CSS selector.
- `where`: "beforeBegin", "afterBegin", "beforeEnd", "afterEnd".
- Inserted elements persist — they don't get destroyed when other things
  update.
- **Problem**: Shiny doesn't automatically clean up `input` values for
  removed elements. They stick around as zombie values in `input`.

### 3.5 Dynamic Number of Modules

A common advanced pattern — generating a variable number of module instances:

```r
# Track IDs
module_ids <- reactiveVal(character(0))

observeEvent(input$add_module, {
  new_id <- paste0("mod_", length(module_ids()) + 1)
  module_ids(c(module_ids(), new_id))

  insertUI("#module_container", "beforeEnd",
    mod_item_ui(new_id)
  )
  mod_item_server(new_id, ...)
})
```

**Warning**: `moduleServer()` calls should only happen once per module
instance. If you call `mod_item_server("mod_1", ...)` twice, you get
duplicate observers. Use a tracking mechanism to avoid this.

---

## 4. Performance

### 4.1 Reactlog

```r
# Enable before running the app
options(shiny.reactlog = TRUE)
library(reactlog)
shiny::reactlogShow()  # after app runs, opens an interactive viewer
```

- Visualizes the reactive graph and execution order.
- Shows which reactives were invalidated, which re-executed, and which
  were pulled from cache.
- Essential for debugging unexpected re-executions.
- Press Ctrl+F3 in a running app to snapshot the reactlog (when enabled).
- **Performance cost** — don't leave reactlog enabled in production.

### 4.2 Profiling with `profvis`

```r
library(profvis)
profvis({
  shiny::runApp(".")
})
```

- Standard R profiling — shows where time is spent.
- Useful for identifying slow computations in reactive expressions.
- Flame graph shows call stack over time.
- Focus on the "hot" paths — the tallest/widest bars.

### 4.3 `bindCache()` (Shiny 1.6+)

```r
output$plot <- renderPlot({
  expensive_plot(input$dataset, input$var)
}) %>% bindCache(input$dataset, input$var)

# Also works with reactive()
data <- reactive({
  expensive_computation(input$params)
}) %>% bindCache(input$params)
```

- Caches the result keyed on the specified inputs.
- If the same combination of inputs has been seen before, returns the
  cached result without re-executing the expression.
- Cache is **per-session** by default. Use `cache = "app"` for cross-session:
  ```r
  bindCache(input$x, input$y, cache = "app")
  ```
- App-level cache is great for expensive computations that don't depend
  on session-specific state.
- Default cache store is memory. Can use disk:
  ```r
  shinyOptions(cache = cachem::cache_disk("./app_cache"))
  ```
- **Cache key must fully determine the output.** If the output depends on
  something not in the cache key, you'll get stale/wrong results.

### 4.4 `bindEvent()` for Controlling Execution

```r
output$plot <- renderPlot({
  expensive_plot(data())
}) %>% bindEvent(input$go)
```

Not caching per se, but prevents expensive computations from running until
the user explicitly requests it (e.g., clicking a button). Reduces
unnecessary re-executions.

### 4.5 Async with `promises` and `future`

```r
library(promises)
library(future)
plan(multisession)  # use background R processes

output$result <- renderTable({
  future_promise({
    slow_computation(isolate(input$params))
  }) %...>% {
    .  # the result
  }
})
```

**Why async?** Shiny is single-threaded by default. A slow computation in
one session blocks *all other sessions*. Async offloads work to a background
process, freeing the main Shiny process to serve other users.

**Key points:**
- `future_promise()` runs code in a background R process.
- Returns a promise object. Use `%...>%` (pipe) or `then()` to handle the
  result.
- `%...!%` handles errors.
- The **current session** still waits (the user who triggered it still sees
  a spinner), but **other sessions** are unblocked.
- You cannot access `input`, `output`, or `session` inside the future.
  Read all reactive values *before* entering the future (use `isolate()` or
  read them into local variables).
- `plan(multisession)` — each future gets its own R process. Safest, works
  everywhere.
- `plan(multicore)` — forked processes, Linux/Mac only, faster but can have
  issues with certain packages.

**Extended async pattern:**
```r
data <- reactive({
  params <- list(x = input$x, y = input$y)
  future_promise({
    slow_query(params$x, params$y)
  })
})

output$table <- renderTable({
  data() %...>% head(10)
})
```

### 4.6 General Performance Tips from the Book

- **Minimize reactive scope.** Don't put everything in one giant reactive.
  Break computations into smaller reactives so only the necessary parts
  re-execute.
- **Move computation outside of reactives** when possible. If something
  doesn't depend on inputs, compute it once at the top of the server
  function (or outside the server entirely).
- **Use `req()` early.** Prevents downstream code from running when
  prerequisites aren't met.
- **Plot caching** is particularly valuable because plots are expensive.
  `renderCachedPlot()` (older API) or `renderPlot() %>% bindCache()`.

---

## 5. Tidy Evaluation in Shiny

### 5.1 The Problem

Users select column names via `input$var` as strings. Tidyverse functions
use non-standard evaluation (NSE). You need to bridge the gap.

### 5.2 The `.data` Pronoun (Recommended Approach)

```r
data() %>%
  filter(.data[[input$var]] > input$threshold) %>%
  group_by(.data[[input$group]]) %>%
  summarize(mean = mean(.data[[input$var]], na.rm = TRUE))
```

`.data` is a pronoun from `rlang` (re-exported by dplyr). `.data[[string]]`
lets you use a string to refer to a column. This is the **safest and
simplest** approach.

### 5.3 `!!` (Bang-Bang) with `sym()`

```r
var <- sym(input$var)
data() %>%
  filter(!!var > input$threshold)
```

Or inline:
```r
data() %>%
  filter(!!sym(input$var) > input$threshold)
```

`sym()` converts a string to a symbol. `!!` unquotes it into the expression.
Works but is more complex than `.data[[]]`.

### 5.4 `across()` for Multiple Columns

```r
data() %>%
  summarize(across(all_of(input$vars), list(
    mean = ~mean(.x, na.rm = TRUE),
    sd = ~sd(.x, na.rm = TRUE)
  )))
```

`all_of()` and `any_of()` convert character vectors to tidy selections.
Essential when the user selects multiple columns.

### 5.5 `aes()` in ggplot2

```r
ggplot(data(), aes(x = .data[[input$x]], y = .data[[input$y]])) +
  geom_point()
```

Same `.data` pronoun works in `aes()`.

For string-based aesthetics with no column reference:
```r
aes(color = .data[[input$color_var]])
```

### 5.6 User-Supplied Expressions (Advanced)

If you let users type R expressions (dangerous but sometimes needed):
```r
expr <- parse(text = input$filter_expr)
data() %>% filter(eval(expr))
```

**Security warning**: Never do this in a multi-user/public app. User-supplied
code is arbitrary code execution.

### 5.7 Functional Programming Patterns

When you want to parameterize the *function* applied:
```r
stat_fn <- switch(input$stat,
  "mean" = mean,
  "median" = median,
  "sd" = sd
)
data() %>%
  summarize(result = stat_fn(.data[[input$var]], na.rm = TRUE))
```

---

## 6. Layout and Themes (bslib)

### 6.1 Page-Level Layouts

```r
# Modern bslib approach (Bootstrap 5)
ui <- page_sidebar(
  title = "My App",
  sidebar = sidebar(
    selectInput("var", "Variable", choices = names(mtcars))
  ),
  card(
    card_header("Plot"),
    plotOutput("plot")
  )
)

# Multi-page with navbar
ui <- page_navbar(
  title = "My App",
  theme = bs_theme(bootswatch = "flatly"),
  nav_panel("Tab 1", ...),
  nav_panel("Tab 2", ...),
  nav_spacer(),
  nav_menu("More",
    nav_panel("Tab 3", ...),
    nav_panel("Tab 4", ...)
  )
)

# Fillable page (contents expand to fill browser)
ui <- page_fillable(
  layout_columns(
    card(plotOutput("plot1")),
    card(plotOutput("plot2"))
  )
)
```

### 6.2 Layout Functions

```r
# Column-based layout
layout_columns(
  col_widths = c(4, 8),  # Bootstrap 12-column grid
  card(...),
  card(...)
)

# Responsive breakpoints
layout_columns(
  col_widths = breakpoints(sm = c(12, 12), md = c(4, 8)),
  card(...),
  card(...)
)

# layout_column_wrap — equal-width columns that wrap
layout_column_wrap(
  width = "250px",  # minimum column width
  card(...),
  card(...),
  card(...)
)
```

### 6.3 Cards

```r
card(
  card_header("Title"),
  card_body(
    plotOutput("plot")
  ),
  card_footer("Footer text"),
  full_screen = TRUE  # adds expand button
)

# Cards with multiple body sections and a sidebar
card(
  card_header("Analysis"),
  layout_sidebar(
    sidebar = sidebar(
      selectInput("var", "Variable", choices)
    ),
    plotOutput("plot")
  )
)
```

### 6.4 Sidebar

```r
sidebar(
  title = "Controls",
  width = 300,  # pixels
  open = "open",  # "open", "closed", "always" (can't be closed)
  selectInput("x", "X", choices),
  selectInput("y", "Y", choices)
)
```

Sidebars can be nested inside `page_sidebar()`, `layout_sidebar()`, and
`card()`.

### 6.5 Accordions

```r
accordion(
  id = "controls",
  open = "Data",  # which panel starts open
  accordion_panel("Data",
    fileInput("file", "Upload CSV"),
    icon = bsicons::bs_icon("database")
  ),
  accordion_panel("Analysis",
    selectInput("stat", "Statistic", c("mean", "median")),
    icon = bsicons::bs_icon("calculator")
  ),
  accordion_panel("Display",
    checkboxInput("title", "Show Title", TRUE),
    icon = bsicons::bs_icon("palette")
  )
)
```

Accordions inside sidebars give you collapsible sections — excellent for
apps with many controls.

### 6.6 Value Boxes

```r
value_box(
  title = "Total Subjects",
  value = textOutput("n_subjects"),
  showcase = bsicons::bs_icon("people"),
  theme = "primary"
)
```

### 6.7 Theming with `bs_theme()`

```r
theme <- bs_theme(
  version = 5,                  # Bootstrap version
  bootswatch = "flatly",        # Bootswatch theme
  bg = "#FFFFFF",               # background
  fg = "#333333",               # foreground (text)
  primary = "#0062cc",          # primary color
  base_font = font_google("Open Sans"),
  heading_font = font_google("Roboto Slab"),
  font_scale = 0.9
)

ui <- page_navbar(
  theme = theme,
  ...
)
```

**Real-time theme customization** during development:
```r
ui <- page_navbar(
  theme = bs_theme() |> bs_theme_preview(),
  ...
)
# This adds a theme-picker widget to the app for interactive tuning.
```

Or use `bs_themer()` in the server:
```r
server <- function(input, output, session) {
  bs_themer()  # adds theme editor overlay
  ...
}
```

### 6.8 CSS Customization

```r
# Add custom CSS
ui <- page_sidebar(
  theme = bs_theme(),
  tags$head(
    tags$style(HTML("
      .card { margin-bottom: 1rem; }
      .sidebar { background-color: #f8f9fa; }
    "))
  ),
  ...
)

# Or use bs_add_rules() for Sass
theme <- bs_theme() |>
  bs_add_rules(".my-class { color: $primary; }")
```

---

## 7. Uploads and Downloads

### 7.1 File Upload

```r
# UI
fileInput("file", "Upload CSV",
  accept = c(".csv", ".tsv", "text/csv"),
  multiple = FALSE,
  buttonLabel = "Browse...",
  placeholder = "No file selected"
)

# Server
data <- reactive({
  req(input$file)
  ext <- tools::file_ext(input$file$name)
  switch(ext,
    csv = read.csv(input$file$datapath),
    tsv = read.delim(input$file$datapath),
    validate("Invalid file type. Please upload a CSV or TSV file.")
  )
})
```

**`input$file` structure** (a data frame with one row per file):
- `name` — original filename
- `size` — file size in bytes
- `type` — MIME type (may be empty)
- `datapath` — temporary path where Shiny stored the uploaded file

**Key points:**
- `datapath` is a temp file. The filename is NOT the original name —
  it's something like `/tmp/Rtmp.../0.csv`. Use `input$file$name` for the
  original name.
- Default upload limit is 5 MB. Increase with:
  ```r
  options(shiny.maxRequestSize = 30 * 1024^2)  # 30 MB
  ```
- `multiple = TRUE` allows multiple files. `input$file` becomes a data frame
  with multiple rows.
- `accept` filters the file picker dialog but doesn't prevent wrong file
  types — always validate server-side.

### 7.2 File Download

```r
# UI
downloadButton("download", "Download Results")
# or
downloadLink("download", "Download Results")

# Server
output$download <- downloadHandler(
  filename = function() {
    paste0("results_", Sys.Date(), ".csv")
  },
  content = function(file) {
    write.csv(filtered_data(), file, row.names = FALSE)
  }
)
```

**`downloadHandler()` arguments:**
- `filename` — a function that returns the suggested filename.
- `content` — a function that takes a `file` path and writes the output to it.
  Shiny provides the temp file path; you write to it.
- `contentType` — optional MIME type. Usually auto-detected from extension.

**Downloading plots:**
```r
output$download_plot <- downloadHandler(
  filename = function() "plot.png",
  content = function(file) {
    ggsave(file, plot = current_plot(), width = 8, height = 6, dpi = 300)
  }
)
```

**Downloading reports (Rmd → PDF/HTML):**
```r
output$report <- downloadHandler(
  filename = "report.html",
  content = function(file) {
    # Copy the report template to a temp dir (avoid permission issues)
    tempReport <- file.path(tempdir(), "report.Rmd")
    file.copy("report.Rmd", tempReport, overwrite = TRUE)

    params <- list(data = filtered_data(), title = input$title)
    rmarkdown::render(tempReport,
      output_file = file,
      params = params,
      envir = new.env(parent = globalenv())
    )
  }
)
```

**Key patterns:**
- Always generate the filename dynamically (include dates, parameters).
- `content` writes to the provided `file` path — don't return a value.
- Use `withProgress()` or `showNotification()` for slow downloads.
- `downloadButton()` does NOT work inside `renderUI()` / `uiOutput()` in
  some older Shiny versions. Test carefully.

### 7.3 Multiple File Types

Let the user choose the format:
```r
radioButtons("format", "Format", c("CSV" = "csv", "Excel" = "xlsx"))

output$download <- downloadHandler(
  filename = function() {
    paste0("data.", input$format)
  },
  content = function(file) {
    if (input$format == "csv") {
      write.csv(data(), file, row.names = FALSE)
    } else {
      writexl::write_xlsx(data(), file)
    }
  }
)
```

---

## 8. Bookmarking State

### 8.1 What Bookmarking Does

Bookmarking captures the state of all inputs and encodes them into a URL.
When someone opens that URL, the app restores to the exact state.

### 8.2 Enabling Bookmarking

```r
ui <- function(request) {  # NOTE: the `request` parameter is required
  fluidPage(
    bookmarkButton(),  # adds a "Bookmark" button
    sliderInput("n", "N", 1, 100, 50),
    plotOutput("plot")
  )
}

server <- function(input, output, session) {
  output$plot <- renderPlot({
    hist(rnorm(input$n))
  })
}

shinyApp(ui, server, enableBookmarking = "url")
```

### 8.3 Bookmarking Modes

- `enableBookmarking = "url"` — state encoded in the URL query string.
  Simple, no server storage needed. Works for small state. URLs get long
  with many inputs.
- `enableBookmarking = "server"` — state saved to a file on the server,
  URL contains only a short ID. Works for large state. Requires persistent
  storage on the server.

### 8.4 Customizing Bookmarking

**Exclude inputs:**
```r
setBookmarkExclude(c("file_upload", "password"))
```

**Save extra state:**
```r
onBookmark(function(state) {
  state$values$custom_data <- my_reactive_val()
})
```

**Restore extra state:**
```r
onRestore(function(state) {
  my_reactive_val(state$values$custom_data)
})
```

**Callback timing:**
```r
onBookmarked(function(url) {
  # Called after bookmark is created
  showModal(modalDialog(
    title = "Bookmarked!",
    paste("Share this URL:", url)
  ))
})
```

### 8.5 Bookmarking with Modules

Bookmarking works with modules automatically because module inputs are
just namespaced regular inputs. However:
- `setBookmarkExclude()` inside a module needs the **non-namespaced** ID
  (the one you'd use with `input$`).
- `onBookmark` / `onRestore` callbacks should be registered inside
  `moduleServer()` to get the correct session scope.

### 8.6 Bookmarking Limitations

- `fileInput` state cannot be bookmarked (the uploaded file is gone).
- `renderUI`-generated inputs may have timing issues on restore.
- Dynamic module instances are very difficult to bookmark.
- Bookmarking captures *input* state, not *computed* state. If your app
  has side effects (database writes, etc.), bookmarking won't replay them.

---

## 9. Best Practices

### 9.1 App Structure and Organization

**For small apps** (< 500 lines): Single `app.R` file is fine.

**For medium apps**: Split into `ui.R`, `server.R`, and `global.R`.
Or use `app.R` with sourced files.

**For large/production apps** (Wickham's recommended structure):
```
myapp/
├── app.R            # entry point, sources everything
├── R/               # auto-sourced by Shiny (>= 1.5.0)
│   ├── mod_data.R
│   ├── mod_analysis.R
│   ├── mod_plot.R
│   ├── utils.R
│   └── fct_helpers.R
├── www/             # static files (CSS, JS, images)
├── tests/
│   └── testthat/
└── DESCRIPTION      # optional, declares dependencies
```

**R/ directory auto-sourcing**: As of Shiny 1.5.0, all `.R` files in `R/`
are automatically sourced before the app starts (alphabetical order).
No need to manually `source()` them. This is the recommended approach.

### 9.2 Code Organization Patterns

**Naming conventions:**
- `mod_*.R` — Shiny modules
- `fct_*.R` — pure functions (business logic, no Shiny)
- `utils_*.R` — small utility functions

**Separate logic from presentation:**
- Extract data processing into plain R functions (`fct_*.R`).
- These functions take regular R objects (data frames, vectors), not
  reactives.
- Test these functions with standard unit tests (testthat).
- Call them from reactives: `reactive({ process_data(data(), input$params) })`

### 9.3 Error Handling

```r
# validate() — user-friendly error messages in outputs
output$plot <- renderPlot({
  validate(
    need(input$var, "Please select a variable"),
    need(nrow(data()) > 0, "No data matches your filters"),
    need(is.numeric(data()[[input$var]]), "Selected variable must be numeric")
  )
  hist(data()[[input$var]])
})
```

`validate()` + `need()`:
- Displays a grey message in the output area (not an angry red error).
- `need(expr, message)` — if `expr` is falsy (NULL, NA, FALSE, empty string,
  empty vector), displays the message and stops execution.
- Multiple `need()` calls show the first failing message.

**`tryCatch()` for unexpected errors:**
```r
data <- reactive({
  tryCatch(
    read.csv(input$file$datapath),
    error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
      NULL
    }
  )
})
```

### 9.4 Notifications and Progress

```r
# Simple notification
showNotification("Data loaded!", type = "message", duration = 3)

# Progress bar
withProgress(message = "Computing...", value = 0, {
  for (i in seq_len(n)) {
    incProgress(1/n, detail = paste("Step", i))
    # ... work ...
  }
})

# Waiter/spinner (external package, but mentioned in the book's ecosystem)
```

### 9.5 Testing

**`testServer()` for unit testing module servers:**
```r
test_that("filter module works", {
  testServer(mod_filter_server, args = list(data = reactive(iris)), {
    session$setInputs(species = "setosa")
    expect_equal(nrow(filtered()), 50)

    session$setInputs(species = "virginica")
    expect_equal(nrow(filtered()), 50)
  })
})
```

**`shinytest2` for end-to-end testing:**
```r
test_that("app works end-to-end", {
  app <- AppDriver$new(app_dir = "path/to/app")
  app$set_inputs(n = 50)
  app$click("go")
  app$expect_values()  # snapshot testing
  app$stop()
})
```

**Testing principles:**
- Test pure functions (business logic) with regular testthat tests.
- Test module servers with `testServer()` for reactive logic.
- Test the full app with `shinytest2` for integration/UI testing.
- `testServer()` doesn't render outputs — it tests reactive logic only.
  Use `shinytest2` to test actual rendered output.

### 9.6 Dependency Management

- Use a `DESCRIPTION` file to declare dependencies (even if not an R package).
- Use `renv` for reproducible package environments.
- Pin package versions for production deployments.

---

## 10. Advanced Patterns for Complex Apps

### 10.1 The "Stratified" Module Architecture

For complex apps, organize modules in layers:

```
Data layer:       mod_data_upload → mod_data_filter → mod_data_preview
Analysis layer:   mod_analysis_config → mod_analysis_run → mod_ard_preview
Output layer:     mod_titles → mod_preview → mod_export
```

Each layer's modules communicate via reactives passed as arguments.
Each layer feeds into the next. This creates a clear data flow.

### 10.2 Central Reactive Store (R6-Based)

For apps where many modules need access to shared state:

```r
AppState <- R6::R6Class("AppState",
  public = list(
    data = NULL,
    config = NULL,
    initialize = function() {
      self$data <- reactiveVal(NULL)
      self$config <- reactiveValues(
        var = NULL,
        group = NULL,
        stats = list()
      )
    }
  )
)

# In app server:
state <- AppState$new()
mod_data_server("data", state)
mod_analysis_server("analysis", state)
mod_export_server("export", state)
```

**Trade-offs:**
- Pro: Avoids threading dozens of reactives through module arguments.
- Con: Modules have hidden dependencies. Harder to test in isolation.
- Use sparingly: only for truly global state (loaded dataset, user config).

### 10.3 Workflow / Wizard Pattern

For step-by-step workflows (common in TFL builders):

```r
# Use tabsetPanel with hidden tabs
ui <- page_navbar(
  id = "wizard",
  nav_panel("Step 1: Data",    mod_data_ui("data")),
  nav_panel("Step 2: Config",  mod_config_ui("config")),
  nav_panel("Step 3: Preview", mod_preview_ui("preview")),
  nav_panel("Step 4: Export",  mod_export_ui("export"))
)

# Enable/disable tabs based on completed steps
observe({
  # Only enable Step 2 after data is loaded
  if (!is.null(data())) {
    nav_show("wizard", "Step 2: Config")
  } else {
    nav_hide("wizard", "Step 2: Config")
  }
})
```

### 10.4 Debouncing and Throttling

```r
# Debounce — wait until input stops changing for 500ms
search_d <- reactive(input$search) %>% debounce(500)

# Throttle — execute at most once per 1000ms
data_t <- reactive(expensive_filter(input$slider)) %>% throttle(1000)
```

- **Debounce**: waits for a pause. Good for text input (search boxes).
- **Throttle**: rate-limits. Good for sliders that fire rapidly.
- Both return reactives. Use the returned reactive instead of the original.

### 10.5 Reactive Polling for External Data

```r
data <- reactivePoll(
  intervalMillis = 10000,  # check every 10 seconds
  session = session,
  checkFunc = function() {
    file.mtime("data.csv")  # cheap check
  },
  valueFunc = function() {
    read.csv("data.csv")    # expensive read, only when check changes
  }
)
```

`reactivePoll()` is more efficient than `invalidateLater()` + `reactive()`
because it separates the cheap check from the expensive read.

### 10.6 Freezing Inputs

```r
observeEvent(input$dataset, {
  freezeReactiveValue(input, "var")
  updateSelectInput(session, "var", choices = names(get_data(input$dataset)))
})
```

When updating cascading inputs, `freezeReactiveValue()` prevents the
downstream reactive from firing with a stale value. Without it:
1. `input$dataset` changes → observer fires → `updateSelectInput()` sent to client
2. But before the client updates, other reactives see the OLD `input$var`
   with the NEW `input$dataset` — mismatched state!
3. `freezeReactiveValue()` marks `input$var` as frozen — reads return
   a silent halt (like `req(FALSE)`) until the new value arrives from the client.

**This is essential for apps with cascading/dependent dropdowns.**

### 10.7 Using `session$userData`

```r
session$userData$app_state <- list(initialized = FALSE)
```

A per-session environment for storing arbitrary data. Not reactive by default.
Useful for storing non-reactive metadata. Discouraged for inter-module
communication (use explicit reactive arguments instead).

### 10.8 `htmlwidgets` Integration

For interactive tables, plots, and visualizations:
```r
# DT tables
output$table <- DT::renderDataTable({
  DT::datatable(data(),
    options = list(pageLength = 25, scrollX = TRUE),
    selection = "single"
  )
})

# Capture row selection
selected_row <- reactive({
  req(input$table_rows_selected)
  data()[input$table_rows_selected, ]
})
```

### 10.9 JavaScript Communication

```r
# Send message from R to JavaScript
session$sendCustomMessage("highlight", list(id = "my-element"))

# Receive message from JavaScript in R
# In JS: Shiny.setInputValue("js_result", value);
# In R: input$js_result is now available

# With priority (force update even if value unchanged):
# JS: Shiny.setInputValue("js_result", value, {priority: "event"});
```

### 10.10 Code Generation Pattern

For apps that produce reproducible R scripts (very relevant to arbuilder):

```r
mod_codegen_server <- function(id, data_code, analysis_code, output_code) {
  moduleServer(id, function(input, output, session) {
    full_script <- reactive({
      glue::glue("
        library(tidyverse)
        library(arframe)

        # Data
        {data_code()}

        # Analysis
        {analysis_code()}

        # Output
        {output_code()}
      ")
    })

    output$code <- renderText(full_script())

    output$download <- downloadHandler(
      filename = function() "analysis.R",
      content = function(file) writeLines(full_script(), file)
    )
  })
}
```

Key principle: each module contributes its code fragment as a reactive string.
A central `mod_codegen` module assembles them into a complete script.

### 10.11 Handling Large Data

- Use `reactiveFileReader()` for files that update.
- Use server-side `DT::datatable()` processing (`server = TRUE`, which is
  the default) for large tables.
- Filter data early in the reactive chain — don't pass full datasets
  through multiple modules.
- Consider `data.table` or `dtplyr` for performance-critical transformations.
- Use `bindCache()` aggressively for expensive computations.

### 10.12 Modal Dialogs

```r
observeEvent(input$settings, {
  showModal(modalDialog(
    title = "Settings",
    textInput("title", "Title", value = current_title()),
    numericInput("dpi", "DPI", value = 300),
    footer = tagList(
      modalButton("Cancel"),
      actionButton("save_settings", "Save")
    ),
    easyClose = TRUE,
    size = "m"  # "s", "m", "l", "xl"
  ))
})

observeEvent(input$save_settings, {
  # Save the settings
  current_title(input$title)
  removeModal()
})
```

### 10.13 Shiny as a Package (The "Golem" Philosophy)

The book discusses (and the ecosystem supports) structuring a Shiny app
as an R package:
```
myapp/
├── DESCRIPTION
├── NAMESPACE
├── R/
│   ├── app_server.R
│   ├── app_ui.R
│   ├── mod_data.R
│   ├── run_app.R
│   ├── fct_helpers.R
│   └── utils.R
├── inst/
│   └── app/www/
├── man/
└── tests/
```

Benefits:
- `devtools::load_all()` for fast reloading during development.
- Formal dependency management via `DESCRIPTION`.
- Proper documentation with roxygen2.
- Standard R package testing infrastructure.
- Easy to install and share.

This is exactly the structure your arbuilder project already follows.

---

## Summary: Key Patterns for a Complex Multi-Module App Like arbuilder

1. **Module communication**: Pass reactives as arguments (not values).
   Return reactives (or named lists of reactives) from module servers.

2. **Cascading inputs**: Use `freezeReactiveValue()` + `update*()` to
   prevent stale-value flicker.

3. **Lazy computation**: Use `bindEvent()` to defer expensive work until
   the user clicks a button.

4. **Caching**: Use `bindCache()` for expensive computations and plots.

5. **Tidy eval**: Use `.data[[input$var]]` everywhere. It's the simplest
   and safest pattern.

6. **Error handling**: `req()` at the top of every reactive that depends
   on optional inputs. `validate()` + `need()` for user-facing messages.

7. **Code generation**: Each module exposes a reactive that returns its
   code fragment as a string. A central module assembles the full script.

8. **Layout**: `page_sidebar()` + `accordion()` in the sidebar +
   `card()` for the main content. Use `bslib` throughout.

9. **Testing**: Pure functions with testthat, module servers with
   `testServer()`, full app with `shinytest2`.

10. **File structure**: `R/` directory with `mod_*.R`, `fct_*.R`,
    `utils_*.R`. Auto-sourced by Shiny.

---

# Book 3: JavaScript for Shiny

# JavaScript for Shiny Users — Field Notes

Based on Colin Fay (ThinkR) JS4Shiny patterns and broader community knowledge.

---

## 1. Including JS in Shiny

Three main approaches, from quick-and-dirty to production-grade.

### 1a. Inline `tags$script`

Fastest for prototyping. JS lives directly in your UI code.

```r
ui <- fluidPage(
  tags$script(HTML("
    $(document).on('shiny:connected', function() {
      console.log('Shiny app connected');
    });
  "))
)
```

Put it at the **end** of the UI (just before closing `fluidPage`) so the DOM
is mostly ready. Alternatively wrap logic in a `$(document).ready()` or
listen for `shiny:connected`.

### 1b. External file in `www/`

Shiny serves everything in `www/` as static assets. Put your JS there.

```
myapp/
  app.R
  www/
    custom.js
    custom.css
```

```r
ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", href = "custom.css"),
    tags$script(src = "custom.js")
  ),
  # ... rest of UI
)
```

`custom.js` is referenced by path relative to `www/`. This is the sweet spot
for most apps — keeps R and JS separate, no bundling needed.

### 1c. `htmlDependency` (package-grade)

When building an R package that ships JS, use `htmltools::htmlDependency`.
This handles versioning, deduplication, and CDN/local switching.

```r
my_js_dep <- function() {
  htmltools::htmlDependency(
    name = "my-widget",
    version = "0.1.0",
    src = system.file("assets", package = "mypkg"),
    script = "widget.js",
    stylesheet = "widget.css"
  )
}

# Attach to any UI element
my_widget_ui <- function(id) {
  ns <- NS(id)
  tagList(
    my_js_dep(),
    tags$div(id = ns("container"), class = "my-widget")
  )
}
```

Key advantage: if two modules both declare the same `htmlDependency` with the
same name+version, Shiny includes it **only once**. This avoids double-loading
jQuery plugins, CSS, etc.

You can also attach dependencies to existing tags:

```r
tagWithDep <- htmltools::attachDependencies(
  tags$div("hello"),
  my_js_dep()
)
```

### Loading order matters

```r
# head = loads before body renders (blocking)
tags$head(tags$script(src = "early.js"))

# end of body = loads after DOM is built
tags$script(src = "late.js")

# defer attribute = non-blocking, runs after parse
tags$head(tags$script(src = "deferred.js", defer = NA))
```

---

## 2. Shiny JS Lifecycle Events

Shiny fires custom jQuery events on `document` at key moments. These are your
hooks for building reactive JS behaviour.

### Event catalog

| Event | Fires when... | `event.detail` / useful properties |
|---|---|---|
| `shiny:connected` | WebSocket connection established | — |
| `shiny:disconnected` | WebSocket drops | — |
| `shiny:busy` | Server starts processing **any** output | — |
| `shiny:idle` | Server finishes **all** outputs | — |
| `shiny:recalculating` | A specific output starts recalculating | `event.target` = output element |
| `shiny:recalculated` | A specific output finishes | `event.target` = output element |
| `shiny:value` | An output receives a new value | `event.target`, `event.value` |
| `shiny:error` | An output errors | `event.target`, `event.message` |
| `shiny:inputchanged` | Any input changes value | `event.name`, `event.value`, `event.inputType` |
| `shiny:visualchange` | An output's visibility changes | `event.target`, `event.visible` |

### Listening

```js
// www/lifecycle.js

$(document).on('shiny:connected', function() {
  console.log('App ready');
  // safe to call Shiny.setInputValue here
});

$(document).on('shiny:disconnected', function() {
  // show reconnect banner
  $('body').append(
    '<div id="dc-banner" style="position:fixed;top:0;left:0;right:0;' +
    'background:#e74c3c;color:#fff;text-align:center;padding:8px;z-index:9999">' +
    'Connection lost. <a href="#" onclick="location.reload()" style="color:#fff;' +
    'text-decoration:underline">Reload</a></div>'
  );
});

$(document).on('shiny:busy', function() {
  $('body').addClass('shiny-busy-custom');
});

$(document).on('shiny:idle', function() {
  $('body').removeClass('shiny-busy-custom');
});

// Per-output granularity
$(document).on('shiny:recalculating', function(event) {
  var id = $(event.target).attr('id');
  console.log('Recalculating: ' + id);
  $(event.target).addClass('recalculating-fade');
});

$(document).on('shiny:recalculated', function(event) {
  $(event.target).removeClass('recalculating-fade');
});

// Watch all input changes (debugging / logging)
$(document).on('shiny:inputchanged', function(event) {
  // event.name = full input id (with namespace)
  // event.value = new value
  // event.inputType = e.g. "shiny.textInput"
  if (event.name.indexOf('.clientdata') === -1) {
    console.log('Input changed:', event.name, '=', event.value);
  }
});

// Intercept output values
$(document).on('shiny:value', function(event) {
  console.log('Output', $(event.target).attr('id'), 'got value');
});
```

### Preventing default

Some events are cancelable. For example, you can prevent an input change
from reaching the server:

```js
$(document).on('shiny:inputchanged', function(event) {
  if (event.name === 'secret_input') {
    event.preventDefault(); // value never sent to server
  }
});
```

---

## 3. Custom Input Bindings

The most powerful Shiny JS pattern. You create a new input type that Shiny
treats like any built-in input — reactive, debounced, type-safe.

### Full anatomy

```js
// www/toggle-binding.js

var toggleBinding = new Shiny.InputBinding();

$.extend(toggleBinding, {

  // 1. find(scope): return all instances of this input within scope
  //    scope is usually document on first pass, then a subtree on updates
  find: function(scope) {
    return $(scope).find('.toggle-switch-input');
  },

  // 2. getId(el): return the input's id (default: el.id — usually fine)
  getId: function(el) {
    return el.id;  // optional override
  },

  // 3. getValue(el): extract current value from the DOM element
  getValue: function(el) {
    return $(el).find('input[type="checkbox"]').prop('checked');
  },

  // 4. setValue(el, value): set the value programmatically (for updateXxxInput)
  setValue: function(el, value) {
    $(el).find('input[type="checkbox"]').prop('checked', value);
    $(el).toggleClass('active', value);
  },

  // 5. subscribe(el, callback): wire up DOM events that trigger re-read
  //    call callback(true) for immediate send, callback(false) for debounced
  subscribe: function(el, callback) {
    $(el).on('change.toggleBinding', function() {
      $(el).toggleClass('active', $(el).find('input[type="checkbox"]').prop('checked'));
      callback(true);  // true = send immediately (no debounce)
    });
  },

  // 6. unsubscribe(el): clean up event listeners (called when element removed)
  unsubscribe: function(el) {
    $(el).off('.toggleBinding');
  },

  // 7. receiveMessage(el, data): handle messages from server
  //    (triggered by session$sendInputMessage)
  receiveMessage: function(el, data) {
    if (data.hasOwnProperty('value')) {
      this.setValue(el, data.value);
    }
    if (data.hasOwnProperty('label')) {
      $(el).find('.toggle-label').text(data.label);
    }
    $(el).trigger('change');  // re-trigger so subscribe picks it up
  },

  // 8. getRatePolicy(): optional throttle/debounce
  getRatePolicy: function() {
    return { policy: 'debounce', delay: 250 };
    // alternatives: 'throttle', 'direct' (immediate)
  },

  // 9. getType(): optional — tells Shiny the R type for deserialization
  //    e.g. 'shiny.number' → numeric, default is character
  getType: function() {
    return 'shiny.logical';  // not a real built-in, but you get the idea
    // Common: false (default/string), or omit entirely
  }
});

// Register the binding
Shiny.inputBindings.register(toggleBinding, 'myapp.toggleBinding');
// Second arg is a priority string — higher alpha = checked later (lower priority)
```

### Complete toggle switch example

**R side — UI constructor + update function:**

```r
# R/toggle_input.R

toggle_input <- function(inputId, label, value = FALSE) {
  tags$div(
    id = inputId,
    class = "toggle-switch-input",
    tags$label(
      class = "toggle-container",
      tags$input(
        type = "checkbox",
        checked = if (value) NA else NULL
      ),
      tags$span(class = "toggle-slider"),
      tags$span(class = "toggle-label", label)
    )
  )
}

update_toggle_input <- function(session, inputId, value = NULL, label = NULL) {
  message <- list()
  if (!is.null(value)) message$value <- value
  if (!is.null(label)) message$label <- label
  session$sendInputMessage(inputId, message)
}
```

**CSS:**

```css
/* www/toggle.css */

.toggle-container {
  display: inline-flex;
  align-items: center;
  cursor: pointer;
  gap: 8px;
  user-select: none;
}

.toggle-container input[type="checkbox"] {
  display: none;
}

.toggle-slider {
  width: 44px;
  height: 24px;
  background: #ccc;
  border-radius: 12px;
  position: relative;
  transition: background 0.2s ease;
}

.toggle-slider::after {
  content: '';
  position: absolute;
  width: 20px;
  height: 20px;
  background: #fff;
  border-radius: 50%;
  top: 2px;
  left: 2px;
  transition: transform 0.2s ease;
  box-shadow: 0 1px 3px rgba(0,0,0,0.2);
}

.toggle-container input:checked + .toggle-slider {
  background: #0d6efd;
}

.toggle-container input:checked + .toggle-slider::after {
  transform: translateX(20px);
}
```

**Server usage:**

```r
server <- function(input, output, session) {
  observeEvent(input$my_toggle, {
    cat("Toggle is:", input$my_toggle, "\n")
  })

  # Update from server
  observeEvent(input$reset, {
    update_toggle_input(session, "my_toggle", value = FALSE)
  })
}
```

---

## 4. Custom Output Bindings

Less common than input bindings but essential for custom rendering (D3 charts,
custom tables, etc.).

### Full anatomy

```js
// www/sparkline-binding.js

var sparklineBinding = new Shiny.OutputBinding();

$.extend(sparklineBinding, {

  // 1. find(scope): locate output containers
  find: function(scope) {
    return $(scope).find('.sparkline-output');
  },

  // 2. renderValue(el, data): main render — data comes from the R render function
  renderValue: function(el, data) {
    if (!data) {
      el.innerHTML = '';
      return;
    }

    // data is whatever your R renderXxx function returns via jsonlite
    var values = data.values;
    var color = data.color || '#0d6efd';

    // Example: simple SVG sparkline
    var width = el.offsetWidth;
    var height = 40;
    var max = Math.max.apply(null, values);
    var min = Math.min.apply(null, values);
    var range = max - min || 1;
    var step = width / (values.length - 1);

    var points = values.map(function(v, i) {
      var x = i * step;
      var y = height - ((v - min) / range) * (height - 4) - 2;
      return x + ',' + y;
    }).join(' ');

    el.innerHTML = '<svg width="' + width + '" height="' + height + '">' +
      '<polyline points="' + points + '" fill="none" stroke="' + color +
      '" stroke-width="2"/></svg>';
  },

  // 3. renderError(el, err): show errors gracefully
  renderError: function(el, err) {
    el.innerHTML = '<span style="color:red">Error: ' + err.message + '</span>';
  },

  // 4. clearError(el): remove error display before re-render
  clearError: function(el) {
    // nothing special needed if renderValue replaces innerHTML
  }
});

Shiny.outputBindings.register(sparklineBinding, 'myapp.sparklineBinding');
```

**R side:**

```r
# UI
sparkline_output <- function(outputId, width = "100%", height = "40px") {
  tags$div(
    id = outputId,
    class = "sparkline-output shiny-report-output",
    # shiny-report-output tells Shiny this is an output
    style = paste0("width:", width, ";height:", height, ";")
  )
}

# Server
render_sparkline <- function(expr, env = parent.frame(), quoted = FALSE) {
  func <- shiny::exprToFunction(expr, env, quoted)
  function() {
    val <- func()
    # Must return a list that becomes JSON
    list(values = val$values, color = val$color)
  }
}

# Usage
server <- function(input, output, session) {
  output$my_spark <- render_sparkline({
    list(values = rnorm(20, mean = 50, sd = 10), color = "#198754")
  })
}
```

---

## 5. `Shiny.setInputValue`

The simplest way to send data from JS to R. No custom binding needed.

### Basic usage

```js
// Send a value to R — accessible as input$my_value
Shiny.setInputValue('my_value', 42);

// Send complex data
Shiny.setInputValue('click_info', {
  x: event.clientX,
  y: event.clientY,
  target: event.target.id,
  timestamp: Date.now()
});
```

```r
# R side
observeEvent(input$my_value, {
  cat("Got:", input$my_value, "\n")
})

observeEvent(input$click_info, {
  cat("Clicked at", input$click_info$x, input$click_info$y, "\n")
})
```

### The `priority: 'event'` pattern

By default, Shiny deduplicates — if you send the same value twice, the
second one is ignored. This breaks "button-like" JS events.

```js
// BAD: second click with same data is swallowed
Shiny.setInputValue('btn_click', 'clicked');
// ... user clicks again ...
Shiny.setInputValue('btn_click', 'clicked');  // ignored!

// GOOD: priority 'event' forces delivery every time
Shiny.setInputValue('btn_click', 'clicked', {priority: 'event'});
// equivalent — send a counter or timestamp
Shiny.setInputValue('btn_click', Date.now(), {priority: 'event'});
```

`{priority: 'event'}` is **critical** for:
- Button clicks
- Keyboard shortcuts
- Any action where the same value can repeat

### Namespaced inputs in modules

Inside a Shiny module, input IDs are prefixed with the module namespace
(e.g., `"data-my_input"`). JS doesn't know about this automatically.

**Pattern: pass the namespace via a data attribute.**

```r
# R module UI
data_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$div(
      id = ns("js_target"),
      `data-ns` = ns(""),   # passes "data-" prefix to JS
      class = "my-widget"
    )
  )
}
```

```js
// JS: read the namespace from the DOM
$('.my-widget').on('click', function() {
  var ns = $(this).data('ns');  // e.g., "data-"
  Shiny.setInputValue(ns + 'widget_click', Date.now(), {priority: 'event'});
});
```

Now `input$widget_click` works correctly inside the module server.

**Alternative: use the element's id directly.**

```js
$('.my-widget').on('click', function() {
  // this.id is already namespaced by Shiny (e.g., "data-js_target")
  var base = this.id.replace('js_target', '');
  Shiny.setInputValue(base + 'widget_click', Date.now(), {priority: 'event'});
});
```

---

## 6. `session$sendCustomMessage` Handlers

Send data from R (server) to JS (client). The counterpart to `setInputValue`.

### Registration pattern

```r
# R server
session$sendCustomMessage("show-toast", list(
  message = "Record saved!",
  type = "success"
))
```

```js
// JS handler (registered once, usually on shiny:connected)
Shiny.addCustomMessageHandler('show-toast', function(data) {
  console.log(data.message, data.type);
});
```

**Important:** Handler names must be unique. Registering the same name twice
throws an error. Guard with a check or register at load time.

### 6a. Toast notifications

```js
// www/toast.js
Shiny.addCustomMessageHandler('show-toast', function(data) {
  var toast = document.createElement('div');
  toast.className = 'custom-toast toast-' + (data.type || 'info');
  toast.textContent = data.message;
  document.body.appendChild(toast);

  // Trigger animation
  requestAnimationFrame(function() {
    toast.classList.add('show');
  });

  setTimeout(function() {
    toast.classList.remove('show');
    setTimeout(function() { toast.remove(); }, 300);
  }, data.duration || 3000);
});
```

```css
/* www/toast.css */
.custom-toast {
  position: fixed;
  bottom: 20px;
  right: 20px;
  padding: 12px 20px;
  border-radius: 8px;
  color: #fff;
  font-size: 14px;
  z-index: 9999;
  opacity: 0;
  transform: translateY(20px);
  transition: opacity 0.3s ease, transform 0.3s ease;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}
.custom-toast.show {
  opacity: 1;
  transform: translateY(0);
}
.toast-success { background: #198754; }
.toast-error   { background: #dc3545; }
.toast-info    { background: #0d6efd; }
.toast-warning { background: #ffc107; color: #333; }
```

```r
# R helper
show_toast <- function(session, message, type = "info", duration = 3000) {
  session$sendCustomMessage("show-toast", list(
    message = message, type = type, duration = duration
  ))
}

# Usage
observeEvent(input$save, {
  tryCatch({
    save_data()
    show_toast(session, "Saved successfully!", "success")
  }, error = function(e) {
    show_toast(session, paste("Error:", e$message), "error", 5000)
  })
})
```

### 6b. Loading state

```js
Shiny.addCustomMessageHandler('set-loading', function(data) {
  var el = document.getElementById(data.id);
  if (!el) return;
  if (data.loading) {
    el.classList.add('is-loading');
    el.disabled = true;
    el.dataset.originalText = el.textContent;
    el.innerHTML = '<span class="spinner-border spinner-border-sm"></span> ' +
                   (data.text || 'Loading...');
  } else {
    el.classList.remove('is-loading');
    el.disabled = false;
    el.textContent = el.dataset.originalText || 'Submit';
  }
});
```

```r
with_loading <- function(session, btn_id, expr) {
  session$sendCustomMessage("set-loading", list(id = btn_id, loading = TRUE))
  on.exit(session$sendCustomMessage("set-loading", list(id = btn_id, loading = FALSE)))
  force(expr)
}

observeEvent(input$run_analysis, {
  with_loading(session, "run_analysis", {
    Sys.sleep(2)  # expensive computation
    result()
  })
})
```

### 6c. Scroll to element

```js
Shiny.addCustomMessageHandler('scroll-to', function(data) {
  var el = document.getElementById(data.id);
  if (el) {
    el.scrollIntoView({ behavior: 'smooth', block: data.block || 'start' });
    // Optional: highlight briefly
    if (data.highlight) {
      el.classList.add('highlight-flash');
      setTimeout(function() { el.classList.remove('highlight-flash'); }, 1500);
    }
  }
});
```

```css
@keyframes flash-highlight {
  0%, 100% { background: transparent; }
  50% { background: rgba(13, 110, 253, 0.1); }
}
.highlight-flash {
  animation: flash-highlight 0.75s ease 2;
}
```

```r
scroll_to <- function(session, id, highlight = TRUE) {
  session$sendCustomMessage("scroll-to", list(id = id, highlight = highlight))
}
```

### 6d. Clipboard copy

```js
Shiny.addCustomMessageHandler('copy-to-clipboard', function(data) {
  navigator.clipboard.writeText(data.text).then(function() {
    // optional: show confirmation
    if (data.notify) {
      Shiny.setInputValue('clipboard_copied', Date.now(), {priority: 'event'});
    }
  }).catch(function(err) {
    // Fallback for older browsers / non-HTTPS
    var ta = document.createElement('textarea');
    ta.value = data.text;
    ta.style.position = 'fixed';
    ta.style.left = '-9999px';
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
  });
});
```

```r
copy_to_clipboard <- function(session, text) {
  session$sendCustomMessage("copy-to-clipboard", list(text = text, notify = TRUE))
}

observeEvent(input$copy_code, {
  copy_to_clipboard(session, generated_code())
  show_toast(session, "Code copied to clipboard!", "success")
})
```

### 6e. Trigger download

```js
Shiny.addCustomMessageHandler('trigger-download', function(data) {
  // Create a hidden link and click it
  var a = document.createElement('a');
  a.href = data.url;
  a.download = data.filename || '';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
});
```

---

## 7. CSS Transitions and Animations for Premium UI

### Hover effects on cards

```css
.shiny-card {
  background: #fff;
  border: 1px solid #e9ecef;
  border-radius: 8px;
  padding: 16px;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}

.shiny-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}
```

### Button press effect

```css
.btn-press {
  transition: transform 0.1s ease;
}
.btn-press:active {
  transform: scale(0.96);
}
```

### Loading spinner (pure CSS)

```css
.loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #e9ecef;
  border-top-color: #0d6efd;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
```

### Skeleton shimmer (placeholder while loading)

This gives a "content loading" effect like Facebook/YouTube use.

```css
.skeleton {
  background: #e9ecef;
  background-image: linear-gradient(
    90deg,
    #e9ecef 0%,
    #f8f9fa 40%,
    #e9ecef 80%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;
  border-radius: 4px;
}

.skeleton-text {
  height: 14px;
  margin-bottom: 8px;
  width: 80%;
}

.skeleton-text:last-child {
  width: 60%;
}

.skeleton-title {
  height: 20px;
  width: 50%;
  margin-bottom: 16px;
}

.skeleton-rect {
  height: 200px;
  width: 100%;
}

@keyframes shimmer {
  0%   { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

```r
# R helper to create skeleton placeholders
skeleton_block <- function(..., height = "200px") {
  tags$div(
    class = "skeleton-container",
    tags$div(class = "skeleton skeleton-title"),
    tags$div(class = "skeleton skeleton-text"),
    tags$div(class = "skeleton skeleton-text"),
    tags$div(class = "skeleton skeleton-text"),
    ...
  )
}
```

Replace the skeleton with real content once the output renders:

```js
$(document).on('shiny:value', function(event) {
  var el = event.target;
  // Remove any sibling skeleton
  $(el).siblings('.skeleton-container').remove();
  $(el).css('opacity', 0).animate({opacity: 1}, 200);
});
```

### Fade-in on output render

```css
.fade-in-output {
  animation: fadeIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}
```

```js
$(document).on('shiny:value', function(event) {
  $(event.target).addClass('fade-in-output');
  // Remove class after animation so it can re-trigger
  setTimeout(function() {
    $(event.target).removeClass('fade-in-output');
  }, 300);
});
```

---

## 8. NProgress Top Bar Pattern for Busy State

NProgress gives a slim progress bar at the top of the page (like YouTube,
GitHub). Perfect for Shiny busy/idle states.

### Setup

```r
ui <- fluidPage(
  tags$head(
    tags$link(
      rel = "stylesheet",
      href = "https://unpkg.com/nprogress@0.2.0/nprogress.css"
    ),
    tags$script(src = "https://unpkg.com/nprogress@0.2.0/nprogress.js"),
    tags$script(HTML("
      NProgress.configure({
        showSpinner: false,
        minimum: 0.15,
        trickleSpeed: 200
      });

      $(document).on('shiny:busy', function() {
        NProgress.start();
      });

      $(document).on('shiny:idle', function() {
        NProgress.done();
      });
    ")),
    # Optional: customize the bar color
    tags$style(HTML("
      #nprogress .bar {
        background: #0d6efd;
        height: 3px;
      }
      #nprogress .peg {
        box-shadow: 0 0 10px #0d6efd, 0 0 5px #0d6efd;
      }
    "))
  ),
  # ... rest of UI
)
```

That is the entire integration. Three lifecycle hooks, zero R code on the
server. This is one of the highest-impact, lowest-effort JS additions you
can make to a Shiny app.

### Per-output progress (advanced)

```js
// Track how many outputs are recalculating
var recalcCount = 0;

$(document).on('shiny:recalculating', function() {
  recalcCount++;
  if (recalcCount === 1) NProgress.start();
});

$(document).on('shiny:recalculated', function() {
  recalcCount--;
  if (recalcCount <= 0) {
    recalcCount = 0;
    NProgress.done();
  }
});
```

---

## 9. Useful JS Libraries for Premium Shiny

### SortableJS — drag-and-drop reordering

```r
# UI
tags$head(
  tags$script(src = "https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js")
)

tags$ul(id = "sortable-list", class = "list-group",
  tags$li(class = "list-group-item", `data-id` = "age", "Age"),
  tags$li(class = "list-group-item", `data-id` = "sex", "Sex"),
  tags$li(class = "list-group-item", `data-id` = "race", "Race")
)
```

```js
// www/sortable-init.js
$(document).on('shiny:connected', function() {
  var el = document.getElementById('sortable-list');
  if (!el) return;

  Sortable.create(el, {
    animation: 150,
    ghostClass: 'sortable-ghost',
    onEnd: function() {
      var order = Array.from(el.children).map(function(li) {
        return li.dataset.id;
      });
      Shiny.setInputValue('var_order', order);
    }
  });
});
```

```css
.sortable-ghost {
  opacity: 0.4;
  background: #e3f2fd;
}
```

### Tippy.js — tooltips and popovers

```r
tags$head(
  tags$script(src = "https://unpkg.com/@popperjs/core@2"),
  tags$script(src = "https://unpkg.com/tippy.js@6")
)
```

```js
$(document).on('shiny:connected', function() {
  tippy('[data-tippy-content]', {
    placement: 'top',
    animation: 'fade',
    theme: 'light-border'
  });
});

// Re-init after Shiny updates DOM
$(document).on('shiny:value', function() {
  tippy('[data-tippy-content]');
});
```

```r
# R usage: just add the data attribute
actionButton("run", "Run Analysis",
  `data-tippy-content` = "Runs the full demographic analysis pipeline"
)
```

### Driver.js — guided tours / onboarding

```js
Shiny.addCustomMessageHandler('start-tour', function(data) {
  var driver = new Driver({
    animate: true,
    opacity: 0.75,
    onDeselected: function() {
      Shiny.setInputValue('tour_step', driver.getActiveStep(), {priority: 'event'});
    }
  });

  driver.defineSteps(data.steps);
  // data.steps = [{element: '#upload', popover: {title: '...', description: '...'}}, ...]
  driver.start();
});
```

### Hotkeys.js — keyboard shortcuts

See Section 11 below for a full pattern.

### Notyf — lightweight toast library

```r
tags$head(
  tags$link(rel = "stylesheet", href = "https://cdn.jsdelivr.net/npm/notyf@3/notyf.min.css"),
  tags$script(src = "https://cdn.jsdelivr.net/npm/notyf@3/notyf.min.js")
)
```

```js
var notyf = new Notyf({
  duration: 3000,
  position: { x: 'right', y: 'bottom' },
  ripple: true
});

Shiny.addCustomMessageHandler('notyf', function(data) {
  if (data.type === 'success') {
    notyf.success(data.message);
  } else if (data.type === 'error') {
    notyf.error(data.message);
  } else {
    notyf.open({ type: 'info', message: data.message, background: '#0d6efd' });
  }
});
```

---

## 10. Killing the Recalculating Opacity Flash

Shiny's default behaviour: when an output recalculates, it adds the class
`recalculating` which sets `opacity: 0.3` and a blue-ish tint. This looks
jarring.

### Nuclear option: kill it globally

```css
/* www/no-recalc-flash.css */
.recalculating {
  opacity: 1 !important;
}
```

Done. One line. This is the single most impactful CSS override for Shiny UX.

### Selective: kill it for specific outputs only

```css
#my_table.recalculating,
#my_plot.recalculating {
  opacity: 1 !important;
}
```

### Replace with a subtler indicator

Instead of the opacity flash, show a thin progress bar or spinner:

```css
.recalculating {
  opacity: 1 !important;
  position: relative;
}

.recalculating::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: linear-gradient(90deg, transparent, #0d6efd, transparent);
  background-size: 200% 100%;
  animation: shimmer-bar 1.5s ease infinite;
}

@keyframes shimmer-bar {
  0%   { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

### Replace with skeleton (advanced)

```js
$(document).on('shiny:recalculating', function(event) {
  var el = $(event.target);
  // Save current height to avoid layout shift
  el.css('min-height', el.height() + 'px');
  el.html('<div class="skeleton skeleton-rect"></div>');
});
```

---

## 11. Keyboard Shortcuts Pattern

### Using Hotkeys.js

```r
tags$head(
  tags$script(src = "https://cdn.jsdelivr.net/npm/hotkeys-js@3/dist/hotkeys.min.js")
)
```

```js
// www/shortcuts.js
$(document).on('shiny:connected', function() {

  // Ctrl+S / Cmd+S = save
  hotkeys('ctrl+s, command+s', function(event) {
    event.preventDefault();
    Shiny.setInputValue('shortcut_save', Date.now(), {priority: 'event'});
  });

  // Ctrl+Enter = run analysis
  hotkeys('ctrl+enter', function(event) {
    event.preventDefault();
    Shiny.setInputValue('shortcut_run', Date.now(), {priority: 'event'});
  });

  // Escape = close modal / panel
  hotkeys('escape', function(event) {
    Shiny.setInputValue('shortcut_escape', Date.now(), {priority: 'event'});
  });

  // ? = show shortcuts help
  hotkeys('shift+/', function(event) {
    event.preventDefault();
    Shiny.setInputValue('shortcut_help', Date.now(), {priority: 'event'});
  });
});
```

### Vanilla JS (no library)

```js
document.addEventListener('keydown', function(event) {
  // Don't capture when typing in inputs
  var tag = event.target.tagName.toLowerCase();
  if (tag === 'input' || tag === 'textarea' || tag === 'select') return;
  if (event.target.isContentEditable) return;

  var key = event.key.toLowerCase();
  var ctrl = event.ctrlKey || event.metaKey;

  if (ctrl && key === 's') {
    event.preventDefault();
    Shiny.setInputValue('shortcut_save', Date.now(), {priority: 'event'});
  }

  if (ctrl && key === 'enter') {
    event.preventDefault();
    // Simulate clicking the Run button
    var runBtn = document.getElementById('run_analysis');
    if (runBtn) runBtn.click();
  }
});
```

```r
# R server
observeEvent(input$shortcut_save, {
  save_state()
  show_toast(session, "Saved (Ctrl+S)", "success")
})

observeEvent(input$shortcut_help, {
  showModal(modalDialog(
    title = "Keyboard Shortcuts",
    tags$dl(
      tags$dt("Ctrl + S"), tags$dd("Save current state"),
      tags$dt("Ctrl + Enter"), tags$dd("Run analysis"),
      tags$dt("Escape"), tags$dd("Close panel"),
      tags$dt("?"), tags$dd("Show this help")
    ),
    easyClose = TRUE,
    footer = modalButton("Close")
  ))
})
```

---

## 12. Optimistic UI Updates

Update the UI **immediately** in JS, then let the server confirm/correct.
Makes the app feel instant even with slow server operations.

### Pattern: checkbox list with immediate visual feedback

```js
// www/optimistic.js
$(document).on('click', '.optimistic-check', function() {
  var $this = $(this);
  var checked = $this.prop('checked');

  // 1. Immediately update UI (optimistic)
  $this.closest('.list-item').toggleClass('completed', checked);

  // 2. Send to server
  Shiny.setInputValue('item_toggle', {
    id: $this.data('id'),
    checked: checked
  }, {priority: 'event'});
});

// 3. If server rejects, revert
Shiny.addCustomMessageHandler('revert-check', function(data) {
  var $check = $('[data-id="' + data.id + '"]');
  $check.prop('checked', data.checked);
  $check.closest('.list-item').toggleClass('completed', data.checked);

  // Shake animation to indicate rejection
  $check.closest('.list-item').addClass('shake');
  setTimeout(function() {
    $check.closest('.list-item').removeClass('shake');
  }, 500);
});
```

```css
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  25%      { transform: translateX(-4px); }
  75%      { transform: translateX(4px); }
}
.shake { animation: shake 0.3s ease; }

.list-item {
  transition: opacity 0.2s, background 0.2s;
}
.list-item.completed {
  opacity: 0.6;
  text-decoration: line-through;
}
```

### Pattern: optimistic button state

```js
// Immediately disable + show spinner, don't wait for server round-trip
$('#save_btn').on('click', function() {
  var $btn = $(this);
  $btn.prop('disabled', true);
  $btn.data('original', $btn.html());
  $btn.html('<span class="spinner-border spinner-border-sm"></span> Saving...');
});

// Server re-enables when done
Shiny.addCustomMessageHandler('btn-reset', function(data) {
  var $btn = $('#' + data.id);
  $btn.prop('disabled', false);
  $btn.html($btn.data('original'));
});
```

---

## 13. Debounced Search with Loading Indicator

A polished search-as-you-type pattern.

### JS side

```js
// www/search.js
(function() {
  var searchTimer = null;

  $(document).on('input', '#search_box', function() {
    var $input = $(this);
    var $indicator = $input.siblings('.search-indicator');
    var value = $input.val().trim();

    // Show loading indicator immediately
    $indicator.addClass('searching');

    // Clear previous debounce
    clearTimeout(searchTimer);

    if (value.length === 0) {
      $indicator.removeClass('searching');
      Shiny.setInputValue('search_query', '', {priority: 'event'});
      return;
    }

    // Debounce: only fire after 300ms of inactivity
    searchTimer = setTimeout(function() {
      Shiny.setInputValue('search_query', value, {priority: 'event'});
    }, 300);
  });

  // Remove indicator when results arrive
  $(document).on('shiny:value', function(event) {
    if ($(event.target).attr('id') === 'search_results') {
      $('.search-indicator').removeClass('searching');
    }
  });
})();
```

### R UI

```r
search_input_ui <- function(id = "search_box") {
  tags$div(
    class = "search-wrapper",
    tags$input(
      id = id,
      type = "text",
      class = "form-control",
      placeholder = "Search...",
      autocomplete = "off"
    ),
    tags$div(class = "search-indicator",
      tags$div(class = "loading-spinner", style = "width:16px;height:16px;")
    )
  )
}
```

### CSS

```css
.search-wrapper {
  position: relative;
}

.search-indicator {
  position: absolute;
  right: 10px;
  top: 50%;
  transform: translateY(-50%);
  opacity: 0;
  transition: opacity 0.2s;
}

.search-indicator.searching {
  opacity: 1;
}
```

### R server

```r
server <- function(input, output, session) {
  search_results <- reactive({
    req(input$search_query)
    # This naturally debounced by JS, so no invalidateLater needed
    df %>% filter(grepl(input$search_query, name, ignore.case = TRUE))
  })

  output$search_results <- renderDT({
    search_results()
  })
}
```

---

## 14. Connection Loss Handling

### Basic reconnect banner

```js
// www/connection.js
$(document).on('shiny:disconnected', function() {
  if (document.getElementById('reconnect-overlay')) return;

  var overlay = document.createElement('div');
  overlay.id = 'reconnect-overlay';
  overlay.innerHTML =
    '<div class="reconnect-content">' +
    '  <div class="reconnect-icon">&#x26A0;</div>' +
    '  <h3>Connection Lost</h3>' +
    '  <p>The connection to the server was interrupted.</p>' +
    '  <button onclick="location.reload()" class="btn btn-primary">Reconnect</button>' +
    '</div>';
  document.body.appendChild(overlay);
});
```

```css
#reconnect-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 99999;
  backdrop-filter: blur(4px);
  animation: fadeIn 0.3s ease;
}

.reconnect-content {
  background: #fff;
  border-radius: 12px;
  padding: 40px;
  text-align: center;
  max-width: 400px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.reconnect-icon {
  font-size: 48px;
  margin-bottom: 16px;
}
```

### Auto-reconnect with exponential backoff

```js
(function() {
  var attempts = 0;
  var maxAttempts = 5;
  var baseDelay = 1000;

  $(document).on('shiny:disconnected', function() {
    tryReconnect();
  });

  function tryReconnect() {
    if (attempts >= maxAttempts) {
      showFinalDisconnect();
      return;
    }

    attempts++;
    var delay = baseDelay * Math.pow(2, attempts - 1); // 1s, 2s, 4s, 8s, 16s
    updateStatus('Reconnecting in ' + (delay / 1000) + 's... (attempt ' +
                 attempts + '/' + maxAttempts + ')');

    setTimeout(function() {
      updateStatus('Attempting to reconnect...');
      location.reload();
    }, delay);
  }

  function updateStatus(msg) {
    var el = document.getElementById('reconnect-status');
    if (el) el.textContent = msg;
  }

  function showFinalDisconnect() {
    // Show the full overlay from the previous example
  }
})();
```

### Heartbeat pattern (detect silent disconnects)

```js
// Periodically check if we're still connected
setInterval(function() {
  if (Shiny && Shiny.shinyapp && Shiny.shinyapp.$socket) {
    var state = Shiny.shinyapp.$socket.readyState;
    // 0=CONNECTING, 1=OPEN, 2=CLOSING, 3=CLOSED
    if (state === 3) {
      $(document).trigger('shiny:disconnected');
    }
  }
}, 5000);
```

### Save state before disconnect

```js
// When user navigates away or closes tab
window.addEventListener('beforeunload', function() {
  // Try to save current form state
  if (Shiny && Shiny.shinyapp && Shiny.shinyapp.$socket &&
      Shiny.shinyapp.$socket.readyState === 1) {
    Shiny.setInputValue('save_on_exit', Date.now(), {priority: 'event'});
  }
});
```

---

## Quick Reference: Common Patterns

| Want to... | Use... |
|---|---|
| Send data JS -> R | `Shiny.setInputValue('name', value)` |
| Send data R -> JS | `session$sendCustomMessage('type', data)` |
| Fire repeatedly with same value | `{priority: 'event'}` |
| Handle namespaces in modules | `data-ns` attribute pattern |
| New input type | Custom input binding |
| New output type | Custom output binding |
| Global busy indicator | NProgress + `shiny:busy`/`shiny:idle` |
| Kill opacity flash | `.recalculating { opacity: 1 !important; }` |
| Keyboard shortcuts | Hotkeys.js + `setInputValue` |
| Toast notifications | `sendCustomMessage` + custom handler |
| Loading button | Optimistic JS + `sendCustomMessage` reset |
| Premium feel | CSS transitions on everything (150-300ms) |

---

*Notes compiled from Colin Fay's JS4Shiny field notes, Shiny documentation, and community patterns.*

---

# Book 4: Outstanding User Interfaces with Shiny

# Outstanding User Interfaces with Shiny — David Granjon

Book URL: <https://unleash-shiny.rinterface.com/>

Notes compiled from training knowledge. The book covers how Shiny works under
the hood (HTML generation, JS bindings, websocket protocol) and how to make
Shiny apps look and feel like modern web applications rather than default
Bootstrap 3 dashboards.

---

## 1. How Shiny Generates HTML

### 1.1 Tags, Attributes, Children

Every piece of UI in Shiny is ultimately an R object that prints as HTML.
The workhorse is `shiny::tags`, a named list of tag-generating functions.

```r
# tags$<element>(...)  creates an HTML tag
tags$div(
  class = "card",
  id = "my-card",
  tags$h3("Title"),
  tags$p("Some paragraph text")
)
# produces:
# <div class="card" id="my-card">
#   <h3>Title</h3>
#   <p>Some paragraph text</p>
# </div>
```

**Rules:**

- Named arguments become HTML **attributes** (`class`, `id`, `style`, `data-*`).
- Unnamed arguments become **children** (nested tags or text nodes).
- Use backtick-quoted names for attributes with hyphens: `` tags$div(`data-value` = 10) ``.
- Boolean attributes: `tags$input(type = "text", disabled = NA)` produces `<input type="text" disabled>`.
- `NULL` children are silently dropped — useful for conditional UI.

```r
# Conditional child
tags$div(
 if (show_warning) tags$p(class = "text-danger", "Watch out!") else NULL
)
```

### 1.2 Common Shortcuts

Shiny exports shortcuts for the most common tags so you don't need `tags$`:

```r
# These are equivalent:
div(class = "mt-3", "hello")
tags$div(class = "mt-3", "hello")

# Shortcuts available: div, span, a, br, hr, h1-h6, p, pre, code,
#   img, strong, em
```

### 1.3 withTags

`withTags()` lets you drop the `tags$` prefix inside a block:

```r
withTags(
  table(
    class = "table",
    thead(tr(th("Name"), th("Value"))),
    tbody(
      tr(td("Alpha"), td("0.05")),
      tr(td("Beta"),  td("0.20"))
    )
  )
)
```

### 1.4 tagList

`tagList()` bundles multiple tags into a single object **without** a wrapping
container element. This is the idiomatic way to return multiple elements from a
module UI function.

```r
my_ui <- tagList(
  tags$h2("Section A"),
  tags$p("Paragraph one"),
  tags$p("Paragraph two")
)
# renders as three sibling elements — no wrapper div
```

### 1.5 HTML() vs Text

By default, text children are **escaped** (safe from XSS). Use `HTML()` to
inject raw HTML:

```r
tags$p("2 &lt; 3")          # text is escaped: shows literal "2 < 3"
tags$p(HTML("2 &lt; 3"))     # raw HTML: shows "2 < 3" as entity
tags$p(HTML("<b>bold</b>"))  # renders bold
```

### 1.6 Tag Manipulation

Tags are R lists. You can inspect and modify them:
```r
my_tag <- div(class = "original", "hello")

# Read attributes
my_tag$attribs$class   # "original"

# Add / overwrite attributes
my_tag <- tagAppendAttributes(my_tag, class = "extra", `data-x` = 5)

# Append children
my_tag <- tagAppendChild(my_tag, p("new child"))

# Check if a tag has a specific class
tagHasAttribute(my_tag, "class")
```

### 1.7 htmlDependency System

Shiny manages CSS/JS assets via `htmltools::htmlDependency`. When a dependency
is attached to a tag, Shiny:

1. Deduplicates — only one copy of each dependency (by name + version) is sent.
2. Orders — dependencies are loaded in the correct sequence.
3. Serves — files are served from the package's installed location.

```r
my_dep <- htmltools::htmlDependency(
  name = "my-widget",
  version = "1.0.0",
  src = c(file = system.file("assets", package = "mypkg")),
  # or src = c(href = "https://cdn.example.com/widget/1.0.0/"),
  stylesheet = "widget.css",
  script = "widget.js",
  all_files = FALSE
)

# Attach to any tag
my_ui <- tagList(
  my_dep,
  div(class = "my-widget", "content")
)

# Or use attachDependencies()
my_tag <- div("content")
my_tag <- htmltools::attachDependencies(my_tag, my_dep)
# append = TRUE to add to existing deps rather than replace
my_tag <- htmltools::attachDependencies(my_tag, my_dep, append = TRUE)
```

**Finding Shiny's own dependencies:**

```r
# Shiny ships jQuery, Bootstrap 3 (or via bslib), shiny.js, etc.
# You can see them:
shiny::bootstrapLib()  # the Bootstrap dependency object
```

---

## 2. CSS Fundamentals

### 2.1 Three Ways to Add CSS in Shiny

```r
# 1. Inline style attribute
div(style = "color: red; font-size: 14px;", "hello")

# 2. Internal stylesheet via tags$style in the head
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      .my-class { color: blue; margin-top: 1rem; }
    "))
  ),
  div(class = "my-class", "styled")
)

# 3. External stylesheet via tags$link or htmlDependency
ui <- fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", href = "custom.css")
    # file lives in www/custom.css
  )
)
```

### 2.2 Specificity and the Cascade

Specificity determines which rule wins when multiple rules target the same
element. Scored as (inline, IDs, classes/attributes/pseudo-classes, elements):

| Selector              | Specificity | Notes                     |
|:----------------------|:------------|:--------------------------|
| `*`                   | (0,0,0,0)   | Universal                 |
| `div`                 | (0,0,0,1)   | Element                   |
| `.card`               | (0,0,1,0)   | Class                     |
| `div.card`            | (0,0,1,1)   | Element + class           |
| `#main`               | (0,1,0,0)   | ID                        |
| `#main .card`         | (0,1,1,0)   | ID + class                |
| `style="..."`         | (1,0,0,0)   | Inline always wins        |
| `!important`          | Overrides all| Avoid when possible       |

**Cascade order** (last wins among equal specificity):

1. User-agent (browser) defaults
2. Author normal styles
3. Author `!important`
4. User `!important`

### 2.3 The Box Model

Every element is a rectangular box:

```
┌──────────────── margin ────────────────┐
│ ┌──────────── border ──────────────┐   │
│ │ ┌────────── padding ──────────┐  │   │
│ │ │                              │ │   │
│ │ │       content area           │ │   │
│ │ │                              │ │   │
│ │ └──────────────────────────────┘ │   │
│ └──────────────────────────────────┘   │
└────────────────────────────────────────┘
```

**Critical:** Always set `box-sizing: border-box` so `width` includes padding
and border:

```css
*, *::before, *::after {
  box-sizing: border-box;
}
```

### 2.4 Positioning

| Value      | Behavior                                                  |
|:-----------|:----------------------------------------------------------|
| `static`   | Default. Normal document flow.                            |
| `relative` | Normal flow, but `top/left` offset from its own position. |
| `absolute` | Removed from flow, positioned relative to nearest positioned ancestor. |
| `fixed`    | Removed from flow, positioned relative to viewport.       |
| `sticky`   | Normal flow until scroll threshold, then becomes fixed.   |

```css
/* Sticky header */
.app-header {
  position: sticky;
  top: 0;
  z-index: 1000;
  background: white;
}
```

### 2.5 Units

| Unit   | Meaning                                | Use for                    |
|:-------|:---------------------------------------|:---------------------------|
| `px`   | Absolute pixel                         | Borders, shadows, icons    |
| `rem`  | Relative to root font-size (16px)      | Font sizes, spacing, padding |
| `em`   | Relative to parent's font-size         | Component-scoped sizing    |
| `%`    | Percentage of parent                   | Widths, responsive layouts |
| `vh`   | 1% of viewport height                  | Full-height sections       |
| `vw`   | 1% of viewport width                   | Full-width elements        |
| `fr`   | Fraction of available space (grid)     | Grid columns               |
| `ch`   | Width of "0" character                 | Input widths               |

```css
/* Responsive font scale using clamp */
h1 { font-size: clamp(1.5rem, 2.5vw, 2.5rem); }

/* Full-viewport app shell */
.app-shell {
  height: 100vh;
  width: 100vw;
  overflow: hidden;
}
```

---

## 3. Custom Input Bindings — The Full Protocol

Custom input bindings are the mechanism to create entirely new Shiny input
types. The protocol has both an R side (UI + server helpers) and a JS side
(the binding object registered with Shiny).

### 3.1 JavaScript Side — The Binding Object

```js
// inst/js/myInput.js

var myInputBinding = new Shiny.InputBinding();

$.extend(myInputBinding, {

  // 1. find(scope): return all instances of this input within scope
  //    scope is the element Shiny is searching (usually document on init,
  //    or a newly inserted UI chunk)
  find: function(scope) {
    return $(scope).find('.my-custom-input');
  },

  // 2. getId(el): return the input's id — usually from the DOM id attribute
  getId: function(el) {
    return el.id;
  },

  // 3. getValue(el): extract the current value from the DOM
  getValue: function(el) {
    return {
      text: $(el).find('.input-field').val(),
      checked: $(el).find('.toggle').is(':checked')
    };
    // This object arrives in R as input$myid (a list with $text and $checked)
  },

  // 4. setValue(el, value): programmatically set the value (called by update*)
  setValue: function(el, value) {
    $(el).find('.input-field').val(value.text);
    $(el).find('.toggle').prop('checked', value.checked);
  },

  // 5. subscribe(el, callback): tell Shiny when the value changes
  subscribe: function(el, callback) {
    $(el).on('change.myInputBinding', function() {
      callback(true);  // true = use rate policy; false = fire immediately
    });
    $(el).on('click.myInputBinding', '.action-btn', function() {
      callback(false);
    });
  },

  // 6. unsubscribe(el): clean up event listeners
  unsubscribe: function(el) {
    $(el).off('.myInputBinding');
  },

  // 7. getRatePolicy(): debounce or throttle
  getRatePolicy: function() {
    return { policy: 'debounce', delay: 250 };
    // options: 'debounce', 'throttle', 'direct' (no delay)
  },

  // 8. receiveMessage(el, data): handle messages from updateMyInput() in R
  receiveMessage: function(el, data) {
    if (data.hasOwnProperty('text')) {
      this.setValue(el, data);
    }
    if (data.hasOwnProperty('label')) {
      $(el).find('label').text(data.label);
    }
    $(el).trigger('change');  // trigger change so Shiny picks up new value
  },

  // 9. getType(): register a custom input type for server-side processing
  getType: function() {
    return 'mypkg.myinput';
    // corresponds to registerInputHandler("mypkg.myinput", ...)
  }
});

// Register with priority (higher = checked first)
Shiny.inputBindings.register(myInputBinding, 'mypkg.myInputBinding');
```

### 3.2 R Side — UI Function

```r
#' @export
myInput <- function(inputId, label, text = "", checked = FALSE, width = NULL) {

  dep <- htmltools::htmlDependency(
    name = "myInput",
    version = "0.1.0",
    src = c(file = system.file("js", package = "mypkg")),
    script = "myInput.js",
    stylesheet = "myInput.css"
  )

  tags$div(
    id = inputId,
    class = "my-custom-input",
    style = if (!is.null(width)) paste0("width: ", validateCssUnit(width), ";"),

    tags$label(`for` = inputId, label),
    tags$input(class = "input-field", type = "text", value = text),
    tags$input(class = "toggle", type = "checkbox",
               checked = if (checked) NA else NULL),

    dep
  )
}
```

### 3.3 R Side — Update Function

```r
#' @export
updateMyInput <- function(session = getDefaultReactiveDomain(),
                          inputId, label = NULL, text = NULL, checked = NULL) {
  message <- dropNulls(list(
    label = label,
    text = text,
    checked = checked
  ))
  session$sendInputMessage(inputId, message)
  # This calls receiveMessage() on the JS side
}

# Utility
dropNulls <- function(x) x[!vapply(x, is.null, logical(1))]
```

### 3.4 R Side — registerInputHandler

If `getType()` returns `"mypkg.myinput"`, you register a handler to
post-process the raw JSON value before it reaches reactive code:

```r
# In .onLoad() or zzz.R
.onLoad <- function(libname, pkgname) {
  shiny::registerInputHandler("mypkg.myinput", function(data, shinysession, name) {
    # data is the raw JSON-parsed value from getValue()
    # Transform it however you need:
    data$text <- trimws(data$text)
    data$checked <- isTRUE(data$checked)
    data$timestamp <- Sys.time()
    data
  }, force = TRUE)
}
```

### 3.5 Lifecycle Summary

```
User interacts with DOM
  → subscribe callback fires
  → Shiny calls getValue(el)
  → if getType() is defined, registerInputHandler transforms the value
  → value arrives in R as input$<id>
  → reactive graph invalidates

R calls updateMyInput()
  → session$sendInputMessage(id, data)
  → receiveMessage(el, data) called on JS side
  → setValue(el, data) updates DOM
  → triggers change event
  → getValue(el) runs again → new value sent to R
```

---

## 4. Custom Output Bindings

### 4.1 JavaScript Side

```js
// inst/js/myOutput.js

var myOutputBinding = new Shiny.OutputBinding();

$.extend(myOutputBinding, {

  // find: locate all output containers
  find: function(scope) {
    return $(scope).find('.my-custom-output');
  },

  // renderValue: called when R sends a new value
  renderValue: function(el, data) {
    if (data === null) {
      // Clear the output
      $(el).empty();
      return;
    }

    // data is whatever your R render function returns (after serialization)
    $(el).html(
      '<div class="result">' +
        '<h4>' + data.title + '</h4>' +
        '<p>' + data.content + '</p>' +
      '</div>'
    );
  },

  // renderError: called when the R expression errors
  renderError: function(el, err) {
    $(el).html(
      '<div class="shiny-output-error">' + err.message + '</div>'
    );
  },

  // clearError: called when a previous error is resolved
  clearError: function(el) {
    $(el).find('.shiny-output-error').remove();
  }
});

Shiny.outputBindings.register(myOutputBinding, 'mypkg.myOutputBinding');
```

### 4.2 R Side — Output UI Function

```r
#' @export
myOutput <- function(outputId, width = "100%", height = "400px") {

  dep <- htmltools::htmlDependency(
    name = "myOutput",
    version = "0.1.0",
    src = c(file = system.file("js", package = "mypkg")),
    script = "myOutput.js",
    stylesheet = "myOutput.css"
  )

  tags$div(
    id = outputId,
    class = "my-custom-output shiny-report-output",
    style = sprintf("width: %s; height: %s;",
                    htmltools::validateCssUnit(width),
                    htmltools::validateCssUnit(height)),
    dep
  )
}
```

### 4.3 R Side — Render Function

```r
#' @export
renderMyOutput <- function(expr, env = parent.frame(), quoted = FALSE) {
  # Convert expr to a function
  func <- shiny::exprToFunction(expr, env, quoted)

  function() {
    result <- func()
    # Return a list that will be JSON-serialized and sent to renderValue()
    list(
      title = result$title,
      content = result$content
    )
  }
}

# Usage in server:
# output$report <- renderMyOutput({
#   list(title = "Results", content = paste("p =", round(pval, 4)))
# })
```

### 4.4 htmlwidgets Pattern (createWidget / shinyRenderWidget)

The `htmlwidgets` package provides a higher-level abstraction for custom
outputs, especially for wrapping JavaScript visualization libraries:

```r
#' @export
myWidget <- function(data, width = NULL, height = NULL, elementId = NULL) {
  # prepare data for JS
  x <- list(
    data = data,
    options = list(animate = TRUE)
  )

  htmlwidgets::createWidget(
    name = "myWidget",        # must match JS binding name
    x = x,                    # data payload → JSON
    width = width,
    height = height,
    package = "mypkg",
    elementId = elementId
  )
}

#' @export
myWidgetOutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(outputId, "myWidget", width, height, "mypkg")
}

#' @export
renderMyWidget <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) expr <- substitute(expr)
  htmlwidgets::shinyRenderWidget(expr, myWidgetOutput, env, quoted = TRUE)
}
```

The corresponding JS file (`inst/htmlwidgets/myWidget.js`):

```js
HTMLWidgets.widget({
  name: 'myWidget',
  type: 'output',

  factory: function(el, width, height) {
    return {
      renderValue: function(x) {
        // x is the JSON-parsed version of the R list
        el.innerHTML = '<p>' + JSON.stringify(x.data) + '</p>';
      },
      resize: function(width, height) {
        // handle resize
      }
    };
  }
});
```

---

## 5. Bootstrap Internals

### 5.1 The 12-Column Grid

Bootstrap divides every row into 12 equal columns. Shiny's `fluidRow()` +
`column()` map directly to Bootstrap's grid:

```r
fluidRow(
  column(4, "sidebar"),   # 4/12 = 33%
  column(8, "main")       # 8/12 = 67%
)
# produces:
# <div class="row">
#   <div class="col-sm-4">sidebar</div>
#   <div class="col-sm-8">main</div>
# </div>
```

### 5.2 Responsive Breakpoints

| Breakpoint | Class infix | Min-width | Typical device        |
|:-----------|:------------|:----------|:----------------------|
| xs         | (none)      | 0         | Portrait phones       |
| sm         | `-sm-`      | 576px     | Landscape phones      |
| md         | `-md-`      | 768px     | Tablets               |
| lg         | `-lg-`      | 992px     | Desktops              |
| xl         | `-xl-`      | 1200px    | Large desktops        |
| xxl        | `-xxl-`     | 1400px    | Extra large (BS5)     |

```r
# In Bootstrap 5 / bslib, you can use responsive column classes directly:
div(
  class = "row",
  div(class = "col-12 col-md-6 col-lg-4", "Card 1"),
  div(class = "col-12 col-md-6 col-lg-4", "Card 2"),
  div(class = "col-12 col-md-6 col-lg-4", "Card 3")
)
# Full width on mobile, 2-col on tablet, 3-col on desktop
```

### 5.3 Bootstrap Components Shiny Uses

Shiny relies heavily on these Bootstrap components:

- **Grid** (`row`, `col-*`) — layout via `fluidRow()`, `column()`
- **Panels/Cards** — `wellPanel()` maps to `.well` (BS3) or `.card` (BS5)
- **Navs/Tabs** — `tabsetPanel()`, `navbarPage()`, `navlistPanel()`
- **Modals** — `modalDialog()`, `showModal()`
- **Buttons** — `actionButton()` → `.btn.btn-default`
- **Forms** — `textInput()`, `selectInput()` → `.form-group`, `.form-control`
- **Alerts** — via `shinyFeedback` or manual `div(class = "alert alert-danger")`
- **Progress bars** — `withProgress()` → `.progress > .progress-bar`
- **Dropdowns** — inside `navbarPage()`, also `dropdownMenu()` in shinydashboard

### 5.4 Utility Classes (BS5)

```html
<!-- Spacing: m=margin, p=padding; t/b/s/e/x/y = sides; 0-5 + auto -->
<div class="mt-3 mb-2 px-4">...</div>

<!-- Display -->
<div class="d-flex d-none d-md-block">...</div>

<!-- Text -->
<p class="text-center text-muted fs-5 fw-bold">...</p>

<!-- Borders / Rounded -->
<div class="border rounded-3 shadow-sm">...</div>

<!-- Colors -->
<span class="text-primary bg-light">...</span>
```

---

## 6. bslib Theming in Depth

### 6.1 Basic Theme Creation

```r
library(bslib)

my_theme <- bs_theme(
  version = 5,                          # Bootstrap version
  bootswatch = "flatly",                # optional Bootswatch theme

  # Core Sass variables
  bg = "#ffffff",                        # background
  fg = "#212529",                        # foreground (text)
  primary = "#0d6efd",                   # brand primary
  secondary = "#6c757d",
  success = "#198754",
  info = "#0dcaf0",
  warning = "#ffc107",
  danger = "#dc3545",

  # Typography
  base_font = font_google("Inter"),
  heading_font = font_google("Poppins"),
  code_font = font_google("Fira Code"),
  font_scale = 1.0,                      # multiplier for base font size

  # Layout
  "border-radius" = "0.5rem",
  "card-border-radius" = "0.75rem",
  spacer = "1rem",
  "enable-shadows" = TRUE,
  "enable-rounded" = TRUE
)

ui <- page_sidebar(
  theme = my_theme,
  title = "My App",
  sidebar = sidebar("Controls"),
  "Main content"
)
```

### 6.2 Sass Variables vs. CSS Custom Properties

bslib exposes Bootstrap's full Sass variable system. You can override any
variable:

```r
# Override any Bootstrap Sass variable
my_theme <- bs_theme(
  version = 5,
  "navbar-bg" = "#1a1a2e",
  "navbar-dark-color" = "#e0e0e0",
  "input-bg" = "#f8f9fa",
  "input-border-color" = "#dee2e6",
  "card-spacer-y" = "1.25rem",
  "card-spacer-x" = "1.25rem",
  "modal-content-border-radius" = "1rem"
)
```

### 6.3 bs_add_rules — Custom CSS/Sass

Inject arbitrary CSS or Sass that can reference Bootstrap variables:

```r
my_theme <- bs_theme(version = 5, primary = "#6366f1") |>
  bs_add_rules("
    // This is Sass — you can use Bootstrap variables
    .custom-header {
      background: $primary;
      color: $white;
      padding: $spacer * 2;
      border-radius: $border-radius-lg;
    }

    // Nesting works
    .stats-card {
      border-left: 4px solid $primary;
      transition: transform 0.2s ease;

      &:hover {
        transform: translateY(-2px);
        box-shadow: $box-shadow;
      }

      .stats-value {
        font-size: 2rem;
        font-weight: 700;
        color: $primary;
      }

      .stats-label {
        font-size: 0.875rem;
        color: $text-muted;
        text-transform: uppercase;
        letter-spacing: 0.05em;
      }
    }
  ")
```

### 6.4 The `.where` Parameter (Specificity Control)

`.where()` is a CSS feature (`:where()` pseudo-class) that bslib uses to keep
specificity at zero, making it easy to override:

```r
# bs_add_rules with .where wrapping for low-specificity defaults
my_theme <- bs_theme() |>
  bs_add_rules("
    :where(.my-widget) {
      padding: 1rem;
      border: 1px solid var(--bs-border-color);
    }
    /* Easy to override without specificity wars */
  ")
```

### 6.5 Dark Mode

```r
ui <- page_navbar(
  theme = bs_theme(version = 5) |>
    bs_add_rules("
      [data-bs-theme='dark'] {
        --app-bg: #1a1a2e;
        --app-surface: #16213e;
        --app-text: #e0e0e0;
      }
    "),
  title = "My App",

  # Dark mode toggle — bslib provides this:
  # The navbar gets a toggle automatically with:
  nav_spacer(),
  nav_item(
    input_dark_mode(id = "dark_mode", mode = "light")
  )
)
```

`input_dark_mode()` adds a toggle that sets `data-bs-theme="dark"` on the
`<html>` element. Bootstrap 5.3+ respects this attribute for all its
components. For custom styles, scope to `[data-bs-theme='dark']`:

```css
/* Light mode (default) */
.my-card {
  background: #ffffff;
  color: #333;
  box-shadow: 0 1px 3px rgba(0,0,0,0.12);
}

/* Dark mode */
[data-bs-theme="dark"] .my-card {
  background: #1e1e2e;
  color: #cdd6f4;
  box-shadow: 0 1px 3px rgba(0,0,0,0.4);
}
```

---

## 7. CSS Animations

### 7.1 Transitions

Transitions animate property changes smoothly:

```css
/* Transition specific properties */
.card {
  transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.15s ease;
}

.card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(0,0,0,0.15);
  border-color: var(--bs-primary);
}

/* Button press effect */
.btn-custom {
  transition: all 0.15s ease;
}
.btn-custom:active {
  transform: scale(0.97);
}
```

### 7.2 Keyframe Animations

#### fadeIn

```css
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.fade-in {
  animation: fadeIn 0.3s ease-out forwards;
}

/* Staggered fade-in for lists */
.fade-in-item:nth-child(1) { animation-delay: 0.05s; }
.fade-in-item:nth-child(2) { animation-delay: 0.10s; }
.fade-in-item:nth-child(3) { animation-delay: 0.15s; }
.fade-in-item:nth-child(4) { animation-delay: 0.20s; }
```

#### Shimmer (loading placeholder)

```css
@keyframes shimmer {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
}

.skeleton {
  background: linear-gradient(
    90deg,
    #f0f0f0 25%,
    #e0e0e0 50%,
    #f0f0f0 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;
  border-radius: 4px;
}

.skeleton-text {
  height: 1em;
  margin-bottom: 0.5em;
  width: 80%;
}

.skeleton-title {
  height: 1.5em;
  width: 60%;
  margin-bottom: 1rem;
}
```

#### Pulse

```css
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.loading-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--bs-primary);
  animation: pulse 1.4s ease-in-out infinite;
}

.loading-dot:nth-child(2) { animation-delay: 0.2s; }
.loading-dot:nth-child(3) { animation-delay: 0.4s; }
```

#### Ripple (Material Design button effect)

```css
@keyframes ripple {
  to {
    transform: scale(4);
    opacity: 0;
  }
}

.btn-ripple {
  position: relative;
  overflow: hidden;
}

.btn-ripple::after {
  content: '';
  position: absolute;
  width: 100px;
  height: 100px;
  background: rgba(255,255,255,0.3);
  border-radius: 50%;
  transform: scale(0);
  pointer-events: none;
}

.btn-ripple:active::after {
  animation: ripple 0.6s ease-out;
}
```

#### Spin (for loading icons)

```css
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

.spinner {
  width: 24px;
  height: 24px;
  border: 3px solid var(--bs-border-color);
  border-top-color: var(--bs-primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
```

### 7.3 Adding Animations from R

```r
# In a module — animate new content
output$results <- renderUI({
  req(input$go)
  div(class = "fade-in",
    h4("Results"),
    tableOutput(ns("result_table"))
  )
})

# Trigger animation on reactive change using shinyjs
observeEvent(input$calculate, {
  shinyjs::addClass("result-card", "fade-in")
  # Remove class after animation to allow re-triggering
  shinyjs::delay(300, shinyjs::removeClass("result-card", "fade-in"))
})
```

### 7.4 Respecting User Preferences

```css
/* Disable animations for users who prefer reduced motion */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 8. CSS Grid for Dashboard Layouts

### 8.1 Named Grid Areas

```css
.dashboard-layout {
  display: grid;
  grid-template-areas:
    "header header  header"
    "nav    main    aside"
    "footer footer  footer";
  grid-template-columns: 250px 1fr 300px;
  grid-template-rows: auto 1fr auto;
  min-height: 100vh;
  gap: 0;
}

.dashboard-header { grid-area: header; }
.dashboard-nav    { grid-area: nav; }
.dashboard-main   { grid-area: main; overflow-y: auto; }
.dashboard-aside  { grid-area: aside; }
.dashboard-footer { grid-area: footer; }

/* Responsive: collapse sidebar on mobile */
@media (max-width: 768px) {
  .dashboard-layout {
    grid-template-areas:
      "header"
      "main"
      "footer";
    grid-template-columns: 1fr;
  }
  .dashboard-nav,
  .dashboard-aside {
    display: none;
  }
}
```

```r
# R side
ui <- div(
  class = "dashboard-layout",
  div(class = "dashboard-header", "Header"),
  div(class = "dashboard-nav",    "Navigation"),
  div(class = "dashboard-main",   "Main Content"),
  div(class = "dashboard-aside",  "Side Panel"),
  div(class = "dashboard-footer", "Footer")
)
```

### 8.2 Auto-Fit Card Grid

```css
/* Cards that auto-wrap — no media queries needed */
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
  padding: 1.5rem;
}
```

```r
div(class = "card-grid",
  lapply(1:6, function(i) {
    div(class = "metric-card",
      h4(paste("Metric", i)),
      p(class = "metric-value", round(runif(1, 10, 100), 1))
    )
  })
)
```

### 8.3 Complex Dashboard Grid

```css
.analytics-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-template-rows: auto auto 1fr;
  gap: 1rem;
}

/* KPI cards span 1 column each across the top */
.kpi-card { }

/* Chart spans 3 columns */
.main-chart {
  grid-column: 1 / 4;
  grid-row: 2 / 4;
}

/* Side panel spans 1 column, 2 rows */
.side-panel {
  grid-column: 4;
  grid-row: 2 / 4;
}
```

---

## 9. Flexbox Patterns

### 9.1 Centered Content

```css
/* Perfect centering — the classic use case */
.center-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
}

/* Center a loading spinner */
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  padding: 3rem;
}
```

### 9.2 Space-Between

```css
/* Header with logo left, nav right */
.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1.5rem;
  border-bottom: 1px solid var(--bs-border-color);
}

/* Card footer with actions */
.card-footer-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
}

/* Metric row: label left, value right */
.metric-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  padding: 0.5rem 0;
  border-bottom: 1px solid var(--bs-border-color-translucent);
}
```

### 9.3 Sticky Footer

```css
/* Page-level sticky footer using flex */
.app-wrapper {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.app-header { flex-shrink: 0; }
.app-main   { flex: 1; }          /* takes all available space */
.app-footer { flex-shrink: 0; }   /* stays at bottom */
```

### 9.4 Card Decks (Equal-Height Cards)

```css
.card-deck {
  display: flex;
  flex-wrap: wrap;
  gap: 1.5rem;
}

.card-deck > .card {
  flex: 1 1 300px;        /* grow, shrink, min-width */
  display: flex;
  flex-direction: column;
}

/* Push card footer to bottom regardless of content height */
.card-deck > .card .card-body {
  flex: 1;
}
```

```r
div(class = "card-deck",
  lapply(list("Treatment A", "Treatment B", "Placebo"), function(arm) {
    div(class = "card",
      div(class = "card-body",
        h5(class = "card-title", arm),
        p("N = 83, Mean = 24.5")
      ),
      div(class = "card-footer text-muted", "Last updated: today")
    )
  })
)
```

### 9.5 Inline Flex Utilities

```css
/* Tag/chip list */
.tag-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

/* Vertical stack with gap (replaces margin hacks) */
.v-stack {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* Horizontal group of buttons */
.btn-group-flex {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}
```

---

## 10. CSS Custom Properties — Full Design Token System

CSS custom properties (variables) enable a complete design token system.
Define them on `:root` and reference everywhere:

### 10.1 Color Tokens

```css
:root {
  /* Brand palette */
  --color-primary-50:  #eef2ff;
  --color-primary-100: #e0e7ff;
  --color-primary-200: #c7d2fe;
  --color-primary-300: #a5b4fc;
  --color-primary-400: #818cf8;
  --color-primary-500: #6366f1;
  --color-primary-600: #4f46e5;
  --color-primary-700: #4338ca;
  --color-primary-800: #3730a3;
  --color-primary-900: #312e81;

  /* Semantic colors */
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-danger:  #ef4444;
  --color-info:    #3b82f6;

  /* Surface colors */
  --color-bg:      #ffffff;
  --color-surface: #f8fafc;
  --color-raised:  #ffffff;
  --color-overlay: rgba(0, 0, 0, 0.5);

  /* Text colors */
  --color-text:         #1e293b;
  --color-text-muted:   #64748b;
  --color-text-subtle:  #94a3b8;
  --color-text-inverse: #ffffff;

  /* Border */
  --color-border:       #e2e8f0;
  --color-border-focus: var(--color-primary-500);
}
```

### 10.2 Spacing Tokens

```css
:root {
  --space-0:  0;
  --space-1:  0.25rem;   /* 4px */
  --space-2:  0.5rem;    /* 8px */
  --space-3:  0.75rem;   /* 12px */
  --space-4:  1rem;      /* 16px */
  --space-5:  1.25rem;   /* 20px */
  --space-6:  1.5rem;    /* 24px */
  --space-8:  2rem;      /* 32px */
  --space-10: 2.5rem;    /* 40px */
  --space-12: 3rem;      /* 48px */
  --space-16: 4rem;      /* 64px */
}
```

### 10.3 Typography Tokens

```css
:root {
  /* Font families */
  --font-sans:  'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono:  'Fira Code', 'Cascadia Code', 'Consolas', monospace;
  --font-heading: 'Poppins', var(--font-sans);

  /* Font sizes — modular scale (1.25 ratio) */
  --text-xs:   0.75rem;    /* 12px */
  --text-sm:   0.875rem;   /* 14px */
  --text-base: 1rem;       /* 16px */
  --text-lg:   1.125rem;   /* 18px */
  --text-xl:   1.25rem;    /* 20px */
  --text-2xl:  1.5rem;     /* 24px */
  --text-3xl:  1.875rem;   /* 30px */
  --text-4xl:  2.25rem;    /* 36px */

  /* Line heights */
  --leading-tight:  1.25;
  --leading-normal: 1.5;
  --leading-relaxed: 1.75;

  /* Font weights */
  --weight-normal:   400;
  --weight-medium:   500;
  --weight-semibold: 600;
  --weight-bold:     700;

  /* Letter spacing */
  --tracking-tight:  -0.025em;
  --tracking-normal:  0;
  --tracking-wide:    0.05em;
  --tracking-caps:    0.1em;
}
```

### 10.4 Shadow Tokens (Elevation)

```css
:root {
  --shadow-xs:  0 1px 2px rgba(0,0,0,0.05);
  --shadow-sm:  0 1px 3px rgba(0,0,0,0.1), 0 1px 2px rgba(0,0,0,0.06);
  --shadow-md:  0 4px 6px rgba(0,0,0,0.1), 0 2px 4px rgba(0,0,0,0.06);
  --shadow-lg:  0 10px 15px rgba(0,0,0,0.1), 0 4px 6px rgba(0,0,0,0.05);
  --shadow-xl:  0 20px 25px rgba(0,0,0,0.1), 0 10px 10px rgba(0,0,0,0.04);
  --shadow-2xl: 0 25px 50px rgba(0,0,0,0.25);
  --shadow-inner: inset 0 2px 4px rgba(0,0,0,0.06);
}
```

### 10.5 Border Radius Tokens

```css
:root {
  --radius-none: 0;
  --radius-sm:   0.25rem;    /* 4px */
  --radius-md:   0.5rem;     /* 8px */
  --radius-lg:   0.75rem;    /* 12px */
  --radius-xl:   1rem;       /* 16px */
  --radius-2xl:  1.5rem;     /* 24px */
  --radius-full: 9999px;     /* pill shape */
}
```

### 10.6 Transition Tokens

```css
:root {
  --ease-default: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-in:      cubic-bezier(0.4, 0, 1, 1);
  --ease-out:     cubic-bezier(0, 0, 0.2, 1);
  --ease-in-out:  cubic-bezier(0.4, 0, 0.2, 1);
  --ease-bounce:  cubic-bezier(0.68, -0.55, 0.265, 1.55);

  --duration-fast:   100ms;
  --duration-normal: 200ms;
  --duration-slow:   300ms;
  --duration-slower: 500ms;
}
```

### 10.7 Using Tokens Throughout

```css
.metric-card {
  background: var(--color-raised);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--space-6);
  box-shadow: var(--shadow-sm);
  transition: all var(--duration-normal) var(--ease-default);
  font-family: var(--font-sans);
}

.metric-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
  border-color: var(--color-primary-200);
}

.metric-card .value {
  font-size: var(--text-3xl);
  font-weight: var(--weight-bold);
  color: var(--color-primary-600);
  line-height: var(--leading-tight);
}

.metric-card .label {
  font-size: var(--text-sm);
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: var(--tracking-caps);
  margin-top: var(--space-1);
}
```

### 10.8 Dark Mode Via Token Swap

```css
[data-bs-theme="dark"] {
  --color-bg:          #0f172a;
  --color-surface:     #1e293b;
  --color-raised:      #334155;
  --color-text:        #f1f5f9;
  --color-text-muted:  #94a3b8;
  --color-border:      #334155;

  --shadow-sm: 0 1px 3px rgba(0,0,0,0.4);
  --shadow-md: 0 4px 6px rgba(0,0,0,0.4);
}
/* All components that use tokens automatically adapt — zero extra rules */
```

---

## 11. Making Shiny Not Look Like Shiny

The default Shiny aesthetic screams "academic tool" — Bootstrap 3 panel wells,
Times New Roman, uniform gray, `selectize.js` with default chrome. This section
covers how to kill the defaults and build something that feels premium.

### 11.1 Kill the Defaults

```css
/* Reset Shiny's default body styling */
body {
  font-family: var(--font-sans);
  background: var(--color-bg);
  color: var(--color-text);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Remove default Shiny container padding */
.container-fluid {
  padding: 0 !important;
  max-width: 100% !important;
}

/* Kill the well panel look */
.well {
  background: var(--color-raised);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

/* Override Shiny's default notification style */
#shiny-notification-panel {
  top: auto;
  bottom: 1rem;
  right: 1rem;
  left: auto;
  width: 360px;
}
```

### 11.2 Typography That Does Not Look Like a Default

```css
h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-heading);
  font-weight: var(--weight-semibold);
  letter-spacing: var(--tracking-tight);
  color: var(--color-text);
  line-height: var(--leading-tight);
}

h1 { font-size: var(--text-4xl); margin-bottom: var(--space-6); }
h2 { font-size: var(--text-3xl); margin-bottom: var(--space-5); }
h3 { font-size: var(--text-2xl); margin-bottom: var(--space-4); }
h4 { font-size: var(--text-xl);  margin-bottom: var(--space-3); }

p {
  line-height: var(--leading-relaxed);
  color: var(--color-text-muted);
  max-width: 65ch;  /* optimal reading width */
}

/* Subtle section labels */
.section-label {
  font-size: var(--text-xs);
  font-weight: var(--weight-semibold);
  text-transform: uppercase;
  letter-spacing: var(--tracking-caps);
  color: var(--color-text-subtle);
  margin-bottom: var(--space-3);
}
```

### 11.3 Elevation and Shadows

Use shadows to create visual hierarchy, not borders:

```css
/* Elevation levels */
.surface-flat    { box-shadow: none; }
.surface-raised  { box-shadow: var(--shadow-sm); }
.surface-overlay { box-shadow: var(--shadow-lg); }
.surface-modal   { box-shadow: var(--shadow-2xl); }

/* Interactive elevation — cards lift on hover */
.interactive-card {
  box-shadow: var(--shadow-sm);
  transition: box-shadow var(--duration-normal) var(--ease-default),
              transform var(--duration-normal) var(--ease-default);
}

.interactive-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}
```

### 11.4 Whitespace

Premium apps breathe. Cramped UI is the number one giveaway of a Shiny app.

```css
/* Generous padding inside cards */
.card-body {
  padding: var(--space-6) var(--space-8);
}

/* Spacing between sections */
.content-section + .content-section {
  margin-top: var(--space-10);
}

/* Sidebar with room */
.sidebar-content {
  padding: var(--space-6);
}

.sidebar-content .form-group {
  margin-bottom: var(--space-6);  /* not the cramped default 15px */
}
```

### 11.5 Restrained Color

Premium apps use color sparingly. Most of the interface is neutral; color
draws attention to what matters.

```css
/* The 60-30-10 rule:
   60% — neutral backgrounds/surfaces
   30% — secondary (borders, muted text, subtle backgrounds)
   10% — primary/accent (CTAs, active states, key data)
*/

/* Primary only on actionable elements */
.btn-primary {
  background: var(--color-primary-600);
  color: var(--color-text-inverse);
  border: none;
  box-shadow: 0 1px 2px rgba(99, 102, 241, 0.3);
}

/* Use tinted backgrounds instead of bold colors for status */
.status-success {
  background: color-mix(in srgb, var(--color-success) 10%, transparent);
  color: var(--color-success);
}

.status-danger {
  background: color-mix(in srgb, var(--color-danger) 10%, transparent);
  color: var(--color-danger);
}
```

---

## 12. Modern Form Inputs, Status Badges, Table CSS

### 12.1 Modern Form Inputs

```css
/* Clean, minimal input style */
.form-control {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.625rem 0.875rem;
  font-size: var(--text-sm);
  font-family: var(--font-sans);
  color: var(--color-text);
  background: var(--color-bg);
  transition: border-color var(--duration-fast) var(--ease-default),
              box-shadow var(--duration-fast) var(--ease-default);
}

.form-control:focus {
  outline: none;
  border-color: var(--color-primary-400);
  box-shadow: 0 0 0 3px var(--color-primary-100);
}

.form-control::placeholder {
  color: var(--color-text-subtle);
}

/* Floating label style */
.form-floating > .form-control:focus ~ label,
.form-floating > .form-control:not(:placeholder-shown) ~ label {
  transform: scale(0.8) translateY(-0.75rem);
  color: var(--color-primary-600);
}

/* Custom select */
.form-select {
  appearance: none;
  background-image: url("data:image/svg+xml,...");  /* custom chevron */
  background-repeat: no-repeat;
  background-position: right 0.75rem center;
  padding-right: 2.5rem;
}

/* Input group with icon */
.input-icon-wrapper {
  position: relative;
}

.input-icon-wrapper .icon {
  position: absolute;
  left: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  color: var(--color-text-subtle);
  pointer-events: none;
}

.input-icon-wrapper .form-control {
  padding-left: 2.5rem;
}
```

### 12.2 Status Badges and Pills

```css
.badge {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.25rem 0.75rem;
  font-size: var(--text-xs);
  font-weight: var(--weight-medium);
  border-radius: var(--radius-full);
  line-height: 1;
  white-space: nowrap;
}

/* Soft/tinted badges — more modern than solid */
.badge-primary {
  background: var(--color-primary-100);
  color: var(--color-primary-700);
}

.badge-success {
  background: #d1fae5;
  color: #065f46;
}

.badge-warning {
  background: #fef3c7;
  color: #92400e;
}

.badge-danger {
  background: #fee2e2;
  color: #991b1b;
}

/* Badge with dot indicator */
.badge-dot::before {
  content: '';
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: currentColor;
}
```

```r
# R helper function
status_badge <- function(label, type = c("primary", "success", "warning", "danger")) {
  type <- match.arg(type)
  span(class = paste0("badge badge-dot badge-", type), label)
}

# Usage
status_badge("Active", "success")
status_badge("Pending Review", "warning")
status_badge("Failed", "danger")
```

### 12.3 Modern Table CSS

```css
/* Clean data table */
.modern-table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
  font-size: var(--text-sm);
}

.modern-table thead th {
  background: var(--color-surface);
  padding: 0.75rem 1rem;
  font-weight: var(--weight-semibold);
  font-size: var(--text-xs);
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
  color: var(--color-text-muted);
  border-bottom: 2px solid var(--color-border);
  text-align: left;
  position: sticky;
  top: 0;
  z-index: 1;
}

.modern-table tbody td {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text);
  vertical-align: middle;
}

.modern-table tbody tr:hover {
  background: var(--color-primary-50);
}

.modern-table tbody tr:last-child td {
  border-bottom: none;
}

/* Numeric columns right-aligned */
.modern-table td.numeric,
.modern-table th.numeric {
  text-align: right;
  font-variant-numeric: tabular-nums;
}

/* Zebra striping (subtle) */
.modern-table.striped tbody tr:nth-child(even) {
  background: var(--color-surface);
}
```

```r
# Apply to DT::datatable
DT::datatable(
  df,
  class = "modern-table",
  options = list(
    dom = 'frtip',
    pageLength = 20,
    scrollX = TRUE
  )
) |>
  DT::formatRound(columns = numeric_cols, digits = 2)
```

---

## 13. Skeleton Loading and App Shell Pattern

### 13.1 Skeleton Loading Screens

Show placeholder shapes that mimic the final layout while data loads:

```css
/* Skeleton base */
.skeleton {
  background: linear-gradient(
    90deg,
    var(--color-surface) 25%,
    var(--color-border) 50%,
    var(--color-surface) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;
  border-radius: var(--radius-sm);
}

.skeleton-text     { height: 0.875rem; margin-bottom: 0.5rem; }
.skeleton-title    { height: 1.5rem; width: 40%; margin-bottom: 1rem; }
.skeleton-avatar   { width: 40px; height: 40px; border-radius: var(--radius-full); }
.skeleton-card     { height: 200px; border-radius: var(--radius-lg); }
.skeleton-table-row { height: 2.5rem; margin-bottom: 2px; }

/* Different widths for realistic text appearance */
.skeleton-text:nth-child(1) { width: 90%; }
.skeleton-text:nth-child(2) { width: 75%; }
.skeleton-text:nth-child(3) { width: 85%; }
.skeleton-text:nth-child(4) { width: 60%; }
```

```r
# R helper: skeleton placeholder for a card
skeleton_card <- function(ns = identity) {
  div(class = "card",
    div(class = "card-body",
      div(class = "skeleton skeleton-title"),
      div(class = "skeleton skeleton-text"),
      div(class = "skeleton skeleton-text"),
      div(class = "skeleton skeleton-text"),
      div(class = "skeleton skeleton-text")
    )
  )
}

# In UI: show skeleton, then replace with real content
output$metrics_ui <- renderUI({
  # On first load, data might be NULL
  if (is.null(data())) {
    return(div(class = "card-grid",
      skeleton_card(), skeleton_card(), skeleton_card()
    ))
  }

  # Real content
  div(class = "card-grid",
    lapply(metrics(), function(m) metric_card(m$label, m$value))
  )
})
```

### 13.2 App Shell Pattern

Render the structural chrome (header, sidebar, footer) immediately as static
HTML; only the content area is reactive. This eliminates the "blank page" flash.

```r
ui <- tagList(
  tags$head(
    tags$style(HTML("
      /* The shell renders instantly — no server needed */
      .app-shell {
        display: grid;
        grid-template-rows: auto 1fr auto;
        min-height: 100vh;
      }
    "))
  ),

  div(class = "app-shell",
    # STATIC: renders immediately
    tags$header(class = "app-header",
      div(class = "d-flex justify-content-between align-items-center px-4 py-3",
        h4(class = "mb-0", "arbuilder"),
        span(class = "text-muted", "v0.1.0")
      )
    ),

    # DYNAMIC: content area — starts with skeleton
    div(class = "app-main p-4",
      uiOutput("main_content")  # skeleton → real content
    ),

    # STATIC: footer renders immediately
    tags$footer(class = "app-footer text-muted text-center py-3",
      "arbuilder | powered by arframe"
    )
  )
)
```

### 13.3 CSS-Only Loading Indicator

```css
/* Full-page loading overlay */
.loading-overlay {
  position: fixed;
  inset: 0;
  background: var(--color-bg);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  transition: opacity 0.3s ease;
}

.loading-overlay.fade-out {
  opacity: 0;
  pointer-events: none;
}

/* Three-dot loader */
.dot-loader {
  display: flex;
  gap: 0.5rem;
}

.dot-loader > span {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: var(--color-primary-500);
  animation: pulse 1.4s ease-in-out infinite;
}

.dot-loader > span:nth-child(2) { animation-delay: 0.2s; }
.dot-loader > span:nth-child(3) { animation-delay: 0.4s; }
```

```r
# Remove overlay after Shiny connects
tags$script(HTML("
  $(document).on('shiny:connected', function() {
    setTimeout(function() {
      var overlay = document.querySelector('.loading-overlay');
      if (overlay) {
        overlay.classList.add('fade-out');
        setTimeout(function() { overlay.remove(); }, 300);
      }
    }, 500);
  });
"))
```

---

## 14. Custom Scrollbars and Focus Management

### 14.1 Custom Scrollbars

```css
/* Modern thin scrollbar — Webkit (Chrome, Safari, Edge) */
.custom-scroll::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

.custom-scroll::-webkit-scrollbar-track {
  background: transparent;
}

.custom-scroll::-webkit-scrollbar-thumb {
  background: var(--color-border);
  border-radius: var(--radius-full);
}

.custom-scroll::-webkit-scrollbar-thumb:hover {
  background: var(--color-text-subtle);
}

/* Firefox */
.custom-scroll {
  scrollbar-width: thin;
  scrollbar-color: var(--color-border) transparent;
}

/* Auto-hide scrollbar — show only on hover */
.auto-scroll {
  overflow-y: auto;
}
.auto-scroll::-webkit-scrollbar-thumb {
  background: transparent;
}
.auto-scroll:hover::-webkit-scrollbar-thumb {
  background: var(--color-border);
}

/* Apply to Shiny's sidebar */
.bslib-sidebar-layout > .sidebar {
  scrollbar-width: thin;
  scrollbar-color: var(--color-border) transparent;
}
```

### 14.2 Focus Management

```css
/* Remove the ugly default outline, replace with modern focus ring */
*:focus {
  outline: none;
}

/* Only show focus ring for keyboard navigation (not mouse clicks) */
*:focus-visible {
  outline: 2px solid var(--color-primary-500);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}

/* Custom focus for form inputs — use box-shadow instead of outline */
.form-control:focus-visible {
  outline: none;
  border-color: var(--color-primary-400);
  box-shadow: 0 0 0 3px var(--color-primary-100);
}

/* Skip-to-content link (accessibility) */
.skip-link {
  position: absolute;
  top: -100%;
  left: 1rem;
  padding: 0.5rem 1rem;
  background: var(--color-primary-600);
  color: var(--color-text-inverse);
  border-radius: var(--radius-md);
  z-index: 10000;
  transition: top var(--duration-fast) var(--ease-default);
}

.skip-link:focus {
  top: 1rem;
}
```

```r
# Add skip link in UI
ui <- tagList(
  tags$a(class = "skip-link", href = "#main-content", "Skip to content"),
  # ... rest of UI ...
  div(id = "main-content", tabindex = "-1",
    # main content
  )
)
```

### 14.3 Focus Trapping in Modals

```js
// Trap focus inside a modal (accessibility requirement)
function trapFocus(element) {
  var focusableEls = element.querySelectorAll(
    'a[href], button:not([disabled]), textarea, input, select, [tabindex]:not([tabindex="-1"])'
  );
  var firstFocusable = focusableEls[0];
  var lastFocusable = focusableEls[focusableEls.length - 1];

  element.addEventListener('keydown', function(e) {
    if (e.key !== 'Tab') return;

    if (e.shiftKey) {
      if (document.activeElement === firstFocusable) {
        lastFocusable.focus();
        e.preventDefault();
      }
    } else {
      if (document.activeElement === lastFocusable) {
        firstFocusable.focus();
        e.preventDefault();
      }
    }
  });

  firstFocusable.focus();
}
```

---

## 15. Responsive Design

### 15.1 Media Queries

```css
/* Mobile-first approach: base styles are mobile, then layer up */

/* Base: single column */
.content-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1rem;
  padding: 1rem;
}

/* Tablet: 2 columns */
@media (min-width: 768px) {
  .content-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 1.5rem;
    padding: 1.5rem;
  }
}

/* Desktop: 3 columns */
@media (min-width: 1024px) {
  .content-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 2rem;
    padding: 2rem;
  }
}

/* Large desktop: 4 columns, constrained width */
@media (min-width: 1400px) {
  .content-grid {
    grid-template-columns: repeat(4, 1fr);
    max-width: 1400px;
    margin-inline: auto;
  }
}

/* Hide sidebar on mobile */
@media (max-width: 767px) {
  .app-sidebar {
    display: none;
  }

  .app-main {
    grid-column: 1 / -1;
  }

  /* Stack horizontal layouts */
  .metric-row {
    flex-direction: column;
    gap: 0.5rem;
  }

  /* Smaller headings */
  h1 { font-size: var(--text-2xl); }
  h2 { font-size: var(--text-xl); }
}
```

### 15.2 Touch-Friendly Targets

```css
/* Minimum touch target: 44x44px (WCAG 2.5.5) */
@media (pointer: coarse) {
  .btn, button, .nav-link, .dropdown-item {
    min-height: 44px;
    min-width: 44px;
    padding: 0.75rem 1rem;
  }

  /* Larger checkboxes and radios on touch */
  input[type="checkbox"],
  input[type="radio"] {
    width: 20px;
    height: 20px;
  }

  /* More spacing between clickable items */
  .list-group-item {
    padding: 1rem 1.25rem;
  }

  /* Disable hover effects on touch (they stick) */
  .card:hover {
    transform: none;
    box-shadow: var(--shadow-sm);
  }
}

/* Fine pointer (mouse) — tighter spacing is OK */
@media (pointer: fine) {
  .compact-table td {
    padding: 0.375rem 0.75rem;
  }
}
```

### 15.3 Responsive Tables

```css
/* Horizontal scroll wrapper */
.table-responsive {
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
  border-radius: var(--radius-lg);
  border: 1px solid var(--color-border);
}

/* Fade hint that table scrolls */
.table-scroll-hint {
  position: relative;
}

.table-scroll-hint::after {
  content: '';
  position: absolute;
  right: 0;
  top: 0;
  bottom: 0;
  width: 40px;
  background: linear-gradient(to right, transparent, var(--color-bg));
  pointer-events: none;
}

/* Card-style table on mobile */
@media (max-width: 640px) {
  .responsive-table thead {
    display: none;
  }

  .responsive-table tbody tr {
    display: block;
    margin-bottom: 1rem;
    border: 1px solid var(--color-border);
    border-radius: var(--radius-lg);
    padding: 1rem;
  }

  .responsive-table tbody td {
    display: flex;
    justify-content: space-between;
    padding: 0.375rem 0;
    border: none;
  }

  .responsive-table tbody td::before {
    content: attr(data-label);
    font-weight: var(--weight-semibold);
    color: var(--color-text-muted);
  }
}
```

### 15.4 Container Queries (Modern CSS)

```css
/* Container queries — respond to parent size, not viewport */
.card-container {
  container-type: inline-size;
  container-name: card;
}

@container card (min-width: 400px) {
  .card-content {
    display: flex;
    gap: 1.5rem;
  }
}

@container card (max-width: 399px) {
  .card-content {
    display: block;
  }
  .card-content > * + * {
    margin-top: 1rem;
  }
}
```

---

## 16. The Non-Negotiable List for Premium Shiny Apps

This is the checklist — the minimum bar for a Shiny app that looks professional.
Based on the themes throughout the book:

### Visual Foundation
1. **Custom font** — load Inter, Source Sans, or similar via `font_google()`. Never ship with the browser default serif.
2. **Design tokens** — define colors, spacing, radius, shadows as CSS custom properties. Reference tokens everywhere, never hard-code values.
3. **Consistent spacing** — use a spacing scale (4/8/12/16/24/32/48). Never eyeball margins.
4. **Restrained color palette** — 1 primary, 1-2 neutrals, semantic colors. 60-30-10 rule.
5. **Elevation system** — use shadows for hierarchy, not just borders.

### Typography
6. **Type scale** — use a modular scale. Body at 14-16px, headings proportional.
7. **Line height** — 1.5 for body, 1.25 for headings. Never leave at default.
8. **Max line length** — `max-width: 65ch` on paragraphs.
9. **Font smoothing** — `-webkit-font-smoothing: antialiased`.

### Layout
10. **No default Shiny chrome** — override the container-fluid padding, well panel look, default button styles.
11. **CSS Grid or Flexbox** — not just Bootstrap `column()` for everything.
12. **Responsive** — works on tablets at minimum. Test at 768px.
13. **Sticky headers** — table headers and app header should stay visible on scroll.

### Interactions
14. **Transitions on everything interactive** — buttons, cards, links. 150-200ms, ease-out.
15. **Loading states** — skeleton screens or spinners for every async operation. Users must never see a blank space where data is loading.
16. **Focus-visible** — visible keyboard focus ring, removed on mouse click.
17. **Smooth state changes** — fade in new content, don't just pop it in.

### Polish
18. **Custom scrollbars** — thin, matching the color scheme.
19. **Consistent border-radius** — pick one (8px is safe) and use it everywhere.
20. **Dark mode support** — or at minimum, light mode that is not eye-searing white (#f8fafc > #ffffff).
21. **Reduced motion** — honor `prefers-reduced-motion`.
22. **No layout shift** — use skeleton placeholders so content does not jump when it loads.

### Code Quality
23. **htmlDependency for all assets** — never use raw `tags$link` for package CSS.
24. **Custom bindings where needed** — do not fight Shiny's defaults with hacks; build a proper input/output binding.
25. **Design tokens in bslib** — use Sass variables, not inline styles.

### Implementation Checklist in R

```r
# Minimal premium setup
ui <- page_sidebar(
  theme = bs_theme(
    version = 5,
    bg = "#f8fafc", fg = "#1e293b",
    primary = "#6366f1",
    base_font = font_google("Inter"),
    heading_font = font_google("Inter"),
    code_font = font_google("Fira Code"),
    "enable-shadows" = TRUE,
    "border-radius" = "0.5rem",
    "card-border-radius" = "0.75rem"
  ) |>
    bs_add_rules(sass::sass_file("inst/css/tokens.scss")) |>
    bs_add_rules(sass::sass_file("inst/css/components.scss")) |>
    bs_add_rules(sass::sass_file("inst/css/overrides.scss")),

  title = "arbuilder",
  sidebar = sidebar(
    width = 300,
    # ... inputs
  ),
  # ... main content with skeleton loading
)
```

### Quick Reference: Shiny Functions and Their HTML Output

| Shiny Function      | HTML Output                              |
|:---------------------|:-----------------------------------------|
| `fluidPage()`        | `<div class="container-fluid">`          |
| `fluidRow()`         | `<div class="row">`                      |
| `column(4, ...)`     | `<div class="col-sm-4">`                 |
| `wellPanel()`        | `<div class="well">`                     |
| `actionButton()`     | `<button class="btn btn-default action-button">` |
| `textInput()`        | `<div class="form-group shiny-input-container">` with `<input>` |
| `selectInput()`      | `<div class="form-group shiny-input-container">` with selectize |
| `tabsetPanel()`      | `<ul class="nav nav-tabs">` + `<div class="tab-content">` |
| `conditionalPanel()` | `<div data-display-if="...">` (JS expression) |
| `uiOutput()`         | `<div class="shiny-html-output">` (placeholder) |

---

## Summary

The core thesis of the book: Shiny is a web framework, and the browser is your
rendering engine. Every concept from modern web development — semantic HTML,
CSS architecture, JavaScript event handling, responsive design — applies
directly. The difference between a "Shiny app" and a "web application built
with Shiny" is whether you treat the HTML/CSS/JS layer as a first-class
concern or leave it to defaults.

Key takeaways:
- Understand `tags`, `tagList`, and `htmlDependency` — they are the foundation.
- Custom input/output bindings are not scary; they follow a predictable protocol.
- CSS custom properties (design tokens) are the single highest-ROI investment.
- The app shell + skeleton loading pattern eliminates the "loading..." problem.
- `bslib` + `bs_add_rules` with Sass variables gives you full control without ejecting from the Shiny ecosystem.
- Whitespace, typography, and restrained color do more for perceived quality than any animation or widget.

---

# Key Takeaways for arbuilder

## Architecture
1. **Comb Strategy** — `app_server.R` is the single wiring point. Modules return lists of reactives, never call each other.
2. **fct_/utils_ separation** — ARD builders (`ard_demog.R`) are pure R functions, fully unit-testable without Shiny.
3. **App-as-package** — DESCRIPTION declares dependencies, `launch()` is the entry point. Users install and run.

## Design
4. **Kill the Shiny look** — Custom font (Inter), CSS variables for design tokens, shadow-based elevation, generous whitespace.
5. **Kill recalculating flash** — `opacity: 1 !important` on `.recalculating`, use NProgress top bar instead.
6. **Skeleton loading** — Shimmer animations instead of spinners for perceived performance.

## JS Integration
7. **Custom message handlers** — Toast notifications, loading states, clipboard copy via `session$sendCustomMessage`.
8. **Keyboard shortcuts** — Ctrl+Enter to preview, Ctrl+S to export, Escape to close panels.
9. **SortableJS** — Drag-and-drop variable selection and reordering.

## Performance
10. **bindCache** — Cache expensive ARD computations.
11. **bindEvent** — Only compute ARD on button click, not every input change.
12. **Server-side rendering** — reactable handles large datasets client-side efficiently.

## Testing
13. **Unit test ARD builders** — `testthat` on `ard_demog()`, `ard_ae()` etc. (no Shiny needed).
14. **testServer for modules** — Test module interfaces (inputs → returned reactives).
15. **One E2E test** — Full demographics workflow with shinytest2.

