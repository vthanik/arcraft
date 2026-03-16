# arbuilder — Implementation Plan

**Local Shiny app for building submission-ready TFLs from ADaM data.**
Separate package. Uses `arframe` (currently `tlframe`) as the rendering engine.

Date: 2026-03-15

---

## 1. Product Vision

### The Problem

Small pharma statistician has:
- No SAS license ($$$)
- No Shiny Server / Posit Connect
- No IT team to deploy teal/tern
- Limited R coding confidence

### The Solution

```
arframe      = the engine (pure R, no UI, CRAN package)
arbuilder    = the workshop (local Shiny app, separate package)

arbuilder::launch() → browser opens locally → build tables → export RTF/PDF + R script
```

### The Pipeline

```
ADaM data  →  Population  →  ARD wide   →  arframe   →  RTF/PDF
(raw)         filter          (summary)     (format)     (output)

adsl.csv      SAFFL=="Y"     tbl_demog     fr_table()   t_14_1_1.rtf
adae.csv      ITTFL=="Y"     tbl_ae_soc    fr_titles()  t_14_2_1.rtf
adtte.csv                    tbl_tte       fr_render()  t_14_3_1.rtf
```

---

## 2. Competitive Landscape

|                  | teal + tern  | SAS          | arbuilder    |
|------------------|-------------|-------------|-------------|
| Server needed    | Yes          | No           | No           |
| License cost     | Free         | $$$$$        | Free         |
| IT setup         | Heavy        | Medium       | Zero         |
| Coding needed    | Some R       | SAS          | Optional     |
| Audit trail      | Shiny logs   | .sas + .log  | .R script    |
| RTF quality      | Basic        | Gold std     | Submission   |
| Pagination       | No           | Yes          | Yes          |
| Time to first table | Days (setup) | Hours (if expert) | Minutes |

**Target market:** Small pharma, CROs (like Clinimetrics), teams without server infrastructure, shops migrating from SAS to R.

---

## 3. System Architecture

```
┌───────────────────────────────────────────────────────┐
│                    USER'S LAPTOP                      │
│                                                       │
│  ┌─────────────────────────────────────────────────┐  │
│  │               arbuilder (Shiny app)             │  │
│  │                                                 │  │
│  │  ┌───────────┐  ┌───────────┐  ┌────────────┐  │  │
│  │  │ DATA LAYER│  │ ARD LAYER │  │FORMAT LAYER│  │  │
│  │  │           │  │           │  │            │  │  │
│  │  │ Load ADaM ├─►│ Summarize ├─►│ fr_table() │  │  │
│  │  │ (adsl,    │  │ to ARD    │  │ fr_titles()│  │  │
│  │  │  adae)    │  │ wide      │  │ fr_cols()  │  │  │
│  │  │ Filter    │  │ (dplyr)   │  │ fr_render()│  │  │
│  │  └───────────┘  └───────────┘  └────────────┘  │  │
│  │                                     │           │  │
│  │                              uses arframe API   │  │
│  └─────────────────────────────────────────────────┘  │
│                    │                  │                │
│                    ▼                  ▼                │
│             ┌───────────┐  ┌──────────────────┐       │
│             │  Browser  │  │  Output Files    │       │
│             │ localhost │  │  - report.rtf    │       │
│             │ :3838     │  │  - report.pdf    │       │
│             └───────────┘  │  - pipeline.R    │       │
│                            └──────────────────┘       │
└───────────────────────────────────────────────────────┘
```

**Key rule:** arbuilder knows about arframe. arframe knows nothing about arbuilder.

---

## 4. Package Structure

