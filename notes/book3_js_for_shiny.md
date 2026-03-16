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
