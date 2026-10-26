# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Three audiences come to maven.apache.org, each with a different job:

1. **Users of Maven.** Java developers who build their projects with Maven: from someone typing `mvn` for the first time to a build engineer fixing a mirror, a proxy, a multi-module reactor or a toolchain in CI. They arrive from a search engine or an error message, mostly with one concrete question, and want the answer for the Maven version they run (3.9, 3.10 or 4.0).
2. **Developers for Maven.** The wider ecosystem that writes code Maven runs: plugin authors (Mojo API, plugin testing, plugin documentation), extension and lifecycle-participant authors, archetype authors, people publishing to Maven Central, tool builders consuming the repository layout and metadata, and Doxia/site-skin authors.
3. **Contributors to Maven itself.** People who fix, build, test and release Maven core and the Apache Maven plugins: first-time contributors looking for the conventions, committers looking for release procedures, GPG keys, website deployment and policies.

## Product Purpose

The documentation site of Apache Maven. This repository is a demonstration, built for the Maven project, of how their own site could work: the existing content, restructured by audience and by kind of page (Diátaxis), in a new frame that keeps Maven's identity. Success: a Maven committer opens it and recognises their own site, finds every page they know, and sees that each of the three audiences now has a clear front door and a short way to the answer.

## Positioning

It is Maven's own content, not a rewrite: every existing page is carried over, at a new home under its audience, with the old URL redirecting there. The demo proves the restructure is possible with the content they have, plus a user guide written from that content and checked against Maven 3.9.16, 3.10.0 and 4.0.0-rc-7.

## Operating Context

- Sources are the Doxia site sources in `content/` (Markdown, Velocity `.md.vm`, xdoc), built with Jekyll through the plugins in `jekyll/_plugins/`; the user guide lives in `jekyll/_guide/` and follows `GUIDE.md`.
- Many links point to sub-sites that are not in this repository (each plugin's site, `/ref/`, `/resolver/`, `/doxia/` component sites); these go to maven.apache.org.
- Published on GitHub Pages of the fork (https://dashorst.github.io/maven-site/, base URL `/maven-site`) through `jekyll/publish.sh`, and locally on the Tailscale server, port 4010.
- Readers use desktop browsers while coding, and phones to read or check something; a page must read well on both.

## Capabilities and Constraints

- **Works 100% without JavaScript.** One committer insists on it, and it is a binding constraint: reading, navigating, finding every page and every menu must work with JavaScript disabled. JavaScript is allowed only for non-essential enhancements that never block reading (for example search-as-you-type over the existing index, remembering the chosen Maven version). Every such feature needs a working no-JS path or must be safe to be absent.
- The Fluido skin is replaced by a frame of our own; no Bootstrap and no Fluido JavaScript.
- Pages move to new URLs grouped by audience; every old maven.apache.org URL in this build keeps working through a redirect page (meta refresh plus a plain link, so it works without JavaScript).
- Content of existing pages is not rewritten in this demo; only its place, its navigation and its frame change. The user guide and the News entries are the exception and are our own writing, from what Maven's pages say. Visible flaws that would embarrass the demo (a "pay someone to explain this to you" line, a published TODO, a placeholder row) are fixed, and every such fix is listed for the Maven project.
- Search works without JavaScript: the search form leads to a static index of every page by title and term; with JavaScript it searches as you type over the same index. No query goes to a third party.
- Release lines: 3.9 (maintained), 3.10 (current), 4.0 (upcoming, 4.0.0-rc-7), from `jekyll/_data/releases.yml`.

## Brand Commitments

- The Apache Maven logo stays as is: `content/resources/images/apache-maven-project-light-theme.svg` and `-dark-theme.svg`.
- The colors stay Maven's: the navy of the wordmark (`#003063`) and the feather's gradient (orange `#f79a23`, `#dd552c`, red `#d22128`, purple `#7c297d`).
- Simple over expressive: the site follows the category standard for documentation (top tabs, a short side panel, a reading column, page facts), chosen by Martijn on 2026-10-26 over more expressive visual worlds. Links and chrome in Maven navy, the feather orange as the single accent.
- It is an Apache Software Foundation project: the ASF links (license, sponsorship, security, thanks, privacy) and the trademark footer stay.

## Evidence on Hand

- About 284 existing pages in `content/`, the menu in `content/site.xml`, and the 19-page Diátaxis user guide in `jekyll/_guide/` (four topics: start, configure, multi-module, jdk).
- The list of more than 40 discrepancies the guide writers found in Maven's current docs (in the conversation, not yet in a file).
- No testimonials, statistics, download counts or user quotes are on hand; do not invent them.

## Product Principles

1. Three front doors, one site: each audience gets its own entry and navigation, and no audience has to wade through another's pages to find theirs.
2. Nothing lost: every page Maven has today can be found, and every old URL still arrives.
3. Reading never depends on JavaScript.
4. Their content, their identity: restructure and reframe, don't rebrand or rewrite.
5. Version-honest: pages say which Maven version they hold for.

## Accessibility & Inclusion

The no-JavaScript constraint above. Beyond it, the usual WCAG 2.2 AA for a public documentation site: keyboard navigation, visible focus, sufficient contrast, readable without CSS.