```
arbuilder/
├── DESCRIPTION
├── NAMESPACE
├── LICENSE
├── R/
│   ├── launch.R                 # Entry point: arbuilder::launch()
│   ├── app_ui.R                 # Top-level UI assembly
│   ├── app_server.R             # Top-level server wiring
│   │
│   ├── # ── DATA LAYER ──────────────────────────
│   ├── mod_data.R               # Load ADaM datasets (upload/bundled)
│   ├── mod_data_filter.R        # Population filter (SAFFL, ITTFL, etc.)
│   ├── mod_data_preview.R       # Raw ADaM data browser
│   │
│   ├── # ── ARD LAYER ───────────────────────────
│   ├── mod_analysis.R           # Analysis type picker
│   ├── mod_grouping.R           # Treatment var, by-vars, strata
│   ├── mod_stats.R              # Which statistics (n, mean, SD, %)
│   ├── mod_ard_preview.R        # Preview generated ARD wide table
│   │
│   ├── ard_demog.R              # Demographics (ADSL)
│   ├── ard_disp.R               # Disposition (ADSL)
│   ├── ard_ae.R                 # AE summary SOC/PT (ADAE+ADSL)
│   ├── ard_cm.R                 # Concomitant meds (ADCM+ADSL)
│   ├── ard_exposure.R           # Exposure/dosing (ADSL/ADEX)
│   ├── ard_vitals.R             # Vital signs (ADVS)
│   ├── ard_labs.R               # Laboratory results (ADLB)
│   ├── ard_shift.R              # Shift tables (ADLB/ADEG/ADQS)
│   ├── ard_efficacy_cont.R      # Continuous efficacy (ADEFF/ADQS)
│   ├── ard_efficacy_cat.R       # Categorical efficacy (ADRS)
│   ├── ard_tte.R                # Time-to-event (ADTTE)
│   ├── ard_ecg.R                # ECG/cardiac (ADEG)
│   ├── ard_pk.R                 # Pharmacokinetics (ADPC/ADPPK)
│   ├── ard_custom.R             # User-defined analysis (any)
│   │
│   ├── # ── FORMAT LAYER ────────────────────────
│   ├── mod_titles.R             # Titles + footnotes
│   ├── mod_cols.R               # Column widths, labels, alignment
│   ├── mod_header.R             # Header styling + N-counts
│   ├── mod_styles.R             # Row/col/cell conditional styles
│   ├── mod_rules.R              # Hlines + vlines
│   ├── mod_page.R               # Margins, orientation, page head/foot
│   ├── mod_spans.R              # Column spanning headers
│   ├── mod_theme.R              # Save/load theme presets
│   │
│   ├── # ── OUTPUT LAYER ────────────────────────
│   ├── mod_preview.R            # Live HTML table preview
│   ├── mod_codegen.R            # Assembles full pipeline (data + arframe)
│   ├── mod_export.R             # Render RTF/PDF + download R script
│   │
│   ├── # ── BATCH LAYER ─────────────────────────
│   ├── mod_batch.R              # Multi-TFL project manager
│   │
│   ├── # ── UTILITIES ───────────────────────────
│   ├── utils_ui.R               # Shared UI helpers
│   ├── utils_reactive.R         # Shared reactive helpers
│   ├── utils_codegen.R          # Code string builders (glue templates)
│   ├── utils_formats.R          # Statistical format functions
│   ├── utils_ard.R              # Shared ARD computation helpers
│   └── utils_adam.R             # ADaM variable detection & validation
│
├── inst/
│   ├── specs/
│   │   ├── demog_default.yml    # Default analysis spec for demographics
│   │   ├── ae_default.yml       # Default analysis spec for AE summary
│   │   ├── disp_default.yml     # Default analysis spec for disposition
│   │   └── tte_default.yml      # Default analysis spec for TTE
│   └── www/
│       ├── styles.css           # Custom theme
│       ├── logo.svg             # Branding
│       └── tutorial.js          # First-run guided tour
│
├── tests/
│   └── testthat/
│       ├── test-mod_codegen.R
│       ├── test-mod_data.R
│       ├── test-ard_demog.R
│       ├── test-ard_ae.R
│       └── test-utils.R
│
├── man/
└── vignettes/
    └── getting-started.Rmd
```

---

## 5. Dependency Stack

```
arbuilder
├── arframe          # The engine — builds and renders TLFs
├── shiny            # App framework
├── bslib            # Modern Bootstrap 5 UI
├── DT               # Interactive data table preview
├── shinyAce         # Code editor (view generated R script)
├── htmltools        # HTML construction
├── shinyjs          # JS helpers (toggle, show/hide)
│
├── # ── TIDYVERSE (app + generated scripts) ──
├── dplyr            # Data manipulation in modules + output scripts
├── tidyr            # Reshape data for ARD wide format
├── purrr            # Iterate over module configs, map reactives
├── stringr          # String ops for codegen template building
├── tibble           # Tidy data structures throughout app
├── readr            # CSV import in mod_data + output scripts
├── forcats          # Factor handling in mod_styles filters
└── glue             # Code string interpolation in mod_codegen
```

**Tidyverse boundary:**
- `arframe` (engine) = NO tidyverse — stays lean for validation
- `arbuilder` (app) = YES tidyverse everywhere
- Generated R scripts = YES tidyverse (dplyr, tidyr, readr)

