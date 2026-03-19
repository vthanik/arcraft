# VS Code Data Wrangler UX Reference

Comprehensive UX reference for replicating Data Wrangler's patterns in arbuilder.
Based on official VS Code docs, Microsoft Fabric docs, GitHub issues, and blog posts.

---

## 1. Overall Layout

```
+-----------------------------------------------------------------------+
| [Viewing | Editing]  Rows: 891  Cols: 15  [Go to column] [Views v] [Export v] |  <- Toolbar
+-------------------+---------------------------------------------------+
|                   |                                                   |
|  LEFT SIDEBAR     |  DATA GRID                                        |
|  (~280px)         |  (fills remaining space)                          |
|                   |                                                   |
|  +--------------+ | +--col1-------+--col2-------+--col3---------+     |
|  | DATA SUMMARY | | | Name  str  | Age   int64 | Score  float64|     |
|  | (or)         | | | [bar chart]| [histogram] | [histogram]   |     |
|  | OPERATIONS   | | | 0 missing  | 3 missing   | 1 missing     |     |
|  | (or)         | | | 891 distinct| 89 distinct | 200 distinct  |     |
|  | CLEANING     | | +------------+-------------+---------------+     |
|  | STEPS        | | | Alice      | 34          | 88.5          |     |
|  |              | | | Bob        | 28          | 92.1          |     |
|  +--------------+ | | Carol      | NaN         | 76.3          |     |
|                   | | ...        | ...         | ...           |     |
+-------------------+---------------------------------------------------+
|  CODE PREVIEW (collapsible bottom panel)                              |
|  def clean_data(df):                                                  |
|      df = df.dropna(subset=['Age'])                                   |
|      return df                                                        |
+-----------------------------------------------------------------------+
```

### Key Layout Properties
- **Two-region layout**: Left sidebar + main data grid
- **Bottom panel**: Code preview, collapsible, appears in Editing mode
- **Sidebar width**: ~280px, not resizable by user
- **Grid**: Fills all remaining horizontal and vertical space
- **Toolbar**: Full-width strip above both sidebar and grid

---

## 2. Toolbar

### Elements (left to right)

| Element | Type | Behavior |
|---------|------|----------|
| **Mode toggle** | Segmented control: `[Viewing \| Editing]` | Switches between two modes. Default: Viewing |
| **Dimensions badge** | Static text, e.g. `891 rows x 15 columns` | Updates after operations are applied |
| **Go to column** | Search input / dropdown | Type to fuzzy-search column names, click to scroll grid to that column |
| **Views** | Dropdown button | Toggle visibility of panels: Summary, Operations, Cleaning Steps, Code Preview. Accommodates small screens |
| **Export** | Dropdown button | Three options (see Export section) |

### Mode Toggle Details
- **Viewing**: Pill/segment is highlighted. Sidebar shows DATA SUMMARY only. Grid is read-only exploration. Filter/sort available from column headers
- **Editing**: Pill/segment is highlighted. Sidebar switches to show OPERATIONS and CLEANING STEPS. Bottom Code Preview panel appears. Data diff overlay becomes available

### Dimensions Badge
- Format: `{n} rows x {m} columns`
- Updates live after each applied operation (e.g., drop rows changes count)
- Styled as muted/secondary text, not a button

---

## 3. Sidebar Panels

The sidebar content changes based on mode and context.

### 3A. DATA SUMMARY Panel (Viewing Mode)

**When no column is selected** — shows dataset-level overview:
- Total rows and columns
- Total missing values across dataset
- Memory usage
- Data types distribution

**When a column is selected** (click column header) — shows column-level statistics:

#### For Numeric Columns:
| Statistic | Description |
|-----------|-------------|
| Count | Non-null count |
| Missing | Count + percentage of NaN/null |
| Distinct | Number of unique values |
| Mean | Arithmetic mean |
| Std Dev | Standard deviation |
| Min | Minimum value |
| 25% | First quartile |
| Median (50%) | Median value |
| 75% | Third quartile |
| Max | Maximum value |
| Sum | Sum of all values (added in v1.21.3) |

Plus a **histogram visualization** showing value distribution.

#### For Categorical/Text Columns:
| Statistic | Description |
|-----------|-------------|
| Count | Non-null count |
| Missing | Count + percentage |
| Distinct | Number of unique values |
| Most Frequent | Mode value + its count |
| Top values | Bar chart of top N most frequent values |

