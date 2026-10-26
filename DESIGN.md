---
name: Apache Maven
description: The documentation frame of maven.apache.org; five tabs, a short group list, a reading column and pages that state their own facts.
colors:
  navy: "#003063"
  navy-deep: "#00224a"
  navy-soft: "#e8eef6"
  orange: "#f79a23"
  orange-soft: "#fff3e3"
  feather-purple: "#7c297d"
  ink: "#1d2433"
  ink-strong: "#0f1a2e"
  muted: "#555f70"
  line: "#dde2ea"
  line-strong: "#c4ccd8"
  paper: "#ffffff"
  paper-2: "#f6f8fb"
  code-bg: "#f3f5f8"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, Noto Sans, sans-serif"
    fontSize: "clamp(2.2rem, 1.3rem + 3vw, 3.6rem)"
    fontWeight: 700
    lineHeight: 1.08
    letterSpacing: "-0.025em"
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, Noto Sans, sans-serif"
    fontSize: "clamp(1.9rem, 1.4rem + 1.6vw, 2.5rem)"
    fontWeight: 700
    lineHeight: 1.15
    letterSpacing: "-0.015em"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, Noto Sans, sans-serif"
    fontSize: "1.5rem"
    fontWeight: 700
    lineHeight: 1.25
  subtitle:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, Noto Sans, sans-serif"
    fontSize: "1.2rem"
    fontWeight: 700
    lineHeight: 1.3
  lead:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, Noto Sans, sans-serif"
    fontSize: "1.2rem"
    fontWeight: 400
    lineHeight: 1.55
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, Noto Sans, sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.65
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Helvetica Neue, Arial, Noto Sans, sans-serif"
    fontSize: "0.9rem"
    fontWeight: 400
    lineHeight: 1.45
  code:
    fontFamily: "ui-monospace, SF Mono, Cascadia Mono, JetBrains Mono, Menlo, Consolas, Liberation Mono, monospace"
    fontSize: "0.875rem"
    fontWeight: 400
    lineHeight: 1.55
rounded:
  hair: "2px"
  chip: "3px"
  sm: "4px"
  md: "6px"
spacing:
  gutter: "clamp(1rem, 3vw, 2rem)"
  measure: "46rem"
  side-panel: "15rem"
  rail: "15rem"
  column-gap: "3rem"
  frame-max: "84rem"
  home-max: "76rem"
components:
  button-primary:
    backgroundColor: "{colors.orange}"
    textColor: "{colors.navy-deep}"
    rounded: "{rounded.md}"
    padding: "0.75rem 1.2rem"
  button-primary-hover:
    backgroundColor: "#ffae45"
  button-secondary:
    backgroundColor: "transparent"
    textColor: "{colors.paper}"
    rounded: "{rounded.md}"
    padding: "0.75rem 1.2rem"
  tab:
    textColor: "{colors.ink}"
    padding: "1.35rem 0 1.15rem"
  tab-active:
    textColor: "{colors.navy}"
  search-input:
    backgroundColor: "{colors.paper-2}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "0.45rem 0.7rem 0.45rem 2.1rem"
    width: "15rem"
  page-list-item:
    textColor: "{colors.ink}"
    rounded: "{rounded.sm}"
    padding: "0.3rem 0.5rem 0.3rem 0.9rem"
  page-list-item-current:
    backgroundColor: "{colors.navy-soft}"
    textColor: "{colors.navy}"
  step:
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "0.35rem 0.5rem"
  facts:
    backgroundColor: "{colors.paper}"
    rounded: "{rounded.md}"
    padding: "0.8rem 0.9rem"
  version-chip:
    textColor: "{colors.navy}"
    rounded: "{rounded.chip}"
    padding: "0 0.35rem"
  code-block:
    backgroundColor: "{colors.code-bg}"
    textColor: "{colors.ink}"
    typography: "{typography.code}"
    rounded: "{rounded.md}"
    padding: "0.9rem 1rem"
  inline-code:
    backgroundColor: "{colors.code-bg}"
    rounded: "{rounded.sm}"
    padding: "0.05em 0.3em"
  note-version:
    backgroundColor: "{colors.orange-soft}"
    rounded: "{rounded.md}"
    padding: "0.75rem 1rem"
  start-here:
    backgroundColor: "{colors.navy-soft}"
    rounded: "{rounded.md}"
    padding: "1rem 1.25rem"
