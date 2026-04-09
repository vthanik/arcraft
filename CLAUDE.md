# CLAUDE.md — loom

Local Shiny app for building submission-ready TFLs from ADaM data. Uses `arframe` as the rendering engine. No server needed — runs on a laptop.

## Quick Context

- **arframe** = the rendering engine (pure R, no UI) — already built at `../arframe/`
- **loom** = this project — Shiny app that takes ADaM → ARD wide → arframe → RTF/PDF
- **adam_pilot** = test datasets at `../adam_pilot/` — 11 synthetic ADaM datasets, 250 subjects

## Source of Truth

Session memory is a hint — not ground truth. Always verify against actual source.

| Question | Read this first |
|---|---|
| Phase 2 BDS/Response design | `.local/specs/2026-04-01-bds-response-templates-design.md` |
| Current implementation plan | `.claude/plans/cozy-prancing-hedgehog.md` |
| Visual design (colors, spacing, components) | `.local/design/DESIGN-SPEC.md` |
| CSS component rules | `inst/app/www/app.css` — authoritative, not memory |
| JS message handler names | `inst/app/www/app.js` section 7 — check before adding new handlers |
| Template registry | `R/fct_template_registry.R` |
| Sidebar patterns per template | `R/mod_analysis_vars.R` |
| Backup template implementations | `.local/backup_templates/R/` |
| ADaM variable reference | `.local/cdisc-reference.md` |
| CSS/JS rules detail | `.claude/skills/css-js.md` |

Never infer design decisions from context. Read the spec file first.

## Template Inventory (19 total)

### Phase 1 — LIVE

| # | Template | Category | ADaM | sidebar_pattern | Spec | ARD Engine |
|---|----------|----------|------|----------------|------|------------|
| 1 | Demographics | Study Info | ADSL | `variable_stat` | `spec_demog.R` | `fct_ard_demog_cards.R` |
| 2 | AE Overall Summary | Safety | ADAE | `flag_summary` | `spec_ae.R` | `fct_ard_ae.R` |
| 3 | AE by SOC/PT | Safety | ADAE | `hierarchical` | `spec_ae.R` | `fct_ard_ae.R` |

### Phase 2 — IN PROGRESS (BDS + Response)

Design spec: `.local/specs/2026-04-01-bds-response-templates-design.md`
Implementation plan: `.claude/plans/cozy-prancing-hedgehog.md`

| # | Template | Category | ADaM | sidebar_pattern | Spec | ARD Engine |
|---|----------|----------|------|----------------|------|------------|
| 4 | Vital Signs Summary | Safety | ADVS | `parameter_visit` | `spec_bds.R` | `fct_ard_bds.R` (shared) |
| 5 | Lab Summary | Laboratory | ADLB | `parameter_visit` | `spec_bds.R` | `fct_ard_bds.R` (shared) |
| 6 | ECG Summary | Safety | ADEG | `parameter_visit` | `spec_bds.R` | `fct_ard_bds.R` (shared) |
| 7 | Response Summary | Efficacy | ADRS | `response_summary` | `spec_response.R` | `fct_ard_response.R` |

**Architecture:** Vitals/Lab/ECG share ONE `fct_ard_bds()` engine. Each `spec_vitals()`/`spec_lab()`/`spec_ecg()` is a thin wrapper with domain-specific defaults.

**Before starting any Phase 2 template, read in order:**
1. `.local/specs/2026-04-01-bds-response-templates-design.md`
2. `.claude/plans/cozy-prancing-hedgehog.md`
3. An existing live template as reference (e.g. `spec_ae.R`)

**Phase 2 wiring checklist** — all must be done before marking LIVE:
- [ ] ARD engine (`fct_ard_bds.R` or `fct_ard_response.R`)
- [ ] Spec factory (`spec_bds.R` wrapper or `spec_response.R`)
- [ ] Template registry entry (`fct_template_registry.R`)
- [ ] Sidebar pattern wired in `mod_analysis_vars.R`
- [ ] ARD dispatch entry (`fct_ard_dispatch.R`)
- [ ] Codegen dispatch entry (`fct_codegen_dispatch.R`)
- [ ] Variable suggestion entry (`fct_suggest_vars.R`)
- [ ] Tests for ARD engine + spec factory
- [ ] Example in gallery site

### Backlog (not started)

