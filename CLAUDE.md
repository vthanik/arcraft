# CLAUDE.md — arbuilder

Local Shiny app for building submission-ready TFLs from ADaM data. Uses `arframe` (currently `tlframe`) as the rendering engine. No server needed — runs on a laptop.

## Quick Context

- **arframe** (`tlframe`) = the rendering engine (pure R, no UI) — already built at `../tlframe/`
- **arbuilder** = this project — Shiny app that takes ADaM → ARD wide → arframe → RTF/PDF
- **adam_pilot** = test datasets at `../adam_pilot/` — 11 synthetic ADaM datasets, 250 subjects

## Plans

- `PLAN.md` — full arbuilder implementation plan (803 lines, read this first)
- `ARFRAME-PLAN.txt` — master plan with stat formats, TFL catalog, ADaM specs

## Phase 1 MVP Target

Demographics table end-to-end: upload ADSL → pick demographics → configure stats → preview → export RTF + R script.

Modules for Phase 1:
- `mod_data`, `mod_data_filter`, `mod_data_preview`
- `mod_analysis`, `mod_grouping`, `mod_stats`, `mod_ard_preview`
- `ard_demog`
- `mod_titles`, `mod_cols`, `mod_header`, `mod_rules`, `mod_page`
- `mod_preview`, `mod_codegen`, `mod_export`

## Dependencies

shiny, bslib, DT, shinyAce, htmltools, shinyjs + tidyverse (dplyr, tidyr, purrr, stringr, tibble, readr, forcats, glue) + arframe (tlframe).

## Commands

```bash
Rscript -e "shiny::runApp('.')"
```

## Test Data

```r
source("../adam_pilot/R/init.R")
load_adam()
```

## Coding Conventions

- Shiny modules: `mod_*.R` with `*_ui(id)` and `*_server(id, ...)`
- ARD builders: `ard_*.R` — one per ADaM domain, plain dplyr
- Generated scripts: plain tidyverse + arframe, no special packages
- UI: bslib Bootstrap 5, accordion sidebar
- All reactive outputs are tibbles or lists
- mod_codegen is the single integration point
