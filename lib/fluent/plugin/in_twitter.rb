require "fluent/plugin/input"

require 'twitter'
require 'nkf'

module Fluent::Plugin
  class TwitterInput < Fluent::Plugin::Input
    Fluent::Plugin.register_input('twitter', self)

    helpers :thread

    TIMELINE_TYPE = %i(userstream sampling location tracking)
    OUTPUT_FORMAT_TYPE = %i(nest flat simple)

    config_param :consumer_key, :string, secret: true
    config_param :consumer_secret, :string, secret: true
    config_param :access_token, :string, secret: true
    config_param :access_token_secret, :string, secret: true
    config_param :tag, :string
    config_param :timeline, :enum, list: TIMELINE_TYPE
    config_param :keyword, :string, default: nil
    config_param :follow_ids, :string, default: nil
    config_param :locations, :string, default: nil
    config_param :lang, :string, default: nil
    config_param :output_format, :enum, list: OUTPUT_FORMAT_TYPE, default: :simple
    config_param :flatten_separator, :string, default: '_'

    config_section :proxy, multi: false do
      config_param :host, :string
      config_param :port, :string
      config_param :username, :string, default: nil
      config_param :password, :string, default: nil, secret: true
    end

    def initialize
      super
      @running = false
    end

    def configure(conf)
      super

      @keyword = @keyword.gsub('${hashtag}', '#') unless @keyword.nil?

      @client = Twitter::Streaming::Client.new do |config|
        config.consumer_key = @consumer_key
        config.consumer_secret = @consumer_secret
        config.access_token = @access_token
        config.access_token_secret = @access_token_secret
        config.proxy = @proxy.to_h if @proxy
      end
    end

    def start
      @running = true
      thread_create(:in_twitter) do
        run
      end
    end

    def shutdown
      @running = false
      @client.close if @client.respond_to?(:close)
      super
    end

    def run
      notice = "twitter: starting Twitter Streaming API for #{@timeline}."
      notice << " tag:#{@tag}"
      notice << " lang:#{@lang}" unless @lang.nil?
      notice << " keyword:#{@keyword}" unless @keyword.nil?
      notice << " follow:#{@follow_ids}" unless @follow_ids.nil? && !@keyword.nil?
      log.info notice

      if [:sampling, :tracking].include?(@timeline) && @keyword
        @client.filter(track: @keyword, &method(:handle_object))
      elsif @timeline == :tracking && @follow_ids
        @client.filter(follow: @follow_ids, &method(:handle_object))
      elsif @timeline == :sampling && @keyword.nil? && @follow_ids.nil?
        @client.sample(&method(:handle_object))
      elsif @timeline == :userstream
        @client.user(&method(:handle_object))
      end
    end

    def handle_object(object)
      return unless @running
      if is_message?(object)
        get_message(object)
      end
    end

    def is_message?(tweet)
      return false if !tweet.is_a?(Twitter::Tweet)
      return false if (!@lang.nil? && @lang != '') && !@lang.include?(tweet.user.lang)
      if @timeline == :userstream && (!@keyword.nil? && @keyword != '')
        pattern = NKF::nkf('-WwZ1', @keyword).gsub(/,\s?/, '|')
        tweet = NKF::nkf('-WwZ1', tweet.text)
        return false if !Regexp.new(pattern, Regexp::IGNORECASE).match(tweet)
      end
      return true
    end

    def get_message(tweet)
      case @output_format
      when :nest
        record = hash_key_to_s(tweet.to_h)
      when :flat
        record = hash_flatten(tweet.to_h)
      when :simple
        record = {}
        record['message'] = tweet.text.scrub('')
        record['geo'] = tweet.geo
        record['place'] = tweet.place
        record['created_at'] = tweet.created_at
        record['user_name'] = tweet.user.name
        record['user_screen_name'] = tweet.user.screen_name
        record['user_profile_image_url'] = tweet.user.profile_image_url
        record['user_time_zone'] = tweet.user.time_zone
        record['user_lang'] = tweet.user.lang
      end
      router.emit(@tag, Fluent::Engine.now, record)
    end

    def hash_flatten(record, prefix = nil)
      record.inject({}) do |d, (k, v)|
        k = prefix.to_s + k.to_s
        if v.instance_of?(Hash)
          d.merge(hash_flatten(v, k + @flatten_separator))
        elsif v.instance_of?(String)
          d.merge(k => v.scrub(""))
        else
          d.merge(k => v)
        end
      end
    end

    def hash_key_to_s(hash)
      newhash = {}
      hash.each do |k, v|
        if v.instance_of?(Hash)
          newhash[k.to_s] = hash_key_to_s(v)
        elsif v.instance_of?(Array)
          newhash[k.to_s] = array_key_to_s(v)
        elsif v.instance_of?(String)
          newhash[k.to_s] = v.scrub('')
        else
          newhash[k.to_s] = v
        end
      end
      newhash
    end

    def array_key_to_s(array)
      array.map do |v|
        if v.instance_of?(Hash)
          hash_key_to_s(v)
        elsif v.instance_of?(Array)
          array_key_to_s(v)
        elsif v.instance_of?(String)
          v.scrub('')
        else
          v
        end
      end
    end
  end
end
