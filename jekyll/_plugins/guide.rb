require 'json'
require 'nokogiri'

# The user guide (jekyll/_guide/, see GUIDE.md).
#
# - Generates a page per topic in _data/guide.yml at /guides/topics/<id>.html, a page per
#   kind (tutorials, how-to guides, ...) at /guides/kinds/<slug>.html, and the A-Z index of
#   the `terms` in the front matter at /guides/a-z.html.
# - Marks the Doxia pages a guide page was written from (its `source`), so they can point
#   to the pages that replace them.
# - Writes /guides/search.json: a record per page and per ## section, of the guide and of
#   every other page of the site, for the search in js/guide.js.
# - Warns about pages with an unknown topic, kind or release line.
module MavenGuide
  KINDS = %w[tutorial howto reference explanation].freeze

  # "3.10" > "3.9"
  def self.version(v)
    Gem::Version.new(v.to_s.empty? ? '0' : v.to_s)
  end

  class GeneratedPage < Jekyll::PageWithoutAFile
    def initialize(site, dir, name, data)
      super(site, site.source, dir, name)
      self.data.merge!(data)
      self.content = ''
    end
  end

  def self.kind_slug(kind)
    kind['title'].downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
  end

  class Generator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      guide = site.collections['guide'] or return
      config = site.data['guide'] || {}
      topics = config['topics'] || []
      topic_ids = topics.map { |t| t['id'] }
      lines = site.data.dig('releases', 'lines') || []
      series = lines.map { |l| l['series'].to_s }
      crumbs = [{ 'name' => 'Guides', 'url' => '/guides/index.html' }]

      topics.each do |topic|
        site.pages << GeneratedPage.new(site, 'guides/topics', "#{topic['id']}.html",
                                        'layout' => 'guide-topic', 'title' => topic['title'], 'topic' => topic['id'],
                                        'summary' => topic['summary'], 'crumbs' => crumbs, 'menu_url' => '/guides/index.html')
      end
      (config['kinds'] || []).each do |kind|
        kind['url'] = "/guides/kinds/#{MavenGuide.kind_slug(kind)}.html"
        site.pages << GeneratedPage.new(site, 'guides/kinds', "#{MavenGuide.kind_slug(kind)}.html",
                                        'layout' => 'guide-kind', 'title' => kind['title'], 'kind' => kind['id'],
                                        'summary' => kind['intro'], 'crumbs' => crumbs, 'menu_url' => '/guides/index.html')
      end

      terms = Hash.new { |h, k| h[k] = [] }
      sources = Hash.new { |h, k| h[k] = [] }
      guide.docs.each do |doc|
        name = doc.relative_path
        Jekyll.logger.warn 'Guide:', "#{name}: unknown topic '#{doc.data['topic']}'" unless topic_ids.include?(doc.data['topic'])
        Jekyll.logger.warn 'Guide:', "#{name}: unknown type '#{doc.data['type']}'" unless KINDS.include?(doc.data['type'])
        Jekyll.logger.warn 'Guide:', "#{name}: no summary" if doc.data['summary'].to_s.strip.empty?
        Jekyll.logger.warn 'Guide:', "#{name}: since '#{doc.data['since']}' is not a line in releases.yml" unless series.include?(doc.data['since'].to_s)
        topic = topics.find { |t| t['id'] == doc.data['topic'] } || {}
        doc.data['crumbs'] = crumbs + [{ 'name' => topic['title'], 'url' => "/guides/topics/#{topic['id']}.html" }]
        doc.data['menu_url'] = '/guides/index.html'
        Array(doc.data['terms']).each { |t| terms[t.to_s] << doc }
        Array(doc.data['source']).each do |s|
          sources[s.to_s] << doc
          next if s.to_s.include?(':')
          file = File.join(site.source, 'content', 'markdown', s.to_s)
          Jekyll.logger.warn 'Guide:', "#{name}: source #{s} does not exist" unless File.exist?(file) || File.exist?("#{file}.vm")
        end
      end

      site.data['guide_terms'] = terms.keys.sort_by { |t| t.downcase.sub(/\A[^a-z0-9]+/, '') }.map do |t|
        { 'name' => t, 'letter' => t.sub(/\A[^A-Za-z0-9]+/, '')[0].to_s.upcase,
          'pages' => terms[t].sort_by { |d| KINDS.index(d.data['type']) || 9 } }
      end
      site.pages << GeneratedPage.new(site, 'guides', 'a-z.html',
                                      'layout' => 'guide-a-z', 'title' => 'A–Z index', 'crumbs' => crumbs,
                                      'summary' => 'Every file, POM and settings element, command-line option and plugin the guide explains.',
                                      'menu_url' => '/guides/index.html')

      # A Doxia page that guide pages were written from links to them.
      site.pages.each do |page|
        src = page.data['doxia_source'] or next
        rel = src.sub(%r{\Acontent/markdown/}, '').sub(/\.vm\z/, '')
        docs = sources[rel]
        page.data['split_into'] = docs.sort_by { |d| [KINDS.index(d.data['type']) || 9, d.data['order'].to_i] } if docs.any?
      end

      site.data['guide_oldest'] = lines.reject { |l| l['status'] == 'upcoming' }.map { |l| l['series'].to_s }.min_by { |v| MavenGuide.version(v) }
      site.data['guide_upcoming'] = lines.find { |l| l['status'] == 'upcoming' }
    end
  end

  def self.records
    @records ||= []
  end

  def self.text(nodes)
    nodes.map { |n| n.xpath('descendant-or-self::text()').map(&:text).join(' ') }.join(' ').gsub(/\s+/, ' ').strip
  end

  # Element names, files and options in code within the nodes: <mirrorOf>, settings.xml, -pl.
  def self.identifiers(nodes)
    nodes.flat_map { |n| n.css('code').map(&:text) + (n.name == 'code' ? [n.text] : []) }
         .select { |t| t.length < 60 }
         .flat_map { |t| t.scan(/<?[A-Za-z][\w.-]*>?|--?[a-z][\w-]*/) }
         .uniq.first(30)
  end

  # Splits a rendered page into its intro and its ## sections.
  def self.index(item, kind, extra)
    html = Nokogiri::HTML5.fragment(item.content)
    base = item.site.config['baseurl'].to_s + item.url
    common = { 'page' => item.data['title'], 'kind' => kind, 'topic' => extra['topic'].to_s,
               'since' => item.data['since'].to_s }
    sections = [[nil, []]]
    html.children.each do |node|
      next if node.comment?
      if node.name == 'h2'
        sections << [node, []]
      elsif node.name != 'h1'
        sections.last[1] << node
      end
    end
    intro = sections.shift[1]
    records << common.merge('id' => item.url, 'url' => base, 'title' => item.data['title'].to_s,
                            'text' => (item.data['summary'] || text(intro)[0, 160]).to_s,
                            'keywords' => Array(item.data['keywords']).join(' '),
                            'terms' => (Array(item.data['terms']).map(&:to_s) + identifiers(intro)).uniq.join(' '),
                            'body' => text(intro))
    sections.each do |heading, nodes|
      id = Doxia.encode_id(heading.text) or next
      body = text(nodes)
      records << common.merge('id' => "#{item.url}##{id}", 'url' => "#{base}##{id}",
                              'title' => heading.text.strip, 'text' => body[0, 160], 'keywords' => '',
                              'terms' => identifiers(nodes).join(' '), 'body' => body)
    end
  end
end

Jekyll::Hooks.register :site, :pre_render do |_site|
  MavenGuide.records.clear
end

Jekyll::Hooks.register :guide, :post_convert do |doc|
  topic = (doc.site.data.dig('guide', 'topics') || []).find { |t| t['id'] == doc.data['topic'] } || {}
  MavenGuide.index(doc, doc.data['type'], 'topic' => topic['title'])
end

# Every other page of the site is searchable too, as "Page"; release notes by title only.
Jekyll::Hooks.register :pages, :post_convert do |page|
  next unless page.data['doxia_source']
  next if page.url =~ %r{\A/docs/\d}
  MavenGuide.index(page, 'page', {})
end

Jekyll::Hooks.register :site, :post_write do |site|
  next unless site.collections['guide']
  dir = File.join(site.dest, 'guides')
  FileUtils.mkdir_p(dir)
  File.write(File.join(dir, 'search.json'), JSON.generate(MavenGuide.records.sort_by { |r| r['id'] }))
end