---

## 6. UI Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│  arbuilder                                  [Save Project] [Help]   │
├─────────────┬───────────────────────────────────────────────────────┤
│             │                                                       │
│  DATA       │  ┌─ PREVIEW ──────────────────────────────────────┐  │
│  ▸ Source   │  │                                                 │  │
│  ▸ Filter   │  │  Table 14.1.1                                  │  │
│  ▸ Browse   │  │  Summary of Demographic and                     │  │
│             │  │  Baseline Characteristics                       │  │
│  ANALYSIS   │  │  Safety Population                              │  │
│  ▸ Type     │  │                                                 │  │
│  ▸ Grouping │  │  ┌──────────┬─────────┬─────────┬─────────┐   │  │
│  ▸ Stats    │  │  │          │ Drug A  │ Drug A  │ Placebo │   │  │
│  ▸ ARD View │  │  │          │ 200mg   │ 400mg   │         │   │  │
│             │  │  │          │ (N=100) │ (N=100) │ (N=50)  │   │  │
│  FORMAT     │  │  ├──────────┼─────────┼─────────┼─────────┤   │  │
│  ▸ Titles   │  │  │ Age (yr) │         │         │         │   │  │
│  ▸ Columns  │  │  │  Mean    │  57.3   │  58.1   │  58.5   │   │  │
│  ▸ Header   │  │  │  SD     │  11.8   │  12.2   │  11.5   │   │  │
│  ▸ Spans    │  │  │ Sex      │         │         │         │   │  │
│  ▸ Styles   │  │  │  Male    │56 (56%) │55 (55%) │28 (56%) │   │  │
│  ▸ Rules    │  │  │  Female  │44 (44%) │45 (45%) │22 (44%) │   │  │
│  ▸ Page     │  │  └──────────┴─────────┴─────────┴─────────┘   │  │
│             │  │                                                 │  │
│  THEME      │  │  Source: ADSL   Program: t_14_1_1.R             │  │
│  ▸ Presets  │  └─────────────────────────────────────────────────┘  │
│             │                                                       │
│  EXPORT     │  ┌─ R CODE ───────────────────────────────────────┐  │
│  [RTF]      │  │  library(arframe)                               │  │
│  [PDF]      │  │  library(dplyr)                                 │  │
│  [R Script] │  │  library(readr)                                 │  │
│             │  │                                                 │  │
│             │  │  # --- Load & filter ADaM ---                   │  │
│             │  │  adsl <- read_csv("data/adsl.csv") |>           │  │
│             │  │    filter(SAFFL == "Y")                         │  │
│             │  │                                                 │  │
│             │  │  # --- Build ARD wide ---                       │  │
│             │  │  tbl_demog <- adsl |>                           │  │
│             │  │    group_by(TRT01A) |>                          │  │
│             │  │    summarise(...)  |>                            │  │
│             │  │    pivot_wider(...)                              │  │
│             │  │                                                 │  │
│             │  │  # --- Format & render ---                      │  │
│             │  │  tbl_demog |>                                   │  │
│             │  │    fr_table() |>                                │  │
│             │  │    fr_titles(...) |>                             │  │
│             │  │    fr_render("t_14_1_1.rtf")                    │  │
│             │  │                                        [Copy]  │  │
│             │  └─────────────────────────────────────────────────┘  │
└─────────────┴───────────────────────────────────────────────────────┘
```

---

## 7. Module Detail

### 7.1 mod_data — ADaM Data Source

```
┌─ DATA SOURCE ──────────────────────────────────────┐
│                                                     │
│  Source:  ○ Upload ADaM datasets                    │
│          ○ Upload pre-summarized data               │
│          ○ Bundled sample data (adam_pilot)          │
│                                                     │
│  ── ADaM Datasets (upload multiple) ──────────     │
│  [+ Upload files]                                   │
│                                                     │
│  ┌────────┬──────┬──────┬──────────┬────────────┐  │
│  │ Name   │ Rows │ Cols │ ADaM     │ Builders   │  │
│  ├────────┼──────┼──────┼──────────┼────────────┤  │
│  │ adsl   │ 250  │ 40   │ ADSL     │ demog,disp │  │
│  │ adae   │ 1305 │ 31   │ ADAE     │ ae         │  │
│  │ adtte  │ 726  │ 13   │ ADTTE    │ tte        │  │
│  └────────┴──────┴──────┴──────────┴────────────┘  │
│                                                     │
│  ── Population Filter ─────────────────────────    │
│  Flag variable: [SAFFL  ▾]                          │
│  Filter:        [== "Y" ▾]                          │
│  Resulting N:   248 subjects                        │
│                                                     │
│  ── Browse Raw Data ───────────────────────────    │
│  Dataset: [adsl ▾]     (interactive DT table)       │
└─────────────────────────────────────────────────────┘
```

**Auto-detection:** Uses `adam_detect()` (from adam_pilot prototype) to classify each uploaded file and suggest available ARD builders.

### 7.2 mod_analysis — Analysis Type Picker

```
┌─ ANALYSIS TYPE ─────────────────────────────────────┐
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ (●) Demographics          (adsl)            │   │
│  │ ( ) Disposition           (adsl)             │   │
│  │ ( ) AE Summary by SOC/PT  (adae)            │   │
│  │ ( ) Exposure              (adsl/adex)        │   │
│  │ ( ) Vital Signs           (advs)             │   │
│  │ ( ) Laboratory Results    (adlb)             │   │
│  │ ( ) Shift Table           (adlb/adeg)        │   │
│  │ ( ) Time-to-Event         (adtte)            │   │
│  │ ( ) Tumor Response        (adrs)             │   │
│  │ ( ) Continuous Efficacy   (adeff)            │   │
│  │ ( ) ECG / Cardiac         (adeg)             │   │
│  │ ( ) PK Summary            (adpc)             │   │
│  │ ( ) Custom Analysis       (any)              │   │
│  └─────────────────────────────────────────────┘   │
│                                                     │
│  Each type auto-configures default grouping,        │
│  statistics, row structure, and titles.              │
└─────────────────────────────────────────────────────┘
```

### 7.3 mod_grouping — Treatment & Analysis Variables

```
┌─ GROUPING ──────────────────────────────────────────┐
│                                                     │
│  Treatment variable: [TRT01A       ▾]               │
│  (auto-detected: TRT01A, TRT01P, TRTA, TRTP)       │
│                                                     │
│  Treatment values:                                  │
│  [✓] Drug A 200mg  (n=100)                          │
│  [✓] Drug A 400mg  (n=100)                          │
│  [✓] Placebo       (n=50)                           │
│                                                     │
│  Include Total column: [✓]                          │
│                                                     │
│  ── Analysis Variables (Demographics) ──────────   │
│  [✓] AGE     Continuous   (mean, SD, median, range) │
│  [✓] SEX     Categorical  (n, %)                    │
│  [✓] RACE    Categorical  (n, %)                    │
│  [✓] ETHNIC  Categorical  (n, %)                    │
│  [✓] BMIBL   Continuous   (mean, SD, median, range) │
│  [ ] HEIGHTBL Continuous                             │
│  [ ] WEIGHTBL Continuous                             │
│                                                     │
│  Auto-detect: numeric = continuous,                  │
│               character/factor = categorical         │
└─────────────────────────────────────────────────────┘
```

### 7.4 mod_stats — Statistics Configuration

```
┌─ STATISTICS ────────────────────────────────────────┐
│                                                     │
│  ── Continuous Variables ────────────────────────   │
│  [✓] N                                              │
│  [✓] Mean (SD)     Format: [{mean} ({sd})]          │
│  [✓] Median        Format: [{median}]               │
│  [✓] Q1, Q3       Format: [{q1}, {q3}]             │
│  [✓] Min, Max     Format: [{min}, {max}]           │
│  [ ] Geometric Mean (CV%)                           │
│                                                     │
│  Decimal places: [1 ▾]                              │
│                                                     │
│  ── Categorical Variables ──────────────────────   │
│  [✓] n (%)         Format: [{n} ({pct}%)]           │
│  [ ] n only                                         │
│  [ ] n/N (%)                                        │
│                                                     │
│  Zero style: ○ Style A (show 0.0)                   │
│              ○ Style D (show n only)                 │
│  Denominator: (●) Big N  ( ) Column N  ( ) Row N    │
│  Decimal for %: [1 ▾]                               │
└─────────────────────────────────────────────────────┘
```

### 7.5 mod_ard_preview — ARD Wide Table Preview

```
┌─ ARD WIDE TABLE (generated from ADaM) ──────────────┐
│                                                      │
│  Status: Generated 12 rows × 4 cols from adsl       │
│                                                      │
│  ┌──────────┬───────────┬───────────┬───────────┐   │
│  │ param    │ Drug A    │ Drug A    │ Placebo   │   │
│  │          │ 200mg     │ 400mg     │           │   │
│  │          │ (N=100)   │ (N=100)   │ (N=50)    │   │
│  ├──────────┼───────────┼───────────┼───────────┤   │
│  │ Age (yr) │           │           │           │   │
│  │   N      │ 100       │ 100       │ 50        │   │
│  │   Mean   │ 57.3      │ 58.1      │ 58.5      │   │
│  │   (SD)   │ (11.8)    │ (12.2)    │ (11.5)    │   │
│  │   Median │ 57.0      │ 58.0      │ 59.0      │   │
│  │   Range  │ 19, 87    │ 21, 89    │ 25, 84    │   │
│  │ Sex      │           │           │           │   │
│  │   Male   │ 56 (56.0%)│ 55 (55.0%)│ 28 (56.0%)│  │
│  │   Female │ 44 (44.0%)│ 45 (45.0%)│ 22 (44.0%)│  │
│  └──────────┴───────────┴───────────┴───────────┘   │
│                                                      │
│  [Edit manually]  [Refresh]  [Export as CSV]         │
└──────────────────────────────────────────────────────┘
```

### 7.6 mod_titles — Titles & Footnotes

```
┌─ TITLES & FOOTNOTES ────────────────────────────────┐
│                                                     │
│  Title 1:  [Table 14.1.5                        ]   │
│  Title 2:  [Summary of Demographic and           ]  │
│  Title 3:  [Baseline Characteristics             ]  │
│  + Add title line                                   │
│                                                     │
│  Population: [Safety Population                 ]   │
│  Align:      [center ▾]                             │
│                                                     │
│  ── Footnotes ──────────────────────────────────   │
│  1: [Percentages based on N in each group    ]     │
│  2: [SD = Standard Deviation                 ]     │
│  + Add footnote                                     │
│                                                     │
│  Source:  [ADSL                              ]      │
└─────────────────────────────────────────────────────┘
```

### 7.7 mod_cols — Column Configuration

```
┌─ COLUMNS ───────────────────────────────────────────┐
│                                                     │
│  ┌────────┬──────────────┬───────┬────────┬──────┐ │
│  │ Column │ Label        │ Width │ Align  │ Show │ │
│  ├────────┼──────────────┼───────┼────────┼──────┤ │
│  │ param  │ [Parameter]  │ [2.0] │ [left] │ [✓]  │ │
│  │ trt1   │ [Drug A 200] │ [auto]│ [ctr ] │ [✓]  │ │
│  │ trt2   │ [Drug A 400] │ [auto]│ [ctr ] │ [✓]  │ │
│  │ trt3   │ [Placebo   ] │ [auto]│ [ctr ] │ [✓]  │ │
│  └────────┴──────────────┴───────┴────────┴──────┘ │
│                                                     │
│  Width mode: ○ Auto  ○ Equal  ○ Custom              │
└─────────────────────────────────────────────────────┘
```

### 7.8 mod_header, mod_rules, mod_page, mod_theme

(Same wireframes as in ARFRAME-PLAN.txt — header bold/bg/N-counts, hline presets, page margins/orientation/tokens, theme save/load.)

### 7.9 mod_batch — Multi-TFL Project Manager

```
┌─ BATCH MANAGER ─────────────────────────────────────────────┐
│                                                             │
│  Project: [ARFR-2025-001 Phase III CSR ▾]                   │
│                                                             │
│  ┌────┬────────────┬──────────────────┬────────┬──────────┐│
│  │ #  │ Output ID  │ Title            │ Status │ Actions  ││
│  ├────┼────────────┼──────────────────┼────────┼──────────┤│
│  │ 1  │ t_14_1_5   │ Demographics     │ ✓ Done │ Edit  ⬇  ││
│  │ 2  │ t_14_3_1_2 │ TEAE Summary     │ ✓ Done │ Edit  ⬇  ││
│  │ 3  │ t_14_1_3   │ Disposition      │ ⚙ WIP  │ Edit  ⬇  ││
│  │ 4  │ t_14_2_1_1 │ Time to Event    │ ○ New  │ Edit     ││
│  └────┴────────────┴──────────────────┴────────┴──────────┘│
│                                                             │
│  [+ New Table]  [+ New Listing]  [+ New Figure]            │
│  [▶ Render All]  [⬇ Download All (.zip)]                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. Data Flow

