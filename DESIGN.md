# arbuilder — VS Code Activity Bar UX Design Plan

**Local Shiny app for building submission-ready TFLs from ADaM data.**
Uses `arframe` (currently `tlframe`) as the rendering engine. No server needed — runs on a laptop.

Date: 2026-03-17

---

## 1. Design Philosophy

arbuilder is a **builder tool**, not a dashboard, not an explorer. Think Figma, not Grafana.

**Core principles:**
- The table preview IS the product — everything else serves it
- Progressive disclosure — show only what's needed at each step
- Sequential guidance for new users, free navigation for power users
- Zero default-Shiny look — Linear/Notion/Vercel-level polish
- Every interaction feels intentional — no clutter, no visual noise

**Design references:**
- VS Code: Activity bar pattern (5 icons + bottom gear)
- Figma: Always-visible canvas with contextual side panels
- Linear: Clean hierarchy, refined spacing, premium typography
- NN/g research: Progressive unlocking stepper (not strict wizard, not pure random-access)

**Theme:**
- Light grey warmth: `#f8f8f7`, `#e5e4e2`, `#f4f4f3`
- Accent: `#4a6fa5` (muted blue)
- Typography: Inter (UI) + JetBrains Mono (data/code)
- Spacing: 4px grid, 6px radius, 150ms transitions

---

## 2. The Pipeline

```
ADaM data → Population filter → Template → Analysis config → ARD wide → arframe format → RTF/PDF + R script
  (raw)      SAFFL=="Y"         demog       per-var stats    (dplyr)    fr_table()        (output)
  adsl.csv                      ae_soc      grouping                    fr_titles()
  adae.csv                      tte         decimals                    fr_render()
```

The 5-step workflow maps directly to 5 activity bar icons:

| Step | Icon | Action | What User Does |
|------|------|--------|----------------|
| 1 | Data | Load | Upload/select datasets, explore, set population |
| 2 | Template | Choose | Pick table or figure type (demographics, AE, TTE...) |
| 3 | Analysis | Configure | Treatment var, analysis vars, per-variable stats |
| 4 | Format | Style | Titles, columns, spans, page, rules — full arframe API |
| 5 | Output | Export | Validation, recipes, export RTF/PDF/R script |

---

## 3. Complete Layout

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│  ● arbuilder     [▶ Generate Preview]                    [⬇ RTF] [⬇ .R] [⛶]   │
│                                                                       40px      │
├────┬──────────────────────┬─────────────────────────────────────────────────────┤
│    │                      │  📊 Data  │  📋 ARD  │  📄 Table  │  </> R Code   │
│ 📊 │                      ├─────────────────────────────────────────────────────┤
│    │  SIDEBAR PANEL       │                                                    │
│ 📋 │  (scrollable,        │                                                    │
│    │   ALL CAPS section   │                                                    │
│ 📈 │   headers,           │              C A N V A S                           │
│    │   accordion          │         (active tab content)                       │
│ 🎨 │   sections for       │                                                    │
│    │   the active step)   │   Data:   VS Code Data Wrangler grid              │
│    │                      │   ARD:    computed analysis results (reactable)    │
│    │                      │   Table:  white-page formatted preview             │
│    │                      │   Code:   shinyAce R script editor                │
│────│                      │                                                    │
│ ⬇  │                      │                                                    │
├────┴──────────────────────┴─────────────────────────────────────────────────────┘
48px       340px                               flex: 1
```

**Dimensions:**
- Top bar: 40px height, full width, `#ffffff` bg
- Activity bar: 48px width, full height below top bar, `#f8f8f7` bg
- Sidebar: 340px when open, 0px collapsed (200ms ease transition), `#f8f8f7` bg
- Canvas: `flex: 1`, `#f4f4f3` bg
- Canvas tabs: 36px height, `#ffffff` bg

---

## 4. Top Bar

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ●  arbuilder     [▶ Generate Preview]               [⬇ RTF] [⬇ .R] [⛶]   │
└──────────────────────────────────────────────────────────────────────────────┘
   │                     │                                │       │      │
   │                     │                                │       │      └─ fullscreen toggle (fa-expand)
   │                     │                                │       └─ download .R script (dl_script)
   │                     │                                └─ download RTF (export_rtf)
   │                     └─ ar-btn-primary, accent blue (id: preview_btn)
   └─ 7px square dot (accent) + "arbuilder" 13px font-weight:700
```

| Element | ID | Type | Style |
|---------|-----|------|-------|
| Brand | — | Static text | 7px dot + bold text |
| Generate Preview | `preview_btn` | actionButton | `ar-btn-primary` filled blue |
| Export RTF | `export_rtf` | downloadButton | `ar-btn-outline` bordered |
| Download .R | `dl_script` | downloadButton | `ar-btn-ghost` text only |
| Fullscreen | `toggle_fullscreen` | HTML button | `ar-btn-ghost` icon only |

**Pipeline progress dots:** Between brand and Generate Preview button.
```
● arbuilder  ①──②──③──④──⑤   [▶ Generate Preview]   [⬇RTF] [⬇.R] [⛶]
             ✓   ✓   ●   ○   ○
```

**Context summary line:** Below the topbar (or inside it as a second row, 24px).
```
ADSL │ Demographics │ N=248 (SAFFL=Y) │ 5 vars │ Landscape
```
Updates reactively. Shows "—" for unconfigured segments. 10px, muted grey (`#a3a09c`).

**Keyboard shortcut:** `Ctrl+Enter` or `Cmd+Enter` → clicks Generate Preview

**CSS:**
```css
.ar-topbar {
  height: 40px;
  background: var(--bg);              /* #ffffff */
  border-bottom: 1px solid var(--border);  /* #e5e4e2 */
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 12px;
}
```

---

## 5. Activity Bar — 5 Icons

```
┌────┐
│    │
│ 📊 │  fa-database      id: ab_data        "Data (Ctrl+1)"
│    │
│ 📋 │  fa-th-list        id: ab_template    "Template (Ctrl+2)"
│    │
│ 📈 │  fa-chart-bar      id: ab_analysis    "Analysis (Ctrl+3)"
│    │
│ 🎨 │  fa-paint-brush    id: ab_format      "Format (Ctrl+4)"
│    │
│    │  ── spacer (flex: 1) ──
│    │
│────│  ── visual separator ──
│ ⬇  │  fa-download       id: ab_output      "Output"
│    │
└────┘
```

### Icon States

| State | Icon Color | Background | Border |
|-------|-----------|------------|--------|
| Inactive | `#78716c` | transparent | none |
| Hover | `#1a1918` | `#f0efed` | none |
| Active | `#4a6fa5` | transparent | 2px left `#4a6fa5` |
| Disabled | `#a3a09c` | transparent | none, `opacity: 0.4` |

### Behavior

| Action | Result |
|--------|--------|
| Click inactive icon | Open that panel, close previous |
| Click active icon | Collapse sidebar to 0px (200ms) |
| Click disabled icon | Nothing (tooltip says prerequisite) |
| `Ctrl+1` / `Ctrl+2` / `Ctrl+3` / `Ctrl+4` | Jump to step panel |
| `Ctrl+B` | Toggle sidebar open/closed |

### Progressive Unlocking

| Step | Unlocked When | Disabled Tooltip |
|------|--------------|-----------------|
| 1. Data | Always | — |
| 2. Template | At least 1 dataset loaded | "Load a dataset first" |
| 3. Analysis | Template selected | "Choose a template first" |
| 4. Format | At least 1 analysis var selected | "Configure analysis first" |
| 5. Output | Always (but validation warns) | — |

**Important:** Once unlocked, a step stays unlocked forever in that session. Users can freely jump between any unlocked step. This is NOT a strict wizard — it's progressive unlocking with free navigation.

### CSS

```css
.ar-activity-bar {
  width: 48px;
  background: var(--bg-sidebar);      /* #f8f8f7 */
  border-right: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  align-items: center;
  flex-shrink: 0;
  padding: 8px 0;
}

.ar-activity-bar__top {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  flex: 0;
}

.ar-activity-bar__bottom {
  margin-top: auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  padding-bottom: 8px;
}

.ar-ab-btn {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: none;
  border: none;
  border-left: 2px solid transparent;
  border-radius: 0;
  cursor: pointer;
  color: var(--fg-3);                  /* #78716c */
  font-size: 16px;
  transition: all 150ms ease;
}

.ar-ab-btn:hover {
  color: var(--fg);                    /* #1a1918 */
  background: var(--bg-hover);         /* #f0efed */
}

.ar-ab-btn.active {
  color: var(--accent);                /* #4a6fa5 */
  border-left-color: var(--accent);
}

.ar-ab-btn.disabled {
  color: var(--fg-muted);              /* #a3a09c */
  opacity: 0.4;
  cursor: not-allowed;
}

.ar-ab-sep {
  width: 24px;
  height: 1px;
  background: var(--border);
  margin: 4px 0;
}
```

---

## 6. Sidebar — Panel Sections

The sidebar shows one panel at a time, determined by the active activity bar icon. Each panel contains collapsible sections with ALL CAPS headers.

### Section Header Pattern

```
 ▾ SECTION NAME          ← open (arrow rotated 90°)
────────────────────
  (content)

 ▸ SECTION NAME          ← collapsed (arrow pointing right)
────────────────────
  (hidden)
```

| Property | Value |
|----------|-------|
| Font size | 10px |
| Font weight | 600 |
| Text transform | uppercase |
| Letter spacing | 0.06em |
| Open color | `#4a6fa5` (accent) |
| Closed color | `#78716c` |
| Arrow | `▶` rotated 90° when open |
| Padding | 8px 14px |
| Border | bottom 1px solid `#e5e4e2` |
| Transition | 200ms ease |

### CSS

```css
.ar-sidebar {
  width: 340px;
  flex-shrink: 0;
  background: var(--bg-sidebar);
  border-right: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  transition: width 200ms ease, opacity 200ms ease;
}

.ar-sidebar.collapsed {
  width: 0;
  opacity: 0;
  overflow: hidden;
  border: none;
}

.ar-sidebar__scroll {
  flex: 1;
  overflow-y: auto;
  padding: 0;
}

.ar-sidebar-panel {
  display: none;
}

.ar-sidebar-panel.active {
  display: block;
}

.ar-ps {
  border-bottom: 1px solid var(--border);
}

.ar-ps__header {
  display: flex;
  align-items: center;
  gap: 6px;
  width: 100%;
  padding: 8px 14px;
  background: none;
  border: none;
  cursor: pointer;
  font-family: var(--font);
  font-size: 10px;
  font-weight: 600;
  color: var(--fg-3);
  text-transform: uppercase;
  letter-spacing: 0.06em;
  transition: all 150ms ease;
  text-align: left;
}

.ar-ps__header:hover {
  background: var(--bg-hover);
  color: var(--fg);
}

.ar-ps__arrow {
  font-size: 7px;
  width: 10px;
  transition: transform 200ms ease;
  display: inline-block;
  color: var(--fg-muted);
}

.ar-ps--open > .ar-ps__header .ar-ps__arrow {
  transform: rotate(90deg);
}

.ar-ps--open > .ar-ps__header {
  color: var(--accent);
}

.ar-ps__body {
  display: none;
  padding: 4px 14px 14px;
}

.ar-ps--open > .ar-ps__body {
  display: block;
}
```

---

## 7. Panel 1: DATA

