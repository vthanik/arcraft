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