Plus a **horizontal bar chart** showing frequency of top categories.

#### For Boolean Columns:
| Statistic | Description |
|-----------|-------------|
| Count | Non-null count |
| Missing | Count + percentage |
| Most Frequent | Which boolean value appears more |
| True/False | Counts of each |

#### For DateTime Columns:
| Statistic | Description |
|-----------|-------------|
| Count | Non-null count |
| Missing | Count + percentage |
| Distinct | Number of unique values |
| Most Frequent | Most common datetime value |
| Min | Earliest date |
| Max | Latest date |

**Statistics precision**: Values displayed with appropriate significant digits. Recent updates improved precision display.

---

### 3B. OPERATIONS Panel (Editing Mode)

**Structure**:
- **Search bar** at top: Type to filter operations by name (e.g., typing "drop" shows "Drop column", "Drop missing values", "Drop duplicate rows")
- **Categorized list** below: Operations grouped under collapsible category headers
- **Custom Operation** entry: Special entry for writing freeform Python/pandas code

**Operation Categories and Complete List** (40 operations total):

#### Sort and Filter
| Operation | Description |
|-----------|-------------|
| Sort | Sort column(s) ascending or descending |
| Filter | Filter rows based on one or more conditions |

#### Schema (Column Structure)
| Operation | Description |
|-----------|-------------|
| Change column type | Change the data type of a column |
| Drop column | Delete one or more columns |
| Select column | Choose one or more columns to keep, delete the rest |
| Rename column | Rename one or more columns |
| Clone column | Create a copy of one or more columns |

#### Clean and Transform (Missing Values / Duplicates)
| Operation | Description |
|-----------|-------------|
| Drop missing values | Remove rows with missing values |
| Drop duplicate rows | Drop all rows with duplicate values in one or more columns |
| Fill missing values | Replace cells with missing values with a new value (mean, median, mode, custom) |
| Find and replace | Replace cells with a matching pattern. Options: Match full string, Match case, Use regex |
| Strip whitespace | Remove whitespace from beginning and end of text |

#### Text Operations
| Operation | Description |
|-----------|-------------|
| Split text | Split a column into several columns based on a delimiter |
| Capitalize first character | Converts first character to uppercase, rest to lowercase |
| Convert text to lowercase | Convert text to lowercase |
| Convert text to UPPERCASE | Convert text to UPPERCASE |

#### New Column / Derive
| Operation | Description |
|-----------|-------------|
| Create column from formula | Create a column using a custom Python formula |
| Calculate text length | New column with length of each string value |
| One-hot encode | Split categorical data into new column for each category |
| Multi-label binarizer | Split categorical data using a delimiter into binary columns |

#### Aggregation
| Operation | Description |
|-----------|-------------|
| Group by column and aggregate | Group by columns and aggregate results |

#### Numeric
| Operation | Description |
|-----------|-------------|
| Scale min/max values | Scale a numerical column between a min and max value |
| Round | Round numbers to specified decimal places |
| Round down (floor) | Round numbers down to nearest integer |
| Round up (ceiling) | Round numbers up to nearest integer |

#### AI / By Example
| Operation | Description |
|-----------|-------------|
| String transform by example | Automatically perform string transforms when a pattern is detected from examples |
| DateTime formatting by example | Automatically perform DateTime formatting from examples |
| New column by example | Automatically create a column when a pattern is detected from examples |
| Flash Fill | Automatically create new column based on examples derived from existing column |

#### Custom
| Operation | Description |
|-----------|-------------|
| Custom operation | Write freeform Python/pandas code for any transformation |

**Operation Selection Workflow**:
1. User clicks an operation from the list (or searches and clicks)
2. Sidebar content replaces with **operation configuration form**:
   - Target column(s) dropdown/multi-select
   - Operation-specific parameters (e.g., for "Fill missing values": dropdown with "mean", "median", "mode", "custom value"; for "Find and replace": input fields for find/replace strings + checkboxes for match options)
3. **Apply** and **Discard** buttons appear prominently
4. Grid immediately shows a live preview with diff highlighting

---

### 3C. CLEANING STEPS Panel (Editing Mode)

**Structure**: Vertical list of applied operations, ordered chronologically (newest at bottom).

