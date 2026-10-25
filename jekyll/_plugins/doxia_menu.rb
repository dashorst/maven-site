require 'nokogiri'
require 'cgi'

# The left-hand menu of the Fluido skin, read from content/site.xml as the Doxia site
# renderer reads it, followed by the menus maven.apache.org inherits from its parent site
# descriptors (jekyll/_data/menu_parent.yml).
#
#   {% maven_menu %}
#
# An item with sub-items is open when it is not marked collapse="true", or when the page
# being shown is one of its sub-items; the current page is marked active. A generated page
# can name the item it belongs to in `menu_url`, which is then marked active as well.
# `menu_labels` in _config.yml renames items by URL.
module DoxiaMenu
  def self.items(node)
    node.xpath('./item').map do |item|
      { 'name' => item['name'], 'href' => item['href'], 'collapse' => item['collapse'] == 'true',
        'items' => items(item) }
    end
  end

  def self.menus(site)
    @menus ||= begin
      xml = Nokogiri::XML(File.read(File.join(site.source, 'content', 'site.xml')))
      xml.remove_namespaces!
      own = xml.xpath('//body/menu').map { |m| { 'name' => m['name'], 'items' => items(m) } }
      own + (site.data['menu_parent'] || [])
    end
  end

  # "/index.html", "developers/x.html" and "../x.html" are all site paths.
  def self.path(href)
    return nil if href.nil? || href.empty?
    return href if href =~ %r{\A[a-z]+:}i
    '/' + href.sub(%r{\A/}, '')
  end

  def self.contains?(item, url)
    path(item['href']) == url || Array(item['items']).any? { |i| contains?(i, url) }
  end

  def self.link(item, url, base, icon)
    target = path(item['href'])
    label = CGI.escapeHTML((@labels && @labels[target]) || item['name'].to_s)
    return %(<a>#{icon}#{label}</a>) if target.nil? || target == url
    href = target.start_with?('/') ? "#{base}#{target}" : target
    %(<a href="#{CGI.escapeHTML(href)}">#{icon}#{label}</a>)
  end

  def self.render_item(item, url, base, indent, section = nil)
    children = Array(item['items'])
    active = path(item['href']) == url || (section && path(item['href']) == section)
    open = children.any? && (!item['collapse'] || children.any? { |c| contains?(c, url) || (section && contains?(c, section)) })
    icon = if children.empty? then ''
           elsif open then '<span class="icon-chevron-down"></span>'
           else '<span class="icon-chevron-right"></span>'
           end
    html = +%(#{indent}<li#{active ? ' class="active"' : ''}>#{link(item, url, base, icon)})
    if open
      html << %(\n#{indent} <ul class="nav nav-list">\n)
      children.each { |c| html << render_item(c, url, base, indent + '  ', section) }
      html << %(#{indent} </ul>)
    end
    html << "</li>\n"
  end

  class Tag < Liquid::Tag
    def render(context)
      site = context.registers[:site]
      page = context.registers[:page]
      url = page['url']
      section = page['menu_url']
      base = site.config['baseurl'].to_s
      DoxiaMenu.instance_variable_set(:@labels, site.config['menu_labels'] || {})
      html = +%(<ul class="nav nav-list">\n)
      DoxiaMenu.menus(site).each do |menu|
        html << %(  <li class="nav-header">#{CGI.escapeHTML(menu['name'])}</li>\n) if menu['name']
        menu['items'].each { |i| html << DoxiaMenu.render_item(i, url, base, '  ', section) }
      end
      html << '</ul>'
    end
  end
end

Liquid::Template.register_tag('maven_menu', DoxiaMenu::Tag)
