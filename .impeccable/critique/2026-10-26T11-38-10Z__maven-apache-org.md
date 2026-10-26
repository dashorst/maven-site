---
target: current maven site (maven.apache.org)
total_score: 20
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "url:https://maven.apache.org/"
timestamp: 2026-10-26T11-38-10Z
slug: maven-apache-org
---
Method: dual-agent (A: design review in browser · B: detector CLI + headless URL mode)

maven.apache.org scores 20/40 (Acceptable, bottom). Content and Download page are good; the frame is stock Bootstrap 2 with a 55–90-link menu on every page, no search, and on mobile 2–3.6 screens of logo and menu before the page title. The home page already splits Use / Extend / Contribute; every other page drops that split.

| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of System Status | 2 | Breadcrumb never shows the section; "Last Published" is the build date |
| 2 | Match System / Real World | 2 | "Index (category)", "Mojo", "Centre"; "Developers" means two different audiences |
| 3 | User Control and Freedom | 3 | Static pages; back, deep links and edit work |
| 4 | Consistency and Standards | 2 | Downloads to two URLs; Doxia/Plugins/Extensions/Archetypes twice in menu; chevrons look like toggles |
| 5 | Error Prevention | 2 | Pages don't say which Maven version they hold for |
| 6 | Recognition Rather Than Recall | 2 | No search; 4-level tree paths to remember |
| 7 | Flexibility and Efficiency | 1 | No search, no page TOC, no skip link |
| 8 | Aesthetic and Minimalist Design | 1 | Two logos, 3,330px menu, ~167 chars/line, four equal H1s |
| 9 | Error Recovery | 2 | 404 without search or suggestions |
| 10 | Help and Documentation | 3 | Broad content, organised as a tree not by task |
| Total | | 20/40 | Acceptable (bottom) |

Design specificity: nothing besides two competing logos is authored for Maven; UI color is Bootstrap #0088cc, not Maven navy/feather. Only authored decision: the Use/Extend/Contribute table on home.

Detector: low-contrast 94 (88 = one rule: link blue on code bg 3.6:1 on plugins; active nav white on #0088cc 3.9:1), line-length 8 (155–166 chars), text-overflow 2 (deeply nested nav labels), skipped-heading 1 (home h1→h3). False positives: border-accent-on-rounded/side-tab (Bootstrap carets), dark-glow (input focus, no inputs), layout-transition (.collapse/.progress unused), cramped-padding (prettify zebra lines). Overlay blocked by CSP script-src-elem.

Strengths: home Use/Extend/Contribute table; version-honest Download page; reading works fully without JS today.

Priority issues:
- [P1] Mobile: content after the whole menu (title at 2,062px home, 3,046px mirror settings; home 858px wide, plugins 656px; 26px targets). Fix: content first, no-JS menu disclosure, scrollable tables, 44px targets. /impeccable adapt
- [P1] No search; wayfinding via deep tree (90 links, 4 levels, 81px label columns). Fix: no-JS search form enhanced by JS, real breadcrumbs, page TOC. /impeccable layout
- [P1] Three audiences, one shared menu (Documentation mixes manual, plugin dev, contribute, Doxia, books; 19-item projects list on every page; committer material equal to first steps). Fix: per-audience nav, projects page, committer group. /impeccable distill
- [P2] Frame accessibility: link 3.89:1/3.58:1, nav headers & breadcrumb 2.61:1, logos alt="" (nameless home link, two empty H1s), no skip link (60–94 tab stops), menu as second banner landmark, multiple H1s. /impeccable audit, /impeccable harden
- [P2] Flat typography: 14/20px body, ~167 chars/line, title and section heads both 38.5px. /impeccable typeset

Persona red flags:
- Jordan: no link to Maven in 5 Minutes on home; "Run" leads to CLI syntax; 5-minutes page says "pay someone to explain this to you"; unexplained "POM".
- Casey: mirror settings title at 3,046px; no search for mirrorOf; only "Maven 3.8.0" as version info; home scrolls sideways.
- Sam: two empty H1s, nameless logo link, 60–94 tab stops, chevrons without state.
- Plugin author: visible TODO on Plugin Developers Centre; Maven 4 plugin row is a placeholder question; Your First Mojo doesn't name its API; Mojo API in the contributor area.
- First contributor: "Help Maven"/"Develop Maven" near-identical; contribute index 40 links with GPG keys and website deploy level with first steps; no link to core issues.

Minor: 145KB jQuery/Bootstrap JS + 127KB CSS for highlighting and anchors; no dark mode; plugin "Type*" column needs a footnote; Download stacks two H1s; home ends with paragraphs about the site itself.

Questions: If Maven itself says Use/Extend/Contribute on home, why should the nav say something else? What if "Last Published" became "Holds for Maven 3.9 · 3.10 · 4.0"? Is the 19-item projects list a stand-in for missing search? Which of the two logos is the brand?
