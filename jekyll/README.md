# maven.apache.org with Jekyll: a demonstration

This branch builds the pages of this repository with Jekyll instead of the Doxia site
renderer, in the Fluido skin of maven.apache.org, and adds a user guide in which every
page does one job: a tutorial, a how-to guide, reference or explanation
(see [GUIDE.md](../GUIDE.md)). Nothing in `content/` is changed; `mvn site` still builds it.

- `_plugins/doxia_content.rb` reads `content/markdown`, `content/xdoc` and `content/resources`
  at the URLs they have on maven.apache.org, and adds what Doxia adds: heading ids in Doxia's
  form, the toc macro, table styles. Links to pages outside this build, such as the plugin
  sites and `/ref/`, go to maven.apache.org.
- `velocity/render.sh` renders the Velocity templates (`*.vm`) first, with Velocity itself and
  the properties of `pom.xml` and its parents, as the Doxia site renderer does.
- `_plugins/doxia_menu.rb` builds the menu from `content/site.xml`.
- `_plugins/guide.rb` builds the guide's topic pages, kind pages, A–Z index and the search
  index, which covers every page of the site. `skin/js/guide.js` runs the search.
- `_guide/` holds the guide pages; `_data/guide.yml` the topics, `_data/releases.yml` the
  Maven lines they describe.

Build with `jekyll/build.sh` (Java 17+ on the host, Jekyll in a `ruby:3.3` container named
`maven-site-jekyll` that mounts the repository at `/site`).