**Activity bar icon:** `fa-database` (always enabled)
**Purpose:** Explore any loaded dataset (top) + configure pipeline data source with stackable filters (bottom)

### Sidebar: Explorer on top, Analysis Source on bottom

```
┌──────────────────────┐
│ ▾ EXPLORER           │  ← TOP: browse any dataset freely
│──────────────────────│
│                      │
│ Dataset: [ADSL    ▾] │  selectInput — pick any loaded dataset
│                      │
│ 250 rows × 40 cols   │  dimensions pill
│                      │
│ Column profiles:     │  clickable profile cards (mini charts)
│ ┌──────┐┌──────┐    │
│ │AGE   ││SEX   │    │
│ │NUM   ││CHR   │    │
│ │18-89 ││M/F   │    │
│ │▁▃▅▇▅▃││██▓░  │    │  mini histogram / bar chart
│ └──────┘└──────┘    │
│ ┌──────┐┌──────┐    │
│ │RACE  ││SAFFL │    │
│ │CHR   ││CHR   │    │
│ └──────┘└──────┘    │
│                      │
│ (click card →        │
│  detail panel in     │
│  canvas below grid)  │
│                      │
│ Explorer filters:    │  local filters (exploratory only)
│ ┌──────────────────┐ │
│ │ AGE  >  65   [✕] │ │
│ └──────────────────┘ │
│ [+ Add Filter]       │
│ 86 of 250 rows       │  filtered count
│                      │
│ ▾ SOURCE             │  ← data loading
│──────────────────────│
│                      │
│ Datasets:            │  selectizeInput (multi-select)
│ ┌──────────────────┐ │  from ../adam_pilot/data/*.rds
│ │ adsl, adae, adtte│ │
│ └──────────────────┘ │
│ [Load]  [📎 Upload]  │  actionButton + styled fileInput
│                      │
│ ┌─────┐┌──────┐     │  dataset pills
│ │ADSL ││ADAE  │     │
│ │250× ││1305× │     │
│ │ 40  ││  31  │     │
│ └─────┘└──────┘     │
│                      │
│ ▾ ANALYSIS SOURCE    │  ← BOTTOM: pipeline data config
│──────────────────────│
│                      │
│ Primary dataset:     │  selectInput — which dataset feeds pipeline
│ [ADSL           ▾]   │
│                      │
│ Pipeline filters:    │  STACKABLE — multiple AND conditions
│ ┌──────────────────┐ │  feeds into the ARD builder
│ │ SAFFL    = Y [✕] │ │  filter 1 (population flag)
│ ├──────────────────┤ │
│ │ NPRLINE  = 2 [✕] │ │  filter 2 (2nd line therapy)
│ └──────────────────┘ │
│ [+ Add Filter]       │
│                      │
│ Each filter row:     │
│ [Column ▾] [Op ▾]   │  op: =, !=, >, <, >=, <=, in, not in
│ [Value  ▾]     [✕]  │  value: auto-detect from column
│                      │
│ Resulting N: 124     │  live count after ALL filters applied
│ subj (ADSL)          │
│                      │
└──────────────────────┘
```

### Filter Widget Pattern (teal-style, used everywhere)

Same filter widget for both Explorer and Pipeline filters. Inspired by teal's `teal_slices()` but simpler — no operators, just value selection with counts.

**Adding a filter:** Click `[+ Add Filter]` → dropdown of all columns → select one → filter card appears.

**Categorical columns:** Checkboxes for every unique value, all checked by default.
```
┌──────────────────┐
│ SAFFL        [✕] │  column name + remove button
│ ─────────────── │
│ ☑ Y     (248)   │  checked = included, count in parens
│ ☐ N     (2)     │  unchecked = excluded
│ ☐ <NA>  (0)     │  missing always shown as <NA>
│                  │
│ [All] [Clear]   │  toggle shortcuts
│ 248 of 250      │  included / total
└──────────────────┘
```

**Numeric columns:** Range slider with min/max inputs.
```
┌──────────────────┐
│ AGE          [✕] │
│ ─────────────── │
│ [51]════════[89] │  slider or two number inputs
│                  │
│ 186 of 248      │
└──────────────────┘
```

**Date columns:** Date range picker (two date inputs).

