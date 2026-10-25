# Writing the Maven guides

The guides live in `jekyll/_guide/`, one Markdown file per page, and are published under `/guides/`. Every page has one job, one of the four kinds below, and belongs to one topic. Readers find pages through search, through the topic pages that gather a topic's pages of every kind, and through the A–Z index. All three are built from the front matter, so the front matter is part of the content.

The pages are plain Markdown with YAML front matter and relative links. Jekyll builds them here, but nothing in them depends on Jekyll; the Doxia Markdown module reads the same files.

## Front matter

```yaml
---
title: Use a repository manager as a mirror
type: howto
topic: configure
summary: Send every download through your organisation's repository manager instead of Maven Central.
since: "3.9"
terms: [settings.xml, <mirrors>, <mirror>, <mirrorOf>]
keywords: [nexus, artifactory, reposilite, proxy repository, corporate repository, offline]
order: 20
source: [guides/mini/guide-mirror-settings.md, guides/mini/guide-configuring-maven.md]
---
```

- **title**: what the page is about, in the reader's words. How-to guides start with a verb ("Encrypt server passwords", "Build part of a multi-module project"); reference pages name the thing described ("settings.xml elements", "Reactor options"); explanation pages name the subject ("Where Maven reads its configuration"); tutorials name what the reader builds ("Create your first project").
- **type**: `tutorial`, `howto`, `reference` or `explanation`.
- **topic**: one of the ids in `jekyll/_data/guide.yml`.
- **summary**: one sentence, at most about 25 words, saying what the reader gets from the page. It is shown in listings and search results.
- **since**: the oldest release line the page is correct for, as a quoted string: `"3.9"`, `"3.10"` or `"4.0"`. See [Versions](#versions).
- **terms**: the files, POM and settings elements, command-line options, properties and plugins the page explains, written as the reader types them: `settings.xml`, `<mirrorOf>`, `-pl`, `maven.compiler.release`, `maven-toolchains-plugin`. They feed the A–Z index and rank highest in search after the title, so list the ones a reader would look up, not every element that appears in passing.
- **keywords**: words a reader may search for that are not in the title or summary: synonyms, product names, terms from Gradle or other tools, the error message they are seeing.
- **order**: position within the topic and kind, lowest first. Tutorials are read in this order.
- **source**: what the page was written from. A path under `content/markdown/` for a page of this site (`guides/mini/guide-using-toolchains.md`), or `apache/<repository>:<path>` for documentation in another repository (`apache/maven:impl/maven-core/src/site/markdown/inheritance.md`). The page it names shows a notice that links to the pages written from it, and the page's foot links back.

## The four kinds

**Tutorial**: a lesson. The reader builds something that works, step by step, and has a working result at the end of each step. Numbered steps, one way of doing things, no alternatives, no background beyond a sentence. Link to the explanation pages at the end instead of explaining along the way.

**How-to guide**: directions for a competent user with a goal. Open with one sentence on when you need it, then the steps, the configuration and the commands. Leave out what the reader does not need for this goal; mention a variant in a sentence and link to it. Link the reference and explanation behind a step where the step needs it.

**Reference**: a description of the machinery: elements, options, properties, files, the order of a lookup. Tables and lists with a consistent structure, complete within their scope, and short examples of use. No instructions and no reasoning. Where Maven generates the reference from its source (the POM and settings descriptors, the command-line options, the lifecycles), link to that instead of repeating it.

**Explanation**: why Maven works the way it does: the design, the trade-offs, the alternatives, how parts relate. No steps. Explanation is where "reactor", "effective POM" and "aggregation versus inheritance" are made to make sense.

A page that does two of these jobs is two pages. When a section starts explaining in the middle of a how-to guide, move it to an explanation page and link to it.

## Versions

The guide describes the release lines in `jekyll/_data/releases.yml`: Maven 3.9 and 3.10, and Maven 4.0 while it is a release candidate.

`since` holds the oldest line for which the page is correct. A page that holds on 3.9, 3.10 and 4.0 has `since: "3.9"`. A page about something only Maven 4 has, such as mixins or the `<subprojects>` element, has `since: "4.0"` and is marked as not yet released. Do not keep a second copy of a page for another line.

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
- The layout lists the other pages of the topic under every page, so do not end a page with a list of related pages; link in the text where a link helps.
- Link to other guide pages relatively, `mirror-settings.html`, to a section with `#Heading_text` in the form Doxia gives headings (spaces become `_`, other characters `.XX`). Link to the rest of the site relatively as well, `../settings.html#Mirrors`.