| # | Template | Category | ADaM | sidebar_pattern |
|---|----------|----------|------|----------------|
| 8 | Disposition | Study Info | ADSL | `variable_stat` |
| 9 | Protocol Deviations | Study Info | ADSL | `variable_stat` |
| 10 | Analysis Populations | Study Info | ADSL | `variable_stat` |
| 11 | Enrollment | Study Info | ADSL | `variable_stat` |
| 12 | Medical History | Study Info | ADSL | `variable_stat` |
| 13 | Concomitant Meds | Study Info | ADCM | `variable_stat` |
| 14 | AE by Severity | Safety | ADAE | `hierarchical` |
| 15 | Lab Shift Table | Laboratory | ADLB | `parameter_visit` |
| 16 | Continuous Efficacy | Efficacy | ADEFF | `parameter_visit` |
| 17 | Time-to-Event / KM | Efficacy | ADTTE | `time_to_event` |
| 18 | AE Listing | Listings | ADAE | `flat_listing` |
| 19 | ConMed Listing | Listings | ADCM | `flat_listing` |

Backup specs: `.local/backup_templates/R/`

## Sidebar Patterns (6 distinct)

| Pattern | Used By | Key UI Element |
|---------|---------|---------------|
| `variable_stat` | Demog, Disposition, Populations, MedHist, ConMed | Per-variable cards with stat/level config |
| `flag_summary` | AE Overall | Flag variables with exclude/rename levels |
| `hierarchical` | AE SOC/PT, AE Severity | Drag-reorder hierarchy levels (L1/L2/L3) |
| `parameter_visit` | Vitals, Lab, ECG, Lab Shift, Continuous Efficacy | Parameter list + Visit list + shared stats + per-param decimals |
| `response_summary` | Response Summary | Endpoint dropdown + category list + format + comparison tests |
| `time_to_event` | TTE/KM | Parameter + timepoints + survival stats (future) |
| `flat_listing` | AE Listing, ConMed Listing | Column selection + sort order (future) |

## BDS Template Design Decisions (2026-04-01)

- **Domain-wise gallery cards, shared engines** — one `fct_ard_bds()` engine, three gallery cards
- **Parameter list with per-param decimals** — reorderable checkbox list, decimals auto-detected from data
- **Visit list** — auto-populated from AVISIT sorted by AVISITN. Baseline pinned first
- **CFB toggle** — Change from Baseline ON by default for BDS
- **Response template** — single PARAMCD dropdown, category list, format selector, optional comparison panel
- **`fct_suggest_vars` semantic change** — for BDS/response returns PARAMCDs not column names
- **Population flag default** — Safety → SAFFL, Efficacy → ITTFL

## Architecture Principles

- **NOT a dashboard** — elegant focused builder (Figma/Linear, not Grafana)
- **VS Code Activity Bar layout** — 5 icons (DATA, TMPL, ANLYS, FMT, OUT) + sidebar + canvas
- **25/75 ratio** — sidebar 25%, canvas 75%. Resizable. Collapsible (Ctrl+B)
- **Live auto-preview** — config changes trigger preview (800ms debounce)
- **Non-reactive format drafts** — modules return `get_draft()`, collected on Generate Preview
- **ARD-centric** — computation (ARD) separated from presentation (arframe spec)
- **Variables always pre-selected** — `spec_*()` defaults and `fct_suggest_vars()` must agree

## Never Do These

- **Never reference `tlframe`** — the package is `arframe`. Update any occurrence found.
- **Never add a new JS message handler** without checking section 7 of `app.js` first — duplicates silently overwrite
- **Never hardcode colors, fonts, or spacing** — use `var(--token)` from `:root`
- **Never write a new ARD engine for Vitals/Lab/ECG** — they share `fct_ard_bds()`, add a thin wrapper
- **Never use `library()` inside `R/`** — use `::` operator only
- **Never use `setwd()`** — use explicit paths
- **Never add a new sidebar pattern** without updating `mod_analysis_vars.R` and `fct_template_registry.R` in the same commit
- **Never generate `library()` in `fct_codegen.R`** — generated scripts use `pkg::function()`
- **Never add CSS outside a component's nested block**
- **Never use `stop()` / `warning()` / `message()`** — use `cli_abort()` only
- **Never commit `.local/`** — gitignored for a reason
- **Never read `../adam_pilot/` into context** — use synthetic summary datasets only
- **Never use inline `style =` in R** — use CSS classes

## Multi-Agent Guidance

| Task | Approach |
|---|---|
| Single new template (spec + ARD + module) | Sequential |
| All 3 BDS templates in parallel | Sub-agents — one per template, shared engine in main |
| CSS + JS for a new component | Sequential — CSS first, JS second |
| Audit entire `R/` layer | Sub-agent per module group |
| Tests for multiple new functions | Sub-agents — one per function group |

