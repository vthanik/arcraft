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
