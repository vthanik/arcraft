# CLAUDE.md — arbuilder

Local Shiny app for building submission-ready TFLs from ADaM data. Uses `arframe` (currently `tlframe`) as the rendering engine. No server needed — runs on a laptop.

## Quick Context

- **arframe** (`tlframe`) = the rendering engine (pure R, no UI) — already built at `../tlframe/`
- **arbuilder** = this project — Shiny app that takes ADaM → ARD wide → arframe → RTF/PDF
- **adam_pilot** = test datasets at `../adam_pilot/` — 11 synthetic ADaM datasets, 250 subjects

## Phase 1: Demographics Only

Demographics template is the ONLY active template. All other templates (AE, lab, TTE, figures, listings) are backed up in `.local/backup_templates/R/`. Do NOT add new templates until demographics is bulletproof.

Quality gate: `devtools::check()`, end-to-end test, generated script runs standalone, `/simplify` audit.

## Architecture Principles

- **NOT a dashboard** — elegant focused builder tool (Figma/Linear, not Grafana)
- **VS Code Activity Bar layout** — 5 icons (DATA, TMPL, ANLYS, FMT, OUT) + sidebar + canvas
- **25/75 ratio** — sidebar 25%, canvas 75%. Resizable. Collapsible (Ctrl+B / double-click)
- **Live auto-preview** — config changes auto-trigger preview (800ms debounce)
- **Non-reactive format drafts** — modules return `get_draft()` functions, collected on Generate Preview
- **ARD-centric** — computation (ARD) separated from presentation (arframe spec)
- **Code is a deliverable** — generated R scripts must be beginner-friendly, pure tidyverse, self-contained

## Design Standards

- Must make teal/tern/NEST look like dust — categorically superior in every dimension
- Linear/Notion/Vercel-level polish. Premium typography, refined spacing, subtle interactions
- White canvas (`#ffffff`), gray sidebar (`#f7f8fa`), single accent (`#4a6fa5`)
- Only 3 text colors: `--fg-1` (primary), `--fg-2` (secondary), `--fg-muted` (tertiary)
- No shadows, no gradients, no animations except toast slide-in and chevron rotate
- Inter font, 11-12px body, 4px spacing grid
- Progressive disclosure — accordion panels, expandable cards, empty states with CTAs
- See `.local/design/DESIGN-SPEC.md` for full pixel-level specification

## Verify After Every Change (MUST FOLLOW)

After ANY bug fix, feature, or code change:
1. Run `Rscript -e "devtools::load_all('.'); app <- shiny::shinyApp(app_ui(), app_server); cat('OK')"` to verify the app creates without error
2. If UI was changed, run the app (`shiny::runApp('.')`) and manually test the affected flow
3. Confirm to the user that verification passed before marking done

## Reference TFL Materials

Regulatory TFL shell specs are at `../references/TFL_Materials/`:
- `FDA-2022-N-1961-0046_attachment_1.pdf` — FDA Standard Safety Tables (60+ table types)
- `Standard Safety TFLs.pdf` — Safety TFL shells by module (AE, lab, vitals, AESI)
- `Standard Efficacy Tables.pdf` — Efficacy endpoint table shells
- `Global Clinical Study Report DPP.pdf` — CSR data presentation plan template

## Commands

```bash
Rscript -e "shiny::runApp('.')"
```

## Test Data

```r
# Quick: load ADSL + auto-configure demographics
# Click "Demo Data" button in the app
```

## Dependencies

shiny, bslib, htmltools, reactable + tidyverse (dplyr, tidyr, tibble, readr, glue) + arframe (tlframe). No shinyjs — all JS via app.js + sendCustomMessage.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Ctrl+1-5 | Switch activity bar tabs |
| Ctrl+Enter | Generate preview |
| Ctrl+S | Export RTF |
| Ctrl+Shift+S | Download R script |
| Ctrl+B | Toggle sidebar collapse |
| Escape | Collapse all open cards |

## End-to-End Rule (MUST FOLLOW)

Every new feature, bugfix, or parameter change MUST be implemented across ALL 5 layers:

1. **UI** (`mod_*.R`) — input control visible to the user
2. **Defaults** (`utils_helpers.R` → `normalize_fmt`) — default value in schema
3. **IR** (`fct_spec_ir.R`) — passed through intermediate representation
4. **Render** (`fct_render.R`) — wired to the `arframe::fr_*()` API call
5. **Codegen** (`fct_codegen.R`) — generates the argument in the standalone R script

Before marking any change as done, grep the param name across all 5 files and confirm it appears in each. If a layer is missing, the feature is incomplete.

## Coding Conventions