Sub-agents must be independent — never give one a task requiring another's output.

## Design Standards

- Must make teal/tern/NEST look like dust
- White canvas (`#ffffff`), gray sidebar (`#f7f8fa`), single accent (`#4a6fa5`)
- 3 text colors only: `--fg-1`, `--fg-2`, `--fg-muted`
- No shadows, no gradients, no animations except toast slide-in and chevron rotate
- Inter font, 11-12px body, 4px spacing grid
- Full spec: `.local/design/DESIGN-SPEC.md`

## Verify After Every Change (MUST FOLLOW)

1. `Rscript -e "devtools::load_all('.'); app <- shiny::shinyApp(app_ui(), app_server); cat('OK')"`
2. If UI changed: run app and manually test the affected flow
3. Confirm verification passed before marking done

## End-to-End Rule (MUST FOLLOW)

Every feature/fix must be wired through ALL 5 layers:

1. **UI** (`mod_*.R`) — input control
2. **Defaults** (`utils_helpers.R` → `normalize_fmt`) — default value
3. **IR** (`fct_spec_ir.R`) — intermediate representation
4. **Render** (`fct_render.R`) — wired to `arframe::fr_*()`
5. **Codegen** (`fct_codegen.R`) — generates argument in standalone R script

Grep the param name across all 5 files before marking done.

## Coding Conventions

- Shiny modules: `mod_*.R` with `*_ui(id)` and `*_server(id, ...)`
- All reactive outputs are tibbles or lists
- BEM naming in CSS: `.ar-block__element--modifier`
- No unused code — if it's not called, delete it
- CSS detail → see `.claude/skills/css-js.md`

## Generated R Code Standards

- **Beginner-friendly** — pure tidyverse, no base R loops
- **Self-contained** — helpers defined inline, no Shiny dependencies
- **Well-commented** — `# --- Data ---`, `# --- ARD ---`, `# --- Formatting ---`
- **Reproducible** — `readRDS("data/adsl.rds")` + population filter + arframe pipeline

## Commands

```bash
Rscript -e "shiny::runApp('.')"
```

## Dependencies

shiny, bslib, htmltools, reactable + tidyverse (dplyr, tidyr, tibble, readr, glue) + arframe.
No shinyjs — all JS via `app.js` + `sendCustomMessage`.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Ctrl+1-5 | Switch activity bar tabs |
| Ctrl+Enter | Generate preview |
| Ctrl+S | Export RTF |
| Ctrl+Shift+S | Download R script |
| Ctrl+B | Toggle sidebar collapse |
| Escape | Collapse all open cards |

## File Map

```
R/
  app_ui.R, app_server.R               # Core shell + server
  utils_helpers.R, utils_formats.R, utils_ui.R
  spec_demog.R, spec_ae.R              # Live template specs
  spec_bds.R, spec_response.R          # [PLANNED]
  fct_adam.R                           # ADaM auto-detection
  fct_ard_demog_cards.R, fct_ard_ae.R  # Live ARD engines
  fct_ard_bds.R, fct_ard_response.R    # [PLANNED]
  fct_ard_dispatch.R                   # Template → ARD router
  fct_render.R, fct_preview.R          # arframe spec builder + preview
  fct_codegen.R, fct_codegen_dispatch.R
  fct_template_registry.R, fct_suggest_vars.R
  fct_validate.R, fct_format_designs.R, fct_profile.R
  mod_data.R, mod_data_viewer.R, mod_template.R
  mod_grouping.R, mod_treatment.R, mod_analysis_vars.R
  mod_titles.R, mod_columns.R, mod_header_spans.R
  mod_page.R, mod_rules.R, mod_rows.R, mod_page_chrome.R
  mod_validation.R, mod_code.R
  launch.R, _disable_autoload.R

inst/app/www/
  app.css, app.js, Sortable.min.js
```

## `.local/` Structure

```
.local/
  archive/              # Pre-rebuild snapshot
  backup_templates/R/   # 34 files for backlog templates
  design/               # DESIGN-SPEC.md, LAYOUT-ALTERNATIVES.md
  specs/                # Phase design specs
  plans/                # Implementation plans
  docs/                 # CSS-BASICS.md, CSS-NESTING-GUIDE.md
  cdisc-reference.md    # ADaM variable reference (read on demand)
  screenshots/, output/
```

All temp files, scratch work, and generated output go in `.local/` — never in package root.
