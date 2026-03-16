# VS Code Data Wrangler -- Complete Feature Inventory

Compiled 2026-03-16 from official docs, blog posts, GitHub repo, Fabric docs, and community tutorials.

Purpose: Reference for building a Shiny equivalent in arbuilder that matches or exceeds every feature.

---

## 1. Grid / Table UI

### Data Grid
- Full scrollable pane (horizontal + vertical) displaying entire dataset
- Virtual scrolling for large datasets (default sample: first 5,000 rows; custom sample dialog for size + method)
- Rows displayed with alternating background for readability
- Cells rendered with type-specific formatting (numbers right-aligned, text left-aligned, dates formatted)
- Missing/null values visually distinct -- blank cells auto-detected and highlighted
- Data diff overlay: when previewing an operation, changed cells are highlighted (green for new values, red/strikethrough for removed)
- Real-time preview of operation effects before committing

### Row Display
- Row numbers shown on left edge (zero-indexed in pandas style)
- No explicit "frozen row" feature, but column headers are sticky/fixed during vertical scroll
- Custom sample options: first N rows, last N rows, or random sample

### Cell Rendering
- Type-aware display: numeric, text, categorical, boolean, datetime each rendered differently
- Truncated long text with ellipsis; hover or click to expand
- Missing values shown as visually distinct empty cells (not the text "NaN")

### Selection
- Click to select a column -- updates Summary panel to show that column's stats
- Column header click for sort toggle
- Right-click context menu on column headers for quick operations

---

## 2. Column Headers ("Quick Insights Header")

Each column header contains multiple layers of information:

### Column Name
- Displayed prominently at top of header
- Editable via Rename operation
- Right-click context menu for quick operations (rename, sort, drop, filter, change type)

### Data Type Icon/Badge
- Visual indicator showing column type: numeric, text/string, categorical, boolean, datetime
- Type badge displayed next to or below the column name
- Determines which visualizations and operations are available

### Mini Visualization (in-header)
- **Numeric columns**: Binned histogram showing distribution directly in the header
- **Categorical/text columns**: Frequency bar chart showing top value counts
- **Boolean columns**: Binary proportion bar
- **Datetime columns**: Timeline distribution
- Visualization only appears if column is cast to the correct type
- Can be hidden/shown to maximize screen real estate (toggle in Views toolbar)

### Quick Stats in Header
- **Missing value count/indicator**: Auto-detected, visually flagged so you can spot blanks at a glance
- **Distinct value count**: Shows number of unique values
- These appear as small text/badges below the mini visualization

### Header Menu (dropdown/right-click)
- Sort ascending / descending
- Filter options (context-aware per column type)
- Smaller selection of column operations accessible directly from header menu
- Quick access to rename, drop, change type

---

## 3. Filtering

### Filter Access Points
- Column header dropdown menu
- Operations panel "Filter" operation
- Multiple filters can be applied simultaneously (AND logic across columns)

### Filter Types by Column Type

**Numeric columns:**
- Comparison operators: equals, not equals, greater than, less than, greater than or equal, less than or equal
- Range filtering (between min and max)
- Is missing / is not missing

**Text/String columns:**
- Contains substring
- Does not contain
- Equals (exact match)
- Starts with / ends with
- Match full string option
- Match case option
- Regular expression support
- Is missing / is not missing

**Categorical columns:**
- Multi-select from list of unique values
- Include/exclude specific categories
- Is missing / is not missing

**Boolean columns:**
- True / False / Missing filter

**Datetime columns:**
- Date range filtering
- Before / after specific date
- Is missing / is not missing

### Filter Behavior
- Filters applied in Viewing mode affect display only (non-destructive)
- Filter operation in Editing mode generates Pandas code for row filtering
- Multiple conditions on the same column supported with shorthand syntax
- Unknown data types auto-cast to string type for filtering (compatibility mode)
- Active filters indicated visually

---

## 4. Sorting

### Sort Capabilities
- Single-column sort: click column header to toggle ascending/descending
- Sort operation in Operations panel for more control
- Sort ascending or descending by any column
- Sort by multiple columns (through repeated sort operations)

### Sort Indicators
- Visual arrow/indicator in column header showing current sort direction
- Active sort state persisted across operations

### Sort Compatibility
- Unknown data types cast to string for sorting (compatibility mode)
- All columns sortable regardless of content type

---

## 5. Column Operations (Complete List)

Operations are organized by category in the Operations panel. The panel is searchable.

### Sort and Filter
| Operation | Description |
|-----------|-------------|
| Sort | Sort entire dataframe by a column, ascending or descending |
| Filter | Filter rows based on one or more conditions |

