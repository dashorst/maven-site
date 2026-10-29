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
package org.apache.maven.site.check;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

/**
 * Keeps every address the site has published working: each file, and each anchor on a page.
 *
 * <p>The addresses are listed in {@code src/published-addresses.txt}, one file per line, followed by
 * the ids on that page that a link could point at. The list only grows: an address, once
 * published, stays on it.
 *
 * <ul>
 * <li>{@code check <site> <list>} follows every listed address through the {@code .htaccess} files
 *     of the rendered site, as Apache httpd would, and fails when one leads nowhere, or to a page
 *     without the anchor. Runs after {@code site:site}; see the pom.</li>
 * <li>{@code record <site> <list>} adds the files and anchors of the rendered site to the list.</li>
 * <li>{@code pages <site> <list>} writes a page that forwards to the new address at every listed
 *     address that a redirect leads away from, for a server that ignores {@code .htaccess}, such as
 *     GitHub Pages.</li>
 * </ul>
 *
 * <p>Of {@code .htaccess} it reads {@code Redirect} and {@code RedirectMatch}. Like mod_alias, the
 * rules of a directory come before those of its parents, and the first rule that matches wins,
 * also over a file that exists. A redirect to a part of maven.apache.org that this build does not
 * write (a plugin site, {@code /ref/}, {@code download.cgi}) is not followed further. An address that a
 * {@code Redirect gone} rule matches was retired on purpose: it is listed, not counted as broken.
 */
public class Addresses {
    private static final String HOST = "maven.apache.org";
    private static final Pattern ABSOLUTE = Pattern.compile("^https?://([^/]+)(/.*)?$");
    private static final Pattern GROUP = Pattern.compile("\\$(\\d)");

    /** A Redirect or RedirectMatch line. */
    private static final class Rule {
        Pattern regex;
        String prefix;
        String target;
        boolean gone;
        String source;

        /** The address this rule sends path to, or null when it does not match. */
        String apply(String path) {
            if (regex != null) {
                Matcher m = regex.matcher(path);
                if (!m.find()) {
                    return null;
                }
                if (gone) {
                    return "";
                }
                Matcher g = GROUP.matcher(target);
                StringBuilder sb = new StringBuilder();
                while (g.find()) {
                    int n = Integer.parseInt(g.group(1));
                    String value = n <= m.groupCount() && m.group(n) != null ? m.group(n) : "";
                    g.appendReplacement(sb, Matcher.quoteReplacement(value));
                }
                g.appendTail(sb);
                return sb.toString();
            }
            boolean matches = path.equals(prefix)
                    || path.startsWith(prefix) && (prefix.endsWith("/") || path.charAt(prefix.length()) == '/');
            if (!matches) {
                return null;
            }
            return gone ? "" : target + path.substring(prefix.length());
        }
    }

    /** Where an address ends up. */
    private static final class Outcome {
        String path;
        boolean outside;
        boolean gone;
        String problem;
        final List<String> hops = new ArrayList<>();
    }

    private final Path site;
    private final Map<String, List<Rule>> rules = new TreeMap<>();
    private final Set<String> outsideRoots = new TreeSet<>();
    private final Set<String> ownDirectories = new TreeSet<>();

    Addresses(Path site) throws IOException {
        this.site = site;
        try (Stream<Path> files = Files.walk(site)) {
            for (Path file : files.filter(p -> p.getFileName().toString().equals(".htaccess"))
                    .collect(Collectors.toList())) {
                String dir = "/" + site.relativize(file.getParent()).toString().replace('\\', '/');
                rules.put(dir.endsWith("/") ? dir : dir + "/", parse(file));
            }
        }
        // the component sites are links to directories this build does not write, as on the server
        try (Stream<Path> top = Files.list(site)) {
            top.filter(Files::isSymbolicLink).forEach(p -> outsideRoots.add(p.getFileName().toString()));
        }
    }

    private static List<Rule> parse(Path file) throws IOException {
        List<Rule> list = new ArrayList<>();
        for (String line : Files.readAllLines(file, StandardCharsets.UTF_8)) {
            String[] w = line.trim().split("\\s+");
            if (w.length < 2 || !(w[0].equalsIgnoreCase("Redirect") || w[0].equalsIgnoreCase("RedirectMatch")
                    || w[0].equalsIgnoreCase("RedirectPermanent"))) {
                continue;
            }
            int i = 1;
            Rule r = new Rule();
            r.source = file.getFileName() + ": " + line.trim();
            if (!w[0].equalsIgnoreCase("RedirectPermanent")
                    && w[i].matches("(?i)permanent|temp|seeother|gone|\\d{3}")) {
                r.gone = w[i].equalsIgnoreCase("gone") || w[i].equals("410");
                i++;
            }
            if (w[0].equalsIgnoreCase("RedirectMatch")) {
                r.regex = Pattern.compile(w[i]);
            } else {
                r.prefix = w[i];
            }
            r.target = i + 1 < w.length ? w[i + 1] : null;
            if (r.target == null && !r.gone) {
                continue;
            }
            list.add(r);
        }
        return list;
    }

