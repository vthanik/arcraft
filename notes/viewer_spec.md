# arbuilder Data Viewer — Design Spec

## Layout: Three-Panel (like Data Wrangler Viewing Mode)

```
┌─────────────────────────────────────────────────────────────────┐
│ Toolbar: [Dataset ▾] [250 rows × 40 cols]  [Go to Col] [CSV]  │
├──────────────────────────────────────┬──────────────────────────┤
│                                      │                          │
│  DATA GRID                           │  SUMMARY PANEL           │
│  (reactable, full width)             │  (click column to view)  │
│                                      │                          │
│  ┌──────┬──────┬──────┬──────┐      │  ── AGE ──────────       │
│  │ CHR  │ NUM  │ CHR  │ NUM  │      │  Type: Numeric           │
│  │USUBJ │ AGE  │ SEX  │BMIBL │      │  Non-null: 250           │
│  │▒▒▒▒▒ │▒▒▒▒▒▒│▒▒▒▒▒ │▒▒▒▒▒▒│     │  Missing: 0 (0%)        │
│  │ 3 mis│ 0 mis│ 0 mis│ 2 mis│      │  Unique: 62              │
│  ├──────┼──────┼──────┼──────┤      │  Mean: 57.4              │
│  │filter│filter│filter│filter│      │  SD: 11.9                │
│  ├──────┼──────┼──────┼──────┤      │  Min: 19  Max: 89        │
│  │val   │ val  │ val  │ val  │      │  Q1: 49  Q3: 66          │
│  │val   │ val  │ val  │ val  │      │                          │
│  │val   │ val  │ val  │ val  │      │  [Histogram]             │
│  └──────┴──────┴──────┴──────┘      │                          │
│                                      │                          │
├──────────────────────────────────────┴──────────────────────────┤
│ Status: Showing 1-30 of 250 rows · 40 columns                  │
└─────────────────────────────────────────────────────────────────┘
```

## P0 Features (must have)

1. **Column headers**: type badge + name + mini histogram/bars + missing count
2. **Per-column filters**: text input for search, built into reactable
3. **Sorting**: click header to sort asc/desc
4. **Summary panel**: right sidebar, updates on column click
5. **Global search**: search bar in toolbar
6. **Row/col count**: status display
7. **Column resizing**: drag borders
8. **Missing value styling**: distinct visual for NA
9. **CSV download**
10. **Go to Column**: searchable column picker
11. **ADaM variable labels**: show label attribute in header tooltip

## Implementation: reactable + custom column click + summary panel
