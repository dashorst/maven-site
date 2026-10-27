"""Ports the home page and the About page of the Jekyll example (from _site/, after a Jekyll
build) to XHTML sources for Doxia, content/xhtml/, with links mapped to this build. Run once;
the result is a source like any other. Needs lxml, cssselect and PyYAML."""
import os, re, runpy, sys
from lxml import html, etree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
g = runpy.run_path('doxia/generate.py')
j2d = g['jekyll_to_doxia']
tree = g['tree']
site_dir = os.path.join(ROOT, '_site')

def map_url(path):
    path, _, frag = path.partition('#')
    if path in j2d: path = j2d[path]
    m = re.match(r'^/downloads/releases/(.+)\.html$', path)
    if m: path = '/docs/%s/release-notes.html' % m.group(1)
    if path == '/downloads/index.html': path = '/download.html'
    if path in ('/search.json',): return None
    return path + ('#' + frag if frag else '')

unresolved = set()
def port(src, out, title, select, drop=()):
    doc = html.parse(os.path.join(site_dir, src)).getroot()
    body = doc.cssselect(select)[0]
    for sel in drop:
        for el in body.cssselect(sel): el.drop_tree()
    page_url = '/' + out
    for a in body.iter():
        for attr in ('href', 'src', 'action'):
            v = a.get(attr)
            if not v or not v.startswith('/') or v.startswith('//'): continue
            if v.startswith('/maven-site'): v = v[len('/maven-site'):] or '/index.html'
            p = map_url(v)
            if p is None: continue
            target = p.split('#')[0]
            if not os.path.exists(os.path.join(ROOT, 'target/site', target.lstrip('/'))) and target not in ('/' + out,):
                unresolved.add((out, target))
            rel = os.path.relpath(target, os.path.dirname(page_url)) if target else ''
            a.set(attr, rel + ('#' + p.split('#')[1] if '#' in p else ''))
    inner = (body.text or '') + ''.join(etree.tostring(c, encoding='unicode', method='xml') for c in body)
    inner = re.sub(r' xmlns(:\w+)?="[^"]*"', '', inner)
    path = os.path.join(ROOT, 'content/xhtml', out.replace('.html', '.xhtml'))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write('<!DOCTYPE html>\n<html xmlns="http://www.w3.org/1999/xhtml">\n<head>\n<title>%s</title>\n<meta name="facts" content="none" />\n</head>\n<body>\n%s\n</body>\n</html>\n' % (title, inner.strip()))

port('index.html', 'index.html', 'Apache Maven', 'main#content')
port('about-this-example.html', 'about-this-example.html', 'About this example', '.prose', drop=('.facts', 'a.anchor', 'script'))
for u in sorted(unresolved): print('unresolved', u)

# Doxia reads every heading as the start of a section and closes it at the next heading, wherever
# that is; a heading inside a <div> then leaves a section open across the div's end. A heading
# stays where it is when it is the first child of a <section> nested as deep as its level. So the
# home page uses <section> only where a heading starts, divs elsewhere, and wraps everything
# below the hero in one section, so its h2s sit two deep.
from lxml import etree
p = os.path.join(ROOT, 'content/xhtml/index.xhtml')
t = etree.parse(p)
X = '{http://www.w3.org/1999/xhtml}'
body = t.getroot().find(X + 'body')
for s in body.iter(X + 'section'):
    s.tag = X + 'div'
for h in body.iter(X + 'h1', X + 'h2', X + 'h3'):
    h.attrib.pop('id', None)
    parent = h.getparent()
    assert parent[0] is h, 'heading not first in its parent: ' + (h.text or '')
    parent.tag = X + 'section'
    for a in ('aria-labelledby',):
        parent.attrib.pop(a, None)
kids = list(body)
hero, rest = kids[0], kids[1:]
wrapper = etree.SubElement(body, X + 'section')
wrapper.set('class', 'home-body')
for k in rest:
    wrapper.append(k)
def depth(el):
    d = 0
    while el is not None:
        if el.tag == X + 'section': d += 1
        el = el.getparent()
    return d
for h in body.iter(X + 'h1', X + 'h2', X + 'h3'):
    lvl = int(h.tag[-1])
    if depth(h) != lvl:
        print('depth mismatch', h.tag, depth(h), (h.text or '').strip())
t.write(p, encoding='utf-8', xml_declaration=False, doctype='<!DOCTYPE html>')

# The About page, for the version built with mvn site.
import re
p = os.path.join(ROOT, 'content/xhtml/about-this-example.xhtml')
s = open(p, encoding='utf-8').read()
s = s.replace('<li><strong>No JavaScript needed.</strong> Every page, menu and list works without it. JavaScript only makes the search answer as you type; without it, search opens a page listing every page.</li>',
 '<li><strong>No JavaScript needed.</strong> Every page, menu and list works without it. JavaScript only makes the search answer as you type, and adds the “On this page” list and links on headings; without it, search opens a page listing every page.</li>')
s = s.replace('<li><strong>Old addresses still work.</strong> All 310 old URLs redirect to the new place of their page.</li>',
 '<li><strong>Old addresses stay.</strong> Maven’s own pages keep the address they have on maven.apache.org; only the guide pages and the overview pages are new.</li>')
s = re.sub(r'<p>The example is built with Jekyll.*?</p>',
 '<p>This version of the example is built with Maven’s own tooling: <code>mvn site</code>, maven-site-plugin and Doxia, from the same sources as maven.apache.org. The frame is a skin of its own (<a href="https://github.com/dashorst/maven-site/tree/doxia-demo/doxia/skin"><code>doxia/skin</code></a>), the structure is the site descriptor <code>content/site.xml</code>, one menu three levels deep, and the landing pages, the news and the A–Z index are Markdown pages written from the same data by a small script. After the pages are rendered, two small classes run from the POM colour the code (<code>Highlight</code>) and write the search index (<code>SearchIndex</code>). Not in this version: the date a page last changed; moving pages to new addresses would add <code>.htaccess</code> redirects. The <a href="https://dashorst.github.io/maven-site/">version built with Jekyll</a> has those.</p>',
 s, flags=re.S)
open(p, 'w', encoding='utf-8').write(s)