```
┌──────────┐
│ mod_data │──▶ reactiveValues$datasets  (list of ADaM tibbles)
└──────────┘    reactiveValues$pop_flag  (e.g. "SAFFL")
                reactiveValues$pop_n     (big N per treatment)
                       │
                       ▼
  ┌────────────────────────────────────────────────────┐
  │                    ARD LAYER                       │
  │                                                    │
  │  ┌─────────────┐ ┌────────────┐ ┌──────────────┐ │
  │  │mod_analysis │ │mod_grouping│ │  mod_stats   │ │
  │  │ type picker │ │ trt var    │ │  n, mean, %  │ │
  │  └──────┬──────┘ └─────┬──────┘ └──────┬───────┘ │
  │         └───────┬──────┴───────┬───────┘          │
  │                 ▼                                  │
  │         ┌───────────────┐                          │
  │         │ ard_demog.R   │  (or ard_ae, ard_tte..) │
  │         │ dplyr pipeline│                          │
  │         └───────┬───────┘                          │
  │                 ▼                                  │
  │         ┌────────────────┐                         │
  │         │mod_ard_preview │──▶ ARD wide tibble      │
  │         └────────────────┘                         │
  └────────────────────────────────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
   ┌──────────┐  ┌──────────┐  ┌──────────┐
   │mod_titles│  │ mod_cols │  │mod_header│  ... other format modules
   └────┬─────┘  └────┬─────┘  └────┬─────┘
        └──────────────┼─────────────┘
                       ▼
               ┌──────────────┐
               │ mod_codegen  │
               │              │──▶ reactive$spec  (fr_spec object)
               │ Builds TWO   │──▶ reactive$code  (R script string)
               │ sections:    │
               │ 1. Data prep │
               │ 2. arframe   │
               └──────┬───────┘
                      │
               ┌──────┴──────┐
               ▼             ▼
         ┌───────────┐ ┌───────────┐
         │mod_preview│ │mod_export │
         │ HTML table│ │ ⬇ RTF    │
         │ live      │ │ ⬇ PDF    │
         └───────────┘ │ ⬇ .R     │
                       └───────────┘
```

