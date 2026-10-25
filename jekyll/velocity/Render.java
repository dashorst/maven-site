import java.io.*;
import java.net.URI;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.util.*;
import java.util.stream.*;
import javax.xml.parsers.DocumentBuilderFactory;
import org.apache.velocity.Template;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.VelocityEngine;
import org.w3c.dom.*;

/**
 * Renders the Velocity templates (*.vm) under content/ the way the Doxia site renderer does,
 * so the Jekyll build can read their output.
 *
 * The context holds the properties of pom.xml and of its parent POMs, read from Maven Central,
 * directly and as $context.get("name"), plus $esc for the escapes the templates use.
 *
 * Usage: java -cp <velocity jars> Render.java <repository root> <output directory>
 */
public class Render {
    public static class Esc {
        public String getH() { return "#"; }
        public String getHash() { return "#"; }
        public String getD() { return "$"; }
        public String getDollar() { return "$"; }
    }

    public static void main(String[] args) throws Exception {
        Path root = Paths.get(args[0]).toAbsolutePath();
        Path out = Paths.get(args[1]).toAbsolutePath();
        Path content = root.resolve("content");

        Map<String, Object> props = new LinkedHashMap<>();
        Document pom = parse(Files.newInputStream(root.resolve("pom.xml")));
        List<Document> chain = new ArrayList<>();
        chain.add(pom);
        Document current = pom;
        while (true) {
            Element parent = child(current.getDocumentElement(), "parent");
            if (parent == null) break;
            String g = text(parent, "groupId"), a = text(parent, "artifactId"), v = text(parent, "version");
            current = parse(fetch(g, a, v));
            chain.add(current);
        }
        // The nearest POM wins, so read from the farthest parent down.
        Collections.reverse(chain);
        for (Document d : chain) {
            Element p = child(d.getDocumentElement(), "properties");
            if (p == null) continue;
            NodeList nodes = p.getChildNodes();
            for (int i = 0; i < nodes.getLength(); i++) {
                if (nodes.item(i) instanceof Element e) props.put(e.getTagName(), e.getTextContent().trim());
            }
        }
        Element project = pom.getDocumentElement();
        props.put("project.version", text(project, "version"));

        List<Path> templates;
        try (Stream<Path> s = Files.walk(content)) {
            templates = s.filter(p -> p.toString().endsWith(".vm")).sorted().collect(Collectors.toList());
        }
        for (Path template : templates) {
            VelocityEngine engine = new VelocityEngine();
            engine.setProperty("resource.loaders", "file");
            engine.setProperty("resource.loader.file.path", template.getParent() + "," + content);
            engine.setProperty("resource.loader.file.cache", "false");
            engine.setProperty("parser.space_gobbling", "bc");
            engine.init();
            VelocityContext context = new VelocityContext();
            props.forEach(context::put);
            context.put("context", context);
            context.put("esc", new Esc());
            context.put("project", Map.of("version", props.get("project.version")));
            String name = template.getFileName().toString();
            context.put("currentFileName", name.substring(0, name.length() - 3));
            Template t = engine.getTemplate(template.getFileName().toString(), "UTF-8");
            Path target = out.resolve(content.relativize(template).toString().replaceAll("\\.vm$", ""));
            Files.createDirectories(target.getParent());
            try (Writer w = Files.newBufferedWriter(target, StandardCharsets.UTF_8)) {
                t.merge(context, w);
            }
            System.out.println("rendered " + content.relativize(template));
        }
    }

    static InputStream fetch(String g, String a, String v) throws Exception {
        Path local = Paths.get(System.getProperty("user.home"), ".m2", "repository",
                g.replace('.', '/'), a, v, a + "-" + v + ".pom");
        if (Files.exists(local)) return Files.newInputStream(local);
        String url = "https://repo.maven.apache.org/maven2/" + g.replace('.', '/') + "/" + a + "/" + v + "/" + a + "-" + v + ".pom";
        HttpResponse<InputStream> r = HttpClient.newHttpClient()
                .send(HttpRequest.newBuilder(URI.create(url)).build(), HttpResponse.BodyHandlers.ofInputStream());
        if (r.statusCode() != 200) throw new IOException(url + ": " + r.statusCode());
        return r.body();
    }

    static Document parse(InputStream in) throws Exception {
        try (in) {
            return DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(in);
        }
    }

    static Element child(Element e, String name) {
        NodeList nodes = e.getChildNodes();
        for (int i = 0; i < nodes.getLength(); i++) {
            if (nodes.item(i) instanceof Element c && c.getTagName().equals(name)) return c;
        }
        return null;
    }

    static String text(Element e, String name) {
        Element c = child(e, name);
        return c == null ? null : c.getTextContent().trim();
    }
}
