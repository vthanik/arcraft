# arbuilder

Local Shiny app for building submission-ready clinical Tables, Figures & Listings (TFLs) from ADaM data. Point-and-click interface that generates reproducible R scripts using [arframe](https://github.com/vthanik/arframe) as the rendering engine.

No server infrastructure needed — runs entirely on your laptop.

## Quick Start

```bash
git clone git@github.com:vthanik/arbuilder.git
cd arbuilder
Rscript -e "shiny::runApp('.')"
```

## Prerequisites

- **R** >= 4.1.0
- **arframe** — rendering engine ([install from GitHub](https://github.com/vthanik/arframe))

### Install Dependencies

```r
# Install arframe first
remotes::install_github("vthanik/arframe")

# Install CRAN dependencies
install.packages(c(
  "shiny", "bslib", "htmltools", "dplyr", "tidyr",
  "tibble", "readr", "glue", "reactable", "rlang"
))
```

### Or Install as R Package

```r
remotes::install_github("vthanik/arbuilder")
arbuilder::launch()
```

## How It Works

1. **Load Data** — select ADaM datasets (CDISC pilot data bundled) or upload your own (.rds, .csv)
2. **Select Template** — choose Demographics (more templates coming)
3. **Configure Analysis** — treatment variable, group variable, per-variable statistics
4. **Format Output** — titles, footnotes, columns, headers, page layout, rules
5. **Generate Preview** — Ctrl+Enter renders the table instantly
6. **Export** — download RTF/PDF/HTML + standalone R script

## Bundled Data

10 CDISC pilot datasets from [pharmaverseadam](https://pharmaverse.github.io/pharmaversesdtm/):

| Dataset | Rows | Description |
|---------|------|-------------|
| ADSL | 306 | Subject-level demographics |
| ADAE | 1,191 | Adverse events |
| ADCM | 7,510 | Concomitant medications |
| ADEX | 6,315 | Exposure |
| ADLB | 83,652 | Laboratory results |
| ADMH | 1,818 | Medical history |
| ADRS | 3,694 | Tumor response |
| ADTR | 181 | Tumor results |
| ADTTE | 512 | Time-to-event |
| ADVS | 65,032 | Vital signs |

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+1-5 | Switch tabs (Data/Template/Analysis/Format/Output) |
| Ctrl+Enter | Generate preview |
| Ctrl+S | Export RTF |
| Ctrl+Shift+S | Download R script |
| Ctrl+B | Toggle sidebar |

## Architecture

```
ADaM Data → ARD (wide) → arframe spec → RTF/PDF/HTML
                ↓
         R script (reproducible)
```

- **arframe** = rendering engine (pure R, no UI)
- **arbuilder** = this app (Shiny UI that drives arframe)
- Generated R scripts are standalone — run anywhere with `dplyr` + `arframe`

## Project Structure

```
R/
  app_ui.R / app_server.R    # Shiny app shell
  mod_*.R                     # UI modules (data, template, analysis, format, output)
  fct_ard_demog.R             # Demographics ARD builder
  fct_render.R                # arframe rendering (consumes IR)
  fct_codegen.R               # R script generator (consumes IR)
  fct_spec_ir.R               # Shared intermediate representation
  spec_demog.R                # Demographics template defaults

inst/
  app/www/                    # CSS, JS, highlight.js
  data/                       # Bundled CDISC pilot datasets (.rds)

tests/
  testthat/                   # 57+ regression tests
```

## Corporate Proxy

If behind a firewall for first-time package installs:

```r
Sys.setenv(http_proxy = "http://proxy:port", https_proxy = "http://proxy:port")
```

## License

MIT