    /** The rules that apply to path: those of its own directory first, then of each parent. */
    private List<Rule> rulesFor(String path) {
        List<Rule> list = new ArrayList<>();
        String dir = path.substring(0, path.lastIndexOf('/') + 1);
        while (true) {
            List<Rule> here = rules.get(dir);
            if (here != null) {
                list.addAll(here);
            }
            if (dir.equals("/")) {
                return list;
            }
            dir = dir.substring(0, dir.lastIndexOf('/', dir.length() - 2) + 1);
        }
    }

    Outcome follow(String path) {
        Outcome o = new Outcome();
        for (int hop = 0; hop < 10; hop++) {
            String next = null;
            for (Rule r : rulesFor(path)) {
                next = r.apply(path);
                if (next != null) {
                    o.hops.add(r.source);
                    break;
                }
            }
            if (next == null) {
                break;
            }
            if (next.isEmpty()) {
                o.gone = true;
                return o;
            }
            Matcher m = ABSOLUTE.matcher(next);
            if (m.matches()) {
                if (!m.group(1).equals(HOST)) {
                    o.outside = true;
                    o.path = next;
                    return o;
                }
                next = m.group(2) == null ? "/" : m.group(2);
            }
            path = next;
        }
        if (o.hops.size() >= 10) {
            o.problem = "redirects in a loop";
            return o;
        }
        if (path.endsWith("/")) {
            path += "index.html";
        } else if (Files.isDirectory(file(path))) {
            path += "/index.html";
        }
        o.path = path;
        if (!Files.exists(file(path))) {
            if (!o.hops.isEmpty() && isOutside(path)) {
                o.outside = true;
            } else {
                o.problem = "leads to " + path + ", which does not exist";
            }
        }
        return o;
    }

    /** True when path is in a part of the server that this build does not write. */
    private boolean isOutside(String path) {
        String[] segments = path.substring(1).split("/");
        // download.cgi, the server's script that picks a mirror
        if (outsideRoots.contains(segments[0]) || path.endsWith(".cgi")) {
            return true;
        }
        // a plugin or component site next to this build's own pages: /plugins/maven-jar-plugin/
        String dir = path.substring(0, path.lastIndexOf('/') + 1);
        return !ownDirectories.contains(dir) && !Files.isDirectory(file(dir));
    }

    private Path file(String path) {
        return site.resolve(path.substring(1));
    }

    /** The ids on a page a link could point at: those of the content, not of the frame. */
    static Set<String> anchors(Path page) throws IOException {
        Document doc = Jsoup.parse(page.toFile(), "UTF-8");
        Element content = doc.selectFirst("main#bodyColumn, main#content, main");
        Element root = content != null ? content : doc.body();
        Set<String> ids = new TreeSet<>();
        if (root == null) {
            return ids;
        }
        for (Element e : root.select("[id], a[name]")) {
            if (e == root) {
                continue;
            }
            ids.add(e.hasAttr("id") ? e.id() : e.attr("name"));
        }
        ids.removeIf(id -> id.isEmpty() || id.contains(" "));
        return ids;
    }

    static Map<String, Set<String>> read(Path list) throws IOException {
        Map<String, Set<String>> addresses = new TreeMap<>();
        if (!Files.exists(list)) {
            return addresses;
        }
        for (String line : Files.readAllLines(list, StandardCharsets.UTF_8)) {
            if (line.isBlank() || line.startsWith("#")) {
                continue;
            }
            String[] w = line.trim().split("\\s+");
            Set<String> ids = addresses.computeIfAbsent(w[0], k -> new TreeSet<>());
            for (int i = 1; i < w.length; i++) {
                ids.add(w[i]);
            }
        }
        return addresses;
    }

    static void write(Path list, Map<String, Set<String>> addresses) throws IOException {
        List<String> lines = new ArrayList<>();
        lines.add("# Every address maven.apache.org has published from this repository: a file, and the ids on");
        lines.add("# that page a link could point at. The list only grows. `mvn site` checks that each address");
        lines.add("# still leads to a page with the id, through the redirects in the .htaccess files.");
        lines.add("# Add the addresses of new pages with -Daddresses=record; see src/main/java/org/apache/maven/");
        lines.add("# site/check/Addresses.java.");
        addresses.forEach((path, ids) -> lines.add(ids.isEmpty() ? path : path + " " + String.join(" ", ids)));
        Files.write(list, lines, StandardCharsets.UTF_8);
    }