**Rules:**
- All values checked by default (selecting a filter doesn't exclude anything until you uncheck)
- `<NA>` is always a valid selectable option (missing data is real data)
- Counts update live as other filters change (cascading)
- Each card is **collapsible** — collapsed shows: `SAFFL: Y (248)` or `AGE: 51–89 (186)`
- Cards stack vertically, compact
- `[✕]` removes the filter entirely
- Final N count at bottom: after ALL filters applied

### Filter Examples by Table Type

| Table | Dataset | Filters |
|-------|---------|---------|
| Demographics | ADSL | `SAFFL`: ☑Y |
| Demographics 2nd line | ADSL | `SAFFL`: ☑Y + `NPRLINE`: ☑2 |
| AE Summary | ADAE | `TRTEMFL`: ☑Y + `SAFFL`: ☑Y |
| Disposition | ADSL | `ITTFL`: ☑Y |
| Discontinuation | ADSL | `EOSSTT`: ☑DISCONTINUED |
| Phase 2 subset | ADSL | `SAFFL`: ☑Y + `PHASE`: ☑Phase 2 |
| Efficacy | ADEFF | `EFFFL`: ☑Y + `ANL01FL`: ☑Y |

### Canvas When Data Is Active

The canvas shows **2 tabs** — the data grid and the R code for data loading/filtering.

```
┌──────────────────────────────────────────────────────────────────┐
│  📊 Data Grid  │  </> R Code                                    │
├──────────────────────────────────────────────────────────────────┤
│  [ADSL ▾]  🔍 Go to column...                    250 × 40      │
│─────────────────────────────────────────────────────────────────│
│  # │ USUBJID  │ TRT01A       │ AGE │ SEX │ RACE       │ SAFFL  │
│  1 │ SUBJ-001 │ Placebo      │  76 │ F   │ WHITE      │ Y      │
│  2 │ SUBJ-002 │ Xan Low Dose │  69 │ M   │ BLACK      │ Y      │
│  3 │ SUBJ-003 │ Xan High Dose│  81 │ F   │ WHITE      │ Y      │
│  4 │ SUBJ-004 │ Placebo      │  74 │ M   │ ASIAN      │ Y      │
│  . │ ...                                                        │
│  . │ (scrolls vertically, fixed header, row numbers)            │
│ 250│                                                             │
│─────────────────────────────────────────────────────────────────│
│ Column detail (appears when sidebar profile card clicked):      │
│ AGE │ NUM │ "Age (yr)" │ Range: 18-89 │ Mean: 75.1 │ ...      │
└──────────────────────────────────────────────────────────────────┘
```

**Grid rules:**
- **Row numbers** always shown (first column, fixed 40px, grey background)
- **Column widths** auto-sized: `minWidth = max(nchar(col_name) * 8, 60)`, capped at 300px
- If column values are shorter than column name, **column name width wins**
- **Fixed header row** (sticky top, never scrolls off)
- **No profile/filter/toolbar above the grid** — all controls live in the sidebar now
- Only: dataset selector dropdown + "Go to column" search + dimensions badge at top
- Paginated: 25 / 50 / 100 / 250 rows

**R Code tab shows data loading + pipeline filtering:**
```r
library(readr)

# --- Load ADaM data ---
adsl <- read_rds("../adam_pilot/data/adsl.rds")
adae <- read_rds("../adam_pilot/data/adae.rds")

# --- Pipeline filter (Analysis Source) ---
adsl_filtered <- adsl |>
  filter(SAFFL == "Y", NPRLINE == 2)
# N = 124 subjects
```

**Module:** `mod_data_ui("data")` / `mod_data_server("data")`
**Server returns:** `list(datasets, filtered, active_ds)`
- `datasets` = all loaded datasets (raw)
- `filtered` = primary dataset after pipeline filters applied (feeds ARD builder)
- `active_ds` = name of primary pipeline dataset

---

## 8. Panel 2: TEMPLATE

**Activity bar icon:** `fa-th-list` (unlocks when data loaded)
**Purpose:** Choose what kind of table or figure to build

```
┌──────────────────────┐
│ ▾ TABLE TEMPLATES    │
│──────────────────────│
│                      │
│ ┌──────────────────┐ │
│ │ 📊 Demographics  │ │  ACTIVE — blue border + bg
│ │    ADSL          │ │  "Age, Sex, Race, BMI..."
│ │    6 standard    │ │
│ ├──────────────────┤ │
│ │ 📋 Disposition   │ │  Phase 2 pill
│ │    ADSL          │ │
│ ├──────────────────┤ │
│ │ ⚠ AE Summary     │ │  Phase 2 pill
│ │    ADAE + ADSL   │ │
│ ├──────────────────┤ │
│ │ 💊 Exposure      │ │  Phase 2 pill
│ │    ADSL / ADEX   │ │
│ ├──────────────────┤ │
│ │ 🫀 Vital Signs   │ │  Phase 3 pill
│ │    ADVS (BDS)    │ │
│ ├──────────────────┤ │
│ │ 🧪 Labs          │ │  Phase 3 pill
│ │    ADLB (BDS)    │ │
│ ├──────────────────┤ │
│ │ 🔄 Shift Table   │ │  Phase 3 pill
│ │    ADLB/ADEG     │ │
│ ├──────────────────┤ │
│ │ ⏱ Time-to-Event  │ │  Phase 3 pill
│ │    ADTTE         │ │
│ ├──────────────────┤ │
│ │ 📈 Efficacy      │ │  Phase 3 pill
│ │    ADEFF / ADRS  │ │
│ ├──────────────────┤ │
│ │ 💓 ECG / Cardiac │ │  Phase 4 pill
│ │    ADEG (BDS)    │ │
│ ├──────────────────┤ │
│ │ 💉 PK Summary    │ │  Phase 4 pill
│ │    ADPC / ADPPK  │ │
│ ├──────────────────┤ │
│ │ 💊 Con. Meds     │ │  Phase 3 pill
│ │    ADCM + ADSL   │ │
│ ├──────────────────┤ │
│ │ ⚙ Custom Table   │ │  Phase 4 pill
│ │    Any dataset   │ │
│ └──────────────────┘ │
│                      │
│ ▸ FIGURE TEMPLATES   │  (Phase 5)
│──────────────────────│
│  KM Plot             │
│  Forest Plot         │
│  Bar Chart           │
│  Waterfall           │
│  Spider Plot         │
│                      │
│ ▸ TEMPLATE INFO      │
│──────────────────────│
│  Selected: Demog.    │
│  Covers: 14.1.1-6    │  CSR table numbers
│  ADaM: ADSL          │
│  Stats: N, Mean(SD), │
│   Median, Q1/Q3,     │
│   Min/Max, n(%)      │
│  Default titles:     │
│   "Table 14.1.5"     │
│   "Summary of..."    │
│                      │
└──────────────────────┘
```

**Template card design:**

```
┌──────────────────────────────────┐
│  📊  Demographics       [ADSL]  │  icon + name + ADaM badge
│       Age, Sex, Race, BMI...    │  description (10px, grey)
│       6 standard outputs        │  coverage count
│                        Phase 1  │  phase pill (or nothing if active)
└──────────────────────────────────┘

States:
  Available:  white bg, grey border, clickable
  Active:     accent-muted bg, accent border
  Disabled:   0.45 opacity, not-allowed cursor, phase pill
  Unavailable: hidden (required dataset not loaded)
```

**Auto-configuration:** When a template is selected, it sets defaults for:
- Which ADaM dataset to use
- Default analysis variables (detected from data)
- Default statistics per variable type
- Default title/footnote templates
- Default column structure

These defaults populate Panel 3 (Analysis) and Panel 4 (Format), which the user can then customize.

**Module:** `mod_analysis_ui("analysis")` / `mod_analysis_server("analysis", data_out$datasets)`
**Server returns:** `reactive(list(type = "demog", adam_source = "adsl", ...))`

### Template → ARD Builder Mapping

| Template | ARD Builder | ADaM Source | # Standard TFLs |
|----------|-------------|-------------|-----------------|
| Demographics | `fct_ard_demog` | ADSL | 6 |
| Disposition | `fct_ard_disp` | ADSL | 1 |
| AE Summary | `fct_ard_ae` | ADAE+ADSL | 35 |
| Exposure | `fct_ard_exposure` | ADSL/ADEX | 8 |
| Vital Signs | `fct_ard_vitals` | ADVS | 3 |
| Labs | `fct_ard_labs` | ADLB | 6 |
| Shift Table | `fct_ard_shift` | ADLB/ADEG/ADQS | 10 |
| Time-to-Event | `fct_ard_tte` | ADTTE | 6 |
| Efficacy (cont) | `fct_ard_efficacy_cont` | ADEFF/ADQS | 3 |
| Efficacy (cat) | `fct_ard_efficacy_cat` | ADRS | 6 |
| ECG / Cardiac | `fct_ard_ecg` | ADEG | 1 |
| PK Summary | `fct_ard_pk` | ADPC/ADPPK | ~0* |
| Con. Meds | `fct_ard_cm` | ADCM+ADSL | 3 |
| Custom Table | `fct_ard_custom` | any | 1 |
| **Total** | **15 builders** | **8 ADaM classes** | **91 TFLs** |

---

## 9. Panel 3: ANALYSIS

**Activity bar icon:** `fa-chart-bar` (unlocks when template selected)
**Purpose:** Configure treatment variable, analysis variables, and per-variable statistics

```
┌──────────────────────┐
│ ▾ GROUPING           │
│──────────────────────│
│                      │
│ Treatment variable:  │  selectInput, auto-detected
│ [TRT01A          ▾]  │  (TRT01A, TRT01P, TRTA, TRTP)
│                      │
│ ☑ Include Total      │  checkboxInput
│                      │
│ Treatment levels:    │  auto-detected from data
│  Placebo      (n=86) │  read-only display
│  Xan Low Dose (n=84) │
│  Xan High Dose(n=84) │
│                      │
│ ▾ ANALYSIS VARIABLES │
│──────────────────────│
│                      │
│ ☑ AGE    NUM         │  checkbox + variable + type badge
│ ☑ SEX    CHR         │  auto-detected from data
│ ☑ RACE   CHR         │  label shown on hover
│ ☐ ETHNIC CHR         │
│ ☐ BMIBL  NUM         │
│ ☐ HEIGHTBL NUM       │
│ ☐ WEIGHTBL NUM       │
│                      │
│ ▾ VARIABLE CONFIG    │  ← THE KEY INNOVATION
│──────────────────────│
│                      │
│ One card per selected │
│ analysis variable:   │
│                      │
│ ┌─ AGE ─────────────┐│  (see Section 9A below)
│ │ ...                ││
│ └────────────────────┘│
│                      │
│ ┌─ SEX ─────────────┐│
│ │ ...                ││
│ └────────────────────┘│
│                      │
│ ┌─ RACE ────────────┐│
│ │ ...                ││
│ └────────────────────┘│
│                      │
└──────────────────────┘
```

**Module:** `mod_grouping_ui("grouping")` + `mod_stats_ui("stats")`
**Server returns:**
- `mod_grouping_server` → `reactive(list(trt_var, trt_levels, include_total, analysis_vars))`
- `mod_stats_server` → `reactive(list(vars = list(...per-variable config...)))`

### 9A. Per-Variable Config Cards

Each selected analysis variable gets a collapsible card. Cards are **draggable** to reorder (drag handle `[≡]`). The card order = table output order.

#### Continuous Variable Card (e.g., AGE)

```
┌─[≡]── AGE ──────────────────────────────────────────────────┐
│  NUM   "Age (yr)"                     5 stats, 1 dec   [▾] │  ← collapsed summary
├─────────────────────────────────────────────────────────────┤
│  (expanded)                                                  │
│                                                              │
│  STATISTICS                  LABEL                           │
│  ☑ [≡] N                    [N               ]              │
│  ☑ [≡] Mean (SD)            [Mean (SD)       ]              │
│  ☑ [≡] Median               [Median          ]              │
│  ☑ [≡] Q1, Q3               [Q1, Q3          ]              │
│  ☑ [≡] Min, Max             [Min, Max        ]              │
│  ☐ [≡] Geo Mean (CV%)       [Geo Mean (CV%)  ]              │
│                                                              │
│  Stats are draggable [≡] to reorder within the card.        │
│  Order here = order in table output.                         │
│                                                              │
│  DECIMAL PLACES  [1 ▾]      ALIGNMENT  [decimal ▾]          │
│                                                              │
│                                          [Reset to default] │
└──────────────────────────────────────────────────────────────┘
```

| Element | Input Type | Default | Maps To |
|---------|-----------|---------|---------|
| Stats checkboxes | checkboxGroupInput | N, Mean(SD), Median, Q1/Q3, Min/Max | Which stats to compute |
| Stat labels | textInput per stat | Standard names | Row labels in output |
| Stat order | Drag reorder | N → Mean(SD) → Median → Q1/Q3 → Min/Max | Row order in output |
| Decimal places | numericInput (0-6) | 1 | `fmt_mean_sd(mean, sd, dec)` etc. |
| Alignment | selectInput | decimal | Column alignment for this var's rows |
| Reset | actionButton | — | Restore template defaults |

#### Categorical Variable Card (e.g., SEX)

```
┌─[≡]── SEX ──────────────────────────────────────────────────┐
│  CHR   "Sex"                           n (%), 1 dec    [▾] │  ← collapsed summary
├─────────────────────────────────────────────────────────────┤
│  (expanded)                                                  │
│                                                              │
│  FORMAT                                                      │
│  ● n (%)           →  fmt_npct(n, N, style, dec)            │
│  ○ n only          →  fmt_count(n)                          │
│  ○ n/N (%)         →  fmt_nn_pct(n, N, style, dec)          │
│                                                              │
│  ZERO HANDLING                                               │
│  ● Style A   Show "0 ( 0.0)"                                │
│  ○ Style D   Show "0" (n only when zero)                    │
│                                                              │
│  DENOMINATOR                                                 │
│  ● Big N     Denominator = total N per treatment group       │
│  ○ Column N  Denominator = N in the column for that variable │
│  ○ Row N     Denominator = N in the row                      │
│                                                              │
│  % DECIMAL PLACES  [1 ▾]      ALIGNMENT  [center ▾]         │
│                                                              │
│  CATEGORY ORDER                                              │
│  [≡] Female                                                  │
│  [≡] Male                                                    │
│  (drag to reorder categories in table output)                │
│                                                              │
│                                          [Reset to default] │
└──────────────────────────────────────────────────────────────┘
```

| Element | Input Type | Default | Maps To |
|---------|-----------|---------|---------|
| Format | radioButtons | n (%) | Which format function |
| Zero style | radioButtons | Style A | `fmt_npct(style="A"/"D")` |
| Denominator | radioButtons | Big N | How % is computed |
| % Decimal | numericInput (0-4) | 1 | Decimal places in percentage |
| Category order | Drag reorder | Alphabetical | Row order of category values |
| Reset | actionButton | — | Restore template defaults |

#### Card States

```
COLLAPSED (default after first config):
┌─[≡]── AGE ── NUM  "Age (yr)" ──── 5 stats, 1 dec ──── [▾] ─┐
└──────────────────────────────────────────────────────────────┘

EXPANDED (click [▾] or the card):
┌─[≡]── AGE ── NUM  "Age (yr)" ──── 5 stats, 1 dec ──── [▴] ─┐
│  ...full config content...                                    │
└──────────────────────────────────────────────────────────────┘

CUSTOMIZED (modified from default — subtle indicator):
┌─[≡]── AGE ── NUM  "Age (yr)" ──── 3 stats, 2 dec  ● ── [▾] ─┐
└───────────────────────────────────────────────────────────────┘
                                                      ^ blue dot = customized
```

#### Card CSS

```css
.ar-var-card {
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  margin-bottom: 6px;
  overflow: hidden;
  transition: border-color 150ms ease;
}

.ar-var-card:hover {
  border-color: var(--fg-muted);
}

.ar-var-card.expanded {
  border-color: var(--accent);
}

.ar-var-card__header {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 10px;
  cursor: pointer;
  font-size: 12px;
  user-select: none;
}

.ar-var-card__drag {
  cursor: grab;
  color: var(--fg-muted);
  font-size: 10px;
  padding: 2px;
}

.ar-var-card__drag:active {
  cursor: grabbing;
}

.ar-var-card__name {
  font-weight: 600;
  font-family: var(--font-mono);
  color: var(--fg);
}

.ar-var-card__summary {
  flex: 1;
  text-align: right;
  font-size: 10px;
  color: var(--fg-3);
}

.ar-var-card__toggle {
  color: var(--fg-muted);
  font-size: 9px;
  padding: 2px 4px;
}

.ar-var-card__body {
  display: none;
  padding: 8px 10px 12px;
  border-top: 1px solid var(--border);
}

.ar-var-card.expanded .ar-var-card__body {
  display: block;
}

.ar-var-card__customized {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--accent);
}
```

---

## 10. Panel 4: FORMAT

**Activity bar icon:** `fa-paint-brush` (unlocks when analysis vars selected)
**Purpose:** Full arframe API coverage — titles, columns, spans, header, page, rules, etc.

```
┌──────────────────────┐
│ ▾ TITLES & FOOTNOTES │
│──────────────────────│
│                      │
│ Title lines:         │  dynamic add/remove (up to 5)
│ 1: [Table 14.1.5   ]│  textInput
│    align: [center ▾] │  selectInput per line
│    bold:  ☑          │  checkboxInput per line
│ 2: [Summary of Demo.]│
│    align: [center ▾] │
│    bold:  ☑          │
│ [+ Add title line]   │  actionLink
│                      │
│ Population:          │  textInput
│ [Safety Population ] │
│                      │
│ Overall align:       │  selectInput
│ [center          ▾]  │
│                      │
│ Footnotes:           │  dynamic add/remove
│ 1: [Percentages..]  │  textInput
│ 2: [SD = Standard.]  │
│ [+ Add footnote]     │  actionLink
│                      │
│ Placement:           │  selectInput
│ [every page      ▾]  │  every / last page
│                      │
│ Source:              │  textInput
│ [ADSL              ] │
│                      │
│ Inline markup hint:  │  small text
│ {b}bold{/b}          │
│ {i}italic{/i}        │
│ {super}text{/super}  │
│                      │
│ ▾ COLUMNS            │
│──────────────────────│
│                      │
│ Width strategy:      │  radioButtons
│ ● Auto              │  fr_cols(.width = "auto")
│ ○ Fit               │  fr_cols(.width = "fit")
│ ○ Equal             │  fr_cols(.width = "equal")
│ ○ Custom            │  fr_cols(.width = <numeric>)
│                      │
│ Stub column:         │
│ Width (in): [2.0  ]  │  numericInput
│ Label: [Parameter]   │  textInput (label for param col)
│ Align: [left     ▾]  │  selectInput
│                      │
│ Body alignment:      │  selectInput
│ [center          ▾]  │  fr_cols(.align = )
│                      │
│ N-counts in header:  │
│ Show: ☑              │  checkboxInput
│ Format: [(N={n})  ]  │  textInput
│ Source: [adsl     ▾]  │  selectInput
│ By var: [TRT01A  ▾]  │  selectInput
│                      │
│ Column visibility:   │
│ 👁 param             │  toggles per column
│ 👁 Placebo           │
│ 👁 Xan Low Dose     │
│ 👁 Xan High Dose    │
│ 👁 Total             │
│                      │
│ ▾ SPANNING HEADERS   │
│──────────────────────│
│                      │  fr_spans()
│ Span 1:             │
│ Label: [Treatment  ] │  textInput
│ Columns: ☑ col2 ☑ c3 │  checkboxGroupInput
│ Level: [1         ▾] │  selectInput (1, 2, 3)
│                      │
│ [+ Add Span]        │  actionLink
│                      │
│ ▾ HEADER STYLE       │
│──────────────────────│
│                      │  fr_header()
│ Bold: ☑              │
│ Align: [center    ▾] │
│ V-align: [bottom  ▾] │
│ Background: [      ] │  colourInput (colourpicker pkg)
│ Foreground: [      ] │  colourInput
│ Font size: [9     ]  │  numericInput
│                      │
│ ▾ PAGE LAYOUT        │
│──────────────────────│
│                      │  fr_page()
│ Orientation:         │  radioButtons
│ ● Landscape          │
│ ○ Portrait           │
│                      │
│ Paper:               │  selectInput
│ [letter          ▾]  │  letter / a4 / legal
│                      │
│ Font:                │  selectInput
│ [Courier New     ▾]  │
│                      │
│ Font size (pt):      │  numericInput
│ [9               ]   │  6–14
│                      │
│ Margins (inches):    │
│ ┌────────────────┐   │  4 numericInputs
│ │   Top: [1.0]   │   │
│ │ L        R     │   │
│ │[1.0]   [1.0]  │   │
│ │  Bottom:[1.0]  │   │
│ └────────────────┘   │
│                      │
│ Col gap (in):        │  numericInput
│ [0.1             ]   │  fr_page(col_gap = )
│                      │
│ Continuation:        │  textInput
│ [(cont'd)        ]   │  fr_page(continuation = )
│                      │
│ ▾ RULES              │
│──────────────────────│
│                      │  fr_hlines() + fr_vlines()
│ Hlines preset:       │  selectInput
│ [header          ▾]  │  header / booktabs / box / open / void
│                      │
│ Vlines preset:       │  selectInput
│ [none            ▾]  │  none / all / borders
│                      │
│ ☐ Full grid          │  checkboxInput (overrides both)
│                      │
│ ▾ PAGE HEADER/FOOTER │
│──────────────────────│
│                      │  fr_pagehead() / fr_pagefoot()
│ Page header:         │
│ Left:   [Sponsor   ] │  textInput
│ Center: [          ] │  textInput
│ Right:  [Page {page}]│  textInput
│                      │
│ Page footer:         │
│ Left:   [{program} ] │  textInput
│ Center: [          ] │  textInput
│ Right:  [{datetime}] │  textInput
│                      │
│ Available tokens:    │  hint text (small, grey)
│  {page} {pages}      │
│  {program} {datetime}│
│                      │
│ ▾ ROWS & PAGINATION  │
│──────────────────────│
│                      │  fr_rows()
│ Group by column:     │  selectInput (columns)
│ [              ▾]    │
│                      │
│ Indent by column:    │  selectInput (columns)
│ [              ▾]    │
│                      │
│ Blank row after:     │  selectInput (columns)
│ [              ▾]    │
│                      │
│ Page break by:       │  selectInput (columns)
│ [              ▾]    │
│                      │
│ ▾ SPACING            │
│──────────────────────│
│                      │
│ After titles (lines):│  numericInput
│ [2               ]   │
│                      │
│ Before footnotes:    │  numericInput
│ [2               ]   │
│                      │
│ After page header:   │  numericInput
│ [1               ]   │
│                      │
│ Before page footer:  │  numericInput
│ [1               ]   │
│                      │
│ ▾ CONDITIONAL STYLES │
│──────────────────────│
│                      │  fr_styles()
│ Rule 1:             │
│ ┌──────────────────┐ │
│ │ Apply to:        │ │  radioButtons
│ │ ● Row ○ Col ○Cell│ │
│ │ Where column:    │ │  selectInput
│ │ [param        ▾] │ │
│ │ Operator:        │ │  selectInput
│ │ [contains     ▾] │ │
│ │ Value:           │ │  textInput
│ │ [Age          ]  │ │
│ │ Bold: ☑          │ │
│ │ Indent: [0    ]  │ │
│ │ Bg: [         ]  │ │
│ │           [✕ Del]│ │  actionButton
│ └──────────────────┘ │
│                      │
│ [+ Add Style Rule]   │  actionLink
│                      │
└──────────────────────┘
```

**Modules (all nested inside existing module servers — app_server.R unchanged):**

| Section | Module | Nested In | Returns |
|---------|--------|-----------|---------|
| Titles & Footnotes | `mod_titles_server("titles")` | — (direct) | list(titles, population, align, footnotes, source) |
| Columns + N-counts + Visibility | `mod_columns_server("cols")` | Nests spans, header_style | list(stub_width, body_align, n_counts, visibility, spans, header) |
| Spanning Headers | `mod_spans_server("spans")` | Inside mod_columns | list(spans) |
| Header Style | `mod_header_style_server("hdr")` | Inside mod_columns | list(bold, align, valign, bg, fg, font_size) |
| Page Layout | `mod_page_server("page")` | Nests rules, pagehead, rows, spacing | list(orientation, paper, font, margins, ...) |
| Rules | `mod_rules_server("rules")` | Inside mod_page | list(hline_preset, vline_preset, full_grid) |
| Page Header/Footer | `mod_pagehead_server("pghead")` | Inside mod_page | list(pagehead, pagefoot) |
| Rows & Pagination | `mod_rows_config_server("rows")` | Inside mod_page | list(group_by, indent_by, blank_after, page_by) |
| Spacing | `mod_spacing_server("spacing")` | Inside mod_page | list(titles_after, footnotes_before, ...) |
| Conditional Styles | `mod_styles_server("styles")` | Inside mod_page | list(rules) |

### How app_server.R Stays UNTOUCHED

```r
# app_server.R (ZERO CHANGES)
titles_cfg <- mod_titles_server("titles")     # returns richer list
cols_cfg   <- mod_columns_server("cols")      # internally nests spans, header_style
page_cfg   <- mod_page_server("page")         # internally nests rules, pagehead, rows, spacing
fmt <- reactive({ list(titles = titles_cfg(), cols = cols_cfg(), page = page_cfg()) })
```

The trick: module servers return **richer objects** (more keys in the list), but the reactive wiring in `app_server.R` is identical. `fct_render.R` and `fct_codegen.R` read the expanded keys and call additional arframe verbs.

---

## 11. Panel 5: OUTPUT

**Activity bar icon:** `fa-download` (always enabled, pinned at bottom)
**Purpose:** Validation, recipe save/load, export configuration

```
┌──────────────────────┐
│ ▾ VALIDATION         │
│──────────────────────│
│                      │
│ [Run Validation]     │  actionButton
│                      │
│ Results:             │
│ ✓ Data loaded        │  green check
│ ✓ Template selected  │
│ ✓ Analysis configured│
│ ✓ Titles present     │
│ ✓ All columns mapped │
│ ⚠ No footnotes       │  yellow warning
│ ✗ No source line     │  red error
│                      │
│ Score: 5/7           │  completion indicator
│                      │
│ ▾ RECIPE             │
│──────────────────────│
│                      │
│ Saved recipes:       │  selectInput
│ [FDA Standard    ▾]  │
│ [Load Recipe]        │  actionButton
│                      │
│ [Save Current As..]  │  actionButton → text prompt
│ [Import YAML]        │  fileInput
│ [Export YAML]        │  downloadButton
│                      │
│ Recipe saves:        │  hint text
│  - Template type     │
│  - Statistics config │
│  - All format config │
│  - Does NOT save data│
│                      │
│ ▾ EXPORT             │
│──────────────────────│
│                      │
│ Format:              │
│ ● RTF               │  radioButtons
│ ○ PDF               │  (Phase 2)
│                      │
│ Filename:            │  textInput
│ [t_14_1_5         ]  │  auto-generated from title
│                      │
│ Output directory:    │  textInput
│ [./output          ] │
│                      │
│ [⬇ Export Table]     │  downloadButton (large, primary)
│ [⬇ Download .R]     │  downloadButton (outline)
│                      │
│ Generated files:     │  hint text
│  output/t_14_1_5.rtf │
│  output/t_14_1_5.R   │
│                      │
└──────────────────────┘
```

**Module:** `mod_validation_server("validation")`, `mod_recipe_server("recipe")`
**Note:** Export buttons also exist in the top bar for quick access. The Output panel provides more configuration (filename, directory, format choice).

---

## 12. Canvas (Right Panel) — Per-Step Views

**The canvas changes based on the active activity bar icon.** No fixed 4 tabs. Each step shows its own view + R Code tab. The R code grows progressively as the user moves through the pipeline.

```
Sidebar = where you DO things (controls, decisions)
Canvas  = where you SEE results (read-only, auto-updates)
```

### Canvas Tabs per Step

| Active Step | Tab 1 (View) | Tab 2 (Code) |
|------------|-------------|-------------|
| **Data** | Data Grid — clean table, row numbers, column search | R Code: data loading + pipeline filters |
| **Template** | Variable Preview — selected vars, types, defaults | R Code: data + variable selection |
| **Analysis** | ARD Results — computed analysis results table | R Code: data + filter + ARD creation |
| **Format** | Table Preview — formatted white-page preview | R Code: data + ARD + arframe pipeline |
| **Output** | Final Table — same as Format preview | R Code: complete script (data → render) |

### Progressive R Code Build

The R Code tab grows as the user progresses through the pipeline:

**Step 1 — Data:**
```r
library(readr)

# --- Load ADaM data ---
adsl <- read_rds("../adam_pilot/data/adsl.rds")
adae <- read_rds("../adam_pilot/data/adae.rds")

# --- Pipeline filter ---
adsl_filtered <- adsl |>
  filter(SAFFL == "Y")
# N = 248 subjects
```

**Step 2 — Template:** (adds variable selection)
```r
# ... (data code above) ...

# --- Demographics: selected variables ---
# AGE (continuous): N, Mean(SD), Median, Q1/Q3, Min/Max — 1 dec
# SEX (categorical): n (%) — 1 dec
# RACE (categorical): n (%) — 1 dec
# Group by: TRT01A (include Total)
```

**Step 3 — Analysis:** (adds ARD creation)
```r
# ... (data code above) ...

# --- Build ARD ---
big_n <- adsl_filtered |>
  count(TRT01A, name = "N") |>
  bind_rows(tibble(TRT01A = "Total", N = nrow(adsl_filtered)))

age_stats <- adsl_filtered |>
  bind_rows(adsl_filtered |> mutate(TRT01A = "Total")) |>
  group_by(TRT01A) |>
  summarise(
    N      = as.character(n()),
    `Mean (SD)` = sprintf("%.1f (%.2f)", mean(AGE, na.rm = TRUE), sd(AGE, na.rm = TRUE)),
    Median = sprintf("%.1f", median(AGE, na.rm = TRUE)),
    ...
  )
# ... (one block per variable) ...
tbl_demog <- bind_rows(age_stats, sex_stats, race_stats)
```

**Step 4 — Format:** (adds arframe pipeline)
```r
# ... (data + ARD code above) ...

# --- Format & render ---
tbl_demog |>
  fr_table() |>
  fr_titles("Table 14.1.5", "Summary of Demographic...") |>
  fr_footnotes("Percentages based on N in each group.") |>
  fr_cols(param = fr_col(label = "Parameter", width = 2, align = "left"), .align = "center") |>
  fr_header(bold = TRUE) |>
  fr_hlines("header") |>
  fr_page(orientation = "landscape") |>
  fr_render("t_14_1_5.rtf")
```

**Step 5 — Output:** Complete script with all libraries at top.

### Data Grid (when Data step is active)

```
┌──────────────────────────────────────────────────────────────────┐
│  📊 Data Grid  │  </> R Code                                    │
├──────────────────────────────────────────────────────────────────┤
│  [ADSL ▾]  🔍 Go to column...                    250 × 40      │
│─────────────────────────────────────────────────────────────────│
│  # │ USUBJID  │ TRT01A        │ AGE │ SEX │ RACE        │ ...  │
│  1 │ SUBJ-001 │ Placebo       │  76 │ F   │ WHITE       │      │
│  2 │ SUBJ-002 │ Xan Low Dose  │  69 │ M   │ BLACK       │      │
│  3 │ SUBJ-003 │ Xan High Dose │  81 │ F   │ WHITE       │      │
│  . │ ...                                                        │
│ 250│ SUBJ-250 │ Xan Low Dose  │  72 │ F   │ ASIAN       │      │
└──────────────────────────────────────────────────────────────────┘

Top bar: [Dataset ▾] + [Go to column search] + [dimensions badge]
Grid:    Row numbers | Data columns (auto-width, sticky header)
Bottom:  Column detail panel (appears when sidebar profile card clicked)
```

**Grid rules:**
- Row numbers always shown (first column, fixed 40px, grey)
- Column widths: `minWidth = max(nchar(col_name) * 8, 60)`, capped at 300px
- Column name width always wins over short values
- Fixed header (sticky top)
- No profile/filter/toolbar cluttering the grid — all controls in sidebar
- Paginated: 25 / 50 / 100 / 250

### ARD Results (when Analysis step is active)

```
┌──────────────────────────────────────────────────────────────────┐
│  📈 ARD Results  │  </> R Code                                  │
├──────────────────────────────────────────────────────────────────┤
│  12 rows × 5 cols                                                │
│─────────────────────────────────────────────────────────────────│
│ param       │ Placebo   │ Xan Low   │ Xan High  │ Total        │
│ Age (yr)    │           │           │           │              │
│   N         │ 86        │ 84        │ 84        │ 254          │
│   Mean (SD) │ 75.2(8.6) │ 75.7(8.3) │ 74.4(7.9) │ 75.1(8.2)  │
│   Median    │ 76.0      │ 77.0      │ 76.0      │ 76.0        │
│ Sex         │           │           │           │              │
│   Female    │ 53(61.6%) │ 50(59.5%) │ 40(47.6%) │ 143(56.3%)  │
│   Male      │ 33(38.4%) │ 34(40.5%) │ 44(52.4%) │ 111(43.7%)  │
└──────────────────────────────────────────────────────────────────┘
```

Empty state: "Configure analysis in the sidebar, then press Generate Preview (Ctrl+Enter)"

### Table Preview (when Format step is active)

```
┌──────────────────────────────────────────────────────────────────┐
│  📄 Table Preview  │  </> R Code                                │
├──────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────────┐ │
│  │          Table 14.1.5                                      │ │
│  │  Summary of Demographic and Baseline Characteristics       │ │
│  │  Safety Population                                         │ │
│  │  ──────────────────────────────────────────────────────── │ │
│  │  Parameter    Placebo   Xan Low   Xan High   Total        │ │
│  │               (N=86)    (N=84)    (N=84)     (N=254)      │ │
│  │  ──────────────────────────────────────────────────────── │ │
│  │  Age (yr)                                                  │ │
│  │    N            86        84        84        254          │ │
│  │    Mean (SD)  75.2(8.6) 75.7(8.3) 74.4(7.9) 75.1(8.2)   │ │
│  │  Sex                                                       │ │
│  │    Female     53(61.6%) 50(59.5%) 40(47.6%) 143(56.3%)   │ │
│  │    Male       33(38.4%) 34(40.5%) 44(52.4%) 111(43.7%)   │ │
│  │  ──────────────────────────────────────────────────────── │ │
│  │  Source: ADSL                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

White card on muted background. Font family/size from page config.

### R Code (available on every step)

Read-only shinyAce editor. R language mode, "tomorrow" theme. Code grows progressively per step.
Empty state per step:
- Data: "Load datasets to see data loading code"
- Template: "Select a template to see variable configuration"
- Analysis: "Configure and generate preview to see ARD code"
- Format: "Format settings will appear as arframe pipeline code"
- Output: "Complete pipeline script shown after preview"

---

## 13. Multi-TFL Project & Batch Rendering

### The Problem

Building one table is the MVP. But a real CSR has **91+ tables**. Competitors show off batch capability:
- **Certara:** Cloud project with batch render (but $16-41K/year, PK-only scope)
- **Clymb:** Shell collection + JSON metadata (but never touches real data, 4-step pipeline)
- **SAS:** Metadata spreadsheet + batch `%include` driver (gold standard, but code-only)
- **teal:** Tab-per-module + reporter add-on (but ephemeral sessions, no project concept)

arbuilder needs to beat all of them: **visual project management + batch render + generated scripts**.

### The Pattern: TFL List in Sidebar + Batch in Output Panel

**Key decision: Do NOT add a 6th activity bar icon.** The TFL list is a persistent header *inside* the sidebar, always visible regardless of which step is active. This follows Figma's page list pattern (always at top of sidebar) and VS Code's Explorer (first thing you see).

### Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ● arbuilder   t_14_1_5 Demographics ▾   ①②③④⑤  [▶ Preview] [⬇RTF] [⬇.R] │
│  ADSL │ Demographics │ N=248 (SAFFL=Y) │ 5 vars │ Landscape                 │
├────┬──────────────────────┬──────────────────────────────────────────────────┤
│    │  TFL LIST       [+]  │  Data │ ARD │ Table │ R Code                    │
│    │  ───────────────────  ├──────────────────────────────────────────────────┤
│    │  ● t_14_1_5  Demog   │                                                 │
│ 📊 │    t_14_2_1  AE SOC  │                                                 │
│    │    t_14_2_2  AE PT   │            Active table preview                 │
│ 📋 │    t_14_1_3  Disp    │                                                 │
│    │    t_14_3_1  TTE     │                                                 │
│ 📈 │  ───────────────────  │                                                 │
│    │                       │                                                 │
│ 🎨 │  ▾ GROUPING          │                                                 │
│    │  ───────────────────  │                                                 │
│    │  (step-specific       │                                                 │
│    │   panel content)      │                                                 │
│────│                       │                                                 │
│ ⬇  │                       │                                                 │
└────┴───────────────────────┴──────────────────────────────────────────────────┘
```

### TFL List (Persistent Sidebar Header)

```
┌──────────────────────┐
│  TFL LIST       [+]  │  ← always visible, collapsible
│  ───────────────────  │
│  ● t_14_1_5  Demog   │  ← active (blue dot + bold)
│    t_14_2_1  AE SOC  │  ← configured (dimmed text)
│    t_14_2_2  AE PT   │
│    t_14_1_3  Disp    │  ← draft (italic)
│  ───────────────────  │
└──────────────────────┘

States per TFL:
  ● Active       Blue dot, bold text, currently editing
    Configured   Normal text, has been previewed at least once
    Draft        Italic text, template selected but not fully configured
    Error        Red dot, validation failed
    Rendered     Green check, RTF has been generated

Right-click context menu:
  Duplicate
  Rename
  Delete (with confirmation toast + undo)
  Move Up / Move Down

[+] button → creates new TFL (opens Template panel)
```

### TFL Switcher in Top Bar

```
┌──────────────────────────────────────────────────────────────────────┐
│  ● arbuilder    t_14_1_5 Demographics ▾    [▶ Preview] [⬇] [⛶]    │
└──────────────────────────────────────────────────────────────────────┘
                  ↑ dropdown to switch tables (like VS Code breadcrumb)
```

Click the dropdown → shows all TFLs in the project → click one to switch. Keyboard: `Ctrl+Tab` to cycle through TFLs.

### What Switching TFLs Does

When you click a different TFL in the list:
1. Current TFL's config is **auto-saved** to memory (reactive state)
2. New TFL's config **loads** into all panels (template, analysis, format)
3. Canvas shows the new TFL's preview (if previously generated)
4. Pipeline dots update to reflect the new TFL's progress
5. Context summary line updates
6. Transition: sidebar content fades out (100ms) → fades in (100ms) with new content

**No data loss.** Every TFL's config lives in a reactiveValues list keyed by TFL ID.

### Project = Directory on Disk

```
my_study_tfls/
├── _project.json              # Project metadata (name, data paths, shared settings)
├── t_14_1_5_demog.json        # TFL config (template, analysis, format settings)
├── t_14_2_1_ae_soc.json       # TFL config
├── t_14_1_3_disp.json         # TFL config
├── output/
│   ├── t_14_1_5.rtf           # Generated RTF
│   ├── t_14_1_5.R             # Generated R script
│   ├── t_14_2_1.rtf
│   ├── t_14_2_1.R
│   └── pipeline.R             # Master batch script
└── data/                      # Symlink or path reference to ADaM data
```

**TFL config JSON structure:**
```json
{
  "id": "t_14_1_5",
  "name": "Demographics",
  "template": "demog",
  "analysis": {
    "trt_var": "TRT01A",
    "include_total": true,
    "vars": [
      {"variable": "AGE", "type": "continuous", "stats": ["n","mean_sd","median","q1_q3","min_max"], "decimals": 1},
      {"variable": "SEX", "type": "categorical", "cat_fmt": "npct", "pct_dec": 1}
    ]
  },
  "format": {
    "titles": ["Table 14.1.5", "Summary of Demographic and Baseline Characteristics"],
    "population": "Safety Population",
    "footnotes": ["Percentages based on N in each treatment group."],
    "orientation": "landscape",
    "hline_preset": "header"
  },
  "status": "configured",
  "last_rendered": "2026-03-17T14:30:00"
}
```

### Batch Rendering in Output Panel (5th Icon)

The Output panel gains a **BATCH** section:

```
┌──────────────────────┐
│ ▾ BATCH              │
│──────────────────────│
│                      │
│ Project TFLs:        │
│ ☑ ✓ t_14_1_5 Demog   │  ← green check = rendered
│ ☑ ● t_14_2_1 AE SOC  │  ← blue dot = configured, not rendered
│ ☑   t_14_2_2 AE PT   │  ← no status = draft
│ ☐   t_14_1_3 Disp    │  ← unchecked = skip in batch
│                      │
│ [▶ Generate All]     │  renders all checked TFLs
│ [▶ Generate Selected]│  renders only checked
│                      │
│ Progress:            │
│ ████████░░ 3/5       │  progress bar during batch
│ t_14_2_1 rendering...│  current item
│                      │
│ [⬇ Download All .zip]│  all RTFs + all .R scripts
│ [⬇ Master pipeline.R]│  single script that runs everything
│                      │
│ ▾ VALIDATION         │
│──────────────────────│
│ (same as before)     │
│                      │
│ ▾ RECIPE             │
│──────────────────────│
│ (same as before)     │
│                      │
│ ▾ EXPORT             │
│──────────────────────│
│ (same as before,     │
│  for active TFL)     │
│                      │
└──────────────────────┘
```

### Master pipeline.R (Generated)

```r
# ===========================================================================
# Master Pipeline — ARFR-2025-001 Phase III CSR
# Generated by arbuilder on 2026-03-17
# 5 tables, Safety Population
# ===========================================================================

library(arframe)
library(dplyr)
library(tidyr)
library(readr)

# --- Shared data ---
adsl <- read_csv("data/adsl.csv") |> filter(SAFFL == "Y")
adae <- read_csv("data/adae.csv")

big_n <- adsl |>
  count(TRT01A, name = "N") |>
  bind_rows(tibble(TRT01A = "Total", N = nrow(adsl)))

# --- Table 1: Demographics ---
source("t_14_1_5.R")

# --- Table 2: AE Summary by SOC/PT ---
source("t_14_2_1.R")

# --- Table 3: AE Summary by Preferred Term ---
source("t_14_2_2.R")

# --- Table 4: Disposition ---
source("t_14_1_3.R")

# --- Table 5: Time to Event ---
source("t_14_3_1.R")

cat("All 5 tables rendered successfully.\n")
```

### How This Beats Every Competitor

| Capability | Certara | Clymb | teal | SAS | arbuilder |
|-----------|---------|-------|------|-----|-----------|
| Visual TFL collection | Cloud-only | Shell list (no data) | Tab bar | None | Sidebar tree |
| Live preview per table | Limited | No | One at a time | No | Yes, instant switch |
| Batch render | Cloud | Outside tool | No | Script | In-app + script |
| Generated R scripts | No | siera (rough) | No | N/A (SAS code) | Clean tidyverse |
| Master batch script | No | No | No | Manual | Auto-generated |
| Offline/local | No | No | Needs server | Yes | Yes |
| Project portability | Vendor lock | JSON | None | .sas files | JSON + .R + .rtf |
| Status tracking | Unknown | None | None | .log parsing | Visual checklist |
| Price | $16-41K/yr | Unknown | Free (needs infra) | $$$$$ | Free |
| Code transparency | Black box | Shell only | Debug code | Full | Full + clean |

### Implementation Phases for Multi-TFL

| Phase | What | When |
|-------|------|------|
| **Phase 1** | Single table, no TFL list | Now (MVP) |
| **Phase 2** | TFL List in sidebar, multi-table state management, save/load JSON | After Phase A-I |
| **Phase 3** | Batch section in Output panel, Generate All, progress bar | After multi-table |
| **Phase 4** | Master pipeline.R generation, zip export, project-level settings | After batch |
| **Phase 5** | Project manifest, import/export, shared data/format templates | After pipeline |

### Architecture for Multi-TFL (Design Now, Build Later)

The key architectural decision to make NOW (Phase 1) so multi-TFL works later:

```r
# In app_server.R, the current reactive pattern:
ard <- reactive({ fct_ard_demog(adsl, grouping(), stats_cfg()) })

# For multi-TFL, this becomes (Phase 2):
project <- reactiveValues(
  tfls = list(),           # keyed by TFL ID
  active_tfl = NULL,       # current TFL ID
  shared_data = list()     # loaded datasets (shared across TFLs)
)

# Each TFL stores:
# project$tfls[["t_14_1_5"]] = list(
#   template = "demog",
#   analysis = list(...),
#   format = list(...),
#   ard = NULL,            # computed ARD (cached)
#   status = "configured"
# )
```

**Critical:** The current `app_server.R` wiring works for single-table. When we add multi-TFL in Phase 2, we'll wrap the existing module calls in a reactive context that swaps config based on `active_tfl`. The modules themselves don't change — they just receive different inputs.

---

## 14. Statistical Format Coverage

All formats from `csr_stat_formats.txt` that the ARD builders need:

### Format Functions (utils_formats.R)

```r
# ── COUNTS & FREQUENCIES ──────────────────────────────
fmt_count(n)                                # "120"
fmt_npct(n, N, style = "A", dec = 1)       # " 12 ( 10.0)" or "  0" (style D)
fmt_nn_pct(n, N, style = "A", dec = 1)     # " 12/120 ( 10.0)"
fmt_nn_pct_ci(n, N, lo, hi, style, dec)    # " 12/120 ( 10.0) [  5.6,  16.9]"
fmt_resp_rate(n, N, lo, hi)                # " 62/118 ( 52.5) [ 43.2,  61.7]"

# ── CONTINUOUS SUMMARIES ──────────────────────────────
fmt_mean_sd(mean, sd, dec = 1)              # "52.4 ( 11.2)"
fmt_mean_only(mean, dec = 1)                # "52.4"
fmt_median_only(median, dec = 1)            # "53.0"
fmt_median_iqr(med, q1, q3, dec = 1)       # "53.0 [ 45.0,  60.0]"
fmt_min_max(min, max, dec = 1)              # " 22.0,  78.0"
fmt_stack_cont(n, mean, sd, med, min, max)  # "120 / 52.4 (11.2) / 53.0 / 22, 78"

# ── CHANGE FROM BASELINE ─────────────────────────────
fmt_cfb_mean_sd(mean, sd, dec = 1)          # "-4.1 (  1.2)"
fmt_pct_cfb(mean, sd, dec = 1)              # "-8.6 (  5.9)"

# ── GEOMETRIC / PK ───────────────────────────────────
fmt_gmean_cv(gmean, cv, dec = 2)            # "52.43 ( 23.4%)"
fmt_gmr_ci(gmr, lo, hi, dec = 3)           # "1.024 (0.987, 1.063)"

# ── LS MEANS / TREATMENT COMPARISONS ─────────────────
fmt_lsmean_se(est, se, dec = 2)             # "48.70 (  1.18)"
fmt_lsmean_diff(diff, lo, hi, dec = 2)     # " 3.70 (  1.24,  6.16)"
fmt_trt_diff(diff, lo, hi, p, dec = 2)     # " 3.70 (1.24, 6.16)  0.003"

# ── RISK / ODDS / HAZARD ─────────────────────────────
fmt_risk_diff(est, lo, hi, dec = 3)        # " 0.120 ( 0.042,  0.198)"
fmt_odds_ratio(or, lo, hi, p, dec = 3)     # "2.140 (1.340, 3.420)  0.001"
fmt_haz_ratio(hr, lo, hi, p, dec = 3)      # "0.724 (0.580, 0.904)  0.006"

# ── SURVIVAL / TIME-TO-EVENT ─────────────────────────
fmt_km_median(med, lo, hi, dec = 1)        # "14.3 ( 11.2,  18.6)" / "NR"
fmt_km_rate(rate, lo, hi, dec = 3)         # "0.724 (0.641, 0.795)"

# ── P-VALUES ─────────────────────────────────────────
fmt_pval(p, dec = 3)                        # "0.043" / "<0.001" / ">0.999"

# ── GENERAL CI ───────────────────────────────────────
fmt_ci(est, lo, hi, dec = 3)               # "0.724 (0.580, 0.904)"
                                            # Handles NR, NE, NC, NA, BLQ
```

### Edge Cases Handled

| Scenario | Behavior |
|----------|----------|
| Zero count, Style A | Show `"  0 ( 0.0)"` |
| Zero count, Style D | Show `"  0"` (n only) |
| Percentage < 0.1 | Show `"  1 ( <0.1)"` |
| Percentage > 99.9 | Show `"119 (>99.9)"` |
| CI with NR (not reached) | Show `"  NR ( 22.4,    NR)"` |
| CI with NE (not estimable) | Show `"  NE"` |
| P-value < 0.001 | Show `"<0.001"` |
| P-value > 0.999 | Show `">0.999"` |
| Infinite values | Show `"INF"` or `"-INF"` |
| BLQ (below quantification) | Show `"BLQ"` |
| Missing | Show `"-"` or `"NC"` |

---

## 15. File Change List

### Modified files

| File | Change Scope | Description |
|------|-------------|-------------|
| `R/app_ui.R` | **Rewrite** | Activity bar + sidebar panels + canvas |
| `R/mod_stats.R` | **Major rewrite** | Per-variable config cards |
| `R/mod_titles.R` | **Moderate** | Dynamic add/remove, per-line overrides |
| `R/mod_columns.R` | **Major expansion** | Width, N-counts, visibility, nests spans + header |
| `R/mod_page.R` | **Major expansion** | Margins, continuation, nests rules + pagehead + rows + spacing |
| `R/mod_preview.R` | **Moderate** | Uses expanded fmt for more arframe verbs |
| `R/mod_grouping.R` | **Minor** | Variable order tracking for drag reorder |
| `R/mod_data.R` | **Minor** | UI wrapping for sidebar panel |
| `R/mod_analysis.R` | **Moderate** | Full template card grid with phase badges |
| `R/fct_ard_demog.R` | **Moderate** | Per-variable stats/decimals from config |
| `R/fct_codegen.R` | **Moderate** | Per-variable code + new arframe verbs |
| `R/fct_render.R` | **Moderate** | Call fr_spans, fr_rows, fr_pagehead, etc. |
| `R/utils_ui.R` | **Add helpers** | var_config_card, color_input, dynamic_list |
| `inst/app/www/app.css` | **Major expansion** | +400 lines for activity bar, panels, cards |
| `inst/app/www/app.js` | **Major expansion** | +200 lines for activity bar, drag, fullscreen, progressive unlock |

### New files

| File | Purpose |
|------|---------|
| `R/utils_formats.R` | Statistical format functions (50+ formatters) |
| `R/mod_spans.R` | Spanning header builder (nested in mod_columns) |
| `R/mod_header_style.R` | Header presentation config (nested in mod_columns) |
| `R/mod_rows_config.R` | Row grouping/pagination (nested in mod_page) |
| `R/mod_pagehead.R` | Running headers/footers (nested in mod_page) |
| `R/mod_rules.R` | Hlines/vlines/grid (nested in mod_page) |
| `R/mod_spacing.R` | Section spacing (nested in mod_page) |
| `R/mod_styles.R` | Conditional formatting rules (nested in mod_page) |
| `R/mod_recipe.R` | Recipe save/load (Output panel) |
| `R/mod_validation.R` | Validation runner (Output panel) |

### Untouched (CRITICAL)

| File | Reason |
|------|--------|
| `R/app_server.R` | **Zero changes** — all reactive wiring stays identical |
| `R/fct_adam.R` | No changes needed |
| `R/fct_profile.R` | No changes needed |
| `R/mod_data_viewer.R` | No changes needed |
| `R/mod_code.R` | No changes needed |
| `R/utils_helpers.R` | No changes needed |
| `R/launch.R` | No changes needed |
| `R/_disable_autoload.R` | No changes needed |
| `DESCRIPTION` | No changes needed (Phase A) |

---

## 16. Implementation Phases

### Phase A: Activity Bar Shell + Polish Foundation

Replace accordion sidebar with activity bar + 5-panel switching. All existing functionality works identically, just rearranged. Includes the CSS microinteraction foundation and empty states.

**Files:** `app_ui.R`, `app.css`, `app.js`

**Includes 9.5 patterns:**
- Smooth panel transitions (150ms ease, not instant show/hide)
- Section expand/collapse with `max-height` animation
- Empty states with icons + CTAs in all canvas tabs
- Pipeline progress dots in topbar (✓ ● ○)
- Contextual sidebar footer hint (changes per state)
- Soft unlock on activity bar (clickable but dimmed, toast warning)
- Toast notification system (JS `arToast()`)
- "Load Demo Data" button in Data tab empty state
- Dimmer sidebar / brighter canvas contrast

**Verify:**
1. `for f in R/*.R; do Rscript -e "parse('$f')"; done` — all files parse
2. App starts on `Rscript -e "shiny::runApp('.', port=7842)"`
3. Activity bar shows 5 icons (4 top + 1 bottom), clicking switches panels with smooth transition
4. Soft-locked icons are clickable with toast warning
5. Pipeline dots show progress (✓ for completed steps)
6. Data panel: mod_data works, loads datasets
7. Template panel: mod_analysis cards visible
8. Analysis panel: grouping + stats visible
9. Format panel: titles + columns + page visible (titles + page open, rest collapsed)
10. Output panel: placeholder with validation + recipe sections
11. Canvas: all 4 tabs work, empty states have CTAs
12. "Load Demo Data" in empty Data tab loads ADSL + selects Demographics
13. Generate Preview produces output, Table tab pulses on new content
14. Export RTF works, toast shows "RTF exported"
15. `Ctrl+1/2/3/4`, `Ctrl+B`, `Ctrl+Enter` all work
16. Sidebar footer hint changes per pipeline state

### Phase B: Per-Variable Statistics Config

The signature feature. Replace flat `mod_stats` with per-variable cards.

**Files:** `mod_stats.R`, `utils_formats.R`, `fct_ard_demog.R`, `fct_codegen.R`, `utils_ui.R`, `app.css`, `app.js`

**Verify:**
- Each selected variable gets its own config card
- Cards expand/collapse, show summary when collapsed
- Per-variable decimals produce different formatting in ARD output
- Stat reordering changes table row order
- Generated R script shows per-variable code blocks

### Phase C: Enhanced Titles & Footnotes

Dynamic add/remove lines, per-line overrides, footnote placement.

**Files:** `mod_titles.R`, `fct_render.R`, `fct_codegen.R`

**Verify:** Multiple title lines, per-line align/bold, footnote placement in codegen

### Phase D: Expanded Columns (width, N-counts, visibility)

Full `fr_cols()` API.

**Files:** `mod_columns.R`, `fct_render.R`, `fct_codegen.R`

**Verify:** Column visibility toggles, N-counts in header, width strategy

### Phase E: Spanning Headers + Header Style

`fr_spans()` and `fr_header()`.

**Files:** new `mod_spans.R`, `mod_header_style.R`, modified `mod_columns.R`, `fct_render.R`, `fct_codegen.R`

**Verify:** Spanning headers appear in preview and codegen

### Phase F: Page Layout Expansion

Margins, continuation, col_gap.

**Files:** `mod_page.R`, `fct_render.R`, `fct_codegen.R`

**Verify:** Custom margins in RTF output

### Phase G: Rules, Pagehead/Pagefoot, Rows, Spacing

All remaining arframe layout verbs.

**Files:** new `mod_rules.R`, `mod_pagehead.R`, `mod_rows_config.R`, `mod_spacing.R`, modified `mod_page.R`

**Verify:** Page headers/footers with tokens, row grouping, spacing

### Phase H: Conditional Styles + Validation

`fr_styles()` and validation.

**Files:** new `mod_styles.R`, `mod_validation.R`

**Verify:** Conditional bold/indent/bg rules, validation checklist

### Phase I: Recipe Management

Save/load/import/export format presets.

**Files:** new `mod_recipe.R`

**Verify:** Save recipe as YAML, load it back, all config restored

### Phase J: Progressive Unlocking + Polish

Activity bar state management, step indicators, transitions.

**Files:** `app.js`, `app.css`

**Verify:** Disabled icons until prerequisite met, smooth transitions

---

## 17. Closing the Gap: 8.5 → 9.5/10

Four concerns with the 8.5 design and their solutions, plus seven "feel" patterns that separate good tools from great ones.

### Concern 1: Format Panel Is Too Deep (10 Sections)

**Problem:** The Format panel has 10 collapsible sections (Titles, Columns, Spanning Headers, Header Style, Page Layout, Rules, Page Header/Footer, Rows & Pagination, Spacing, Conditional Styles). 80% of users only touch Titles + Page Layout. The rest is an intimidating scroll.

**Solution: Smart defaults + progressive collapse**
- Only **Titles & Footnotes** and **Page Layout** open by default
- All other sections collapsed with a subtle count badge: `COLUMNS (3 customized)` or `RULES (default)`
- A "Reset section" link appears on any section that's been modified
- The collapsed header shows a one-line summary of current settings: `RULES: header preset, no vlines`

### Concern 2: Template Panel Feels Empty After Selection

**Problem:** Once you pick "Demographics," the Template panel is just a list of cards with one highlighted. No reason to revisit.

**Solution: Template Info section + auto-config summary**
- Below the card grid, a **TEMPLATE INFO** section shows what the selected template auto-configured:
  ```
  ▾ TEMPLATE INFO
  ──────────────────
  Selected: Demographics
  Covers: 14.1.1, 14.1.2, 14.1.4, 14.1.5, 14.1.6
  ADaM source: ADSL
  Default vars: AGE, SEX, RACE, ETHNIC
  Default stats: N, Mean(SD), Median, Q1/Q3, Min/Max, n(%)
  Default titles: "Table 14.1.5", "Summary of..."
  ```
- This makes the panel informative on revisit — you can see exactly what the template gave you
- Future: comparison mode — "this template covers 6 CSR tables, you've completed 2"

### Concern 3: Progressive Unlocking May Frustrate Power Users

**Problem:** Hard-locking steps means a user who loads data can't peek at Format. If they're loading a recipe, they need Format access immediately.

**Solution: Soft unlocking — guidance, not gates**
- Disabled icons are **clickable** but show a toast: "No template selected yet — some defaults may be missing"
- The panel still opens, but sections that depend on missing prerequisites show an inline hint: "Select a table type to populate column settings"
- The icon stays visually dimmed (no left border highlight) until the prerequisite is met
- Once the prerequisite is met, the icon transitions to full color with a subtle pulse animation (200ms)

```
BEFORE data loaded:
  📋  (dimmed, no left border, clickable but shows toast)

AFTER data loaded:
  📋  (full color, 2px left border, subtle pulse once on unlock)
```

### Concern 4: Analysis Panel Needs Template-Driven Flexibility

**Problem:** The per-variable card pattern works for demographics but AE Summary (Phase 2) needs SOC/PT hierarchy, severity filtering, and exposure-adjusted rates — a completely different UI.

**Solution: Template-driven panel rendering**
- The Analysis panel UI is not static — it renders **different sections based on the selected template**
- Demographics template → Grouping + Variable Config cards
- AE template → SOC/PT hierarchy config + severity filter + incidence rate toggle
- TTE template → Parameter selector + timepoint + event definition
- Each template defines its Analysis panel layout via a config list
- `mod_stats_ui("stats")` becomes a `uiOutput` that renders differently per template

```r
# Inside mod_stats_server, the UI is template-driven:
output$stats_ui <- renderUI({
  switch(analysis()$type,
    "demog"  = demog_stats_ui(ns),     # per-variable cards
    "ae"     = ae_stats_ui(ns),         # SOC/PT hierarchy
    "tte"    = tte_stats_ui(ns),        # KM/Cox config
    "custom" = custom_stats_ui(ns)      # user-defined
  )
})
```

This is critical for Phase 2+ but we design the architecture now so it's ready.

---

### Pattern 1: Microinteractions (CSS Transitions)

**What:** Every state change has a brief, purposeful animation. Not decorative — communicative.

| Interaction | Animation | Duration |
|-------------|-----------|----------|
| Panel switch (activity bar) | Background-color fade on icon | 100ms ease |
| Section expand/collapse | `max-height` + `opacity` transition | 150ms ease-out |
| Button press | `transform: scale(0.98)` | 80ms |
| Generate Preview complete | Table tab border pulses accent blue | 200ms, once |
| Export complete | Download button flashes green | 300ms, once |
| Stat checkbox toggle | Card summary text updates with CSS transition | 150ms |
| Variable card drag | Card lifts with `box-shadow` + slight scale | 150ms |
| Sidebar collapse | Width 340→0 + opacity 1→0 | 200ms ease |

**CSS additions:**
```css
/* Panel switch glow on activity bar button */
.ar-ab-btn.active {
  transition: color 100ms ease, border-left-color 100ms ease;
}

/* Section expand with smooth height */
.ar-ps__body {
  overflow: hidden;
  max-height: 0;
  opacity: 0;
  transition: max-height 250ms ease-out, opacity 150ms ease-out, padding 150ms ease;
}
.ar-ps--open > .ar-ps__body {
  max-height: 2000px;  /* large enough for any content */
  opacity: 1;
  padding: 4px 14px 14px;
}

/* Tab pulse when new content arrives */
@keyframes ar-tab-pulse {
  0% { border-bottom-color: transparent; }
  50% { border-bottom-color: var(--accent); }
  100% { border-bottom-color: transparent; }
}
.ar-canvas-tab.has-update {
  animation: ar-tab-pulse 600ms ease-out;
}

/* Card lift on drag */
.ar-var-card.dragging {
  box-shadow: 0 4px 16px rgba(0,0,0,0.12);
  transform: scale(1.02);
  z-index: 100;
}
```

**Priority:** Must-have | **Effort:** Low

### Pattern 2: Contextual Sidebar Intelligence

**What:** The sidebar reacts to pipeline state — not static, but alive.

| Pipeline State | Sidebar Behavior |
|---------------|-----------------|
| No data loaded | Data panel: "Load datasets to begin" with CTA. Other panels: dimmed with hint. |
| Data loaded, no template | Template panel highlights, shows "Choose a table type". Analysis/Format show "Select a template first." |
| Template selected | Analysis panel populates with detected variables. Format populates with template defaults. |
| Analysis configured | Format panel shows column names from ARD output dynamically. |
| Preview generated | Output panel validation runs automatically. |

**Sidebar footer hint changes contextually:**
```
State: no data      → "Load ADaM datasets to begin"
State: no template  → "Choose a table type (Ctrl+2)"
State: no analysis  → "Configure analysis variables (Ctrl+3)"
State: ready        → "Ctrl+Enter to generate preview"
State: previewed    → "Export RTF or download R script"
```

**Priority:** Must-have | **Effort:** Medium

### Pattern 3: Empty States with CTAs

**What:** Every empty panel has (1) an icon, (2) a clear message, (3) a direct action.

```
┌─────────────────────────────────────────┐
│                                         │
│              📊                          │
│                                         │
│     No data loaded yet                  │
│                                         │
│     Load ADaM datasets from the Data    │
│     panel to explore and analyze.       │
│                                         │
│     [Load Demo Data]  [Open Data Panel] │
│                                         │
└─────────────────────────────────────────┘
```

| Canvas Tab | Empty State Message | CTA |
|-----------|-------------------|-----|
| Data | "Load ADaM datasets to explore" | [Load Demo Data] |
| ARD | "Analysis results appear here after Generate Preview" | [Open Analysis Panel] |
| Table | "Your formatted table appears here" | [Generate Preview] |
| R Code | "Reproducible R script generates after preview" | [Generate Preview] |

**"Load Demo Data" button:** One click loads ADSL from adam_pilot, selects Demographics template, checks default vars. User sees the full pipeline in 3 seconds. This is the single most impactful onboarding feature.

**Priority:** Must-have | **Effort:** Low

### Pattern 4: Pipeline Progress Indicator

**What:** A thin progress strip in the top bar showing pipeline status.

```
┌──────────────────────────────────────────────────────────────────────┐
│  ● arbuilder  ① ── ② ── ③ ── ④ ── ⑤   [▶ Preview] [⬇RTF] [⬇.R]  │
│               ✓    ✓    ●    ○    ○                                  │
│              Data  Tmpl  Anlys Fmt  Out                               │
└──────────────────────────────────────────────────────────────────────┘
                ✓ = completed (green)
                ● = current (accent blue, filled)
                ○ = pending (grey, hollow)
```

| Indicator | Meaning | Color |
|-----------|---------|-------|
| `✓` (checkmark) | Step completed | `#2d8a4e` (success green) |
| `●` (filled dot) | Current step (last panel visited) | `#4a6fa5` (accent blue) |
| `○` (hollow dot) | Not yet visited / configured | `#a3a09c` (muted grey) |
| Line between dots | Solid when both sides complete, dashed when not | `#e5e4e2` / `#2d8a4e` |

Clicking a dot navigates to that panel (same as clicking the activity bar icon).

**CSS:**
```css
.ar-pipeline {
  display: flex;
  align-items: center;
  gap: 0;
  margin: 0 16px;
}

.ar-pipeline__step {
  display: flex;
  align-items: center;
  gap: 0;
  cursor: pointer;
}

.ar-pipeline__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  border: 1.5px solid var(--fg-muted);
  background: transparent;
  transition: all 200ms ease;
}

.ar-pipeline__dot--done {
  background: var(--success);
  border-color: var(--success);
}

.ar-pipeline__dot--active {
  background: var(--accent);
  border-color: var(--accent);
}

.ar-pipeline__line {
  width: 20px;
  height: 1.5px;
  background: var(--border);
  transition: background 200ms ease;
}

.ar-pipeline__line--done {
  background: var(--success);
}

.ar-pipeline__label {
  font-size: 8px;
  color: var(--fg-muted);
  margin-top: 2px;
  text-align: center;
}
```

**Priority:** Must-have | **Effort:** Low-Medium

### Pattern 5: Context Summary Line

**What:** A single line in the top bar showing what's currently configured.

```
┌──────────────────────────────────────────────────────────────────────┐
│  ● arbuilder  ①②③④⑤  [▶ Preview]          [⬇RTF] [⬇.R] [⛶]      │
│  ADSL │ Demographics │ N=248 (SAFFL=Y) │ 5 vars │ Landscape        │
└──────────────────────────────────────────────────────────────────────┘
                    ↑ context summary line (10px, muted grey)
```

| Segment | Source | Example |
|---------|--------|---------|
| Dataset | `data_out$active_ds` | "ADSL" |
| Template | `analysis()$type` | "Demographics" |
| Population | Pop filter | "N=248 (SAFFL=Y)" |
| Variables | `length(grouping()$analysis_vars)` | "5 vars" |
| Page | `page_cfg()$orientation` | "Landscape" |

Updates reactively as user configures. Shows "—" for unconfigured segments.

**Priority:** Nice-to-have | **Effort:** Low

### Pattern 6: Toast Notification System

**What:** Brief, non-blocking success/warning messages. Bottom-right, auto-dismiss.

```
                                          ┌──────────────────────┐
                                          │ ✓ RTF exported       │
                                          │   t_14_1_5.rtf       │
                                          │              4s auto │
                                          └──────────────────────┘
```

| Event | Type | Message | Duration |
|-------|------|---------|----------|
| Data loaded | Success | "3 datasets loaded (ADSL, ADAE, ADTTE)" | 4s |
| Preview generated | Success | "Preview updated — 12 rows × 5 cols" | 4s |
| RTF exported | Success | "t_14_1_5.rtf exported" | 4s |
| R script copied | Success | "R script copied to clipboard" | 3s |
| Validation warning | Warning | "No footnotes defined" | 6s |
| Recipe saved | Success | "Recipe 'FDA Standard' saved" | 4s |

**Never use toast for errors.** Errors go inline in the relevant sidebar section with red border.

**JS implementation:**
```javascript
function arToast(message, type, duration) {
  type = type || 'success';
  duration = duration || 4000;
  var toast = document.createElement('div');
  toast.className = 'ar-toast ar-toast--' + type;
  toast.innerHTML = '<span class="ar-toast__icon"></span>' +
                    '<span class="ar-toast__msg">' + message + '</span>';
  document.getElementById('ar_toast_container').appendChild(toast);
  setTimeout(function() { toast.classList.add('ar-toast--out'); }, duration);
  setTimeout(function() { toast.remove(); }, duration + 300);
}
```

**CSS:**
```css
#ar_toast_container {
  position: fixed;
  bottom: 16px;
  right: 16px;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.ar-toast {
  background: var(--bg);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 10px 14px;
  font-size: 12px;
  color: var(--fg);
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
  animation: ar-toast-in 200ms ease-out;
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 200px;
}

.ar-toast--success { border-left: 3px solid var(--success); }
.ar-toast--warning { border-left: 3px solid var(--warning); }
.ar-toast--error   { border-left: 3px solid var(--error); }

.ar-toast--out {
  animation: ar-toast-out 300ms ease-in forwards;
}

@keyframes ar-toast-in {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

@keyframes ar-toast-out {
  from { opacity: 1; transform: translateY(0); }
  to   { opacity: 0; transform: translateY(8px); }
}
```

**Priority:** Must-have | **Effort:** Low-Medium

### Pattern 7: Linear-Style Polish

**What:** The collective micro-decisions that make something feel premium.

| Detail | Implementation |
|--------|---------------|
| **Dimmer sidebar** | Activity bar: `#f8f8f7`, Sidebar: `#f9f9f8`, Canvas: `#ffffff` — subtle 2-shade gradient left→right |
| **Hover reveals** | Variable card summary shows "5 stats, 1 dec" collapsed; full stat list only on expand. Column visibility toggles appear on hover, not always. |
| **Speed perception** | Generate Preview spinner starts **client-side instantly** via JS (don't wait for server). `will-change: transform` on animated elements. |
| **Consistent spacing** | 4px base grid. All margins/paddings are multiples of 4. Section gaps: 8px. Card gaps: 6px. Input gaps: 8px. |
| **Typography hierarchy** | Section headers: 10px/600/uppercase/0.06em spacing. Labels: 12px/500. Values: 13px/400. Hints: 10px/400/muted. |
| **Subtle borders** | All borders 1px `#e5e4e2`. Active borders 1px `#4a6fa5`. No thick borders anywhere. |
| **Intentional whitespace** | Sidebar scroll padding: 0 14px. Canvas body padding: 16px. Card padding: 8-10px. |
| **No gradients, no shadows (almost)** | Flat design. Only shadow: toast notifications (`0 4px 12px rgba(0,0,0,0.08)`). |

**Priority:** Must-have | **Effort:** Low (CSS tweaks)

---

### Summary: What Gets Us to 9.5/10

| Category | 8.5 Design | 9.5 Design |
|----------|-----------|-----------|
| **Panel switching** | Instant show/hide | Smooth transitions (150ms) |
| **Empty states** | "No data yet" text | Icon + message + CTA button + "Load Demo" |
| **Sidebar** | Static panels | Contextual hints, reactive footer, disable states |
| **Progress** | No indicator | Pipeline dots in topbar (✓ ● ○) |
| **Feedback** | No confirmation | Toast for success, inline for errors |
| **Format panel** | All sections open | Smart defaults: 2 open, 8 collapsed with summaries |
| **Progressive unlock** | Hard lock (can't click) | Soft lock (clickable, toast warning, hint) |
| **Template panel** | Card list only | Card list + Template Info + auto-config summary |
| **Analysis panel** | Static per-variable cards | Template-driven UI (different layout per table type) |
| **Speed** | Server-round-trip wait | Client-side instant spinner, CSS `will-change` |
| **First run** | Blank screen | "Load Demo Data" → full pipeline in 3 seconds |

**Effort estimate for all 9.5 patterns:** ~15-20 hours total, spread across phases.

## 18. Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Enter` / `Cmd+Enter` | Generate Preview |
| `Ctrl+B` / `Cmd+B` | Toggle sidebar |
| `Ctrl+1` | Go to Data panel |
| `Ctrl+2` | Go to Template panel |
| `Ctrl+3` | Go to Analysis panel |
| `Ctrl+4` | Go to Format panel |
| `Ctrl+Tab` | Cycle through TFLs (multi-TFL mode) |
| `Ctrl+N` | New TFL |
| `Ctrl+S` | Quick export (future) |

---

## 19. Color System

```css
:root {
  /* Backgrounds */
  --bg: #ffffff;
  --bg-sidebar: #f8f8f7;
  --bg-muted: #f4f4f3;
  --bg-hover: #f0efed;
  --bg-active: #e8eef5;

  /* Borders */
  --border: #e5e4e2;
  --border-focus: #4a6fa5;

  /* Text */
  --fg: #1a1918;
  --fg-2: #57534e;
  --fg-3: #78716c;
  --fg-muted: #a3a09c;

  /* Accent */
  --accent: #4a6fa5;
  --accent-hover: #3d5d8a;
  --accent-muted: #e8eef5;

  /* Semantic */
  --success: #2d8a4e;
  --success-muted: #ecf7f0;
  --warning: #c17a2f;
  --warning-muted: #fdf5eb;
  --error: #c53030;
  --error-muted: #fdf0f0;

  /* Typography */
  --font: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', Consolas, monospace;

  /* Spacing */
  --radius: 6px;
  --radius-sm: 4px;
  --radius-lg: 8px;
  --ease: 150ms ease;
}
```

---

## 20. Verification Checklist (after each phase)

1. **Parse:** `for f in R/*.R; do Rscript -e "parse('$f')"; done`
2. **Start:** `Rscript -e "shiny::runApp('.', port=7842)"` → no errors
3. **HTTP:** `curl -s -o /dev/null -w '%{http_code}' http://localhost:7842` → 200
4. **Activity bar:** All icons render, clicking switches panels correctly
5. **Sidebar:** Panels show correct content, sections collapse/expand
6. **Canvas:** All 4 tabs work (Data, ARD, Table, R Code)
7. **End-to-end:** Load ADSL → Configure demographics → Generate Preview → ARD + Table + Code populate
8. **Export:** Export RTF downloads valid file, Download .R downloads valid script
9. **Shortcuts:** Ctrl+Enter, Ctrl+B, Ctrl+1/2/3/4 all functional
10. **No regressions:** Everything that worked before still works