### Encoding / Categorical
| Operation | Description |
|-----------|-------------|
| One-hot encode | Create new columns for each unique value, indicating presence (1) or absence (0) per row |
| Multi-label binarizer | Split delimited data and create binary columns for each category |

### Schema / Column Management
| Operation | Description |
|-----------|-------------|
| Drop column | Delete one or more columns |
| Select column | Choose columns to keep; delete all others |
| Rename column | Change a column's name |
| Clone column | Create a copy of an existing column |
| Change column type | Cast column to a different data type (int, float, string, datetime, bool, category) |

### Missing Data
| Operation | Description |
|-----------|-------------|
| Drop missing values | Remove rows containing missing values in specified column(s) |
| Fill missing values | Replace missing cells with a value: mean, median, mode, specific value, forward fill, back fill |
| Drop duplicate rows | Remove all rows with duplicate values in one or more columns |

### Text / String Operations
| Operation | Description |
|-----------|-------------|
| Calculate text length | Create column with character count of text values |
| Find and replace | Replace cells matching an exact pattern (supports: match full string, match case, regex) |
| Strip whitespace | Remove leading and trailing whitespace |
| Split text | Split column into multiple columns based on a delimiter |
| Capitalize first character | Capitalize the first letter of each text value |
| Convert text to lowercase | Transform all text to lowercase |
| Convert text to UPPERCASE | Transform all text to uppercase |

### Numeric Operations
| Operation | Description |
|-----------|-------------|
| Scale min/max values | Scale numeric column to a specified range (e.g., 0 to 1) |
| Round | Round numeric values to specified decimal places |
| Round down (floor) | Round numeric values down to nearest integer |
| Round up (ceiling) | Round numeric values up to nearest integer |

### Aggregation
| Operation | Description |
|-----------|-------------|
| Group by column and aggregate | Group rows by column values and compute aggregates (sum, mean, count, min, max, etc.) |

### AI-Powered / By Example (PROSE / Flash Fill)
| Operation | Description |
|-----------|-------------|
| New column by example | Provide examples of desired output; PROSE infers the transformation pattern and generates code |
| String transform by example | Transform string values by providing examples; PROSE writes the code |
| DateTime formatting by example | Format datetime values by providing examples of desired output format |
| Flash Fill | Automatically fill remaining rows in a new column based on user-provided examples |
| Create column from formula | Write custom Python expression to derive a new column |
| Custom operation | Free-form Python code for any transformation |

### AI Integration (newer versions)
| Operation | Description |
|-----------|-------------|
| GitHub Copilot integration | Natural language: "just ask it to perform the data operations you need" |

**Total: ~30+ built-in operations across 8+ categories**

---

## 6. Data Summary / Profile Panel

### Overall Dataset Summary (no column selected)
- Total row count
- Total column count
- Overall missing value count and percentage
- Memory usage
- Data types distribution across columns

### Column-Specific Summary (when a column is clicked)
Statistics vary by column data type:

**Numeric columns:**
- Count (non-null)
- Mean
- Standard deviation
- Min / Max
- Quartiles (25th, 50th/median, 75th percentile)
- Missing count and percentage
- Distinct/unique count
- Binned histogram visualization (larger than the in-header mini version)

**Text/Categorical columns:**
- Count (non-null)
- Unique count
- Top value and its frequency
- Missing count and percentage
- Frequency bar chart of top N values

**Boolean columns:**
- True count and percentage
- False count and percentage
- Missing count and percentage
- Proportion bar visualization

**Datetime columns:**
- Min date / Max date
- Date range
- Missing count and percentage
- Distinct count
- Timeline distribution visualization

### Visual Design of Summary Panel
- Located on the right side of the interface (in Viewing mode) or integrated into the layout
- Updates dynamically when column selection changes
- Contains both numeric stats and embedded visualizations (histograms, bar charts)
- Collapsible/hideable via Views toolbar

---

## 7. Search / Navigation

### Go to Column
- Toolbar button: "Go to Column"
- Opens search dialog to find and jump to a specific column by name
- Essential for wide datasets with many columns
- Fuzzy/partial matching for column names

### Operations Search
- Search bar within the Operations panel
- Type to filter available operations by name or keyword
- Operations organized in collapsible category groups
- Category expansion state persists across operations and is unique per Data Wrangler tab

### No Explicit Global Cell Search
- No "find text across all cells" feature documented
- Filtering serves as the primary mechanism for finding specific values

---

## 8. Toolbar

### Viewing Mode Toolbar
- **Mode Toggle**: Switch between Viewing and Editing modes
- **Go to Column**: Search/jump to a column
- **Views Tab**: Customize display layout -- show/hide Summary panel, column stats, Code Preview
- **Export**: Dropdown with export options

