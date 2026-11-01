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

# Writing the Maven guides

The guides live in `content/markdown/docs/<group>/`, one Markdown file per page, and are published at `/docs/<group>/<name>.html`. Every page has one job, one of the four kinds below. A page gets its place in the navigation from `content/site.xml`, under the group's item, and is listed on the group's landing page, `content/xhtml/docs/<group>/index.xhtml`. Readers find pages through those lists, through search and through the A–Z index; search and the index are built from the front matter, so the front matter is part of the content.

The pages are Markdown with front matter, read by the Doxia Markdown module. The license header comes after the front matter.

## Front matter

```yaml
---
title: Use a repository manager as a mirror
summary: Send every download through your organisation's repository manager instead of Maven Central.
type: howto
since: 3.9
keywords: nexus, artifactory, reposilite, proxy repository, corporate repository, offline
terms: settings.xml | <mirrors> | <mirror> | <mirrorOf>
---
```

- **title**: what the page is about, in the reader's words. How-to guides start with a verb ("Encrypt server passwords", "Build part of a multi-module project"); reference pages name the thing described ("settings.xml elements", "Reactor options"); explanation pages name the subject ("Where Maven reads its configuration"); tutorials name what the reader builds ("Create your first project").
- **summary**: one sentence, at most about 25 words, saying what the reader gets from the page. It is shown under the title, in listings and in search results.
- **type**: `tutorial`, `howto`, `reference` or `explanation`.
- **since**: the oldest release line the page is correct for: `3.9`, `3.10` or `4.0`. See [Versions](#versions).
- **keywords**: words a reader may search for that are not in the title or summary, separated by commas: synonyms, product names, terms from Gradle or other tools, the error message they are seeing.
- **terms**: the files, POM and settings elements, command-line options, properties and plugins the page explains, separated by `|`, written as the reader types them: `settings.xml`, `<mirrorOf>`, `-pl`, `maven.compiler.release`, `maven-toolchains-plugin`. They feed the A–Z index and rank highest in search after the title, so list the ones a reader would look up, not every element that appears in passing.

## Replacing a page

Every address the site has published keeps working, with every anchor on it; `mvn site` checks this against `src/published-addresses.txt` (see `src/main/java/org/apache/maven/site/check/`). When a new page takes over the content of an old one:

- If the old page moved to the new structure and the new page keeps its address, keep the headings that links point at, or add an `<a id="Old_heading"></a>` before the section that took its place.
- If the old content is split over several pages, turn the old address into a page that forwards: an XHTML file at the old path under `content/xhtml/` with a `<section class="moved">`, one list item per old anchor pointing at its new place, as in `content/xhtml/configure.xhtml`. Remove the `Redirect` for that address from `content/filtered-resources/.htaccess`.
- Run `mvn site`; the address check names every address or anchor that no longer leads anywhere.

## The four kinds

**Tutorial**: a lesson. The reader builds something that works, step by step, and has a working result at the end of each step. Numbered steps, one way of doing things, no alternatives, no background beyond a sentence. Link to the explanation pages at the end instead of explaining along the way.

**How-to guide**: directions for a competent user with a goal. Open with one sentence on when you need it, then the steps, the configuration and the commands. Leave out what the reader does not need for this goal; mention a variant in a sentence and link to it. Link the reference and explanation behind a step where the step needs it.

**Reference**: a description of the machinery: elements, options, properties, files, the order of a lookup. Tables and lists with a consistent structure, complete within their scope, and short examples of use. No instructions and no reasoning. Where Maven generates the reference from its source (the POM and settings descriptors, the command-line options, the lifecycles), link to that instead of repeating it.

**Explanation**: why Maven works the way it does: the design, the trade-offs, the alternatives, how parts relate. No steps. Explanation is where "reactor", "effective POM" and "aggregation versus inheritance" are made to make sense.

A page that does two of these jobs is two pages. When a section starts explaining in the middle of a how-to guide, move it to an explanation page and link to it.

## Diagrams

Draw a diagram where the relation between parts is the point and prose has to walk through it one part at a time: which version wins in a dependency graph, which classpath a dependency is on. Explanation pages need them most; a reference page gets one where a table hides a structure; a how-to guide or tutorial shows the output the reader will see instead. A list or a table is not a diagram. Everything a diagram shows is also in the text, so that nothing depends on seeing it.

- **Source.** One HTML file per diagram in `src/diagrams/<slug>.html`, with the SVG inline, drawn with the [diagram-design](https://github.com/cathrynlavery/diagram-design) skill and its rules: at most 9 nodes, the accent (Maven orange) on one or two elements, right-angled connectors. Each file carries the site's colours as classes, light and dark; copy them from an existing diagram.
- **Published file.** Export the SVG into `content/resources/images/docs/<group>/<slug>.svg` with the skill's `scripts/export_svg.py <source> <target> --system-fonts`. The SVG switches to dark colours by itself, and uses the site's fonts, loading none.
- **Size.** 720 wide, the width of the text column, so the labels keep their size; on a narrow screen the diagram scrolls sideways.
- **In the page.** A figure with the image, its size, an alt text that says in one sentence what the diagram shows (the SVG's `<desc>`), and a caption with its point:

```html
<figure class="diagram">
<img src="../../images/docs/dependencies/nearest-wins.svg" width="720" height="340" alt="The project depends on … Maven uses 1.11, which comes through the dependency declared first." />
<figcaption>Two versions at the same depth: the dependency declared first decides.</figcaption>
</figure>
```

## Versions

The guide describes the release lines Maven 3.9 and 3.10, and Maven 4.0 while it is a release candidate.

`since` holds the oldest line for which the page is correct. A page that holds on 3.9, 3.10 and 4.0 has `since: 3.9`. A page about something only Maven 4 has, such as mixins or the `<subprojects>` element, has `since: 4.0` and is marked as not yet released. Do not keep a second copy of a page for another line.

When a single paragraph differs between the lines, keep one page and mark the paragraph with a quote that starts with the line:

```markdown
> **Maven 4:** The `<modules>` element is called `<subprojects>`, and Maven finds
> subprojects in subdirectories without a list.
```

## Writing

- Address the reader as "you". Present tense, active voice, short sentences.
- Plain words before Maven words: say what something does before naming the element or plugin that does it.
- Show only the part of a file that matters, with the element that contains it, and name the file in italics above the block, like *pom.xml* or *~/.m2/settings.xml*.
- Commands are complete and run from the directory the text says. Show the output only where the reader needs to recognise it.
- Every command and configuration on a page is run on the lines in its `since` before the page is published: Maven 3.9.16 and 3.10.0, and 4.0.0-rc-7 for pages and notes about Maven 4.
- Headings in the page are `##` and `###`; the page title is the only `#` and comes from the front matter. Sections at `##` level appear in "On this page" and as search results of their own, so give them headings a reader would search for.
- The layout lists the other pages of the group beside and under every page, with the previous and next page, so do not end a page with a list of related pages; link in the text where a link helps.
- Link relatively to the page's new place: `mirror-settings.html`, `../reference/pom.html`, and to a section with `#Heading_text` in the form Doxia gives headings (spaces become `_`, other characters `.XX`). Link to a plugin or component site with its path on maven.apache.org, `../../plugins/maven-dependency-plugin/`.
