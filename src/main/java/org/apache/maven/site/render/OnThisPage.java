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
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

/**
 * Writes the "On this page" list into the rail of every rendered page, so that it is in the HTML
 * without JavaScript. The list holds the page's {@code h2} headings, or its {@code h2} and
 * {@code h3} headings when there are two {@code h2} or fewer; a page with fewer than two entries
 * gets no list. A rail left with nothing in it (a group landing without headings) is removed, and
 * the text takes its width.
 *
 * <p>A landing in groups ({@code <section class="landing-groups">}) gets a box per group above the
 * groups instead: the group's name, the definition from its {@code <p class="group-summary">},
 * which moves into the box, and the number of pages. The rail then goes.
 *
 * <p>The skin's js/page.js fills the list only when it is empty: on sites built without this step,
 * such as the plugin sites.
 */
public class OnThisPage {

    public static void main(String[] args) throws IOException {
        Path site = Paths.get(args.length > 0 ? args[0] : "target/site");
        List<Path> pages;
        try (Stream<Path> files = Files.walk(site)) {
            pages = files.filter(p -> p.toString().endsWith(".html")).collect(Collectors.toList());
        }
        int lists = 0;
        for (Path file : pages) {
            String html = new String(Files.readAllBytes(file), StandardCharsets.UTF_8);
            if (!html.contains("<nav id=\"on-this-page\"")) {
                continue;
            }
            Document doc = Jsoup.parse(html);
            doc.outputSettings().prettyPrint(false);
            Element toc = doc.getElementById("on-this-page");
            Element prose = doc.selectFirst("main .prose");
            if (toc == null || prose == null || !toc.children().isEmpty()) {
                continue;
            }
            Element groups = prose.selectFirst(".landing-groups");
            if (groups != null) {
                groups.before(doors(doc, groups));
                removeToc(toc);
                Files.write(file, doc.outerHtml().getBytes(StandardCharsets.UTF_8));
                lists++;
                continue;
            }
            List<Element> heads = prose.select("h2, h3").stream()
                    .filter(h -> h.closest("nav, aside, .facts") == null)
                    .collect(Collectors.toList());
            List<Element> h2s =
                    heads.stream().filter(h -> h.tagName().equals("h2")).collect(Collectors.toList());
            List<Element> listed = h2s.size() > 2 ? h2s : heads;
            if (listed.size() > 1) {
                toc.appendElement("h2").text("On this page");
                Element ul = toc.appendElement("ul");
                for (Element h : listed) {
                    Element li = ul.appendElement("li");
                    if (h.tagName().equals("h3")) {
                        li.addClass("sub");
                    }
                    li.appendElement("a").attr("href", "#" + idOf(doc, h)).text(h.text());
                }
                lists++;
            } else {
                removeToc(toc);
            }
            Files.write(file, doc.outerHtml().getBytes(StandardCharsets.UTF_8));
        }
        System.out.println("On this page: " + lists + " lists and group boxes written");
    }

    /** A box per group of a landing in groups, each a link to its group. */
    static Element doors(Document doc, Element groups) {
        Element nav = new Element("nav").addClass("group-doors").attr("aria-label", "Groups on this page");
        Element ul = nav.appendElement("ul");
        for (Element h : groups.select("h2")) {
            Element summary = h.nextElementSibling();
            int pages = h.parent().select("a.card").size();
            Element a = ul.appendElement("li").appendElement("a").attr("href", "#" + idOf(doc, h));
            a.appendElement("strong").text(h.text());
            if (summary != null && summary.hasClass("group-summary")) {
                a.appendElement("span").addClass("door-summary").text(summary.text());
                summary.remove();
            }
            Element count = a.appendElement("span").addClass("door-count").text(pages + " pages ");
            count.appendElement("span").attr("aria-hidden", "true").text("↓");
        }
        return nav;
    }

    /** Removes the empty "On this page", and the rail with it when nothing else is in it. */
    static void removeToc(Element toc) {
        Element rail = toc.parent();
        toc.remove();
        if (rail != null && rail.hasClass("rail") && rail.children().isEmpty()) {
            Element frame = rail.parent();
            rail.remove();
            if (frame != null) {
                frame.addClass("no-rail");
            }
        }
    }

    /**
     * The fragment that leads to a heading: its own id, the anchor Doxia writes just before it or
     * in it, the id of the section it opens, or else an id made from its text, which it then gets.
     */
    static String idOf(Document doc, Element h) {
        if (!h.id().isEmpty()) {
            return h.id();
        }
        Element anchor = h.selectFirst("a[id], a[name]");
        Element before = h.previousElementSibling();
        if (anchor == null && before != null && before.is("a[id], a[name]")) {
            anchor = before;
        }
        if (anchor != null) {
            return anchor.id().isEmpty() ? anchor.attr("name") : anchor.id();
        }
        Element section = h.parent();
        if (section != null
                && section.tagName().equals("section")
                && section.firstElementChild() == h
                && !section.id().isEmpty()) {
            return section.id();
        }
        String id = h.text().trim().replaceAll("[^A-Za-z0-9]+", "_").replaceAll("^_|_$", "");
        if (doc.getElementById(id) == null) {
            h.id(id);
        }
        return id;
    }
}
