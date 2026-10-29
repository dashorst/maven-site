/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.apache.maven.site.render;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.nodes.Node;
import org.jsoup.nodes.TextNode;
import org.jsoup.select.NodeTraversor;
import org.jsoup.select.NodeVisitor;

/**
 * Writes {@code search.json} into the rendered site: a record per page and per h2 section, for the
 * search as you type in the skin's {@code js/search.js}. Runs after {@code site:site}, over its
 * output; see the pom.
 *
 * <p>A page is indexed when the skin gave it page facts: overview pages (home, sections, groups,
 * news, search) have none. Release notes are left out. Per page the record holds its title, its
 * place in the menu (from the crumbs), its kind and Maven line (from {@code data-kind} and
 * {@code data-since} on {@code <main>}), the keywords and terms of its front matter, and its text;
 * names in {@code <code>} are indexed as terms, so {@code mirrorOf} finds {@code <mirrorOf>}.
 */
public class SearchIndex {
    private static final Pattern RELEASE_NOTES = Pattern.compile("downloads/releases/\\d[^/]*\\.html");
    private static final Pattern IDENTIFIER = Pattern.compile("<?[A-Za-z][\\w.-]*>?|--?[a-z][\\w-]*");
    private static final int SNIPPET = 160;

    /** One record of the index: a page, or one of its h2 sections. */
    private static final class Rec {
        String id;
        String url;
        String title;
        String page;
        String kind;
        String topic;
        String since;
        String text = "";
        String keywords = "";
        final Set<String> terms = new LinkedHashSet<>();
        final StringBuilder body = new StringBuilder();
    }

    public static void main(String[] args) throws IOException {
        Path site = Paths.get(args.length > 0 ? args[0] : "target/site");
        List<Rec> records = new ArrayList<>();
        List<Path> pages;
        try (Stream<Path> files = Files.walk(site)) {
            pages = files.filter(p -> p.toString().endsWith(".html")).sorted().collect(Collectors.toList());
        }
        int indexed = 0;
        for (Path file : pages) {
            String url = site.relativize(file).toString().replace('\\', '/');
            if (RELEASE_NOTES.matcher(url).matches()) {
                continue;
            }
            Document doc = Jsoup.parse(file.toFile(), "UTF-8");
            if (doc.selectFirst("main .facts") == null) {
                continue;
            }
            index(doc, url, records);
            indexed++;
        }
        Path out = site.resolve("search.json");
        Files.write(out, json(records).getBytes(StandardCharsets.UTF_8));
        System.out.println("Search index: " + indexed + " pages, " + records.size() + " records in " + out);
    }

    private static void index(Document doc, String url, List<Rec> records) {
        Element main = doc.selectFirst("main");
        Element prose = main.selectFirst(".prose").clone();
        prose.select(".facts, .anchor, h1, p.lead, script").remove();

        Rec page = new Rec();
        page.id = url;
        page.url = url;
        page.title = text(main.selectFirst(".prose h1"));
        page.page = page.title;
        page.kind = main.hasAttr("data-kind") ? main.attr("data-kind") : "page";
        page.since = main.attr("data-since");
        Element crumbs = main.selectFirst(".crumbs");
        page.topic = crumbs == null ? "" : crumbs.text();
        page.text = meta(doc, "description");
        page.keywords = meta(doc, "keywords");
        for (String term : meta(doc, "terms").split("\\s*\\|\\s*")) {
            if (!term.isEmpty()) {
                page.terms.add(term);
            }
        }
        records.add(page);

        // Walk the text in document order: every h2 starts a record of its own.
        Rec[] current = {page};
        NodeTraversor.traverse(
                new NodeVisitor() {
                    @Override
                    public void head(Node node, int depth) {
                        if (node instanceof Element) {
                            Element el = (Element) node;
                            if (el.normalName().equals("h2")) {
                                Rec section = new Rec();
                                section.id = url + "#" + anchor(el);
                                section.url = section.id;
                                section.title = el.text();
                                section.page = page.title;
                                section.kind = page.kind;
                                section.topic = page.topic;
                                section.since = page.since;
                                records.add(section);
                                current[0] = section;
                            } else if (el.normalName().equals("code")
                                    && el.text().length() < 60) {
                                Matcher m = IDENTIFIER.matcher(el.text());
                                while (m.find() && current[0].terms.size() < 30) {
                                    current[0].terms.add(m.group());
                                }
                            }
                        } else if (node instanceof TextNode && !inHeading(node)) {
                            current[0].body.append(((TextNode) node).text()).append(' ');
                        }
                    }

                    @Override
                    public void tail(Node node, int depth) {}
                },
                prose);

        for (Rec r : records.subList(records.indexOf(page), records.size())) {
            String body = r.body.toString().replaceAll("\\s+", " ").trim();
            r.body.setLength(0);
            r.body.append(body);
            if (r.text.isEmpty()) {
                r.text = body.length() > SNIPPET ? body.substring(0, SNIPPET) : body;
            }
        }
    }

    /** The id Doxia gave the section of a heading: on the heading, or on the {@code <a>} before it. */
    private static String anchor(Element h2) {
        if (h2.hasAttr("id")) {
            return h2.id();
        }
        Element before = h2.previousElementSibling();
        if (before != null && before.normalName().equals("a") && before.hasAttr("id")) {
            return before.id();
        }
        return h2.text().replaceAll("[^A-Za-z0-9_.-]+", "_");
    }

    private static boolean inHeading(Node node) {
        for (Node p = node.parent(); p != null; p = p.parent()) {
            if (p instanceof Element && ((Element) p).normalName().equals("h2")) {
                return true;
            }
        }
        return false;
    }

    private static String meta(Document doc, String name) {
        Element meta = doc.selectFirst("meta[name=" + name + "]");
        return meta == null ? "" : meta.attr("content").trim();
    }

    private static String text(Element el) {
        return el == null ? "" : el.text();
    }

    private static String json(List<Rec> records) {
        StringBuilder out = new StringBuilder("[");
        for (Rec r : records) {
            if (out.length() > 1) {
                out.append(",\n");
            }
            out.append('{');
            field(out, "id", r.id).append(',');
            field(out, "url", r.url).append(',');
            field(out, "title", r.title).append(',');
            field(out, "page", r.page).append(',');
            field(out, "kind", r.kind).append(',');
            field(out, "topic", r.topic).append(',');
            field(out, "since", r.since).append(',');
            field(out, "text", r.text).append(',');
            field(out, "keywords", r.keywords).append(',');
            field(out, "terms", String.join(" ", r.terms)).append(',');
            field(out, "body", r.body.toString());
            out.append('}');
        }
        return out.append("]\n").toString();
    }

    private static StringBuilder field(StringBuilder out, String name, String value) {
        out.append('"').append(name).append("\":\"");
        for (char c : (value == null ? "" : value).toCharArray()) {
            switch (c) {
                case '"':
                    out.append("\\\"");
                    break;
                case '\\':
                    out.append("\\\\");
                    break;
                case '\n':
                    out.append("\\n");
                    break;
                case '\r':
                case '\t':
                    out.append(' ');
                    break;
                default:
                    if (c < 0x20) {
                        out.append(String.format("\\u%04x", (int) c));
                    } else {
                        out.append(c);
                    }
            }
        }
        return out.append('"');
    }
}