**Each step shows**:
- Step number (1, 2, 3, ...)
- Operation name (e.g., "Drop missing values")
- Brief parameter summary (e.g., "on column: Age")
- On hover: **trash can icon** appears (but ONLY on the most recent step)

**Interactions**:

| Action | Behavior |
|--------|----------|
| **Click a step** | Highlights that step. Grid shows the data diff for that specific step. Code Preview shows the generated code for that step |
| **Hover most recent step** | Trash can icon appears to delete/undo that step |
| **Delete most recent step** | Removes it from the pipeline, grid reverts to previous state |
| **Edit most recent step** | Can modify parameters of the most recently applied operation. Changes re-preview in the grid |

**Limitations (as of early 2026)**:
- Can only undo/delete the **most recent** step (not arbitrary steps)
- Can only edit the **most recent** operation
- No drag-to-reorder steps
- No toggle/disable steps (requested in GitHub issue #62, toggle partially implemented in issue #180)
- No re-entrance (cannot return to previously saved cleaning steps from exported code)
- Editing earlier steps is architecturally complex because downstream operations may depend on them

**What's in the backlog** (from GitHub issue #62):
- Edit any previous step (not just most recent)
- Delete any step (with user correction for broken downstream steps)
- Reorder steps via drag
- Toggle/skip steps without deleting (like Blender modifiers)
- Re-entrance from exported notebook code

---

## 4. Operation Workflow (Apply / Discard Pattern)

This is the core interaction pattern that makes Data Wrangler feel powerful and safe.

### Step-by-Step Flow:

```
1. SELECT OPERATION
   User picks an operation from the Operations panel
   (or from column header context menu)
        |
        v
2. CONFIGURE PARAMETERS
   Sidebar shows operation-specific form
   (target columns, options, values)
        |
        v
3. LIVE PREVIEW (automatic)
   - Grid overlays a DATA DIFF view
   - Changed cells highlighted (green = new/modified, red = removed)
   - Added columns appear with highlight
   - Removed rows/columns shown with strikethrough or red
   - Code Preview panel shows generated pandas code
        |
        v
4. VALIDATE
   User reviews:
   a) The data diff in the grid (visual check)
   b) The generated code in Code Preview (code check)
        |
       / \
      /   \
     v     v
5a. APPLY              5b. DISCARD
    - Step added to      - Preview removed
      Cleaning Steps     - Grid returns to
    - Grid updates to      previous state
      reflect changes    - Code Preview cleared
    - Summary stats      - User can try different
      recalculated         operation
    - Dimensions badge
      updates
```

### Apply / Discard Button Placement:
- Buttons appear in the **operation configuration area** of the sidebar (below the parameters)
- Also appear in the **Code Preview** panel at the bottom
- **Apply** is a primary button (blue/accent colored)
- **Discard** is a secondary/ghost button
- Both buttons are **only visible** when an operation is being previewed
- Both buttons are **disabled** if the operation configuration is incomplete/invalid

### Data Diff View Details:
- Overlays the normal data grid
- Color coding:
  - **Green background**: Cells/rows that are new or modified
  - **Red background**: Cells/rows that will be removed
  - **Subtle shading differences** between "changed value" vs "new column" vs "removed row"
- When a cleaning step is clicked, the diff view shows what that specific step changed
- Diff view disappears after Apply or Discard

### Pipeline Behavior:
- Operations stack linearly (step 1, then step 2, then step 3...)
- Each new operation operates on the result of all previous operations
- The grid always shows the current state (after all applied operations)
- Selecting a step in Cleaning Steps shows the diff for just that step
- Generated code wraps everything in a single function

---

## 5. Column Interaction

### Column Header Anatomy

Each column header in the data grid contains multiple pieces of information:

```
+----------------------------------+
| column_name           dtype_badge|  <- Row 1: Name + type
| [=====  ====  ====  ========]   |  <- Row 2: Mini visualization
| 3 missing  |  456 distinct      |  <- Row 3: Quick insights
+----------------------------------+
```

#### Row 1: Column Name + Data Type
- **Column name**: Left-aligned, truncated with ellipsis if too long
- **Data type badge**: Right-aligned, shows pandas dtype (e.g., `int64`, `float64`, `object`, `bool`, `datetime64`)

#### Row 2: Quick Insights Visualization
- **Numeric columns**: Binned histogram showing value distribution (mini bar chart, ~30px tall)
  - Only appears if column is cast as numeric type
  - Bins are proportional, tallest bin fills the height
- **Categorical/text columns**: Horizontal stacked bar showing frequency of top categories
  - Different colors for different categories
  - Each segment is hoverable

#### Row 3: Summary Metrics
- **Missing count**: e.g., "3 missing" (or "0 missing" in green)
- **Distinct count**: e.g., "456 distinct"
- These appear as small muted text below the visualization

#### Stacked Bar Chart (Data Quality Indicator)
- Each column header also has a thin stacked bar showing:
  - **Valid values** proportion (colored)
  - **Invalid values** proportion (different color)
  - **Missing values** proportion (gray/empty)
- Hover over segments to see calculated percentages as tooltip

### Click Column Header
- In **Viewing Mode**: The DATA SUMMARY panel updates to show that column's detailed statistics and visualization
- In **Editing Mode**: Same behavior, plus some operations auto-populate the target column

### Column Header Menu (Click arrow/icon in header, or right-click)
Available operations from the column header context menu:

| Menu Item | Description |
|-----------|-------------|
| **Sort Ascending** | Sort column A-Z or low-to-high |
| **Sort Descending** | Sort column Z-A or high-to-low |
| **Filter** | Opens filter configuration for this column |
| (separator) | |
| **Operations shortcut** | Quick access to common operations pre-configured for this column |

- In Editing mode, additional operations appear (e.g., "Use column for groupby", "Drop this column")
- Filter/Sort operations are available in both Viewing and Editing modes
- Sort has a compatibility mode that casts unknown dtypes to string, so all columns are sortable

### Column Resizing
- **Drag**: Grab the right edge of a column header to resize
- **Double-click column edge**: Auto-expands column to fit the widest content
- No global "auto-resize all columns" by default (users have requested this in issue #245)
- Minimum column width exists to keep headers readable

---

## 6. Data Grid Specifics

### Grid Properties
| Property | Behavior |
|----------|----------|
| **Scrolling** | Both horizontal and vertical scrolling. Virtual scrolling for large datasets |
| **Row numbering** | Row index shown as first frozen column (0-based, matching pandas index) |
| **Cell editing** | Not supported. Data Wrangler is NOT a spreadsheet — all changes go through operations |
| **Cell selection** | Click a cell to see its value. No multi-cell selection for editing |
| **Row selection** | Can select one or more rows. Right-click for context menu with "Copy" option |
| **Copy** | Can copy selected data rows via grid cell context menu |
| **Column freezing** | Index column is frozen. Other columns scroll horizontally |
| **Column reordering** | Not supported via drag (use Select Column operation) |
| **Text truncation** | Long cell values are truncated with ellipsis. Hover or widen column to see full value |

### Sandboxed Environment
- Data Wrangler operates on a **copy** of the data
- The original dataset is NOT modified until you explicitly export
- This is a critical safety guarantee

### Performance
- Default sample: First 5,000 rows (configurable via "Choose custom sample")
- Custom sampling options: First N rows, Last N rows, Random N rows
- Grid uses virtualized rendering for smooth scrolling

---

## 7. Filter and Sort Workflow

### Filtering (step by step):

1. **Access**: Click the column header menu arrow, or select "Filter" from the Operations panel
2. **Filter configuration appears** in the sidebar:
   - **Column selector**: Which column to filter on (pre-populated if accessed from header)
   - **Condition type**: Depends on column dtype:
     - Numeric: equals, not equals, greater than, less than, between, is null, is not null
     - Text: contains, not contains, starts with, ends with, equals, not equals, is null, is not null, regex match
     - Boolean: is true, is false, is null
     - DateTime: before, after, between, equals
   - **Value input**: For the comparison value
   - **Add condition**: Can add multiple conditions on the same column (AND/OR logic)
3. **Live preview**: Grid immediately shows which rows pass/fail the filter (diff highlighting)
4. **Apply** or **Discard**

### Sorting (step by step):

1. **Access**: Click "Sort Ascending" or "Sort Descending" from column header menu, or use Sort operation from Operations panel
2. **Sort configuration**:
   - Column selector
   - Direction: Ascending / Descending
   - Multi-column sort supported (sort by column A, then by column B)
3. **Live preview**: Grid reorders immediately
4. **Apply** or **Discard**

### Filter vs. Sort in Viewing Mode
- In Viewing mode, filters and sorts are **temporary/exploratory** — they don't generate code
- In Editing mode, they become **operations** that generate code and add to Cleaning Steps

---

## 8. Export Options

Three export methods available from the Export dropdown in the toolbar:

### 8A. Export Code to Notebook
- All cleaning steps are wrapped into a **Python function**:
  ```python
  def clean_data(df):
      df = df.dropna(subset=['Age'])
      df = df.rename(columns={'Name': 'patient_name'})
      df = df[df['Score'] > 50]
      return df
  ```
- A new cell is inserted into the source Jupyter notebook containing this function
- Running the cell applies the transformations to the original dataframe
- The original dataframe is NOT overwritten — the function returns a new dataframe
- Data Wrangler closes after export

### 8B. Export Data to File
- Saves the cleaned/transformed dataset as a new file
- Supported formats: **CSV**, **Parquet**
- File picker dialog to choose save location
- Does not generate code — just saves the resulting data

### 8C. Copy Code to Clipboard
- Copies all generated code (the complete function) to clipboard
- User can paste anywhere — notebook, script file, etc.
- Data Wrangler stays open after copy

---

## 9. Code Preview Panel

### Location and Behavior
- **Position**: Bottom panel, below the data grid (collapsible)
- **Visibility**: Only visible in Editing mode
- **Toggle**: Can be hidden/shown via Views dropdown

### Content
- When **no operation is selected**: Panel is empty or shows a placeholder
- When **operation is being previewed**: Shows the Python/pandas code that would be generated
- When **a cleaning step is clicked**: Shows the code for that specific step
- Shows **cumulative code** for all steps when viewing the full pipeline

### Editability
- The generated code **can be manually edited** by the user
- When edited, the data grid updates to reflect the manual code changes
- This allows power users to tweak the auto-generated code

### Panel Actions
- **Apply** button: Also available in this panel (same as sidebar Apply)
- **Discard** button: Also available here
- Opens/closes via double-clicking a cleaning step or clicking "Custom operation"

---

## 10. Views Dropdown

The **Views** dropdown in the toolbar lets users customize which panels are visible:

| Toggle | Default |
|--------|---------|
| Summary panel | Visible |
| Operations panel | Visible (Editing mode) |
| Cleaning Steps panel | Visible (Editing mode) |
| Code Preview panel | Visible (Editing mode) |
| Column quick insights | Visible |

- Purpose: Accommodate different screen sizes
- Small screens can hide sidebar panels and focus on the grid
- Column quick insights (the mini charts in headers) can be hidden for a denser grid view (requested in issue #221)

---

## 11. Entry Points (How Data Wrangler Opens)

### From Jupyter Notebook (VS Code):
1. **Variables panel button**: Click "Open in Data Wrangler" next to a DataFrame variable
2. **Cell output button**: After running a cell that produces a DataFrame, click "Open 'df' in Data Wrangler"
3. **Notebook toolbar**: "View data" dropdown showing all available DataFrame variables

### From File Explorer (VS Code):
4. **Right-click a file**: CSV, Excel (.xlsx), Parquet files can be opened directly in Data Wrangler
5. **Double-click**: If Data Wrangler is set as default viewer for CSV/Parquet

### From Microsoft Fabric Notebook:
6. **Ribbon "Home" tab**: Data Wrangler dropdown shows active DataFrames

### Custom Sampling on Open:
- "Choose custom sample" option in the dropdown
- Dialog with:
  - **Sample size**: Number of rows (default: 5,000)
  - **Sampling method**: First N rows, Last N rows, Random N rows

---

## 12. Keyboard Shortcuts and Interactions

| Shortcut | Action |
|----------|--------|
| Click column header | Select column, update summary panel |
| Right-click column header | Open column context menu |
| Double-click column edge | Auto-resize column width |
| Ctrl+C (on selected cells/rows) | Copy data |
| Scroll wheel | Vertical scroll through data |
| Shift + Scroll | Horizontal scroll |

---

## 13. Key Design Principles (for arbuilder adaptation)

### What Makes Data Wrangler Excellent:

1. **Preview-before-commit**: Every operation shows a live diff before applying. Users never feel unsafe. This is the single most important pattern.

2. **Code transparency**: Generated code is always visible. Users trust the tool because they can see exactly what it does. Even non-coders gain confidence from seeing the code.

3. **Sandboxed editing**: Original data is never modified. All operations are on a copy. The export step is explicit and deliberate.

4. **Progressive disclosure**: Viewing mode is simple (just data + stats). Editing mode reveals the full power (operations, steps, code). Users aren't overwhelmed.

5. **Column-first interaction**: Click a column, see its stats, apply operations to it. The column is the primary unit of interaction, not the row.

6. **Linear pipeline**: Operations stack simply. No branching, no DAGs. Step 1 then Step 2 then Step 3. Easy to understand, easy to undo.

7. **Dual validation**: Users validate both visually (diff view) AND programmatically (code preview) before committing. Two independent checks.

8. **Contextual sidebar**: The sidebar shows different content based on mode and selection. It's not a fixed form — it adapts.

9. **Quick insights without clicks**: Column headers show type, distribution, missing, and distinct at a glance. No clicking required to get an overview.

10. **Non-destructive undo**: Can always undo the most recent step. The cleaning steps history is always visible.

---

## 14. Adaptation Notes for arbuilder (Shiny/R)

| Data Wrangler Concept | arbuilder Equivalent |
|-----------------------|---------------------|
| Viewing / Editing mode toggle | Segmented control in toolbar switching sidebar content |
| Operations panel | Accordion with operation categories, search input at top |
| Cleaning Steps panel | Ordered list of applied analysis steps |
| Data diff overlay | Highlight changed cells/rows in DT or reactable |
| Code Preview | shinyAce editor showing generated R/arframe code |
| Apply / Discard | Action buttons in sidebar, enabled only during preview |
| Column header quick insights | Custom column headers in reactable with sparklines |
| Export to notebook | "Copy R Script" / "Export .R file" |
| pandas code generation | tidyverse + arframe code generation |
| Summary panel | Sidebar panel with column stats (skimr-style) |
| Custom operation | Custom R expression input |
| Sandboxed editing | reactive copy of uploaded data, never modify source |

### R Packages for Implementation:
- **reactable** or **DT**: Data grid with virtual scrolling, custom headers
- **sparkline** or **plotly**: Mini charts in column headers
- **shinyAce**: Code preview/editing panel
- **bslib**: Sidebar, accordion, cards for panel structure
- **shinyjs**: Toggle panel visibility, keyboard shortcuts

---

## Sources

- [VS Code Data Wrangler Documentation](https://code.visualstudio.com/docs/datascience/data-wrangler)
- [VS Code Data Wrangler Quick Start](https://code.visualstudio.com/docs/datascience/data-wrangler-quick-start)
- [Microsoft Fabric Data Wrangler](https://learn.microsoft.com/en-us/fabric/data-science/data-wrangler)
- [Data Wrangler Announcement Blog](https://devblogs.microsoft.com/python/announcing-data-wrangler-code-centric-viewing-and-cleaning-of-tabular-data-in-visual-studio-code/)
- [Data Wrangler Release Blog](https://devblogs.microsoft.com/python/data-wrangler-release/)
- [Data Wrangler GitHub Repository](https://github.com/microsoft/vscode-data-wrangler)
- [GitHub Issue #62 - Cleaning Steps Improvements](https://github.com/microsoft/vscode-data-wrangler/issues/62)
- [GitHub Issue #143 - Sum Statistics Request](https://github.com/microsoft/vscode-data-wrangler/issues/143)
- [GitHub Issue #221 - Hide Column Insights](https://github.com/microsoft/vscode-data-wrangler/issues/221)
- [GitHub Issue #227 - Column Width](https://github.com/microsoft/vscode-data-wrangler/issues/227)
- [GitHub Issue #245 - Auto-resize Columns](https://github.com/microsoft/vscode-data-wrangler/issues/245)
- [Data Wrangling with Data Wrangler - Austin Henley](https://austinhenley.com/blog/datawrangler.html)
- [DeepWiki - vscode-data-wrangler](https://deepwiki.com/microsoft/vscode-data-wrangler)
- [Data Wrangler - VS Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.datawrangler)
- [Microsoft Fabric Data Wrangler for Spark](https://learn.microsoft.com/en-us/fabric/data-science/data-wrangler-spark)
- [Data Wrangler AI Features](https://learn.microsoft.com/en-us/fabric/data-science/data-wrangler-ai)