### Editing Mode Toolbar
- **Mode Toggle**: Switch back to Viewing mode
- **Go to Column**: Same column search
- **Views Tab**: Customize which panels are visible
- **Export Menu**: Code and file export options
- **Apply / Discard**: Buttons to commit or cancel a previewed operation (also appear inline near the code preview)

### Toolbar Design
- Positioned at top of the Data Wrangler interface
- Clean, minimal button row with icon + text labels
- VS Code native styling (integrates with editor theme)

---

## 9. Status Bar / Footer

### Information Displayed
- Row count (total rows in dataset)
- Column count (total columns)
- Active filter status indicator when filters are applied
- Sample size indicator when viewing a subset

### Design
- Bottom edge of the Data Wrangler pane
- Compact, single-line information bar
- Matches VS Code's status bar styling

---

## 10. Export Options

### Export to Notebook
- Generates a complete Python function wrapping all cleaning steps
- Function takes a DataFrame as input, returns cleaned DataFrame
- Added as a new cell in the active Jupyter Notebook
- Code does not auto-execute -- user must manually run the cell
- Original DataFrame is never overwritten (new variable assignment)

### Export to File
- Save cleaned data as CSV file
- Save cleaned data as Parquet file
- Downloads directly to local filesystem

### Copy Code to Clipboard
- Copies all generated Pandas code to system clipboard
- Can paste into any Python file or notebook

### Export Code to Python File
- Creates a new .py file with the generated code

### Code Generation Details
- Every operation generates corresponding Pandas/Python code
- Code is transparent, readable, and uses standard open-source libraries
- Code preview section shows generated code in real-time as operations are applied
- Users can edit generated code manually; changes reflect immediately in the data grid
- Exported functions are reusable and parameterized

---

## 11. Visual Design

### Layout Architecture
- **Four-panel layout** in Editing mode:
  1. **Left sidebar**: Operations panel (searchable operation list by category)
  2. **Center top**: Data Grid (main table view with Quick Insights headers)
  3. **Center bottom**: Code Preview pane (generated Python/Pandas code)
  4. **Right sidebar**: Data Summary panel (statistics + visualizations)
- **Simplified layout** in Viewing mode:
  1. **Center**: Data Grid with Quick Insights headers
  2. **Right**: Data Summary panel
  3. Operations panel hidden

### Color Scheme
- Follows VS Code theme (dark mode and light mode compatible)
- **Data diff highlighting**: Green background for new/changed values, red/strikethrough for removed
- **Missing values**: Visually distinct (typically lighter/grayed out cells)
- **Column type badges**: Color-coded by type (numeric, text, boolean, datetime, categorical)
- **Mini histograms**: Subtle blue/teal bars in column headers
- **Frequency bars**: Proportional bars in categorical column headers
- Clean white/dark grid lines matching VS Code's native look

### Typography
- Monospace font for data cells (consistent column alignment)
- Sans-serif for headers, labels, and UI chrome
- Small but readable font sizes optimized for data density
- Column names slightly bolder/larger than cell values

### Spacing and Density
- Compact row height for data density (see many rows at once)
- Adequate padding in headers for readability of stats + mini charts
- Resizable panel boundaries (drag to resize Operations, Summary, Code Preview panels)
- Responsive to screen size; customizable via Views tab

### Modern UI Patterns
- Rounded corners on cards and panels
- Subtle shadows/borders between panels
- Smooth transitions when switching modes or applying operations
- Loading spinners during computation
- Hover states on interactive elements (column headers, operation buttons)
- Accordion/collapsible sections in Operations panel

---

## 12. Other Notable Features

### Cleaning Steps Panel (Operation History)
- Sequential list of all applied operations
- Each step shows operation name and target column(s)
- Clicking a step highlights the corresponding changes in the data grid
- Clicking a step shows the generated code for that specific operation
- Undo: delete the most recent step (trash can icon on hover)
- Edit: modify parameters of the most recent operation with live preview
- Non-linear undo of specific steps (remove any step, not just the last)
- Steps are cumulative -- removing a middle step recalculates downstream

### Sandboxed Environment
- All exploration and transformations happen in a sandbox
- Original dataset is NEVER modified until explicit export
- Safe to experiment freely without data loss risk

### Custom Sampling
- Dialog to specify sample size (number of rows)
- Sampling methods: first N rows, last N rows, random set
- Default: first 5,000 rows

### Column Resizing
- Columns can be resized by dragging header borders
- Auto-fit column width based on content (implied by grid behavior)

### Keyboard Interaction
- Standard VS Code keyboard shortcuts apply within the extension
- Tab/arrow key navigation within the data grid
- Keyboard accessible toolbar and operations panel