---

# Design System: Apache Maven

## Overview

**Creative North Star: "The Quiet Reference Desk"**

The site is the category standard for documentation, executed with care: a white page, five tabs across the top, a short list of the current group on the left, one reading column in the centre and a rail on the right in which the page states its own facts. Nothing competes with the text. Maven's own navy carries every link and every piece of chrome; the feather orange appears only where the reader needs to be told something: where they are, and what to do first.

Density is that of a reference work, not a landing page. Inner pages are set at 17px on a 1.65 line height in a 46rem column, with navigation and facts in 0.9rem around it. Structure comes from 1px hairlines and pale fills, never from boxes stacked on boxes or from shadows. The home page is the one place the frame raises its voice: a full-width navy band with the key benefit, a terminal showing `mvn verify`, and the orange call to action, followed by the same quiet hairline grammar as the rest of the site.

The frame works completely without JavaScript. Navigation, previous/next, "On this page" and the page facts are all in the HTML from the build; script only turns the search field into search-as-you-type over the same static index.

**Key Characteristics:**
- White ground, ink text, Maven navy for links and chrome, feather orange as the single accent.
- Five top tabs with a 3px navy underline for the active section.
- A left side panel with previous/next and the current group's pages, the current page marked by an orange dot on a navy-soft fill.
- A page-facts block with outlined navy version chips (dashed for an unreleased line).
- Hairline rules and pale fills for structure; shadows only on things that float.
- One system sans stack for all text, one system mono stack for code only.
- Everything reachable without JavaScript.

## Colors

Maven's wordmark navy and feather orange on a cool white, with a ladder of blue-grey neutrals that all lean toward the navy.

### Primary
- **Wordmark Navy** (`navy`): every link, the active tab's underline and label, the current page in a group list, version chips, focus rings, result titles, the Rouge tag colour, and the home hero band. It is the colour of the chrome.
- **Night Navy** (`navy-deep`): the text on the orange button, the skip link, and the background of the home terminal; the darkest blue the site uses.
- **Navy Mist** (`navy-soft`): the fill behind the current page in a group list, the "New to Maven?" panel on the Docs landing, and the highlighted search result.

### Secondary
- **Feather Orange** (`orange`): the "you are here" dot in the side panel, the primary button on the home page, the terminal prompt, and the focus ring inside the navy hero. Nowhere else.
- **Feather Cream** (`orange-soft`): the fill of version-bound notes: the callout that says a passage applies to Maven 3.10 and 4, and the banner on a guide page about an unreleased line. It is the orange accent at reading strength.

### Tertiary
- **Feather Purple** (`feather-purple`): from the logo's gradient; used only in code, for keywords and XML attributes. The other syntax colours are fixed at forest green (#1f6b3a) for strings, rust (#9a3b00) for numbers, deep blue (#00427f) for functions and variables, and slate italic (#5f6877) for comments.

### Neutral
- **Ink** (`ink`): body text, list links, tab labels.
- **Strong Ink** (`ink-strong`): every heading, `strong`, table headers, release versions.
- **Slate** (`muted`): breadcrumbs, the facts block's terms, group summaries, dates, "Previous"/"Next" labels, the footer.
- **Hairline** (`line`): every rule and border: the masthead's bottom edge, facts and code borders, table rows, the "On this page" spine, door and news list rows.
- **Firm Hairline** (`line-strong`): the hover underline of an inactive tab, the floating search panel's border, the heading anchor at rest.
- **Paper** (`paper`): the page.
- **Cool Paper** (`paper-2`): table headers, blockquotes and notes, the search field at rest, the home release strip, the footer.
- **Code Paper** (`code-bg`): code blocks and inline code.

