require 'nokogiri'
require 'set'
require 'uri'

# Reads the Doxia site sources in content/ as they are, so maven.apache.org builds with
# Jekyll without changing a page:
#
# - content/markdown/**/*.md become pages at the same URLs as on maven.apache.org; the
#   Velocity templates (*.md.vm) are read from jekyll/.velocity/, where velocity/render.sh
#   renders them first.
# - content/xdoc/*.xml(.vm) are converted from xdoc to HTML.
# - content/resources/ and the Fluido skin files in jekyll/skin/ are copied to the site root.
#
# After rendering, every page gets what the Doxia renderer adds: an id on each heading in
# Doxia's form ("What are Toolchains?" -> What_are_Toolchains.3F), the toc macro, and tables
# styled by the skin. Links to pages this build does not have (the plugin sites, /ref/, ...)
# point to maven.apache.org instead.
module Doxia
  CONTENT = 'content'
  RENDERED = 'jekyll/.velocity'

  # A file copied to a path of our choosing instead of its own path under the source.
  class MountedFile < Jekyll::StaticFile
    def initialize(site, base, dir, name, url)
      super(site, base, dir, name)
      @mounted_url = url
    end

    def url
      @mounted_url
    end

    def destination(dest)
      File.join(dest, @mounted_url)
    end
  end

  # A page whose content is converted here, not by a Jekyll converter.
  class XdocPage < Jekyll::PageWithoutAFile
  end

  def self.title_of(markdown)
    line = markdown.each_line.find { |l| l =~ /\A#\s+\S/ }
    line && line.sub(/\A#\s+/, '').strip.gsub(/[`*_]/, '').gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')
  end

  # Doxia's DoxiaUtils.encodeId.
  def self.encode_id(text)
    text = text.to_s.strip
    return nil if text.empty?
    out = +''
    text.each_char.with_index do |c, i|
      out << 'a' if i.zero? && c !~ /[A-Za-z_]/
      if c == ' '
        out << '_'
      elsif c =~ /[A-Za-z0-9\-_.]/
        out << c
      else
        c.encode('UTF-8').bytes.each { |b| out << format('.%02X', b) }
      end
    end
    out
  end

  # xdoc to HTML: <section name> and <subsection name> become headed sections, <source>
  # becomes a code block, <macro name="toc"> the toc macro.
  def self.xdoc_to_html(xml)
    doc = Nokogiri::XML(xml)
    doc.remove_namespaces!
    title = doc.at('properties > title')&.text.to_s.strip
    body = doc.at('body') or return [title, '']
    body.css('section, subsection').each do |s|
      level = s.ancestors('section, subsection').size + 1
      heading = Nokogiri::XML::Node.new("h#{level}", doc)
      heading.content = s['name'].to_s
      s.prepend_child(heading) if s['name']
      s.name = 'section'
      s.remove_attribute('name')
    end
    body.css('source').each do |src|
      pre = Nokogiri::XML::Node.new('pre', doc)
      code = Nokogiri::XML::Node.new('code', doc)
      code.content = src.text
      pre.add_child(code)
      src.replace(pre)
    end
    body.css('macro[name=toc]').each { |m| m.replace(Nokogiri::XML::Comment.new(doc, ' MACRO{toc} ')) }
    [title, body.children.to_html]
  end

  class Generator < Jekyll::Generator
    safe true
    priority :highest

    def generate(site)
      taken = site.pages.map(&:url).to_set
      # Pages that give their URL to a page of this build, e.g. /guides/index.html.
      moved = site.config['doxia_moved'] || {}
      markdown = File.join(site.source, CONTENT, 'markdown')
      Dir.glob('**/*.{md,md.vm}', base: markdown).sort.each do |rel|
        dir = File.dirname(rel)
        dir = '' if dir == '.'
        if rel.end_with?('.vm')
          name = File.basename(rel, '.vm')
          page = Jekyll::Page.new(site, site.source, File.join(RENDERED, 'markdown', dir), name)
        else
          name = File.basename(rel)
          page = Jekyll::Page.new(site, site.source, File.join(CONTENT, 'markdown', dir), name)
        end
        url = '/' + [dir, File.basename(name, '.md') + '.html'].reject(&:empty?).join('/')
        url = moved.fetch(url, url)
        next if taken.include?(url)
        page.data['permalink'] = url
        page.data['layout'] ||= 'default'
        page.data['title'] ||= Doxia.title_of(page.content) || File.basename(name, '.md')
        page.data['render_with_liquid'] = false
        page.data['doxia_source'] = "#{CONTENT}/markdown/#{rel}"
        site.pages << page
      end

      xdoc = File.join(site.source, CONTENT, 'xdoc')
      Dir.glob('**/*.{xml,xml.vm}', base: xdoc).sort.each do |rel|
        file = rel.end_with?('.vm') ? File.join(site.source, RENDERED, 'xdoc', rel.sub(/\.vm\z/, '')) : File.join(xdoc, rel)
        next unless File.exist?(file)
        dir = File.dirname(rel)
        dir = '' if dir == '.'
        name = File.basename(rel).sub(/\.xml(\.vm)?\z/, '.html')
        url = '/' + [dir, name].reject(&:empty?).join('/')
        next if taken.include?(url)
        title, html = Doxia.xdoc_to_html(File.read(file))
        page = XdocPage.new(site, site.source, dir, name)
        page.content = html
        page.data['permalink'] = url
        page.data['layout'] = 'default'
        page.data['title'] = title
        page.data['render_with_liquid'] = false
        page.data['doxia_source'] = "#{CONTENT}/xdoc/#{rel}"
        site.pages << page
      end

      [[File.join(CONTENT, 'resources'), ''], ['jekyll/skin', '']].each do |from, _|
        base = File.join(site.source, from)
        Dir.glob('**/*', base: base).sort.each do |rel|
          next if File.directory?(File.join(base, rel))
          site.static_files << MountedFile.new(site, site.source, File.join(from, File.dirname(rel)),
                                               File.basename(rel), "/#{rel}")
        end
      end
    end
  end

  # Every URL this build writes, to tell links within the site from links to the sub-sites.
  def self.urls
    @urls ||= Set.new
  end

  def self.missing
    @missing ||= Hash.new(0)
  end

  def self.toc(main, params)
    opts = params.to_s.split('|').reject(&:empty?).map { |p| p.split('=', 2) }.to_h
    section = opts.fetch('section', '0').to_i
    from = opts.fetch('fromDepth', '0').to_i
    to = opts.fetch('toDepth', '5').to_i
    headings = main.css('h1, h2, h3, h4, h5, h6').reject { |h| h.ancestors('.doxia-toc, nav, .guide-foot, .guide-head').any? }
    if section.positive?
      starts = headings.each_index.select { |i| headings[i].name == 'h1' }
      first = starts[section - 1] or return ''
      last = starts[section] || headings.size
      headings = headings[first...last]
    end
    headings = headings.select { |h| (from..to).cover?(h.name[1].to_i) && h['id'] }
    return '' if headings.empty?
    html = +''
    depth = []
    headings.each do |h|
      level = h.name[1].to_i
      if depth.empty? || level > depth.last
        html << '<ul>'
        depth << level
      else
        html << '</li>'
        while depth.size > 1 && level < depth.last
          html << '</ul></li>'
          depth.pop
        end
      end
      html << %(<li><a href="##{h['id']}">#{CGI.escapeHTML(h.text.strip)}</a>)
    end
    html << '</li>' << ('</ul></li>' * (depth.size - 1)) << '</ul>'
    %(<div class="doxia-toc">#{html}</div>)
  end

  def self.finish(item)
    return unless item.output_ext == '.html' && item.output.to_s.include?('id="bodyColumn"')
    site = item.site
    base = site.config['baseurl'].to_s
    doc = Nokogiri::HTML5.parse(item.output, max_tree_depth: -1)
    main = doc.at_css('#bodyColumn')
    seen = Hash.new(0)
    main.css('h1, h2, h3, h4, h5, h6').each do |h|
      next if h['id'] || h.ancestors('.doxia-toc').any?
      id = Doxia.encode_id(h.text) or next
      seen[id] += 1
      h['id'] = seen[id] > 1 ? "#{id}_#{seen[id] - 1}" : id
    end
    main.xpath('.//comment()').each do |c|
      m = c.text.match(/MACRO\{toc((?:\|[^}]*)?)\}/) or next
      c.replace(Nokogiri::HTML5.fragment(toc(main, m[1])))
    end
    main.css('table').each { |t| t['class'] ||= 'table table-striped' }
    # A version note in the guide: a quote that starts with "Maven 4:".
    main.css('blockquote').each do |q|
      first = q.at_css('p > strong:first-child')
      q['class'] = 'guide-since' if first && first.text =~ /\AMaven \d/
    end

    page_url = item.url
    doc.css('a[href], img[src], link[href], script[src]').each do |el|
      attr = el.name == 'img' || el.name == 'script' ? 'src' : 'href'
      href = el[attr].to_s.strip
      # Some pages link to themselves through maven.apache.org; keep those within this build.
      local = href[%r{\Ahttps?://maven\.apache\.org(/[^#?]*)}, 1]
      if local && Doxia.urls.include?(local.end_with?('/') ? "#{local}index.html" : local)
        el[attr] = base + href.sub(%r{\Ahttps?://maven\.apache\.org}, '')
        next
      end
      next if href.empty? || href.start_with?('#') || href =~ %r{\A[a-z][a-z0-9+.-]*:}i || href.start_with?('//')
      path, frag = href.split('#', 2)
      path = path.split('?', 2).first
      next if path.empty?
      if path.start_with?(base + '/') && !base.empty?
        next
      end
      resolved = begin
        URI.join("http://site#{page_url}", path).path
      rescue URI::InvalidURIError
        next
      end
      # Browsers stop at the root, so "../x.html" on a top-level page works on maven.apache.org;
      # below a base URL it would leave the site.
      climbs = resolved.start_with?('/..')
      resolved = resolved.sub(%r{\A(/\.\.)+}, '')
      key = resolved.end_with?('/') ? "#{resolved}index.html" : resolved
      if Doxia.urls.include?(key) || Doxia.urls.include?("#{key}/index.html")
        el[attr] = "#{base}#{resolved}#{frag ? "##{frag}" : ''}" if path.start_with?('/') || climbs
      else
        Doxia.missing[resolved.sub(%r{\A/([^/]+/)?.*}, '/\1')] += 1
        el[attr] = "https://maven.apache.org#{resolved}#{frag ? "##{frag}" : ''}"
      end
    end
    item.output = doc.to_html
  end
end

Jekyll::Hooks.register :site, :pre_render do |site|
  Doxia.urls.clear
  Doxia.missing.clear
  (site.pages + site.static_files + site.collections.values.flat_map(&:docs)).each { |p| Doxia.urls << p.url }
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
  Doxia.finish(item)
end

Jekyll::Hooks.register :site, :post_write do |_site|
  next if Doxia.missing.empty?
  top = Doxia.missing.sort_by { |_, n| -n }.first(12).map { |k, n| "#{k} (#{n})" }.join(', ')
  Jekyll.logger.info 'Doxia:', "links to maven.apache.org for pages outside this build: #{top}"
end
