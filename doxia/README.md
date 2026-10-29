<!--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
-->

# The example, built with `mvn site`

The same restructured site as the Jekyll example in `jekyll/`, built by maven-site-plugin and
Doxia from `content/`, the way maven.apache.org is built today.

    doxia/build.sh                 # skin install, mvn site; result in target/site/
    doxia/plugin-demo.sh           # the plugin sites in the same skin; target/plugin-demo/sites/
    doxia/publish.sh               # both, then on GitHub Pages in mvn-site/

Without the scripts it is two Maven commands:

    mvn -f doxia/skin/pom.xml install
    mvn site

Published at https://dashorst.github.io/maven-site/mvn-site/, next to the Jekyll example at
https://dashorst.github.io/maven-site/.

- `skin/` is the skin: `META-INF/maven/site.vm` is the frame of every page (tabs, side panel,
  previous and next, the page facts), with the stylesheet of the Jekyll example and two optional
  scripts: `js/page.js` (On this page, heading links) and `js/search.js` (search as you type).
- `content/` is the source of every page: `site.xml` is the menu (sections > groups > pages), and
  the pages live at the address they have on the site. The guide pages, the landing pages, the news
  and the home and About pages were written once from the Jekyll example's data; the scripts that
  did that are gone, so nothing outside Maven is needed to build.
- `src/main/java/org/apache/maven/site/render/Highlight.java` colours the XML, Java and shell
  code blocks of `target/site` after `site:site`, with the class names of Rouge, so the
  stylesheet colours them without JavaScript.
- `src/main/java/org/apache/maven/site/render/SearchIndex.java` writes `target/site/search.json`
  after `site:site`, from the rendered pages: a record per page and per h2 section, for
  `js/search.js`. The pom runs it with exec-maven-plugin in the `site` phase.
- `src/main/java/org/apache/maven/site/check/Addresses.java` keeps every address the site has
  published working; see below. `ThirdParty.java` fails the build when a page loads anything (a
  script, a stylesheet, a font, an image) from a host outside apache.org.

## Component sites

The skin also draws the sites of plugins and other components. A site without the "Site" menu keeps
the five sections of the main site as tabs, and gets a bar of its own under them: crumbs (Docs ›
Plugins for a plugin, Extend › Building blocks for anything else), its name, version and other
versions, its description from the POM, and its own sections, made from the menus of its `site.xml`
(each page of the first menu is a section, Plugin Documentation as Goals; every other menu is one
section). The side panel lists the pages of the current section. The home page opens with the
`<plugin>` or `<dependency>` to add to a POM. Its
`site.xml` can set `<custom><mavenSite>`: `main` (the main site, default https://maven.apache.org/),
`section`, `group`, `groupHref` and `archives`; see `site.vm`. `doxia/plugin-demo.sh` builds the 37
active plugins that have a repository of their own (`doxia/plugin-sites.txt`), each at the release on
maven.apache.org: the only change to a plugin is that its `site.xml` names the skin. For every
component at once, that would be the `site.xml` of maven-parent. A plugin released on a parent older
than maven-parent 44 uses maven-site-plugin 3.12 (Doxia 1), which cannot use this skin; those are
built with the site plugin of a newer parent.

Dark mode follows the reader's system setting, with `prefers-color-scheme`; there is no switch.

A page's facts come from its front matter: Doxia's Markdown parser writes every key as a
`<meta>` element, which the skin reads. `facts: none` leaves them out.

Doxia reads every heading as the start of a section and closes that section at the next
heading. In XHTML sources, a heading therefore has to be the first child of a `<section>` nested
as deep as its level; a heading inside a `<div>` leaves a section open across the div's end.

## Addresses

The pages moved to the addresses of the new structure, the same as in the Jekyll example. Every address
maven.apache.org published from this repository, with the anchors on each page, is listed in
`src/published-addresses.txt`, taken from a build of master. After `site:site`, `Addresses.java` follows
each one through the `.htaccess` files of the rendered site the way Apache httpd does, and fails the
build when an address leads nowhere or to a page without the anchor. CI runs `mvn verify site`, so a pull
request that breaks an address fails.

- A page that moved whole gets a `Redirect Permanent` in `content/filtered-resources/.htaccess`; a
  browser keeps the `#anchor` across the redirect, and the page keeps its anchors.
- A page that was split up or rewritten keeps its address, as a page in `content/xhtml/` that lists
  where each of its old sections is now, under the old anchor. With JavaScript it forwards straight to
  the section the address points at.
- The release notes moved to `/downloads/releases/<version>.html`, with one `RedirectMatch`.
- The download page stays at `/download.html`: the server's `download.cgi` fills in its mirror links.
- The files of the Fluido skin are retired on purpose, with `RedirectMatch gone`; the check lists them.

New pages are added to the list with `mvn site -Daddresses=record`; the list only grows. `doxia/publish.sh`
writes a forwarding page at every redirected address, because GitHub Pages ignores `.htaccess`.

Not in this version: the date a page last changed, and the 404 page.
