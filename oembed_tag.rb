# Title: A Liquid tag for Jekyll sites that allows embedding website supporting oEmbed
#
# Authors: Shogo Ichinose http://twitter.com/shogo82148
# Description:
#
# Syntax {% oembed URL %}
#
# Examples:
# {% oembed http://www.youtube.com/watch?v=rrsxEGgQDkM %}
#
# Output:
# <iframe width="459" height="344" src="http://www.youtube.com/embed/rrsxEGgQDkM?fs=1&feature=oembed" frameborder="0" allowfullscreen></iframe>
#

require 'open-uri'
require 'digest/sha1'
require 'oembed'

module Jekyll

  class OEmbedTag < Liquid::Tag
    def initialize(tag_name, text, token)
      super
      @text = text
      @cache_disabled = false
      @cache_folder   = File.expand_path "../.oembed-cache", File.dirname(__FILE__)
      FileUtils.mkdir_p @cache_folder
    end

    def render(context)
      if @text =~ /(https?:\/\/\S+)/
        uri = $1
        get_cache_for(uri) || get_from_web(uri)
      else
        ""
      end
    end

    def get_cache_for(uri)
      return nil if @cache_disabled
      cache_file = get_cache_file_for uri
      File.read(cache_file) if File.exist? cache_file
    end

    def get_cache_file_for(uri)
      bad_chars = /[^a-zA-Z0-9\-_.]/
      uri      = uri.gsub bad_chars, ''
      File.join @cache_folder, "#{uri}.cache"
    end

    def get_from_web(uri)
      data ||= OEmbed::Providers.get(uri).html rescue nil
      data ||= OEmbed::ProviderDiscovery.discover_provider(uri).get(uri).html rescue nil
      data ||= "<a href=\"#{uri}\">#{uri}</a>"
      cache uri, data unless @cache_disabled
      data
    end

    def cache(uri, data)
      cache_file = get_cache_file_for uri
      File.open(cache_file, "w") do |io|
        io.write(data)
      end
    end

    Twitter = OEmbed::Provider.new("https://api.twitter.com/1/statuses/oembed.{format}")
    Twitter << "https://twitter.com/*/status/*"
    Twitter << "https://twitter.com/*/statuses/*"
    Twitter << "http://twitter.com/*/status/*"
    Twitter << "http://twitter.com/*/statuses/*"
    OEmbed::Providers.register(Twitter)

    OEmbed::Providers.register_all

  end

  class OEmbedNoCache < OEmbedTag
    def initialize(tag_name, text, token)
      super
      @cache_disabled = true
    end
  end

end

Liquid::Template.register_tag('oembed', Jekyll::OEmbedTag)
Liquid::Template.register_tag('oembednocache', Jekyll::OEmbedNoCache)
