#!/usr/bin/env python3
"""Writes the Doxia sources of the example from the Jekyll example's data, so that `mvn site`
can build the same structure:

  content/site.xml                      the structure: one menu of sections > groups > pages
  content/markdown/guide/*.md           the guide pages, from jekyll/_guide/
  content/xhtml/<section>/index.xhtml   the landing page of each section
  content/xhtml/<s>/<group>/index.xhtml the landing page of each group
  content/markdown/news/index.md        the news, from jekyll/_data/news.yml
  content/markdown/search.md            every page, for search without JavaScript
  content/markdown/docs/reference/a-z.md the A-Z index of the guide's `terms`
  content/markdown/about-this-example/discrepancies.md, from jekyll/pages/

Maven's own pages keep the URL they have on maven.apache.org; moving them is a separate step.
Needs PyYAML. Run from the repository root: python3 doxia/generate.py
"""
import os
import re
import shutil
from xml.sax.saxutils import escape, quoteattr

import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JEKYLL = os.path.join(ROOT, 'jekyll')
CONTENT = os.path.join(ROOT, 'content')
MARKDOWN = os.path.join(CONTENT, 'markdown')

# Ruby's YAML parser accepts `title: What is Maven? }` in a flow mapping; PyYAML needs quotes.
site_map = yaml.safe_load(re.sub(r'(title: )([^,"{}\n]*\?)( })', r'\1"\2"\3',
                                 open(os.path.join(JEKYLL, '_data/site_map.yml'), encoding='utf-8').read()))
news = yaml.safe_load(open(os.path.join(JEKYLL, '_data/news.yml')))
guide_dir = os.path.join(JEKYLL, '_guide')


def front_matter(path):
    text = open(path, encoding='utf-8').read()
    m = re.match(r'---\n(.*?)\n---\n', text, re.S)
    return (yaml.safe_load(m.group(1)), text[m.end():]) if m else ({}, text)


guides = {f[:-3]: front_matter(os.path.join(guide_dir, f)) for f in sorted(os.listdir(guide_dir)) if f.endswith('.md')}


def src_url(src):
    """The URL Doxia gives a source under content/."""
    if src.startswith('xdoc/'):
        path = src[5:]
    else:
        path = src
    path = re.sub(r'\.(md|xml|apt|fml)(\.vm)?$', '', path)
    return '/' + path + '.html'


def src_title(src):
    for base in ('markdown', ''):
        path = os.path.join(CONTENT, base, src) if base else os.path.join(CONTENT, src)
        if os.path.exists(path):
            for line in open(path, encoding='utf-8'):
                if line.startswith('# '):
                    return line[2:].strip()
    return None


# Pass 1: every entry's Jekyll URL (what `url:` entries refer to) and its URL in this build.
jekyll_to_doxia = {}
for s in site_map['sections']:
    for g in s.get('groups') or []:
        for e in g.get('pages') or []:
            if 'guide' in e:
                url = '/guide/%s.html' % e['guide']
                default_slug = e['guide']
            elif 'src' in e:
                url = src_url(e['src'])
                default_slug = re.sub(r'\..*$', '', os.path.basename(e['src']))
            else:
                continue
            j = e.get('url') or '/%s/%s/%s.html' % (s['id'], g['id'], e.get('slug') or default_slug)
            jekyll_to_doxia[j] = url
jekyll_to_doxia['/docs/reference/a-z.html'] = '/docs/reference/a-z.html'


def entry(e):
    """(title, url, summary) of a page entry in this build."""
    if 'guide' in e:
        meta = guides[e['guide']][0]
        return e.get('title') or meta['title'], '/guide/%s.html' % e['guide'], meta.get('summary')
    if 'src' in e:
        return e.get('title') or src_title(e['src']) or e['src'], src_url(e['src']), None
    if 'href' in e:
        return e['title'], e['href'], None
    url = jekyll_to_doxia.get(e['url'])
    return (e['title'], url, None) if url else None


# The tree: sections > groups > pages.
tree = []
for s in site_map['sections']:
    sec = {'id': s['id'], 'title': s['title'], 'summary': s.get('summary', ''), 'url': '/%s/index.html' % s['id'], 'groups': []}
    for g in s.get('groups') or []:
        pages = [p for p in (entry(e) for e in g.get('pages') or []) if p]
        sec['groups'].append({'id': g['id'], 'title': g['title'], 'summary': g.get('summary', ''),
                              'url': '/%s/%s/index.html' % (s['id'], g['id']), 'pages': pages})
    # A section whose first page claims the section's own URL opens on that page (Downloads).
    first = (s.get('groups') or [{}])[0].get('pages') or []
    if first and first[0].get('url') == sec['url'] and 'src' in first[0]:
        sec['url'] = src_url(first[0]['src'])
    tree.append(sec)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)


