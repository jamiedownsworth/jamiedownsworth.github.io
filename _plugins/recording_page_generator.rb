require 'rmagick'

module Jekyll
  class ThumbnailFile < StaticFile
    def initialize(site, source_path, base, dir, name)
      super(site, base, dir, name)
      @source_path = source_path
    end

    def path
      @source_path
    end
  end

  class RecordingPage < Page
    def initialize(site, recording)
      @site = site
      @base = site.source
      @dir = "recordings/#{recording['slug']}/"

      @basename = 'index'
      @ext = '.html'
      @name = @basename + @ext

      images = Dir.glob(File.join(site.source, 'recordings', recording['slug'], '*'))
                  .filter { |f| File.file?(f) }
                  .map { |f| f.sub(site.source, '') }

      cache_root = File.join(site.source, '.jekyll-cache', 'thumbnails')

      images.each do |image|
        image_path = File.join(site.source, image)
        image_dir = File.dirname(image)
        image_name = File.basename(image, File.extname(image))
        image_ext = File.extname(image)
        thumb_name = "#{image_name}_thumb#{image_ext}"

        cache_path = File.join(cache_root, image_dir, thumb_name)
        FileUtils.mkdir_p(File.dirname(cache_path))

        if !File.exist?(cache_path) || File.mtime(image_path) > File.mtime(cache_path)
          img = Magick::Image.read(image_path).first
          thumb = img.thumbnail(100, 100)
          thumb.write(cache_path)
          img.destroy!
          thumb.destroy!
        end

        site.static_files << ThumbnailFile.new(
          site, cache_path, site.source, image_dir, thumb_name
        )
      end

      @data = {
        'title' => "#{recording['artist']} Live at #{recording['location']} on #{recording['date']}",
        'layout' => 'recording',
        'categories' => ['recordings'],
        'permalink' => "/recordings/#{recording['slug']}/",
        'recording' => recording,
        'images' => images.map do |image|
          image_dir = File.dirname(image)
          image_name = File.basename(image, File.extname(image))
          image_ext = File.extname(image)

          {
            'full' => image,
            'thumb' => File.join(image_dir, "#{image_name}_thumb#{image_ext}")
          }
        end
      }

      content_path = File.join(site.source, '_data', 'recording_infos', "#{recording['slug']}.txt")

      if images.empty?
        Jekyll.logger.warn 'RecordingPage:', "No images found for #{recording['slug']}"
      end

      if File.exist?(content_path)
        @content = File.read(content_path).strip
      else
        @content = ''
        Jekyll.logger.warn 'RecordingPage:', "Missing content file for #{recording['slug']}"
      end
    end
  end

  class RecordingPageGenerator < Generator
    safe true
    priority :highest

    def generate(site)
      site.data['recordings'].each do |recording|
        page = RecordingPage.new(site, recording)
        site.pages << page
        (site.categories['recordings'] ||= []) << page
      end
    end
  end
end