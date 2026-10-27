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
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.nodes.Entities;

/**
 * Colours the code blocks of the rendered site, so that no JavaScript is needed for it. Doxia
 * writes a fenced block as {@code <pre><code class="language-xml">}; this wraps its tokens in
 * spans with the class names of Rouge ({@code nt} tag, {@code na} attribute, {@code s} string,
 * {@code c} comment, {@code k} keyword...), which the skin's stylesheet colours. XML, Java and
 * shell are coloured; other blocks, and blocks that already hold markup, stay as they are.
 *
 * <p>Many of Maven's pages mark their blocks {@code ```unknown}; for those the language is guessed
 * from the text, as prettify did on the Fluido site. Doxia's {@code nohighlight} blocks stay plain.
 */
public class Highlight {

    /** A language: one pattern of alternatives, each a named group whose name is the class. */
    private static final Map<String, Pattern> LANGUAGES = Map.of(
            "xml",
            Pattern.compile(
                    "(?<c><!--.*?-->)"
                            + "|(?<cp><\\?.*?\\?>|<!DOCTYPE[^>]*>|<!\\[CDATA\\[.*?]]>)"
                            + "|(?<tag></?[\\w:.-]+)(?<attrs>(?:\\s+[\\w:.-]+\\s*=\\s*(?:\"[^\"]*\"|'[^']*'))*)\\s*(?<end>/?>)",
                    Pattern.DOTALL),
            "java",
            Pattern.compile(
                    "(?<cm>/\\*.*?\\*/)|(?<c1>//[^\\n]*)"
                            + "|(?<sb>\"\"\".*?\"\"\")|(?<s>\"(?:\\\\.|[^\"\\\\\\n])*\")|(?<sc>'(?:\\\\.|[^'\\\\\\n])+')"
                            + "|(?<nd>@[A-Za-z_][\\w.]*)"
                            + "|(?<k>\\b(?:abstract|assert|break|case|catch|class|continue|default|do|else|enum|extends|final"
                            + "|finally|for|if|implements|import|instanceof|interface|native|new|package|private|protected"
                            + "|public|record|return|static|super|switch|synchronized|this|throw|throws|transient|try"
                            + "|var|void|volatile|while|yield)\\b)"
                            + "|(?<kt>\\b(?:boolean|byte|char|double|float|int|long|short)\\b)"
                            + "|(?<kc>\\b(?:true|false|null)\\b)"
                            + "|(?<m>\\b\\d[\\d_]*(?:\\.\\d+)?[LlFfDd]?\\b)",
                    Pattern.DOTALL),
            "shell",
            Pattern.compile(
                    "(?<c>(?<=^|\\s)#[^\\n]*)"
                            + "|(?<s2>\"(?:\\\\.|[^\"\\\\])*\")|(?<s1>'[^']*')"
                            + "|(?<nv>\\$\\{[^}]*}|\\$[A-Za-z_]\\w*)",
                    Pattern.MULTILINE));

    /** The token classes of each language, in the order of its pattern. */
    private static final Map<Pattern, List<String>> CLASSES = Map.of(
            LANGUAGES.get("xml"), List.of("c", "cp"),
            LANGUAGES.get("java"), List.of("cm", "c1", "sb", "s", "sc", "nd", "k", "kt", "kc", "m"),
            LANGUAGES.get("shell"), List.of("c", "s2", "s1", "nv"));

    private static final Pattern LOOKS_LIKE_JAVA = Pattern.compile(
            "^\\s*(?:package|import)\\s+[\\w.]+;|\\b(?:public|private|protected)\\s+(?:static\\s+)?(?:final\\s+)?"
                    + "(?:class|interface|enum|record|void|[A-Z]\\w*(?:<[^>]*>)?)\\s|^\\s*@[A-Z]\\w*"
                    + "|\\bnew\\s+[A-Z]\\w*\\s*[(<].*;\\s*$",
            Pattern.MULTILINE);
    private static final Pattern LOOKS_LIKE_SHELL = Pattern.compile("^\\s*(?:\\$\\s+)?(?:mvn|mvnd|\\./mvnw|mvnw)\\b");

    private static final Pattern ATTRIBUTE = Pattern.compile("(\\s+)([\\w:.-]+)(\\s*=\\s*)(\"[^\"]*\"|'[^']*')");

    public static void main(String[] args) throws IOException {
        Path site = Paths.get(args.length > 0 ? args[0] : "target/site");
        List<Path> pages;
        try (Stream<Path> files = Files.walk(site)) {
            pages = files.filter(p -> p.toString().endsWith(".html")).collect(Collectors.toList());
        }
        int blocks = 0;
        for (Path file : pages) {
            String html = new String(Files.readAllBytes(file), StandardCharsets.UTF_8);
            if (!html.contains("<code class=\"language-")) {
                continue;
            }
            Document doc = Jsoup.parse(html);
            doc.outputSettings().prettyPrint(false);
            int before = blocks;
            for (Element code : doc.select("pre > code[class^=language-]")) {
                String language =
                        code.className().substring("language-".length()).split(" ")[0];
                if (language.equals("unknown")) {
                    language = guess(code.wholeText());
                }
                Pattern pattern = LANGUAGES.get(language.equals("bash") || language.equals("sh") ? "shell" : language);
                if (pattern == null || !code.children().isEmpty()) {
                    continue;
                }
                code.html(colour(code.wholeText(), pattern));
                code.parent().addClass("highlight");
                blocks++;
            }
            if (blocks > before) {
                Files.write(file, doc.outerHtml().getBytes(StandardCharsets.UTF_8));
            }
        }
        System.out.println("Highlight: " + blocks + " code blocks");
    }

    /** The language of a block that doesn't say: XML, Java or shell, or "unknown". */
    private static String guess(String text) {
        String t = text.trim();
        if (t.startsWith("<") && t.endsWith(">")) {
            return "xml";
        }
        if (LOOKS_LIKE_JAVA.matcher(t).find()) {
            return "java";
        }
        if (LOOKS_LIKE_SHELL.matcher(t).find()) {
            return "shell";
        }
        return "unknown";
    }

    private static String colour(String text, Pattern pattern) {
        StringBuilder out = new StringBuilder();
        Matcher m = pattern.matcher(text);
        int at = 0;
        while (m.find()) {
            out.append(escape(text.substring(at, m.start())));
            if (m.pattern().pattern().contains("(?<tag>") && m.group("tag") != null) {
                // An XML tag: the name and the brackets are a tag, each attribute a name and a string.
                out.append(span("nt", m.group("tag")));
                Matcher a = ATTRIBUTE.matcher(m.group("attrs"));
                while (a.find()) {
                    out.append(a.group(1)).append(span("na", a.group(2))).append(escape(a.group(3)));
                    out.append(span("s", a.group(4)));
                }
                out.append(escape(text.substring(m.end("attrs"), m.start("end"))));
                out.append(span("nt", m.group("end")));
            } else {
                for (String name : CLASSES.get(pattern)) {
                    if (m.group(name) != null) {
                        out.append(span(name, m.group(name)));
                        break;
                    }
                }
            }
            at = m.end();
        }
        return out.append(escape(text.substring(at))).toString();
    }

    private static String span(String cls, String text) {
        return "<span class=\"" + cls + "\">" + escape(text) + "</span>";
    }

    private static String escape(String text) {
        return Entities.escape(text);
    }
}
