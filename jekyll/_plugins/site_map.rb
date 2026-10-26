require 'cgi'
require 'open3'
require 'set'

# The structure of the site, from _data/site_map.yml: five sections of groups of pages.
#
# - Every page in the map gets its URL there, /<section>/<group>/<slug>.html, and the page
#   at its old URL becomes a redirect (a meta refresh with a plain link, so it works without
#   JavaScript). Maven pages a guide page replaces are not built; their URLs redirect too.
# - Every page in the map gets `nav`: its section, its group, the group's pages and the
#   previous and next page, for the layout's side panel and the block below the text.
# - Every page gets `facts`: the Maven versions it holds for, the date its source last
#   changed in git, and the file to edit.
# - Generates the landing page of each section, a page per group, the search page, the
#   A-Z index of the guide's terms, the News page and its feed.
module SiteMap
  class GeneratedPage < Jekyll::PageWithoutAFile
    def initialize(site, url, data, content = '')
      dir = File.dirname(url)
      super(site, site.source, dir, File.basename(url))
      self.data.merge!(data)
      self.data['permalink'] = url
      self.content = content
    end
  end

  # Old URL => new URL, read by Doxia.finish to point links straight at the new place.
  def self.moved
    @moved ||= {}
  end

  def self.slugify(text)
    text.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
  end

  def self.slug_of(path)
    File.basename(path).sub(/\.(md|xml)(\.vm)?\z/, '').sub(/\Aindex\z/, File.basename(File.dirname(path)))
  end

  # The last commit date of every file under content/ and jekyll/_guide/.
  def self.git_dates(root)
    out, status = Open3.capture2('git', '-c', 'safe.directory=*', '-C', root, 'log', '--format=@%as',
                                 '--name-only', '--', 'content', 'jekyll/_guide')
    return {} unless status.success?
    dates = {}
    date = nil
    out.each_line do |line|
      line = line.strip
      next if line.empty?
      if line.start_with?('@')
        date = line[1..]
      else
        dates[line] ||= date
      end
    end
    dates
  rescue Errno::ENOENT
    {}
  end

  def self.redirect_html(site, to)
    target = site.config['baseurl'].to_s + to
    <<~HTML
      <!DOCTYPE html>
      <html lang="en"><head><meta charset="utf-8"><title>Moved</title>
      <meta http-equiv="refresh" content="0; url=#{target}">
      <link rel="canonical" href="#{site.config['url']}#{to}">
      <meta name="robots" content="noindex"></head>
      <body><p>This page has moved to <a href="#{target}">#{CGI.escapeHTML(site.config['url'].to_s + to)}</a>.</p></body></html>
    HTML
  end

  class Generator < Jekyll::Generator
    safe true
    priority :high

    def generate(site)
      map = site.data['site_map'] or return
      SiteMap.moved.clear
      lines = site.data.dig('releases', 'lines') || []
      kinds = (site.data.dig('guide', 'kinds') || []).to_h { |k| [k['id'], k['label']] }
      dates = SiteMap.git_dates(site.source)
      by_source = {}
      site.pages.each { |p| by_source[p.data['doxia_source'].sub(%r{\Acontent/(markdown/)?}, '')] = p if p.data['doxia_source'] }
      guides = site.collections['guide']&.docs&.to_h { |d| [d.basename_without_ext, d] } || {}
      redirects = {}
      dropped = Set.new
      src_urls = {}
      tree = []

      map['sections'].each do |section|
        s_url = "/#{section['id']}/index.html"
        s = { 'id' => section['id'], 'title' => section['title'], 'summary' => section['summary'], 'url' => s_url, 'groups' => [] }
        tree << s
        (section['groups'] || []).each do |group|
          g_url = "/#{section['id']}/#{group['id']}/index.html"
          g = { 'id' => group['id'], 'title' => group['title'], 'summary' => group['summary'], 'url' => g_url, 'pages' => [], 'items' => [] }
          s['groups'] << g
          (group['pages'] || []).each do |entry|
            item = nil
            if entry['guide']
              doc = guides[entry['guide']] or (Jekyll.logger.warn('Site map:', "no guide page #{entry['guide']}") && next)
              url = entry['url'] || "/#{section['id']}/#{group['id']}/#{entry['slug'] || entry['guide']}.html"
              redirects[doc.url] = url
              doc.data['old_url'] = doc.url
              doc.data['permalink'] = url
              doc.instance_variable_set(:@url, nil)
              Array(entry['replaces']).each do |old|
                page = by_source[old.sub(/\.vm\z/, '')] || by_source[old]
                if page
                  redirects[page.url] = url
                  dropped << page
                end
                src_urls[old] = url
              end
              since = doc.data['since'].to_s
              holds = lines.select { |l| Gem::Version.new(l['series'].to_s) >= Gem::Version.new(since.empty? ? '0' : since) }
              file = "jekyll/_guide/#{doc.basename}"
              item = { 'title' => entry['title'] || doc.data['title'], 'url' => url, 'summary' => doc.data['summary'], 'doc' => doc,
                       'facts' => { 'holds' => holds.map { |l| { 'series' => l['series'].to_s, 'upcoming' => l['status'] == 'upcoming' } },
                                    'kind' => kinds[doc.data['type']], 'changed' => dates[file],
                                    'edit' => "#{site.config.dig('edit', 'guide')}/#{file}" } }
              src_urls["guide:#{entry['guide']}"] = url
            elsif entry['src']
              page = by_source[entry['src'].sub(/\.vm\z/, '')] || by_source[entry['src']]
              unless page
                Jekyll.logger.warn 'Site map:', "no page for #{entry['src']}"
                next
              end
              url = entry['url'] || "/#{section['id']}/#{group['id']}/#{entry['slug'] || SiteMap.slug_of(entry['src'])}.html"
              redirects[page.url] = url unless page.url == url
              page.data['old_url'] = page.url
              page.data['permalink'] = url
              page.instance_variable_set(:@url, nil)
              file = page.data['doxia_source']
              item = { 'title' => entry['title'] || page.data['title'], 'url' => url, 'doc' => page,
                       'facts' => { 'holds' => [], 'changed' => dates[file],
                                    'edit' => "#{site.config.dig('edit', 'content')}/#{file}" } }
              src_urls[entry['src']] = url
            elsif entry['url'] || entry['href']
              item = { 'title' => entry['title'], 'url' => entry['url'] || entry['href'], 'external' => !entry['href'].nil? }
            end
            next unless item
            g['items'] << item
          end
        end
      end

      site.pages.reject! { |p| dropped.include?(p) }

      # Release notes: /docs/<version>/release-notes.html becomes /downloads/releases/<version>.html.
      site.pages.each do |page|
        m = page.data['doxia_source'].to_s.match(%r{\Acontent/markdown/docs/([^/]+)/release-notes\.md}) or next
        url = "/downloads/releases/#{m[1]}.html"
        redirects[page.url] = url
        page.data['old_url'] = page.url
        page.data['permalink'] = url
        page.instance_variable_set(:@url, nil)
        page.data['release_notes'] = m[1]
        page.data['nav'] = { 'section' => 'downloads', 'group' => 'releases' }
        page.data['facts'] = { 'holds' => [], 'changed' => dates[page.data['doxia_source']],
                               'edit' => "#{site.config.dig('edit', 'content')}/#{page.data['doxia_source']}" }
      end

      site.data['release_notes'] = site.pages.select { |p| p.data['release_notes'] }
                                             .map { |p| { 'version' => p.data['release_notes'], 'url' => p.url } }
                                             .sort_by { |r| Gem::Version.new(r['version'].tr('-', '.')) rescue Gem::Version.new('0') }.reverse

      # Navigation of every page in the map.
      tree.each do |s|
        s['groups'].each do |g|
          internal = g['items'].reject { |i| i['external'] }
          g['items'].each_with_index do |item, i|
            g['pages'] << item.except('doc', 'facts')
            doc = item['doc'] or next
            next if doc.data['nav'] && doc.data['nav']['primary']
            idx = internal.index(item)
            prev = idx && idx.positive? ? internal[idx - 1] : nil
            nxt = idx ? internal[idx + 1] : nil
            doc.data['nav'] = { 'primary' => true, 'section' => s['id'], 'group' => g['id'], 'title' => item['title'],
                                'prev' => prev && prev.slice('title', 'url'), 'next' => nxt && nxt.slice('title', 'url') }
            doc.data['facts'] = item['facts']
          end
        end
      end

      site.data['nav_tree'] = tree
      site.data['nav_sections'] = tree.to_h { |s| [s['id'], s] }
      site.data['nav_groups'] = tree.flat_map { |s| s['groups'].map { |g| ["#{s['id']}/#{g['id']}", g] } }.to_h
      site.data['src_urls'] = src_urls

      # News entries link to the page they are about.
      (site.data['news'] || []).each do |n|
        link = n['link'].to_s
        page = by_source[link.sub(/\.vm\z/, '')] || by_source[link]
        n['url'] = src_urls[link] || page&.url
      end

      # Landing pages (unless a page of the map already has the section's URL), group pages,
      # search, the news feed.
      own = site.pages.map(&:url).to_set
      tree.each do |s|
        unless own.include?(s['url'])
          site.pages << GeneratedPage.new(site, s['url'], 'layout' => s['id'] == 'news' ? 'news' : 'section', 'title' => s['title'],
                                                           'summary' => s['summary'], 'nav' => { 'section' => s['id'] })
        end
        s['groups'].each do |g|
          site.pages << GeneratedPage.new(site, g['url'], 'layout' => 'group', 'title' => g['title'], 'summary' => g['summary'],
                                                           'nav' => { 'section' => s['id'], 'group' => g['id'], 'landing' => true })
        end
      end
      site.pages << GeneratedPage.new(site, '/search.html', 'layout' => 'search', 'title' => 'Search')
      site.pages << GeneratedPage.new(site, '/news/feed.xml', 'layout' => 'feed', 'title' => 'Maven news')

      (map['redirects'] || {}).each { |from, to| redirects[from] = to unless from == to }
      # The guide's old topic and kind pages.
      %w[start configure multi-module jdk].each { |t| redirects["/guides/topics/#{t}.html"] = '/docs/index.html' }
      %w[tutorials how-to-guides reference explanation].each { |k| redirects["/guides/kinds/#{k}.html"] = '/docs/index.html' }

      # Maven pages outside the map whose URL now redirects (old index pages) are not built.
      site.pages.reject! { |p| p.data['doxia_source'] && !p.data['nav'] && redirects.key?(p.url) }
      taken = site.pages.map(&:url).to_set + site.collections.values.flat_map(&:docs).map(&:url)
      # The download script of maven.apache.org; this build has the page itself.
      SiteMap.moved['/download.cgi'] = '/downloads/index.html'
      redirects.each do |from, to|
        SiteMap.moved[from] = to
        next if taken.include?(from)
        page = GeneratedPage.new(site, from, 'layout' => nil, 'sitemap' => false)
        page.content = SiteMap.redirect_html(site, to)
        page.data['render_with_liquid'] = false
        site.pages << page
      end

      unplaced = site.pages.select { |p| p.data['doxia_source'] && !p.data['nav'] }.map(&:url)
      Jekyll.logger.info 'Site map:', "pages outside the map keep their URL: #{unplaced.join(', ')}" if unplaced.any?
    end
  end
end