---

## 9. ARD Builders — Complete Catalog

### Naming Convention

Each builder maps to a specific ADaM domain. No mixing.

| Builder | ADaM Source | Domain | TFL Count |
|---------|-----------|--------|-----------|
| `ard_demog` | ADSL | Subject demographics | 6 |
| `ard_disp` | ADSL | Disposition | 1 |
| `ard_ae` | ADAE+ADSL | Adverse events (all variants) | 35 |
| `ard_cm` | ADCM+ADSL | Prior & concomitant meds | 3 |
| `ard_exposure` | ADSL/ADEX | Exposure, dose, compliance | 8 |
| `ard_vitals` | ADVS | Vital signs BDS | 3 |
| `ard_labs` | ADLB | Laboratory results BDS | 6 |
| `ard_shift` | ADLB/ADEG/ADQS | Shift tables (any BDS) | 10 |
| `ard_efficacy_cont` | ADEFF/ADQS | Continuous efficacy BDS | 3 |
| `ard_efficacy_cat` | ADRS | Categorical/binary efficacy | 6 |
| `ard_tte` | ADTTE | Time-to-event / survival | 6 |
| `ard_ecg` | ADEG | ECG / cardiac safety | 1 |
| `ard_pk` | ADPC/ADPPK | Pharmacokinetics | * |
| `ard_custom` | any | User-defined | 1 |
| **Total** | | | **91** |