def rel(url, from_url):
    """A link to url from the page at from_url, both site-absolute."""
    if re.match(r'^[a-z]+:', url):
        return url
    return os.path.relpath(url, os.path.dirname(from_url))


def yaml_str(value):
    # Doxia's front matter parser keeps quotes as part of the value: write it bare, on one line.
    return ' '.join(str(value).split())


def page_md(title, summary, body, facts=True):
    head = '---\ntitle: %s\n' % yaml_str(title)
    if summary:
        head += 'summary: %s\n' % yaml_str(summary)
    if not facts:
        head += 'facts: none\n'
    return head + '---\n\n' + body


# site.xml
xml = ['<?xml version="1.0" encoding="UTF-8"?>',
       '<!--',
       '  Licensed to the Apache Software Foundation (ASF) under one or more contributor license',
       '  agreements. See the NOTICE file distributed with this work for additional information',
       '  regarding copyright ownership. The ASF licenses this file to you under the Apache License,',
       '  Version 2.0 (the "License"); you may not use this file except in compliance with the License.',
       '  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0',
       '',
       '  The structure of the site, written by doxia/generate.py from jekyll/_data/site_map.yml.',
       '  The one menu holds three levels: the sections (the tabs at the top of every page), their',
       '  groups, and the pages of each group in reading order. The skin draws the tabs, the side',
       '  panel, previous and next from it.',
       '-->',
       '<site xmlns="http://maven.apache.org/SITE/2.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
       '      xsi:schemaLocation="http://maven.apache.org/SITE/2.0.0 https://maven.apache.org/xsd/site-2.0.0.xsd"',
       '      name="Apache Maven">',
       '  <skin>',
       '    <groupId>io.github.dashorst.maven-site</groupId>',
       '    <artifactId>maven-example-skin</artifactId>',
       '    <version>1.0-SNAPSHOT</version>',
       '  </skin>',
       '  <body>',
       '    <menu name="Site">']
for s in tree:
    xml.append('      <item name=%s href=%s>' % (quoteattr(s['title']), quoteattr(s['url'])))
    for g in s['groups']:
        xml.append('        <item name=%s href=%s>' % (quoteattr(g['title']), quoteattr(g['url'])))
        for title, url, _ in g['pages']:
            xml.append('          <item name=%s href=%s/>' % (quoteattr(title), quoteattr(url)))
        xml.append('        </item>')
    xml.append('      </item>')
xml += ['    </menu>', '  </body>', '</site>', '']
write(os.path.join(CONTENT, 'site.xml'), '\n'.join(xml))

# The guide pages, with the front matter Doxia's Markdown parser passes on as <meta>.
out = os.path.join(MARKDOWN, 'guide')
shutil.rmtree(out, ignore_errors=True)
for name, (meta, body) in guides.items():
    head = '---\ntitle: %s\n' % yaml_str(meta['title'])
    for key in ('summary', 'type', 'since'):
        if meta.get(key):
            head += '%s: %s\n' % (key, yaml_str(meta[key]))
    if meta.get('keywords'):
        head += 'keywords: %s\n' % yaml_str(', '.join(meta['keywords']))
    if meta.get('terms'):
        head += 'terms: %s\n' % yaml_str(' | '.join(str(t) for t in meta['terms']))
    write(os.path.join(out, name + '.md'), head + '---\n\n' + body)


def page_list(pages, from_url, summaries=False):
    lines = []
    for title, url, summary in pages:
        line = '- [%s](%s)' % (title, rel(url, from_url))
        if summaries and summary:
            line += ': ' + summary
        lines.append(line)
    return '\n'.join(lines) + '\n'


# Section and group landing pages, as XHTML so they carry the classes of the stylesheet. Doxia
# reads a heading as the start of a section: each heading is the first child of a <section>
# nested as deep as its level, inside one wrapping section (the skin writes the h1).
def xhtml_page(title, summary, body):
    head = '<title>%s</title>' % escape(title)
    if summary:
        head += '\n<meta name="summary" content=%s />' % quoteattr(summary)
    return ('<!DOCTYPE html>\n<html xmlns="http://www.w3.org/1999/xhtml">\n<head>\n%s\n</head>\n<body>\n'
            '<section class="landing">\n%s</section>\n</body>\n</html>\n') % (head, body)