### Named Rules
**The One Feather Rule.** Feather orange is the only saturated accent, and it marks position or the first action: the current-page dot, the home primary button, the terminal prompt. It is never a link colour, a border, a heading colour or a decoration. Its pale tint (Feather Cream) marks version-bound notes and nothing else.

**The Navy Is Chrome Rule.** Links, the active tab, the current page, version chips and focus rings are navy. Headings stay Strong Ink and turn navy only on hover when they are links.

## Typography

**Display Font:** the system sans stack (-apple-system, Segoe UI, Roboto, Helvetica Neue, Arial, Noto Sans)
**Body Font:** the same stack
**Label/Mono Font:** the system mono stack (ui-monospace, SF Mono, Cascadia Mono, JetBrains Mono, Menlo, Consolas), for code, file names and `kbd` only

**Character:** One familiar, native voice for everything a reader reads, so the page looks like the reader's own tools; mono appears only where the text is something to type or a file to open.

### Hierarchy
- **Display** (700, clamp 2.2rem to 3.6rem, 1.08, -0.025em, balanced wrap): the home hero headline only, white on navy.
- **Headline** (700, clamp 1.9rem to 2.5rem, 1.15, -0.015em, balanced wrap): the title of every page. A later `h1` on the same page drops to 1.85rem with 3rem above it.
- **Title** (700, 1.5rem, 1.25): `h2` in the text, with 2.75rem above.
- **Subtitle** (700, 1.2rem, 1.3): `h3` in the text; also news item titles and home release versions (650, tabular).
- **Lead** (400, 1.2rem, 1.55, #38404f): the one-paragraph summary under every page title, group and section landing.
- **Body** (400, 1.0625rem, 1.65): the reading text in a 46rem column; 1rem on phones and in the frame outside the text.
- **Label** (400, 0.9rem, 1.45): side panel, rail, search field, GitHub link. Smaller steps: crumbs 0.875rem, footer 0.85rem, "On this page" heading 0.8rem 600 Slate, version chips 0.78rem 600, step direction 0.75rem.
- **Code** (mono, 0.875rem, 1.55 in blocks; 0.875em inline).

### Named Rules
**The Tabular Facts Rule.** Every number a reader compares is set in tabular numerals: version chips, release versions, the release-notes index, news dates, tables.

**The Mono Means Literal Rule.** Mono is for something to type or a file name, never for labels, dates or decoration.

## Layout

A centred grid up to 84rem wide with a responsive gutter of clamp(1rem, 3vw, 2rem). An inner page has three columns: the side panel (15rem), the reading column (up to 46rem) and the rail (12 to 15rem), with 3rem between them. The side panel and the rail are sticky at 1rem from the top; the side panel scrolls on its own when the group is long. Pages without a group drop the side panel; pages without facts drop the rail; section landings and search widen the single column to 66rem.

Below 1180px the rail disappears: a copy of the page facts sits in the text after the title and lead, and "On this page" is hidden. Below 1000px the tabs move to a second row of the masthead and scroll sideways. Below 860px the side panel disappears; the "More in [group]" block at the end of the text, with previous/next, carries group navigation on its own. Below 560px the search field takes a full row of the masthead, the logo shrinks to 170px and previous/next stack.

The home page is a sequence of full-width bands on a 76rem inner width: the navy hero (two columns, text and terminal), the Cool Paper release strip with three release lines, the three audience doors, the news list in two columns under a 2px Strong Ink rule, and a one-line help strip. Below 860px every one of these becomes a single column.

Vertical rhythm in the text: paragraphs, lists, code and tables 1.1rem apart; `h2` 2.75rem above; `h3` 2.1rem above; the group block 3.5rem below the text. The footer is pushed to the bottom of the window on short pages.

## Elevation & Depth

The system is flat. Depth comes from tone (Paper, Cool Paper, Navy Mist) and 1px hairlines. Two things float, and only those two cast a shadow.

### Shadow Vocabulary
- **Floating panel** (`box-shadow: 0 10px 30px rgba(0, 34, 74, .14)`): the search-as-you-type results that open below the search field.
- **Hero terminal** (`box-shadow: 0 24px 50px rgba(0, 0, 0, .25)`): the `mvn verify` terminal on the navy hero.

### Named Rules
**The Hairline Rule.** In-flow surfaces (facts, code, tables, steps, notes, landings) are separated by a 1px Hairline or a pale fill, never by a shadow. A shadow means the element floats above the page.

## Shapes

Gently rounded corners at one main radius (6px) for every box: buttons, search field, facts block, steps, code blocks, table wrappers, notes, the floating results panel. Smaller things get smaller radii: 4px for items in a group list, inline code and result rows; 3px for version chips; 2px for images and the focus ring. Borders are always 1px, except the 3px tab underline and the 2px rule above the home news list. The file-name tab above a code block is the one composite shape: square at the bottom, rounded at the top, joined to a code block whose top-left corner is squared off.

## Components

### Buttons
Two buttons, only on the navy hero; inside the frame, actions are links.
- **Shape:** gently rounded (6px), 600 weight, 0.75rem by 1.2rem.
- **Primary:** Feather Orange fill with Night Navy text: "Create your first project". Hover lightens to #ffae45.
- **Secondary:** transparent with a 1px white border at 45% and white text: "Download Maven". Hover: full white border and a 6% white wash.
- **Focus:** inside the hero, focus rings turn orange to stay visible on navy.

### Chips
- **Style:** version chips in the facts block: outlined, 1px navy border, navy 0.78rem 600 tabular text, 3px radius, no fill.
- **State:** a released line has a solid outline; an unreleased line (4.0) has a dashed outline and a title explaining it is not released yet.

### Cards / Containers
- **Facts block:** white with a 1px Hairline border, 6px radius, 0.8rem by 0.9rem padding; a two-column definition list (Holds for, Changed, Kind, Source) with Slate terms. Sits at the top of the rail, or after the lead on narrower screens.
- **Notes:** Cool Paper fill, 6px radius, 0.75rem by 1rem, no border. Version-bound notes use Feather Cream.
- **Start here:** a Navy Mist panel at the top of the Docs landing, pointing new users to the first guide.
- **Doors:** no box at all: a 1.45rem heading link, a Slate summary, then a list of links between Hairline rules.

### Inputs / Fields
- **Search:** Cool Paper fill, 1px Hairline border, 6px radius, 0.9rem text, a 16px inline SVG magnifier in Slate, 15rem wide in the masthead. The search page has a large version at full width and 1.05rem.
- **Focus:** a 2px navy outline flush with the field, and the fill turns white.
- **Results:** a floating white panel with a Firm Hairline border and the floating shadow; each result has a navy 600 title, a Slate meta line separated by middots, and an excerpt. The active result has a Navy Mist fill.

### Navigation
- **Tabs:** five section links in Ink at 0.975rem. Hover: navy text with a Firm Hairline underline. Active section: navy 600 with a 3px navy underline. On narrow screens they scroll sideways in their own row.
- **Side panel:** "All of [section]" with an inline SVG chevron in Slate; previous/next steps; the group's title in Strong Ink; the group's pages as a plain list. Hover gives a Cool Paper fill and navy text; the current page has a Navy Mist fill, navy 600 text and a 0.32rem orange dot at its left edge.
- **Previous / Next:** two bordered boxes (1px Hairline, 6px radius) with a 0.75rem Slate direction label above the page title; Next is right-aligned. Hover turns border and text navy.
- **Breadcrumbs:** Slate 0.875rem, section and group separated by a single `›`, underlined only on hover.
- **On this page:** a 0.8rem Slate heading over a list hanging from a 1px Hairline spine; links in Ink, navy on hover.
- **More in [group]:** after the text, above a Hairline rule: the group's pages in two balanced columns with the current one in bold, then previous/next side by side.
- **Footer:** Cool Paper band, 0.85rem Slate, a wrapped row of ASF links in Ink, the trademark line and the demo note.

### Prose and Code
- **Links:** navy, underlined 1px at 0.18em offset; hover thickens to 2px.
- **Code blocks:** Code Paper fill, 1px Hairline border, 6px radius, horizontal scroll for long lines, coloured by Rouge at build time in navy, feather purple, forest green, rust, deep blue and slate italic.
- **File-name tab:** an italic-only paragraph directly above a code block (*pom.xml*) becomes a Cool Paper tab in mono 0.85rem joined to the block.
- **Inline code:** Code Paper with a pale border and 4px radius; wraps anywhere.
- **Tables:** inside a scrolling wrapper with a Hairline border and 6px radius; Cool Paper header row; Hairline row rules; tabular numerals.
- **Heading anchors:** a link after `h2`/`h3`, invisible until the heading is hovered or the anchor is focused.

### Home
- **Hero:** navy band; Display headline in white; lead in #d7e1ee at 1.2rem up to 34rem; the two buttons; on the right the terminal: Night Navy, white hairline border, the floating hero shadow, an orange `$` prompt and a green "BUILD SUCCESS".
- **Release strip:** Cool Paper band under the hero; three release lines (current, maintained, upcoming), each a Strong Ink version, a Slate status line (navy 600 for the current line) and Download / Release notes links.
- **News:** a heading with an "All news" link over a 2px Strong Ink rule; items in two columns, each a tabular Slate date and an Ink title between Hairline rules.

### Named Rules
**The Built-In Navigation Rule.** Every navigation element (tabs, side panel, previous/next, breadcrumbs, "On this page", "More in", page facts) is in the HTML from the build. JavaScript may only enhance, as the search-as-you-type panel does, and the page must be complete without it.

**The Version-Honest Rule.** A page that holds for specific Maven versions says so in the facts block with version chips; a page that has not been checked says "Not yet checked against Maven 3.9, 3.10 and 4.0" in Slate instead of showing chips.

## Do's and Don'ts

### Do:
- **Do** use Wordmark Navy for every link and every active state, with a 1px underline that thickens to 2px on hover.
- **Do** keep reading text in the 46rem column at 1.0625rem / 1.65.
- **Do** separate in-flow content with 1px Hairline rules and Cool Paper or Navy Mist fills.
- **Do** mark the current page in a group with the Navy Mist fill, navy 600 text and the orange dot.
- **Do** show version applicability as outlined navy chips, dashed for an unreleased line.
- **Do** draw icons as inline SVG in `currentColor` (the search magnifier, the back chevron, the GitHub mark).
- **Do** set versions, dates and table figures in tabular numerals.
- **Do** keep focus visible: a 2px navy outline at 2px offset, orange on the navy hero.
- **Do** limit motion to 0.15s ease-out colour, border and background transitions, and only under `prefers-reduced-motion: no-preference`.

### Don't:
- **Don't** use Feather Orange for links, borders, headings or decoration; it marks position and the first action only.
- **Don't** introduce a second accent hue; feather purple and the other syntax colours stay inside code.
- **Don't** put a shadow on an in-flow surface; only the search results panel and the hero terminal float.
- **Don't** build navigation or content that needs JavaScript to appear.
- **Don't** bring back the Fluido skin, Bootstrap, or a second logo next to the Maven logo.
- **Don't** use mono outside code, commands and file names.
- **Don't** alter the Apache Maven logo or recolour Maven's navy and feather colours.