### ADaM Auto-Detection

```r
adam_detect(data, dataset_name)
# Returns: adam_class, domain, builders, population_flags, treatment_vars, etc.
```

| Indicator | ADSL | BDS | OCCDS | ADTTE |
|-----------|------|-----|-------|-------|
| 1 row/subject | ✓ | | | |
| PARAMCD+AVAL | | ✓ | | ✓ |
| AEBODSYS/AEDECOD | | | ✓ (ADAE) | |
| CMCLAS/CMDECOD | | | ✓ (ADCM) | |
| CNSR variable | | | | ✓ |

### Non-Standard Variable Handling

1. **Custom PARAMCD** — auto-detect all unique values, show in UI
2. **Custom flags (*FL)** — scan for all *FL columns, present in filter
3. **Treatment var variants** — check TRT01A, TRT01P, TRTA, TRTP
4. **DTYPE** — user picks observed vs LOCF/WOCF
5. **BASETYPE** — dropdown if multiple baseline definitions
6. **ANLzzFL** — user selects analysis flag
7. **Sponsor variables** — shown in "Additional Variables" section

---

## 10. Statistical Format Coverage

All formats from `csr_stat_formats.txt` are covered:

| Category | Formats |
|----------|---------|
| Counts & N(%) | cnt, npct_a/d, nn_pct, ae_npct, resp_rate |
| Continuous | mean_sd (1/2/3 dec), median, IQR, min/max, stacked |
| Change from baseline | cfb_mean_sd, pct_cfb, cfb_stack |
| LS Means | lsmean_se, lsmean_diff, lsmean_full, trt_diff |
| Risk/Odds/HR | risk_diff, rel_risk, odds_ratio, cmh_or, haz_ratio |
| Survival/KM | km_median (with NR), km_rate, logrank_p |
| PK | gmean_cv, gmr_ci, pk_gmean_ci, pk_tmax, pk_thalf |
| Exposure | exp_dur, cum_dose, dose_int |
| Cardiac | qtcf_stack, qtcf_thresh |
| Shift | lab_shift, npct |
| P-values | pval, pval_low/high, pval_adj |
| Missing/special | NR, NE, NC, BLQ, incomplete CIs, <0.1, >99.9 |

