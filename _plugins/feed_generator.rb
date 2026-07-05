# frozen_string_literal: true

module Jekyll
  class DummyPost < Page
    def initialize(site, title, categories, date, url)
      @site = site
      @base = site.source
      @dir = '/'

      @basename = ''
      @ext = ''
      @name = @basename + @ext

      @data = {
        'title' => title,
        'date' => date,
        'published' => true,
        'categories' => categories,
        'url' => url
      }
    end

    def categories
      @data['categories'] ||= []
    end

    def id
      @data['url'] ||= '/'
    end

    def url
      @data['url'] ||= '/'
    end
  end

  class FeedPage < Page
    def initialize(site, base, category, posts)
      @site = site
      @base = base
      @dir = category.nil? ? '/' : "#{category}/"

      @basename = 'feed'
      @ext = '.xml'
      @name = @basename + @ext

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'feed.xml')
      self.data['category'] = category
      self.data['posts'] = posts.filter { |post| post.data['published'] != false } unless site.config['show_drafts']
    end
  end

  class FeedGenerator < Generator
    safe true
    priority :low

    def generate(site)
      all_posts = site.posts.docs

      # Mix in external writings
      all_posts += site.data['external_writings'].map do |ew|
        DummyPost.new(site, ew['title'], ['writings'], ew['date'], ew['url'])
      end

      # Mix in the recordings
      all_posts += site.data['recordings'].map do |recording|
        DummyPost.new(
          site,
          "#{recording['artist']} Live at #{recording['location']} on #{recording['date']}",
          ['recordings'],
          recording['date'],
          "/recordings/#{recording['slug']}/"
        )
      end

      site.pages << FeedPage.new(site, site.source, nil, all_posts)

      if site.data['external_writings'].any? and !site.categories.key?('writings')
        site.categories['writings'] = []
      end

      site.categories.each_key do |category|
        posts = all_posts.select { |post| post.data['categories'].include?(category) }
        site.pages << FeedPage.new(site, site.source, category, posts)
      end
    end
  end
end