    /** Every file of the rendered site, with the anchors of its pages. */
    Map<String, Set<String>> published() throws IOException {
        Map<String, Set<String>> addresses = new TreeMap<>();
        List<Path> files;
        try (Stream<Path> walk = Files.walk(site)) {
            files = walk.filter(Files::isRegularFile)
                    .filter(p -> !p.getFileName().toString().equals(".htaccess"))
                    .collect(Collectors.toList());
        }
        for (Path f : files) {
            String path = "/" + site.relativize(f).toString().replace('\\', '/');
            addresses.put(path, path.endsWith(".html") ? anchors(f) : new TreeSet<>());
        }
        return addresses;
    }

    int check(Map<String, Set<String>> addresses) throws IOException {
        List<String> problems = new ArrayList<>();
        int redirected = 0;
        int outside = 0;
        List<String> retired = new ArrayList<>();
        for (Map.Entry<String, Set<String>> a : addresses.entrySet()) {
            Outcome o = follow(a.getKey());
            if (o.problem != null) {
                problems.add(a.getKey() + " " + o.problem + (o.hops.isEmpty() ? "" : " (" + String.join(" > ", o.hops) + ")"));
                continue;
            }
            if (o.gone) {
                retired.add(a.getKey());
                continue;
            }
            if (!o.hops.isEmpty()) {
                redirected++;
            }
            if (o.outside) {
                outside++;
                continue;
            }
            if (!a.getValue().isEmpty() && o.path.endsWith(".html")) {
                Set<String> missing = new LinkedHashSet<>(a.getValue());
                missing.removeAll(anchors(file(o.path)));
                // an id the page still has outside its content, in a frame of its own
                if (!missing.isEmpty()) {
                    String html = new String(Files.readAllBytes(file(o.path)), StandardCharsets.UTF_8);
                    missing.removeIf(id -> html.contains("id=\"" + id + "\"") || html.contains("name=\"" + id + "\""));
                }
                if (!missing.isEmpty()) {
                    problems.add(a.getKey() + (o.path.equals(a.getKey()) ? "" : " > " + o.path)
                            + " lacks #" + String.join(" #", missing));
                }
            }
        }
        System.out.printf(
                "Addresses: %d published, %d redirected, %d to sites outside this build, %d retired, %d broken%n",
                addresses.size(), redirected, outside, retired.size(), problems.size());
        if (!retired.isEmpty()) {
            System.out.println("Retired on purpose, with Redirect gone: " + String.join(" ", retired));
        }
        problems.forEach(p -> System.out.println("  " + p));
        return problems.size();
    }

    int pages(Map<String, Set<String>> addresses) throws IOException {
        int written = 0;
        for (String path : addresses.keySet()) {
            if (!path.endsWith(".html") || Files.exists(file(path))) {
                continue;
            }
            Outcome o = follow(path);
            if (o.problem != null || o.gone || o.hops.isEmpty()) {
                continue;
            }
            String to = o.path;
            if (!o.outside || to.startsWith("/")) {
                Path from = Paths.get(path).getParent();
                to = from.relativize(Paths.get(to)).toString().replace('\\', '/');
            }
            String canonical = o.path.startsWith("/") ? "https://" + HOST + o.path : o.path;
            String html = "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"><title>Moved</title>\n"
                    + "<meta http-equiv=\"refresh\" content=\"0; url=" + to + "\">\n"
                    + "<link rel=\"canonical\" href=\"" + canonical + "\">\n"
                    + "<meta name=\"robots\" content=\"noindex\">\n"
                    + "<script>location.replace('" + to + "' + location.hash)</script></head>\n"
                    + "<body><p>This page has moved to <a href=\"" + to + "\">" + canonical + "</a>.</p></body></html>\n";
            Files.createDirectories(file(path).getParent());
            Files.write(file(path), html.getBytes(StandardCharsets.UTF_8));
            written++;
        }
        System.out.printf("Addresses: wrote %d pages that forward to a new address%n", written);
        return 0;
    }

    public static void main(String[] args) throws IOException {
        if (args.length != 3) {
            System.err.println("Usage: Addresses check|record|pages <site> <list>");
            System.exit(2);
        }
        Addresses addresses = new Addresses(Paths.get(args[1]));
        Path list = Paths.get(args[2]);
        Map<String, Set<String>> known = read(list);
        known.keySet().forEach(path -> addresses.ownDirectories.add(path.substring(0, path.lastIndexOf('/') + 1)));
        switch (args[0]) {
            case "record":
                Map<String, Set<String>> published = addresses.published();
                int before = known.size();
                published.forEach((path, ids) -> known.computeIfAbsent(path, k -> new TreeSet<>()).addAll(ids));
                write(list, known);
                System.out.printf("Addresses: %d new, %d listed%n", known.size() - before, known.size());
                break;
            case "check":
                if (addresses.check(known) > 0) {
                    System.exit(1);
                }
                break;
            case "pages":
                addresses.pages(known);
                break;
            default:
                System.err.println("Unknown mode " + args[0]);
                System.exit(2);
        }
    }
}