---

## 11. Generated R Script — What It Looks Like

The app generates **plain tidyverse + arframe code** — no special packages:

```r
# =============================================================================
# t_14_1_5.R — Demographics Summary
# Study: ARFR-2025-001 | Population: Safety
# Generated by arbuilder on 2026-03-15
# =============================================================================

library(arframe)
library(dplyr)
library(tidyr)
library(readr)

# --- Load & filter ADaM ---
adsl <- read_csv("data/adsl.csv") |>
  filter(SAFFL == "Y")

big_n <- adsl |>
  count(TRT01A, name = "N") |>
  bind_rows(tibble(TRT01A = "Total", N = nrow(adsl)))

# --- Age (continuous) ---
age_stats <- adsl |>
  bind_rows(adsl |> mutate(TRT01A = "Total")) |>
  group_by(TRT01A) |>
  summarise(
    N      = as.character(n()),
    Mean   = sprintf("%.1f", mean(AGE, na.rm = TRUE)),
    SD     = sprintf("(%.2f)", sd(AGE, na.rm = TRUE)),
    Median = sprintf("%.1f", median(AGE, na.rm = TRUE)),
    Range  = sprintf("%g, %g", min(AGE), max(AGE))
  ) |>
  pivot_longer(-TRT01A, names_to = "stat") |>
  pivot_wider(names_from = TRT01A) |>
  mutate(param = "Age (yr)", .before = 1)

# --- Sex (categorical) ---
sex_stats <- adsl |>
  bind_rows(adsl |> mutate(TRT01A = "Total")) |>
  count(TRT01A, SEX) |>
  left_join(big_n, by = "TRT01A") |>
  mutate(value = sprintf("%d (%.1f%%)", n, n / N * 100)) |>
  select(TRT01A, stat = SEX, value) |>
  pivot_wider(names_from = TRT01A) |>
  mutate(param = "Sex", .before = 1)

# --- Stack & render ---
tbl_demog <- bind_rows(age_stats, sex_stats)

tbl_demog |>
  fr_table() |>
  fr_titles(
    "Table 14.1.5",
    "Summary of Demographic and Baseline Characteristics",
    population = "Safety Population"
  ) |>
  fr_footnotes("Percentages based on N in each treatment group.") |>
  fr_cols(
    param = fr_col(label = "Parameter", width = 2, align = "left"),
    .align = "center"
  ) |>
  fr_header(bold = TRUE) |>
  fr_hlines("standard") |>
  fr_page(orientation = "landscape") |>
  fr_render("t_14_1_5.rtf")
```

---

## 12. Key Design Principles

1. **arframe is just a library** — arbuilder calls `fr_table()`, `fr_cols()`, etc. like any user would. No special internal APIs.

2. **Modules are independent** — each owns its UI + server, returns a reactive. Modules don't talk to each other directly.

3. **mod_codegen is the single integration point** — consumes all module reactives, uses glue + purrr to build the pipeline string.

4. **Two outputs ALWAYS** — every table produces (a) the rendered RTF/PDF and (b) the reproducible R script. The R script IS the audit trail.

5. **No server needed** — `launch()` opens in local browser. Zero deployment.

6. **Code generator, not a black box** — users see exactly what R code produces their output. They can modify and run it outside arbuilder.

7. **Tidyverse boundary** — arframe stays lean (no tidyverse). arbuilder and generated scripts use tidyverse freely.

