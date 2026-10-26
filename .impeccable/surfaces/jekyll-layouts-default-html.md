---
version: 1
slug: "jekyll-layouts-default-html"
primary_target: "jekyll/_layouts/default.html"
related_targets: []
---

# Surface brief: maven.apache.org site frame

Scope: the frame every page of the site renders in (header, section navigation, page facts, group navigation, footer), the five section landing pages (Docs, Downloads, News, Extend, Community), and the home page. Inner pages are Read mode; the home page is Persuade (key benefit first, a real call to action).

Audience and job: users who arrive with one question from a search engine or error message; plugin and extension authors; contributors to Maven. Each finds their section from the top tabs and stays oriented inside it.

Constraints: works fully without JavaScript; JS only enhances search. Maven logo, Maven navy for links and chrome, feather orange as the single accent. Every old URL redirects. Navigation per .impeccable/ia/navigation.txt (tree-tested 18/18).

## Direction contract

THESIS: The category standard, executed impeccably: a quiet docs frame where every page states its own facts (which Maven versions it holds for, when it last changed, where to edit). Refuses Fluido's menu wall and the logo pair: one site, five tabs, one short group list.

OWN-WORLD: White ground, ink #1d2433 text, Maven navy #003063 for links, the active tab and headings' accents, feather orange #f79a23 as the only accent (the "you are here" mark, the home call to action). Hairline #dde2ea rules, 6px radii, system sans for text, system mono for code only. Page facts block with outlined version chips.

STORY: The reader sees where they stand (tab, breadcrumb, group list), whether the page holds for their Maven version, reads the answer in a 70ch column, and moves on by previous/next or the group list at the bottom.

FIRST VIEWPORT: Inner page: header (Maven wordmark left, five tabs, search, the ASF oak leaf with "Apache" right; the header sits in the same 84rem container on every page) → left side panel with previous/next and the current group's pages (current one marked orange) → title, lead and text in the centre → right rail with the page-facts block above "On this page". Phone and medium widths: header, title, lead, page facts, text; group list with previous/next below the text. Page facts appear on every page with text; overview pages carry none: the section and group pages, search, A–Z, and the download page as the overview of Downloads (Martijn, 2026-10-26). Home: Maven's key benefit as the headline with `mvn verify`, "Create your first project" as the primary action and Download beside it, then the three doors, release lines and news.

FORM: Canon (the category standard), chosen by the user over the roll; seed 5b1a1d9e. Craft bar: Spring and Gradle documentation.

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
