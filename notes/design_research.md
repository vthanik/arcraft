# arbuilder UI Design Research

**Date:** 2026-03-16
**Goal:** Identify premium design patterns from the best pharma dashboards, FDA apps, modern SaaS tools (Linear, Vercel), and top Shiny apps. Use findings to redesign arbuilder so it looks decisively better than teal.

---

## Table of Contents

1. [The "Linear Design" Movement — The Gold Standard](#1-the-linear-design-movement)
2. [Vercel / Geist Design System](#2-vercel--geist-design-system)
3. [shadcn/ui — The Component Bible](#3-shadcnui--the-component-bible)
4. [FDA Open Data & Dashboard Design](#4-fda-open-data--dashboard-design)
5. [teal (Pharmaverse) — What We Must Beat](#5-teal-pharmaverse--what-we-must-beat)
6. [Best Shiny Apps (Appsilon, Jumping Rivers, Posit Gallery)](#6-best-shiny-apps)
7. [Clinical Trial Dashboard Design Patterns](#7-clinical-trial-dashboard-design-patterns)
8. [Appsilon React Wrappers (shiny.fluent, shiny.blueprint)](#8-appsilon-react-wrappers)
9. [Synthesis: The arbuilder Design System](#9-synthesis-the-arbuilder-design-system)
10. [Implementation Plan for bslib + Custom CSS](#10-implementation-plan)

---

## 1. The "Linear Design" Movement

Linear (linear.app) has become the defining aesthetic of premium SaaS in 2024-2026. Dozens of startups now copy "Linear style." Understanding why it works is critical.

### Layout Pattern
- **Collapsible sidebar** on the left (narrow, ~240px). The sidebar is intentionally dimmed — a few notches darker/more muted than the content area — so the main workspace dominates.
- **No top navbar for primary navigation.** Top area is reserved for breadcrumbs, tabs (compact, with rounded corners), and contextual actions.
- Sidebar contains: workspace switcher, favorites/starred items, navigation groups (collapsible), and a minimalist search trigger.
- Content area is the hero. Maximum breathing room.

### Color Palette
- **Dark mode primary** (their default): near-black background (#1a1a1a range), warm neutral grays (shifted away from cool blue-gray toward warmer tones).
- **Light mode**: crisp white (#ffffff) content area, very light warm gray sidebar (#f7f7f5 range).
- **Accent color**: desaturated, muted blue — NOT a saturated primary blue. Comfortable against both light and dark backgrounds.
- **The big insight**: Linear's 2025 refresh *drastically reduced color*. Swapped a monochrome blue scheme for monochrome black/white with very few bold accent colors. Less color = more premium.
- Icons: monochrome, scaled down. Removed colored team icon backgrounds. Visual noise reduction is the #1 priority.

### Typography
- **Inter Display** for headings (adds expression while staying clean).
- **Inter** (regular) for body text.
- Font sizes are restrained. Nothing screams. Hierarchy through weight and subtle size changes.
- Letter-spacing is tight on headings, normal on body.

### What Makes It Premium
1. **Reduced chrome**: tabs are compact, icons are smaller, colored backgrounds are removed.
2. **Warmth in neutrals**: shifted from cool blue-gray to warmer gray. Feels less clinical.
3. **Opacity-based layering**: design uses opacities of black/white to create elevation hierarchy rather than distinct background colors.
4. **Subtle glassmorphism**: translucent frosted-glass panels for overlays and dropdowns, but used sparingly.
5. **Performance**: the visual effects are achievable with pure CSS (no heavy assets), contributing to snappy feel.
6. **Density done right**: information-dense without feeling cluttered. Achieved through consistent spacing and restrained decoration.

### Key CSS Patterns Worth Copying
```css
/* Warm neutral gray scale (not cool/blue) */
--gray-50: #fafaf9;
--gray-100: #f5f5f4;
--gray-200: #e7e5e4;
--gray-300: #d6d3d1;
--gray-400: #a8a29e;
--gray-500: #78716c;
--gray-600: #57534e;
--gray-700: #44403c;
--gray-800: #292524;
--gray-900: #1c1917;

/* Muted accent blue */
--accent: #5e6ad2;  /* desaturated, not #0d6efd bootstrap blue */

/* Sidebar dimming */
.sidebar { background: var(--gray-100); }
.content { background: #ffffff; }

/* Compact tabs */
.tab { border-radius: 6px; padding: 4px 10px; font-size: 13px; }

/* Opacity layering for elevation */
.overlay { background: rgba(255,255,255,0.8); backdrop-filter: blur(12px); }
```

**Sources:**
- [How we redesigned the Linear UI (part II)](https://linear.app/now/how-we-redesigned-the-linear-ui)
- [A calmer interface for a product in motion](https://linear.app/now/behind-the-latest-design-refresh)
- [Linear design: The SaaS design trend — LogRocket](https://blog.logrocket.com/ux-design/linear-design/)
- [The rise of Linear style design — Medium](https://medium.com/design-bootcamp/the-rise-of-linear-style-design-origins-trends-and-techniques-4fd96aab7646)
- [Linear Design Breakdown — 925 Studios](https://www.925studios.co/blog/linear-design-breakdown)
- [Linear Brand Guidelines](https://linear.app/brand)

---

## 2. Vercel / Geist Design System

Vercel's dashboard is the other benchmark for "developer tool that looks expensive."

### Layout Pattern
- **Sidebar navigation** (introduced in their 2024-2025 redesign). Previously top-nav, switched to sidebar to streamline navigation.
- Sidebar shows: projects, deployments, domains, storage, settings. Clean iconography.
- Content area: generous whitespace, card-based layout for project overview.
- Production status, deployment status, and git connection are immediately visible — most crucial info is front and center.

### Typography — Geist Font Family
- **Geist Sans**: geometric sans-serif based on Swiss typography. Used for body copy and headings.
- **Geist Mono**: monospaced companion for code, logs, terminal output.
- Both designed for legibility at all sizes. Available as CSS variables.
- Tight letter-spacing on headings, generous line-height on body.

### Color System
- Primarily monochrome: black, white, and grays.
- Base colors: Neutral, Stone, Zinc variations.
- Accent colors used extremely sparingly — mostly for status indicators (green=success, red=error, blue=info).
- The philosophy: "color means something." Don't use color decoratively.

### What Makes It Premium
1. **First Meaningful Paint optimization**: they decreased FMP by 1.2s. Perceived speed = perceived quality.
2. **Information density**: logs, deployment info, git status all visible without drilling down.
3. **Mobile-responsive**: dashboard works on phone. (Not critical for arbuilder but shows attention to detail.)
4. **Monochrome base + semantic color only**: color is reserved for meaning, never decoration.

### Key Patterns
```css
/* Geist-inspired font stack for Shiny (use Inter as available substitute) */
--font-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
--font-mono: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace;

/* Vercel-style card */
.card {
  border: 1px solid var(--gray-200);
  border-radius: 8px;
  padding: 20px;
  background: #fff;
  box-shadow: none;  /* No shadow! Border only. */
}

/* Status indicators — color only for meaning */
.status-success { color: #0070f3; }
.status-error { color: #ee0000; }
.status-warning { color: #f5a623; }
```

**Sources:**
- [Vercel Dashboard Redesign](https://vercel.com/blog/dashboard-redesign)
- [Geist Typography](https://vercel.com/geist/typography)
- [Geist Colors](https://vercel.com/geist/colors)
- [Geist Font](https://vercel.com/font)
- [Vercel's New Dashboard UX — Medium](https://medium.com/design-bootcamp/vercels-new-dashboard-ux-what-it-teaches-us-about-developer-centric-design-93117215fe31)

---

## 3. shadcn/ui — The Component Bible

shadcn/ui is the most influential component library of 2024-2026. Even if we can't use it directly in Shiny, its design language is the target.

### Design Philosophy
- Components are **copy-paste** — you own the code. No opaque library.
- Built on **Radix UI** primitives (accessibility baked in) + **Tailwind CSS** styling.
- Uses **CSS variables** for theming: `--background`, `--foreground`, `--card`, `--primary`, `--muted`, etc.

### Color System
- Base colors: Neutral, Stone, Zinc, Mauve, Olive, Mist, Taupe.
- Simple convention: every color has a `background` and `foreground` variant.
- Muted variants for secondary content: `--muted` and `--muted-foreground`.
- Destructive actions: `--destructive` and `--destructive-foreground`.

### Component Patterns Worth Emulating in Shiny
| shadcn Component | Shiny Equivalent | Key Visual Detail |
|---|---|---|
| Card | bslib::card() | 1px border, 8px radius, no shadow |
| Table | DT::datatable() | Alternating rows OFF, subtle bottom borders only |
| Button (default) | actionButton() | Solid fill, 6px radius, medium font weight |
| Button (outline) | actionButton() | 1px border, transparent bg, hover fills |
| Button (ghost) | actionButton() | No border, transparent, hover shows bg |
| Select | selectInput() | Clean dropdown, subtle border, chevron icon |
| Badge | Custom span | Pill shape, muted bg, small text |
| Separator | hr | Thin 1px line, muted color |
| Tabs | tabsetPanel() | Underline style, no box/card wrapper |

### The "Not Bootstrap" Look
The reason shadcn/ui looks premium and Bootstrap looks generic:
1. **No box shadows on cards** — just subtle borders.
2. **Muted, not bright** — primary blue is `hsl(222.2 47.4% 11.2%)` (nearly black-blue), not `#0d6efd`.
3. **Consistent radius** — everything uses the same `--radius` variable.
4. **Typography hierarchy** — `text-sm` (14px) is the default, not 16px. Headings are restrained.
5. **Spacing is generous** — padding inside cards is 24px, not 12px.

**Sources:**
- [shadcn/ui Theming](https://ui.shadcn.com/docs/theming)
- [shadcn/ui Colors](https://ui.shadcn.com/colors)
- [shadcn/ui Design System — Figma](https://www.figma.com/community/file/1203061493325953101/shadcn-ui-design-system)

---

## 4. FDA Open Data & Dashboard Design

### open.fda.gov
- **Layout**: Clean, government-style but surprisingly modern. Top navigation bar with logo + main sections.
- **Color palette**: FDA blue (#005ea2 range — USWDS blue), white backgrounds, gray accents.
- **Typography**: Source Sans Pro (the U.S. Web Design System standard).
- **Navigation**: Top horizontal nav for main sections, in-page sidebar for subsections.
- **Data presentation**: API-first approach, clean cards for dataset categories.

### datadashboard.fda.gov
- **Layout**: Full-width dashboard with filter panel that flies out from the left side.
- **Interactive filtering**: Click "Filters" button, flyout panel appears — does not permanently consume sidebar space.
- **Tables**: Sortable, filterable, downloadable. Company names, inspection dates, compliance actions.
- **Design philosophy**: "Transparency through visual accessibility" — customizable, understandable graphics.
- **Data density**: High. Multiple views: maps, charts, grids. Filtering by year, type, geography.

### What to Steal from FDA
1. **Flyout filter panel** — not a permanent sidebar. Filters appear on demand, content gets full width when not filtering.
2. **Government-grade accessibility**: high contrast, readable fonts, clear labels.
3. **Data download prominent**: every view has an export button.
4. **Blue as trust color**: FDA blue conveys authority and trust. For pharma context, blue is correct.

**Sources:**
- [FDA Dashboards](https://datadashboard.fda.gov/oii/index.htm)
- [openFDA](https://open.fda.gov/)
- [FDA Dashboard How-To](https://datadashboard.fda.gov/oii/howto.htm)

---

## 5. teal (Pharmaverse) — What We Must Beat

teal is our direct competitor/comparison point. Understanding its weaknesses tells us where to differentiate.

### teal's Current Design
- **Layout**: Title/header at top, **filter panel on the right side** (always visible, takes ~30% of screen), module tabs below header.
- **Components**: Standard Shiny widgets. selectInput, sliderInput, etc. Default Bootstrap styling.
- **Color**: Default Bootstrap blue (#0d6efd) or basic Shiny gray. No custom palette.
- **Typography**: Default browser/Bootstrap fonts. No custom type hierarchy.
- **Tables**: Standard DT datatables with default styling.

### teal's Weaknesses (Our Opportunities)
1. **Generic Bootstrap look** — immediately recognizable as "a Shiny app." No brand identity.
2. **Filter panel always visible** — wastes screen real estate. Should be collapsible or on-demand.
3. **No visual hierarchy** — everything has the same visual weight. Headers, labels, values all blend.
4. **Tab navigation feels flat** — simple tabsetPanel with no visual distinction.
5. **No card system** — content blocks aren't visually separated into cards.
6. **Dense without being organized** — information density without the spacing discipline to make it readable.
7. **No loading states or transitions** — feels static and unresponsive.

### teal's 2025 Improvements
- The team is working on a "visual overhaul" for better intuitiveness.
- Teal Gallery launched to showcase modules.
- But fundamentally, teal is a framework — it generates functional UIs, not beautiful ones.

### How arbuilder Must Differ
| Aspect | teal | arbuilder Target |
|---|---|---|
| First impression | "Shiny app" | "Modern web app" |
| Color | Bootstrap default | Custom muted palette |
| Typography | System default | Inter, sized hierarchy |
| Filter panel | Always visible, right side | Collapsible sidebar, left side |
| Cards | None | All content in bordered cards |
| Spacing | Tight/default | Generous, deliberate |
| Transitions | None | Subtle fade/slide |
| Loading states | None | Skeleton screens or spinners |

**Sources:**
- [teal — Pharmaverse](https://insightsengineering.github.io/teal/latest-tag/)
- [teal on GitHub](https://github.com/insightsengineering/teal)
- [Building Clinical Data Analysis Apps with teal — R-bloggers](https://www.r-bloggers.com/2024/11/shiny-gatherings-x-pharmaverse-building-clinical-data-analysis-apps-with-teal/)

---

## 6. Best Shiny Apps

### Appsilon — The Benchmark for Beautiful Shiny
Appsilon consistently produces the best-looking Shiny apps. Their key patterns:

1. **Custom CSS everywhere**: They never ship default Bootstrap. Every app has a distinct visual identity.
2. **Full-bleed layouts**: No wasted gutters or margins. Content fills the viewport.
3. **shiny.fluent**: Wraps Microsoft Fluent UI (React) components for Shiny — enterprise-grade look.
4. **shiny.blueprint**: Wraps Palantir's Blueprint (React) — optimized for "complex, data-dense web interfaces."
5. **Dark themes**: Many Appsilon demos use dark backgrounds, which immediately look more premium.
6. **Animation**: Subtle CSS transitions on hover states, panel reveals, loading sequences.

### Key Appsilon Examples
- **Climate scenario visualizer** (with Polish Academy of Sciences): full-screen map, floating control panel, minimal chrome.
- **Lyme disease explorer** (award-winning): rich data visualization, clean navigation, professional color palette.
- **Pharma/life sciences demos**: Purpose-built for clinical data, with regulatory-grade presentation.

### Jumping Rivers Dashboard Gallery
- Showcases diverse dashboard styles (Shiny, Dash, Streamlit, Observable).
- Demonstrates that the same data can look dramatically different depending on styling.
- Their best apps use custom themes, card layouts, and deliberate color systems.

### Posit Shiny Gallery
- Official gallery at shiny.posit.co/r/gallery.
- Ranges from basic to impressive.
- Best entries use bslib extensively with custom themes.

### shinyAppStore — 2025 Best Award Apps
- Community-curated "best of" awards.
- Winning apps tend to share: custom CSS, thoughtful color, good spacing, interactive visualizations.

**Sources:**
- [Appsilon Demo Gallery](https://demo.appsilon.com/)
- [Appsilon Shiny Demo Gallery](https://www.appsilon.com/shiny-demo-gallery)
- [R Shiny in Life Sciences — Appsilon](https://www.appsilon.com/post/r-shiny-in-life-sciences-examples)
- [Jumping Rivers Dashboard Gallery](https://www.jumpingrivers.com/blog/shiny-dashboard-app-gallery/)
- [Shiny Gallery — Posit](https://shiny.posit.co/r/gallery/)
- [Shiny App Store](https://shinyappstore.com/)
- [How to Make Your Shiny App Beautiful — Appsilon](https://www.appsilon.com/post/how-to-make-your-shiny-app-beautiful)

---

## 7. Clinical Trial Dashboard Design Patterns

### Common Layout Patterns
- **Top-level KPIs**: large value boxes showing enrollment count, site count, protocol deviations, etc.
- **Map + Grid**: geographic view of trial sites alongside tabular detail.
- **Timeline/Gantt**: study milestones and recruitment progress over time.
- **Filter bar**: typically horizontal across the top or collapsible left sidebar.

### Design Best Practices from Dribbble/Professional Agencies
- **Card-based layouts**: every metric or chart lives in its own card with consistent border radius.
- **Status colors**: green/amber/red traffic-light system for trial health indicators.
- **Data density**: clinical users want density. But density must be organized into clear visual groups.
- **Whitespace between groups, density within groups**: this is the critical pattern.
- **Progressive disclosure**: summary view first, click to expand detail.

### Professional Agency Patterns (Flatirons, G&Co, Reloadux)
- Clinical trial UIs prioritize: clear information architecture, regulatory compliance, accessibility.
- Navigation designed for task flow: data upload -> configuration -> analysis -> export.
- Mobile is secondary but responsive layout expected.
- Color: medical blue + neutral grays. Avoid red except for errors/warnings (it triggers "adverse event" associations).

### What Makes Clinical Dashboards Look Premium
1. **Value boxes with large numbers**: 48px+ font for the key metric, 12px label below.
2. **Consistent iconography**: matching icon set, not random Bootstrap icons.
3. **Chart consistency**: same color palette across all charts, same axis styling.
4. **White background with card borders**: not gray backgrounds with white cards (the latter looks dated).

**Sources:**
- [Clinical Trials on Dribbble](https://dribbble.com/tags/clinical-trials)
- [Clinical Trial Dashboard — Bold BI](https://www.boldbi.com/dashboard-examples/healthcare/clinical-trials-dashboard/)
- [Clinical Trial UI/UX — Reloadux](https://reloadux.com/ui-ux/clinical-trial/)
- [Clinical Trial UI/UX — Flatirons](https://flatirons.com/services/clinical-trial-ui-ux-design/)

---

## 8. Appsilon React Wrappers

These are worth knowing about but may be overkill for arbuilder Phase 1.

### shiny.fluent (Microsoft Fluent UI)
- Wraps Microsoft's Fluent UI React components.
- Great for enterprise environments already using Microsoft tools.
- Components: DetailsList (tables), CommandBar, Panel, Dialog, Dropdown, etc.
- Looks like a Microsoft 365 app — professional but specific aesthetic.

### shiny.blueprint (Palantir Blueprint)
- Wraps Palantir's Blueprint library.
- **Optimized for complex, data-dense web interfaces** — perfect for clinical data.
- Version 5.10.2 supported.
- Components: tree views, multi-select, popovers, toasts, data tables.
- Darker, more technical aesthetic than Fluent.

### shiny.react (Core)
- Foundation layer that enables any React component in Shiny.
- Could theoretically wrap shadcn/ui components, but complex setup.

### Recommendation for arbuilder
**Don't use these for Phase 1.** They add React as a dependency, complicate the stack, and make code generation harder. Instead, achieve the same visual quality through bslib + custom CSS. The React wrappers are a Phase 3+ consideration if we need specific complex components.

**Sources:**
- [shiny.fluent](https://appsilon.github.io/shiny.fluent/)
- [shiny.blueprint](https://appsilon.github.io/shiny.blueprint/)
- [shiny.react](https://appsilon.github.io/shiny.react/)
- [Shiny-React Ecosystem Updates — Appsilon](https://www.appsilon.com/post/shiny-react-ecosystem-updates)

---

## 9. Synthesis: The arbuilder Design System

Based on all research, here is the target design system for arbuilder.

### Design Philosophy
**"Linear meets clinical."** The restraint and warmth of Linear's design language, applied to a pharma data tool. Professional enough for a regulatory submission review. Modern enough that a biostatistician says "this is nicer than teal."

### Color Palette

```
Background & Surface:
  --bg-app:         #ffffff          (main background)
  --bg-sidebar:     #f8f8f7          (sidebar — warm, slightly off-white)
  --bg-card:        #ffffff          (card background)
  --bg-muted:       #f4f4f3          (muted backgrounds, code blocks)
  --bg-hover:       #f0efed          (hover states)

Borders:
  --border-default: #e5e4e2          (card borders, dividers)
  --border-focus:   #c4c3c0          (focused input borders)

Text:
  --text-primary:   #1a1918          (headings, primary text)
  --text-secondary: #6b6966          (labels, secondary text)
  --text-muted:     #a3a09c          (placeholders, disabled text)

Accent (Pharma Blue — desaturated, not Bootstrap):
  --accent:         #4a6fa5          (primary actions, links)
  --accent-hover:   #3d5d8a          (button hover)
  --accent-muted:   #e8eef5          (selected/active backgrounds)

Semantic:
  --success:        #2d8a4e          (completed, valid)
  --warning:        #c17a2f          (caution, pending)
  --error:          #c53030          (errors, destructive)
  --info:           #4a6fa5          (informational, matches accent)
```

### Typography

```
Font Stack:
  --font-sans:      'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif
  --font-mono:      'JetBrains Mono', 'Fira Code', Consolas, monospace

Scale:
  --text-xs:        12px / 1.5    (badges, footnotes)
  --text-sm:        13px / 1.5    (table cells, secondary labels)
  --text-base:      14px / 1.6    (DEFAULT body text — not 16px)
  --text-md:        15px / 1.5    (input text)
  --text-lg:        18px / 1.4    (section headings)
  --text-xl:        22px / 1.3    (page titles)
  --text-2xl:       28px / 1.2    (KPI value boxes)

Weights:
  Regular: 400 (body)
  Medium:  500 (labels, table headers)
  Semibold: 600 (headings, buttons)
```

### Spacing System (8px Base Grid)

```
  --space-1:  4px     (tight inner padding)
  --space-2:  8px     (standard inner padding)
  --space-3:  12px    (input padding, small gaps)
  --space-4:  16px    (card inner padding, gaps between items)
  --space-5:  20px    (section separation within cards)
  --space-6:  24px    (card padding, major gaps)
  --space-8:  32px    (section separation)
  --space-10: 40px    (page-level separation)
```

### Border Radius

```
  --radius-sm:  4px   (badges, small elements)
  --radius-md:  6px   (buttons, inputs)
  --radius-lg:  8px   (cards, modals)
  --radius-xl:  12px  (large containers, popovers)
```

### Component Specifications

#### Cards
```css
.ar-card {
  background: var(--bg-card);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-lg);
  padding: var(--space-6);
  /* NO box-shadow. Border only. This is the #1 anti-Bootstrap pattern. */
}
.ar-card-header {
  font-size: var(--text-lg);
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: var(--space-4);
  padding-bottom: var(--space-3);
  border-bottom: 1px solid var(--border-default);
}
```

#### Buttons
```css
.ar-btn {
  font-size: var(--text-sm);
  font-weight: 500;
  padding: 6px 14px;
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all 0.15s ease;
}
.ar-btn-primary {
  background: var(--accent);
  color: #ffffff;
  border: none;
}
.ar-btn-primary:hover {
  background: var(--accent-hover);
}
.ar-btn-outline {
  background: transparent;
  color: var(--text-primary);
  border: 1px solid var(--border-default);
}
.ar-btn-outline:hover {
  background: var(--bg-hover);
}
.ar-btn-ghost {
  background: transparent;
  color: var(--text-secondary);
  border: none;
}
.ar-btn-ghost:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}
```

#### Tables (DT Override)
```css
/* Kill the default DT look */
.dataTables_wrapper {
  font-size: var(--text-sm);
}
table.dataTable thead th {
  font-weight: 500;
  color: var(--text-secondary);
  font-size: var(--text-xs);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 1px solid var(--border-default);
  padding: var(--space-2) var(--space-3);
  background: transparent;
}
table.dataTable tbody td {
  padding: var(--space-2) var(--space-3);
  border-bottom: 1px solid var(--bg-muted);
  color: var(--text-primary);
}
table.dataTable tbody tr:hover {
  background: var(--bg-hover) !important;
}
/* NO alternating row colors. Subtle bottom border only. */
table.dataTable.stripe tbody tr.odd { background: transparent; }
```

#### Sidebar
```css
.ar-sidebar {
  width: 260px;
  background: var(--bg-sidebar);
  border-right: 1px solid var(--border-default);
  padding: var(--space-4);
  overflow-y: auto;
  transition: width 0.2s ease;
}
.ar-sidebar.collapsed {
  width: 48px;
}
.ar-sidebar .nav-section-label {
  font-size: var(--text-xs);
  font-weight: 500;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: var(--space-2);
  padding-left: var(--space-2);
}
.ar-sidebar .nav-item {
  font-size: var(--text-sm);
  color: var(--text-secondary);
  padding: 6px var(--space-2);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: all 0.1s ease;
}
.ar-sidebar .nav-item:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}
.ar-sidebar .nav-item.active {
  background: var(--accent-muted);
  color: var(--accent);
  font-weight: 500;
}
```

#### Value Boxes (KPIs)
```css
.ar-value-box {
  background: var(--bg-card);
  border: 1px solid var(--border-default);
  border-radius: var(--radius-lg);
  padding: var(--space-5);
}
.ar-value-box .value {
  font-size: var(--text-2xl);
  font-weight: 600;
  color: var(--text-primary);
  line-height: 1;
}
.ar-value-box .label {
  font-size: var(--text-xs);
  font-weight: 500;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-top: var(--space-1);
}
```

#### Inputs
```css
.ar-input {
  font-size: var(--text-md);
  padding: 8px 12px;
  border: 1px solid var(--border-default);
  border-radius: var(--radius-md);
  background: var(--bg-card);
  color: var(--text-primary);
  transition: border-color 0.15s ease;
}
.ar-input:focus {
  border-color: var(--accent);
  outline: none;
  box-shadow: 0 0 0 3px var(--accent-muted);
  /* Ring focus — like shadcn, not thick Bootstrap blue glow */
}
.ar-input::placeholder {
  color: var(--text-muted);
}
.ar-label {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-secondary);
  margin-bottom: var(--space-1);
}
```

### Layout Architecture

```
+------------------------------------------------------------------+
| Logo  arbuilder              [Study: CDISCPILOT01]    [Export v]  |  <- Top bar (48px, minimal)
+----------+-------------------------------------------------------+
|          |                                                       |
| SIDEBAR  |  MAIN CONTENT                                         |
| 260px    |                                                       |
|          |  +---card---+  +---card---+  +---card---+             |
| Data     |  | N=250   |  | Vars: 48 |  | TRT: 3   |             |  <- KPI value boxes
|  Upload  |  +---------+  +---------+  +---------+             |
|  Filter  |                                                       |
|  Preview |  +------------------------------------------+         |
|          |  | card: Main workspace                     |         |
| Analysis |  |                                          |         |  <- Primary workspace card
|  Groups  |  |  [Table preview / Analysis config /      |         |
|  Stats   |  |   Code editor / RTF preview]             |         |
|  ARD     |  |                                          |         |
|          |  +------------------------------------------+         |
| Output   |                                                       |
|  Titles  |  +------------------------------------------+         |
|  Columns |  | card: Secondary content                  |         |  <- Supporting card
|  Headers |  |  [Logs, validation messages, metadata]   |         |
|  Rules   |  +------------------------------------------+         |
|  Page    |                                                       |
|          |                                                       |
| Preview  |                                                       |
| Code     |                                                       |
| Export   |                                                       |
+----------+-------------------------------------------------------+
```

### Key Differentiators vs teal

1. **Sidebar is on the LEFT** (teal puts filter panel on right). Left sidebar is standard in every modern app.
2. **Sidebar is the workflow stepper** — top to bottom matches the data flow: upload -> filter -> analyze -> format -> export.
3. **Filters are inline or collapsible** — not a permanent panel eating 30% of screen.
4. **Cards everywhere** — every content block is a visually distinct card.
5. **Custom font (Inter)** — immediately looks different from default Shiny.
6. **Muted accent blue** — not Bootstrap's screaming #0d6efd.
7. **14px default text** — slightly smaller than Bootstrap's 16px, higher information density.
8. **Uppercase muted labels** — for section headers, table column headers. Borrowed from Linear/shadcn.
9. **Subtle transitions** — 150ms ease on hover states, panel opens/closes.
10. **Skeleton loading states** — pulsing gray blocks while data loads, not a spinner or blank screen.

---

## 10. Implementation Plan

### Phase 1: bslib Theme + Custom CSS (Immediate)

```r
# In app.R or ui.R
library(bslib)

arbuilder_theme <- bs_theme(
  version = 5,
  bootswatch = NULL,  # No bootswatch — fully custom

  # Core colors
  bg = "#ffffff",
  fg = "#1a1918",
  primary = "#4a6fa5",
  secondary = "#6b6966",
  success = "#2d8a4e",
  warning = "#c17a2f",
  danger = "#c53030",
  info = "#4a6fa5",


  # Typography
  base_font = font_google("Inter"),
  heading_font = font_google("Inter"),
  code_font = font_google("JetBrains Mono"),
  font_scale = 0.875,  # 14px base instead of 16px

  # Borders and shapes
  "border-radius" = "6px",
  "border-radius-sm" = "4px",
  "border-radius-lg" = "8px",
  "card-border-color" = "#e5e4e2",

  # Inputs
  "input-border-color" = "#e5e4e2",
  "input-focus-border-color" = "#4a6fa5",

  # Disable default shadows
  "box-shadow" = "none",
  "box-shadow-sm" = "none",
  "card-box-shadow" = "none",

  # Links
  "link-color" = "#4a6fa5",
  "link-decoration" = "none"
)
```

### Phase 2: Custom CSS File (www/arbuilder.css)

A dedicated CSS file with:
- All the CSS variable definitions from Section 9
- Sidebar component styles
- DT/datatable overrides
- Value box styles
- Button variant styles
- Input/label overrides
- Loading skeleton animation
- Transition/animation definitions
- Print-friendly styles for RTF preview

### Phase 3: Font Loading

```html
<!-- In UI head -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

### Phase 4: Icon System

Use a consistent icon set. Options:
1. **Phosphor Icons** (recommended) — modern, consistent, multiple weights.
2. **Lucide Icons** — what shadcn/ui uses. Clean, minimal.
3. **Bootstrap Icons** — already available via bslib but look generic.

For Shiny, embed as inline SVG or use an icon font via `htmltools::tags$link()`.

### Anti-Patterns to Avoid

1. **Do NOT use shinydashboard** — it looks like 2017.
2. **Do NOT use default DT styling** — override everything.
3. **Do NOT use navbarPage** — it creates a generic top-nav layout.
4. **Do NOT use Bootstrap's default blue (#0d6efd)** — it screams "template."
5. **Do NOT use box shadows on cards** — use borders only.
6. **Do NOT use alternating row colors in tables** — subtle bottom borders only.
7. **Do NOT use 16px body text** — 14px is the modern SaaS standard.
8. **Do NOT use bright colored backgrounds for alerts/cards** — use muted tints.

---

## Appendix: Key Reference Links

### Design Systems
- [Linear Brand Guidelines](https://linear.app/brand)
- [Geist Design System (Vercel)](https://vercel.com/geist/typography)
- [shadcn/ui Theming](https://ui.shadcn.com/docs/theming)
- [shadcn/ui Colors](https://ui.shadcn.com/colors)

### Shiny Design Resources
- [Appsilon — How to Make Your Shiny App Beautiful](https://www.appsilon.com/post/how-to-make-your-shiny-app-beautiful)
- [Appsilon Demo Gallery](https://demo.appsilon.com/)
- [Outstanding User Interfaces with Shiny — Theming Chapter](https://unleash-shiny.rinterface.com/beautify-with-bootstraplib)
- [bslib Documentation](https://rstudio.github.io/bslib/)
- [bslib Theming Guide](https://rstudio.github.io/bslib/articles/theming/index.html)
- [Shiny Custom Themes — Datanovia](https://www.datanovia.com/learn/tools/shiny-apps/ui-design/styling-themes.html)
- [shiny.fluent (Microsoft Fluent UI)](https://appsilon.github.io/shiny.fluent/)
- [shiny.blueprint (Palantir Blueprint)](https://appsilon.github.io/shiny.blueprint/)

### Pharma/Clinical
- [teal — Pharmaverse](https://insightsengineering.github.io/teal/latest-tag/)
- [FDA Data Dashboard](https://datadashboard.fda.gov/oii/index.htm)
- [openFDA](https://open.fda.gov/)
- [Clinical Trials on Dribbble](https://dribbble.com/tags/clinical-trials)

### Inspiration
- [Linear UI Redesign (Part II)](https://linear.app/now/how-we-redesigned-the-linear-ui)
- [A Calmer Interface — Linear](https://linear.app/now/behind-the-latest-design-refresh)
- [Linear Design Trend — LogRocket](https://blog.logrocket.com/ux-design/linear-design/)
- [Vercel Dashboard Redesign](https://vercel.com/blog/dashboard-redesign)
