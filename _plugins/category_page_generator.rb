# frozen_string_literal: true

module Jekyll
  class CategoryPage < Page
    def initialize(site, category, posts)
      @site = site
      @base = site.source
      @dir = category + '/'

      @basename = 'index'
      @ext = '.html'
      @name = @basename + @ext

      @data = {
        'category' => category,
        'layout' => 'category',
        'posts' => posts + (category == 'writings' ? site.data['external_writings'] : []),
        'title' => category.capitalize,
        'permalink' => "/#{category}/"
      }
    end
  end

  class CategoryPageGenerator < Generator
    safe true
    priority :low

    def generate(site)
      if site.data['external_writings'].any? and !site.categories.key?('writings')
        site.categories['writings'] = []
      end

      site.categories.each do |category, posts|
        site.pages << CategoryPage.new(site, category, posts)
      end
    end
  end
end