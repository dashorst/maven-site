# The example, built with `mvn site`

The same restructured site as the Jekyll example in `jekyll/`, built by maven-site-plugin and
Doxia from `content/`, the way maven.apache.org is built today.

    doxia/build.sh                 # skin install, generate.py, mvn site; result in target/site/
    doxia/publish.sh               # the same, then on GitHub Pages in mvn-site/

Without the scripts it is two Maven commands:

    mvn -f doxia/skin/pom.xml install
    mvn site -Drat.skip

`-Drat.skip` because the files of the example have no Apache license header yet, which
apache-rat-plugin checks before the site is built.

Published at https://dashorst.github.io/maven-site/mvn-site/, next to the Jekyll example at
https://dashorst.github.io/maven-site/.

- `skin/` is the skin: `META-INF/maven/site.vm` is the frame of every page (tabs, side panel,
  previous and next, the page facts), with the stylesheet of the Jekyll example and two optional
  scripts: `js/page.js` (On this page, heading links) and `js/search.js` (search as you type).
- `generate.py` writes, from `jekyll/_data/` and `jekyll/_guide/`: `content/site.xml` (one menu,
  sections > groups > pages), the guide pages in `content/markdown/guide/`, the landing pages of
  sections and groups in `content/xhtml/`, the news, the A–Z index, the search page and the list
  of discrepancies. Needs PyYAML.
- `src/main/java/org/apache/maven/site/render/Highlight.java` colours the XML, Java and shell
  code blocks of `target/site` after `site:site`, with the class names of Rouge, so the
  stylesheet colours them without JavaScript.
- `src/main/java/org/apache/maven/site/render/SearchIndex.java` writes `target/site/search.json`
  after `site:site`, from the rendered pages: a record per page and per h2 section, for
  `js/search.js`. The pom runs it with exec-maven-plugin in the `site` phase.
- `port-jekyll-pages.py` ported the home page and the About page from the Jekyll build once; they
  are sources now, in `content/xhtml/`.

A page's facts come from its front matter: Doxia's Markdown parser writes every key as a
`<meta>` element, which the skin reads. `facts: none` leaves them out.

Doxia reads every heading as the start of a section and closes that section at the next
heading. In XHTML sources, a heading therefore has to be the first child of a `<section>` nested
as deep as its level; a heading inside a `<div>` leaves a section open across the div's end.

Not in this version: the date a page last changed, redirects from old addresses (Maven's own pages keep theirs), and the 404 page.