- Shiny modules: `mod_*.R` with `*_ui(id)` and `*_server(id, ...)`
- ARD builder: `fct_ard_demog.R` — demographics only, plain dplyr
- Generated scripts: plain tidyverse + arframe, no special packages
- UI: bslib Bootstrap 5, accordion sidebar, CSS nesting (modern browser-native)
- All reactive outputs are tibbles or lists
- BEM naming in CSS: `.ar-block__element--modifier`
- No unused code — if it's not called, delete it

## CSS/JS Rules — MUST FOLLOW

The frontend is small by design. **Any developer (beginner or senior) must be able to maintain it.**

### Golden Rules (CSS + JS combined)

1. **SMALL IS SACRED** — CSS must stay under 800 lines, JS under 300 lines. If adding a feature pushes past this, refactor first.
2. **NEVER write CSS/JS without a matching R `class =`** — every CSS rule must have a corresponding `class = "ar-..."` in an R file. Dead CSS = tech debt.
3. **ALWAYS search before adding** — run `grep "ar-new-class" R/*.R inst/app/www/*` before creating any new class. Reuse existing classes.
4. **ONE component = ONE nested block** — a component like `.ar-col-item` has ALL its children (header, body, chevron, badge) nested inside it. Never scatter a component's rules across the file.
5. **NEVER use inline styles in R** — use CSS classes. `style = "color: red;"` in R code is banned. Create a utility class or add to the component.
6. **NEVER write inline `onclick` JS** longer than one line in R — use `Shiny.addCustomMessageHandler()` in app.js instead.
7. **Test in DevTools (F12) BEFORE editing the file** — change values live in the browser, confirm it looks right, then update app.css.

### CSS Rules (`inst/app/www/app.css` — ~670 lines)

**Structure:**
- **Section 1**: Design tokens (`:root` variables) — ALL colors, fonts, sizes defined here
- **Sections 2-9**: Layout shell (topbar, activity bar, sidebar, canvas)
- **Sections 10-15**: Generic components (buttons, forms, badges, pills, empty states, toasts)
- **Sections 16-37**: Feature components (templates, preview, code, variables, columns, titles, etc.)
- **Sections 38-45**: Framework overrides (scrollbar, accordion, tabs, inputs, utilities)

**Naming (BEM):**
```
.ar-block           → the component (e.g., .ar-col-item)
.ar-block__element  → a part of it (e.g., .ar-col-item__header)
.ar-block--modifier → a variant (e.g., .ar-col-item__badge--stub)
```

**Nesting (native CSS, no build step):**
```css
.ar-col-item {
  border-bottom: 1px solid var(--border-light);
  &__header { display: flex; }    /* becomes .ar-col-item__header */
  &__badge { font-size: 8px;
    &--stub { color: green; }     /* becomes .ar-col-item__badge--stub */
  }
}
```

**How to add a new component:**
1. Pick a name: `.ar-newcomponent`
2. Add a new section at the bottom: `/* ── 46. New Component ── */`
3. Write all rules nested inside `.ar-newcomponent { }`
4. Use design tokens from `:root` — never hardcode colors/fonts
5. In R, use `class = "ar-newcomponent__child"`

**How to change a color/font/size:**
1. Check if there's a `--token` in `:root` (e.g., `--accent`, `--fg-2`)
2. If yes, change the token value — it updates everywhere
3. If no, add a new token to `:root` and use `var(--new-token)`

### JS Rules (`inst/app/www/app.js` — ~265 lines)

**Structure (8 sections):**
1. Variable card toggle
2. Toast notifications
3. Keyboard shortcuts
4. Resizable sidebar
5. Sidebar collapse
6. SortableJS init (generic)
7. Shiny message handlers (ALL handlers go here)
8. DOMContentLoaded setup

**How to add a new feature:**
- **New keyboard shortcut** → add to section 3
- **New Shiny→JS communication** → add `Shiny.addCustomMessageHandler('ar_new', ...)` in section 7, call from R with `session$sendCustomMessage("ar_new", data)`
- **New drag-reorder** → use the generic `arInitSortable()` in section 6 — don't write a new one
- **New DOM manipulation** → prefer CSS class toggle over JS style changes

**How R talks to JS:**
```r
# R sends a message
session$sendCustomMessage("ar_toast", list(message = "Done", type = "success"))
```
```js
// JS receives it (in section 7)
Shiny.addCustomMessageHandler('ar_toast', function(d) { arToast(d.message, d.type); });
```

**How JS talks to R:**
```js
// JS sends a value
Shiny.setInputValue('my_module-my_input', value, {priority: 'event'});
```
```r
# R reads it
observeEvent(input$my_input, { ... })
```

### Quality Checklist (before every CSS/JS change)