8. **Plain dplyr, no cards/cardx** — generated scripts use standard `group_by() |> summarise()`. Any programmer can read them.

---

## 13. Build Phases

### Phase 1 — MVP (Demographics table, end-to-end)

**DATA LAYER:**
- `mod_data` — upload ADaM CSVs + bundled adam_pilot data
- `mod_data_filter` — population flag filter (SAFFL, ITTFL)
- `mod_data_preview` — browse raw ADaM with DT

**ARD LAYER (demographics only):**
- `mod_analysis` — type picker (only "Demographics" in Phase 1)
- `mod_grouping` — treatment var, analysis variables
- `mod_stats` — pick statistics (n, mean, SD, %)
- `mod_ard_preview` — view generated ARD wide table
- `ard_demog.R` — dplyr pipeline: adsl → tbl_demog

**FORMAT LAYER:**
- `mod_titles` — titles, footnotes, population
- `mod_cols` — labels, widths, alignment
- `mod_header` — bold, background color
- `mod_rules` — presets only (standard, minimal, grid)
- `mod_page` — orientation, margins

**OUTPUT LAYER:**
- `mod_preview` — live HTML preview
- `mod_codegen` — generates full R script (data prep + arframe)
- `mod_export` — RTF download + R script download

### Phase 2 — Safety tables (AE, Disposition, Exposure)

- `ard_ae.R` — AE summary by SOC/PT (ADAE+ADSL)
- `ard_disp.R` — Disposition summary (ADSL)
- `ard_exposure.R` — Exposure/dosing (ADSL/ADEX)
- `mod_styles` — conditional row/col/cell styles
- `mod_spans` — column spanning headers
- `mod_header` — N-counts, font size, valign
- `mod_theme` — save/load presets, YAML import/export
- `mod_page` — page header/footer with tokens
- `mod_export` — PDF support

### Phase 3 — Labs + Vitals + Shifts + Efficacy

- `ard_vitals.R` — Vital signs (ADVS)
- `ard_labs.R` — Laboratory results (ADLB)
- `ard_shift.R` — Shift tables (ADLB, ADEG, ADQS)
- `ard_efficacy_cont.R` — Continuous efficacy (ADEFF/ADQS)
- `ard_efficacy_cat.R` — Categorical/binary efficacy (ADRS)
- `ard_tte.R` — Time-to-event (ADTTE + survival)
- `ard_cm.R` — Concomitant medications (ADCM+ADSL)

### Phase 4 — ECG, PK, Custom + Batch

- `ard_ecg.R` — Cardiac safety QTcF (ADEG)
- `ard_pk.R` — Pharmacokinetic summary (ADPC/ADPPK)
- `ard_custom.R` — User-defined analysis (any dataset)
- `mod_batch` — multi-TFL project manager
- Render all, project save/load (.arproj), shell import

### Phase 5 — Listings & Figures

- `mod_listing` — listing-specific config (long tables)
- `mod_figure` — `fr_figure()` wrapper with ggplot2
- `mod_batch` — mixed tables + listings + figures

---

## 14. Test Data

All development uses `adam_pilot` datasets:

```r
source("/home/vignesh/R_Projects/adam_pilot/R/init.R")
load_adam()
```

| Dataset | Class | Rows | Cols | Subjects |
|---------|-------|------|------|----------|
| adsl | ADSL | 250 | 40 | 250 |
| adae | OCCDS | 1,305 | 31 | 207 |
| adcm | OCCDS | 1,539 | 19 | 250 |
| adtte | ADTTE | 726 | 13 | 250 |
| advs | BDS | 12,678 | 38 | 250 |
| adlb | BDS | 24,996 | 39 | 250 |
| adeg | BDS | 9,402 | 27 | 250 |
| adrs | BDS | 1,970 | 15 | 250 |
| adeff | BDS | 5,000 | 22 | 250 |
| adex | BDS | 1,000 | 17 | 250 |
| adpc | BDS | 2,758 | 17 | 200 |

Treatment effects built in across all domains for meaningful test results.

---

## 15. Naming

| Package | Full Name | Role |
|---------|-----------|------|
| arframe | Analysis Results Frame | Engine (pure R, no UI) |
| arbuilder | (name TBD) | Shiny app (local, modular) |

Candidates for Shiny app name: arstudio, arbuilder, ardesk, arworks.
Function prefix: `fr_` (unchanged in arframe).
Shiny app name is placeholder — find-and-replace when decided.
