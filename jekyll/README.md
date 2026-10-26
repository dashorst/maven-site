# maven.apache.org, restructured: a demonstration

This branch builds the pages of this repository with Jekyll instead of the Doxia site
renderer, in a new frame and a new structure: five sections (Docs, Downloads, News, Extend,
Community), each a list of groups of pages, and a user guide in which every page does one job:
a tutorial, a how-to guide, reference or explanation (see [GUIDE.md](../GUIDE.md)). Maven's
pages keep their text (see [CONTENT-FIXES.md](../CONTENT-FIXES.md) for the one exception);
they move to new URLs, and every old URL redirects. The site works without JavaScript.

- `_data/site_map.yml` is the structure: sections, groups and pages in reading order, the
  guide pages that replace Maven pages, and the redirects of old index pages.
- `_plugins/site_map.rb` gives every page its URL from the site map, writes a redirect page
  at its old URL, and gives every page its navigation (group, previous, next) and its facts
  (the Maven versions it holds for, the date its source last changed in git, the file to
  edit). It generates the section and group pages, the search page and the news feed.
- `_plugins/doxia_content.rb` reads `content/markdown`, `content/xdoc` and `content/resources`,
  and adds what Doxia adds: heading ids in Doxia's form and the toc macro. It points links at
  the new URLs, and links to pages outside this build, such as the plugin sites and `/ref/`,
  at maven.apache.org.
- `velocity/render.sh` renders the Velocity templates (`*.vm`) first, with Velocity itself and
  the properties of `pom.xml` and its parents, as the Doxia site renderer does.
- `_plugins/guide.rb` checks the guide's front matter, builds the A–Z index and the search
  index, which covers every page of the site. `skin/js/search.js` runs the search as you
  type; without it, the search form opens `/search.html`, which lists every page.
- `_guide/` holds the guide pages; `_data/guide.yml` the kinds, `_data/releases.yml` the Maven
  lines they describe, `_data/news.yml` the News, each entry with the source of its date.
- `skin/css/maven.css` is the whole stylesheet; `pages/index.html` the home page.
- `skin/images/oakleaf.svg` is the ASF's oak leaf as the ASF publishes it at
  https://www.apache.org/images/oakleaf.svg; the Maven wordmark is `content/resources/images/logos/MavenLogoLeaf.svg`.

Build with `jekyll/build.sh` (Java 17+ on the host, Jekyll in a `ruby:3.3` container named
`maven-site-jekyll` that mounts the repository at `/site`).
