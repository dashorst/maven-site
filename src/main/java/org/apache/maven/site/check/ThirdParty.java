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
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;

/**
 * Fails the build when a page of the rendered site makes the browser load something from another
 * host: a script, a stylesheet, a font, an image, a frame. The ASF privacy policy allows no
 * third-party requests; what the site needs, it serves itself. Links are not requests and are not
 * checked. Hosts under apache.org are the foundation's own.
 *
 * <p>Runs after {@code site:site}, over its output; see the pom. Usage: {@code ThirdParty <site>}
 */
public class ThirdParty {
    private static final Pattern URL = Pattern.compile("^(?:https?:)?//([^/:?#]+)", Pattern.CASE_INSENSITIVE);
    private static final Pattern CSS_URL = Pattern.compile("url\\(\\s*['\"]?([^'\")\\s]+)");
    private static final String LOADS = "script[src], img[src], img[srcset], iframe[src], frame[src], source[src],"
            + " source[srcset], video[src], video[poster], audio[src], embed[src], object[data], track[src],"
            + " input[type=image][src], link[href]";

    static boolean isThirdParty(String url) {
        Matcher m = URL.matcher(url.trim());
        if (!m.find()) {
            return false;
        }
        String host = m.group(1).toLowerCase();
        return !(host.equals("apache.org") || host.endsWith(".apache.org"));
    }

    static List<String> requests(Path file) throws IOException {
        List<String> found = new ArrayList<>();
        String name = file.getFileName().toString();
        if (name.endsWith(".css")) {
            Matcher m = CSS_URL.matcher(new String(Files.readAllBytes(file), StandardCharsets.UTF_8));
            while (m.find()) {
                if (isThirdParty(m.group(1))) {
                    found.add(m.group(1));
                }
            }
            return found;
        }
        Document doc = Jsoup.parse(file.toFile(), "UTF-8");
        for (Element e : doc.select(LOADS)) {
            if (e.tagName().equals("link")) {
                // a link element loads only for these relations; canonical, alternate and the like do not
                String rel = e.attr("rel").toLowerCase();
                if (!rel.matches(".*\\b(stylesheet|icon|preload|modulepreload|prefetch|manifest)\\b.*")) {
                    continue;
                }
            }
            for (String attr : new String[] {"src", "href", "data", "poster"}) {
                if (e.hasAttr(attr) && isThirdParty(e.attr(attr))) {
                    found.add(e.attr(attr));
                }
            }
            for (String attr : new String[] {"srcset"}) {
                for (String candidate : e.attr(attr).split(",")) {
                    if (!candidate.isBlank() && isThirdParty(candidate.trim().split("\\s+")[0])) {
                        found.add(candidate.trim());
                    }
                }
            }
        }
        for (Element e : doc.select("[style*=url(], style")) {
            Matcher m = CSS_URL.matcher(e.tagName().equals("style") ? e.data() : e.attr("style"));
            while (m.find()) {
                if (isThirdParty(m.group(1))) {
                    found.add(m.group(1));
                }
            }
        }
        return found;
    }

    public static void main(String[] args) throws IOException {
        Path site = Paths.get(args.length > 0 ? args[0] : "target/site");
        List<Path> files;
        // Files.walk does not follow the links to the component sites, which are built elsewhere
        try (Stream<Path> walk = Files.walk(site)) {
            files = walk.filter(Files::isRegularFile)
                    .filter(p -> p.toString().endsWith(".html") || p.toString().endsWith(".css"))
                    .sorted()
                    .collect(Collectors.toList());
        }
        List<String> problems = new ArrayList<>();
        for (Path file : files) {
            for (String url : requests(file)) {
                problems.add("/" + site.relativize(file).toString().replace('\\', '/') + " loads " + url);
            }
        }
        System.out.printf(
                "Third-party requests: %d files checked, %d requests to other hosts%n", files.size(), problems.size());
        problems.forEach(p -> System.out.println("  " + p));
        if (!problems.isEmpty()) {
            System.exit(1);
        }
    }
}
