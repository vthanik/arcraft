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