### GitHub Copilot Integration (newer versions)
- Natural language requests: describe what you want done to the data
- Copilot generates the operation sequence
- Integrated into the Operations panel workflow

### PROSE / Flash Fill (AI-powered)
- Based on Microsoft's program synthesis technology (same as Excel Flash Fill)
- User provides 1-3 examples of desired output
- System infers the transformation pattern
- Generates Python code automatically
- If the inference is wrong, add another example to correct it
- Supports string transforms, datetime formatting, and general column derivation

### File Format Support
- CSV (with delimiter configuration)
- TSV (tab-separated)
- Excel (.xls, .xlsx) with sheet selection
- Parquet
- JSONL
- Open directly from VS Code file explorer (right-click > "Open in Data Wrangler")
- Can set Data Wrangler as default handler for these file types

### Notebook Integration
- Launch from Jupyter Notebook variables panel
- Launch from cell output ("Open 'df' in Data Wrangler" button)
- Launch from notebook toolbar "View data" dropdown
- Results Table: Data Wrangler replaces default static HTML DataFrame output in notebooks
- One-click expand from Results Table to full Data Wrangler

### Display Customization
- Views toolbar tab to show/hide panels
- Hide/show column statistics in headers (maximize screen real estate)
- Resizable panel boundaries
- Works on large monitors; accommodates smaller screens by hiding panels
- Viewing vs. Editing mode as primary layout toggle

### Error Handling / Troubleshooting
- Kernel connectivity diagnostics
- `Data Wrangler: Clear cached runtime` command palette option
- UnicodeDecodeError handling guidance (encoding parameter)
- Graceful fallback suggestions (chardet library)

### Settings
- Default mode preference (Viewing vs. Editing)
- Telemetry level control
- Python kernel selection on first launch

---

## 13. Feature Comparison Matrix for Shiny Implementation

Priority features for arbuilder's data viewer (what we MUST match):

| Feature | Priority | Shiny Equivalent |
|---------|----------|-----------------|
| Scrollable data grid with virtual scrolling | P0 | reactable / DT with server-side |
| Column type icons + badges | P0 | Custom header render |
| Mini histograms in column headers | P0 | sparkline / inline SVG in reactable |
| Missing value count in headers | P0 | Custom header render |
| Distinct value count in headers | P0 | Custom header render |
| Summary/profile panel on column click | P0 | Sidebar panel with plotly/ggplot |
| Column sorting (asc/desc toggle) | P0 | Built-in reactable/DT |
| Column filtering per type | P0 | Custom filter UI per column type |
| Column operations (rename, drop, retype) | P1 | Shiny modal dialogs |
| Data diff preview | P1 | Conditional cell styling |
| Operation history / undo | P1 | Reactive step list |
| Code generation (R instead of Python) | P0 | mod_codegen integration |
| Export to R script / CSV / RTF | P0 | Already planned |
| Go to Column search | P1 | selectInput with search |
| Sandboxed environment | P0 | All Shiny reactive = sandboxed by default |
| Dark/light theme | P2 | bslib theme switching |

Features where we can EXCEED Data Wrangler:

| Feature | Our Advantage |
|---------|--------------|
| R script generation | Native R/tidyverse instead of Python/Pandas |
| ADaM/CDISC awareness | Column metadata from ADaM spec |
| TFL-specific operations | ARD generation, not just data cleaning |
| RTF/PDF export | Submission-ready output via arframe |
| Clinical stat operations | Demographics, efficacy, safety operations built in |
| Label-aware display | Variable labels from ADaM shown in headers |

---

## Sources

- [VS Code Data Wrangler Docs](https://code.visualstudio.com/docs/datascience/data-wrangler)
- [Quick Start Guide](https://code.visualstudio.com/docs/datascience/data-wrangler-quick-start)
- [Announcement Blog Post](https://devblogs.microsoft.com/python/announcing-data-wrangler-code-centric-viewing-and-cleaning-of-tabular-data-in-visual-studio-code/)
- [Release Blog Post](https://devblogs.microsoft.com/python/data-wrangler-release/)
- [Results Table Blog Post](https://devblogs.microsoft.com/python/data-wrangler-results-table/)
- [GitHub Repository](https://github.com/microsoft/vscode-data-wrangler)
- [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.datawrangler)
- [Microsoft Fabric Data Wrangler Docs](https://learn.microsoft.com/en-us/fabric/data-science/data-wrangler)
- [Austin Henley Blog Review](https://austinhenley.com/blog/datawrangler.html)
- [Microsoft Learn Video](https://learn.microsoft.com/en-us/shows/visual-studio-code/mastering-your-data-with-data-wrangler-in-vs-code)
