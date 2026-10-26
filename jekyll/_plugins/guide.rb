require 'json'
require 'nokogiri'

# The user guide (jekyll/_guide/, see GUIDE.md). Its pages get their place in the site from
# _data/site_map.yml (see site_map.rb); this plugin
#
# - warns about pages with an unknown kind, no summary or a `since` that is no release line,
#   and about sources that do not exist;
# - generates the A-Z index of the `terms` in the front matter at /docs/reference/a-z.html;
# - writes /search.json: a record per page and per ## section, of the guide and of every
#   other page of the site, for the search in js/search.js.
module MavenGuide
  KINDS = %w[tutorial howto reference explanation].freeze

  class Generator < Jekyll::Generator
    safe true
    priority :low

    def generate(site)
      guide = site.collections['guide'] or return
      lines = site.data.dig('releases', 'lines') || []
      series = lines.map { |l| l['series'].to_s }

      terms = Hash.new { |h, k| h[k] = [] }
      guide.docs.each do |doc|
        name = doc.relative_path
        Jekyll.logger.warn 'Guide:', "#{name}: unknown type '#{doc.data['type']}'" unless KINDS.include?(doc.data['type'])
        Jekyll.logger.warn 'Guide:', "#{name}: no summary" if doc.data['summary'].to_s.strip.empty?
        Jekyll.logger.warn 'Guide:', "#{name}: since '#{doc.data['since']}' is not a line in releases.yml" unless series.include?(doc.data['since'].to_s)
        Jekyll.logger.warn 'Guide:', "#{name}: not in site_map.yml" unless doc.data['nav']
        Array(doc.data['terms']).each { |t| terms[t.to_s] << doc }
        Array(doc.data['source']).each do |s|
          next if s.to_s.include?(':')
          file = File.join(site.source, 'content', 'markdown', s.to_s)
          Jekyll.logger.warn 'Guide:', "#{name}: source #{s} does not exist" unless File.exist?(file) || File.exist?("#{file}.vm")
        end
      end

      site.data['guide_terms'] = terms.keys.sort_by { |t| t.downcase.sub(/\A[^a-z0-9]+/, '') }.map do |t|
        { 'name' => t, 'letter' => t.sub(/\A[^A-Za-z0-9]+/, '')[0].to_s.upcase,
          'pages' => terms[t].sort_by { |d| KINDS.index(d.data['type']) || 9 } }
      end
      site.pages << SiteMap::GeneratedPage.new(site, '/docs/reference/a-z.html',
                                               'layout' => 'guide-a-z', 'title' => 'A–Z index',
                                               'summary' => 'Every file, POM and settings element, command-line option and plugin the guide explains.',
                                               'nav' => { 'section' => 'docs', 'group' => 'reference', 'title' => 'A–Z index' })
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

  # Where a page sits, for the search results: "Docs › Configure Maven".
  def self.place(item)
    nav = item.data['nav'] or return ''
    group = item.site.data.dig('nav_groups', "#{nav['section']}/#{nav['group']}")
    [item.site.data.dig('nav_sections', nav['section'], 'title'), group && group['title']].compact.join(' › ')
  end

  # Splits a rendered page into its intro and its ## sections.
  def self.index(item, kind)
    html = Nokogiri::HTML5.fragment(item.content)
    base = item.site.config['baseurl'].to_s + item.url
    # Some Maven pages are titled "Introduction"; their label in the navigation says more.
    title = (kind == 'page' && item.data.dig('nav', 'title') || item.data['title']).to_s
    common = { 'page' => title, 'kind' => kind, 'topic' => place(item), 'since' => item.data['since'].to_s }
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
    records << common.merge('id' => item.url, 'url' => base, 'title' => title,
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
  MavenGuide.index(doc, doc.data['type'])
end

# Every other page of the site is searchable too, as "Page"; release notes are not.
Jekyll::Hooks.register :pages, :post_convert do |page|
  next unless page.data['doxia_source']
  next if page.data['release_notes']
  MavenGuide.index(page, 'page')
end

Jekyll::Hooks.register :site, :post_write do |site|
  next unless site.collections['guide']
  File.write(File.join(site.dest, 'search.json'), JSON.generate(MavenGuide.records.sort_by { |r| r['id'] }))
end