- [ ] Is this class actually used in an R file? (`grep` it)
- [ ] Does this duplicate an existing rule? (search the CSS file)
- [ ] Am I using design tokens, not hardcoded values?
- [ ] Is the rule inside its component's nested block?
- [ ] Did I test in DevTools first?
- [ ] Is the CSS still under 800 lines? JS under 300 lines?

### Learning Resources (bundled in this project)

- `.local/docs/CSS-BASICS.md` — CSS foundations, written for R programmers
- `.local/docs/CSS-NESTING-GUIDE.md` — modern nesting syntax with arbuilder examples
- `.local/design/DESIGN-SPEC.md` — full visual design specification (colors, spacing, components)

## Generated R Code Standards

The R code produced by `fct_codegen.R` must be:
- **Beginner-friendly** — a pharma programmer who knows tidyverse should understand every line
- **Pure tidyverse** — dplyr, tidyr, tibble pipes (`|>`). No base R loops where dplyr works
- **Self-contained** — helper functions (fmt_npct, compute_cont) defined inline
- **Well-commented** — section headers (`# --- Data ---`, `# --- ARD ---`, `# --- Formatting ---`)
- **Reproducible** — `readRDS("data/adsl.rds")` + population filter + arframe pipeline = run anywhere
- No Shiny dependencies, no global variables, no side effects

## File Map (35 R files)

```
R/
  # Core
  app_ui.R              # UI shell — activity bar + sidebar + resize handle + canvas
  app_server.R          # Server — store + module wiring + auto-preview + export

  # Utilities
  utils_helpers.R       # %||%, coalesce_list, safe_label, normalize_fmt
  utils_formats.R       # fmt_npct, fmt_mean_sd, fmt_q1_q3, etc.
  utils_ui.R            # ar_theme, ui_empty_state, ar_build_reactable

  # Demographics pipeline
  fct_adam.R            # detect_var_type, detect_trt_vars, detect_pop_flags
  fct_ard_demog.R       # Demographics ARD builder (continuous + categorical)
  fct_ard_dispatch.R    # Template → ARD router (demog only)
  fct_render.R          # arframe spec builder + RTF export + HTML preview
  fct_preview.R         # HTML preview builder
  fct_codegen.R         # R script generator
  fct_codegen_dispatch.R # Template → codegen router (demog only)
  spec_demog.R          # Demographics defaults

  # Support
  fct_template_registry.R # Template metadata (demog only)
  fct_suggest_vars.R    # Variable suggestions (demog only)
  fct_validate.R        # Pipeline validation checks
  fct_format_designs.R  # Preset definitions + collect_format_drafts
  fct_profile.R         # Column profiler for data explorer

  # Modules (17)
  mod_data.R            # Data upload, load, explore, filter
  mod_data_viewer.R     # VS Code-style data grid (reactable)
  mod_template.R        # Template gallery (canvas)
  mod_grouping.R        # Treatment var + variable list (sidebar)
  mod_treatment.R       # Treatment levels + total toggle
  mod_analysis_vars.R   # Per-variable stat config cards (signature feature)
  mod_titles.R          # Per-title align/bold + footnotes
  mod_columns.R         # Per-column disclosure with eye toggle
  mod_header_spans.R    # Header bold/align + column spans
  mod_page.R            # Page layout (orientation, font, margins)
  mod_rules.R           # Horizontal/vertical rules
  mod_rows.R            # Row structure (group_by, page_by, indent)
  mod_page_chrome.R     # Page header/footer
  mod_validation.R      # Pipeline validation checklist
  mod_code.R            # R code viewer

  # Infrastructure
  launch.R              # Package launcher
  _disable_autoload.R   # Prevent shiny auto-load

inst/app/www/
  app.css               # Design system + layout
  app.js                # Keyboard shortcuts, resize, toasts, sortable handlers
  Sortable.min.js       # Drag reorder library
```

## `.local/` — Non-Package Files

All non-R-package files live in `.local/` (gitignored). Any temp files, scratch work, design docs, or generated output should go here too.

```
.local/
  archive/              # Full pre-rebuild snapshot of all 69 files
  backup_templates/R/   # 34 files for non-demographics templates (AE, lab, TTE, figures, listings)
  design/               # DESIGN.md, DESIGN-SPEC.md, LAYOUT-ALTERNATIVES.md
  plans/                # PLAN.md, ARFRAME-PLAN.txt, PLAN-SAVE-CARDS.md
  docs/                 # CSS-BASICS.md, CSS-NESTING-GUIDE.md, DATA-WRANGLER-UX-REFERENCE.md
    notes/              # Book notes, research notes, viewer spec
    references/         # CDISC, CSR formats, GSK macros, standard TFL specs
  screenshots/          # Dev screenshots
  output/               # Generated RTF/PDF/HTML output files
```

When creating temp files (scratch scripts, test output, debug logs), put them in `.local/` — never in the package root.