def page_list_html(pages, from_url, css='page-list', summaries=False):
    out = '<ul class="%s">\n' % css
    for title, url, summary in pages:
        out += '<li><a href=%s>%s</a>' % (quoteattr(rel(url, from_url)), escape(title))
        if summaries and summary:
            out += '<span class="page-summary">%s</span>' % escape(summary)
        out += '</li>\n'
    return out + '</ul>\n'


XHTML = os.path.join(CONTENT, 'xhtml')
for d in [t['id'] for t in tree]:
    shutil.rmtree(os.path.join(XHTML, d), ignore_errors=True)
for s in tree:
    if s['id'] == 'news':
        continue
    if s['url'] == '/%s/index.html' % s['id']:
        body = ''
        if s['id'] == 'docs':
            body += ('<section class="start-here">\n<h2>New to Maven?</h2>\n<p>Follow the five steps at the top of '
                     '<a href="get-started/index.html">Get started</a>: create a project, add a dependency, configure '
                     'a plugin, test and build it, and split it into modules, all on one small project.</p>\n</section>\n')
        body += '<div class="groups">\n'
        for g in s['groups']:
            body += '<section class="group">\n<h2><a href=%s>%s</a></h2>\n<p class="group-summary">%s</p>\n' % (
                quoteattr(rel(g['url'], s['url'])), escape(g['title']), escape(g['summary']))
            body += page_list_html(g['pages'], s['url']) + '</section>\n'
        body += '</div>\n'
        write(os.path.join(XHTML, s['url'][1:-5] + '.xhtml'), xhtml_page(s['title'], s['summary'], body))
    for g in s['groups']:
        write(os.path.join(XHTML, g['url'][1:-5] + '.xhtml'),
              xhtml_page(g['title'], g['summary'],
                         page_list_html(g['pages'], g['url'], 'page-list page-list--full', summaries=True)))

# News, newest first.
body = ''
for n in sorted(news, key=lambda n: str(n['date']), reverse=True):
    body += '## %s\n\n*%s*\n\n%s\n' % (n['title'], n['date'], n['text'].strip())
    link = n.get('link')
    if link:
        if not re.match(r'^[a-z]+:', link):
            link = jekyll_to_doxia.get(link) or src_url(link)
        body += '\n[Read more](%s)\n' % rel(link, '/news/index.html')
    body += '\n'
news_section = next(s for s in site_map['sections'] if s['id'] == 'news')
write(os.path.join(MARKDOWN, 'news/index.md'), page_md('News', news_section['summary'], body, facts=False))

# Every page, by section and group: the search page without JavaScript.
body = 'Every page of the site, by section. Type in the search box to narrow the list.\n\n'
for s in tree:
    if not s['groups']:
        continue
    body += '## %s\n\n' % s['title']
    for g in s['groups']:
        body += '### %s\n\n' % g['title'] + page_list(g['pages'], '/search.html') + '\n'
write(os.path.join(MARKDOWN, 'search.md'), page_md('Search', None, body, facts=False))

# The A-Z index: every term a guide page explains, from the `terms` in its front matter.
KINDS = ['tutorial', 'howto', 'reference', 'explanation']
LABELS = {'tutorial': 'tutorial', 'howto': 'how-to', 'reference': 'reference', 'explanation': 'explanation'}
terms = {}
for name, (meta, _) in guides.items():
    for t in meta.get('terms') or []:
        terms.setdefault(str(t), []).append((name, meta))
body = ''
letter = None
for t in sorted(terms, key=lambda t: re.sub(r'^[^a-z0-9]+', '', t.lower())):
    first = re.sub(r'^[^A-Za-z0-9]+', '', t)[:1].upper()
    if first != letter:
        letter = first
        body += '\n## %s\n\n' % letter
    pages = sorted(terms[t], key=lambda p: KINDS.index(p[1].get('type')) if p[1].get('type') in KINDS else 9)
    links = ', '.join('[%s](../../guide/%s.html) (%s)' % (m['title'], n, LABELS.get(m.get('type'), m.get('type')))
                      for n, m in pages)
    body += '- `%s`: %s\n' % (t.replace('`', ''), links)
write(os.path.join(MARKDOWN, 'docs/reference/a-z.md'),
      page_md('A–Z index', 'Every file, POM and settings element, command-line option and plugin the guide explains.', body))

# Where Maven's documentation and Maven disagree, from the Jekyll example.
meta, body = front_matter(os.path.join(JEKYLL, 'pages/discrepancies.md'))
body = re.sub(r'^# .*\n+', '', body.lstrip())
write(os.path.join(MARKDOWN, 'about-this-example/discrepancies.md'), page_md(meta['title'], meta['summary'], body))
