module Fluent
  class TwitterInput < Fluent::Input
    TIMELINE_TYPE = %w(userstream sampling)
    Plugin.register_input('twitter', self)

    config_param :consumer_key, :string
    config_param :consumer_secret, :string
    config_param :oauth_token, :string
    config_param :oauth_token_secret, :string
    config_param :tag, :string
    config_param :timeline, :string
    config_param :keyword, :string, :default => nil
    config_param :lang, :string, :default => ''

    def initialize
      super
      require 'tweetstream'
    end

    def configure(conf)
      super
      raise Fluent::ConfigError, "timeline value undefined #{@timeline}" if !TIMELINE_TYPE.include?(@timeline)
      TweetStream.configure do |config|
        config.consumer_key = @consumer_key
        config.consumer_secret = @consumer_secret
        config.oauth_token = @oauth_token
        config.oauth_token_secret = @oauth_token_secret
        config.auth_method = :oauth
      end
    end

    def start
      @thread = Thread.new(&method(:run))
    end

    def shutdown
      Thread.kill(@thread)
    end

    def run
      if @timeline == 'sampling' && @keyword
        start_twitter_track
      elsif @timeline == 'sampling' && @keyword.nil?
        start_twitter_sample
      elsif @timeline == 'userstream'
        start_twitter_userstream
      end
    end

    def start_twitter_track
      $log.info "starting twitter keyword tracking. tag:#{@tag} lang:#{@lang} keyword:#{@keyword}"
      client = TweetStream::Client.new
      client.track(@keyword) do |status|
        next unless status.text
        next unless @lang.include?(status.user.lang)
        get_message(status)
      end
    end

    def start_twitter_sample
      $log.info "starting twitter sampled streaming. tag:#{@tag} lang:#{@lang}"
      client = TweetStream::Client.new
      client.sample do |status|
        next unless status.text
        next unless @lang.include?(status.user.lang)
        get_message(status)
      end
    end

    def start_twitter_userstream
      $log.info "starting twitter userstream tracking. tag:#{@tag} lang:#{@lang}"
      client = TweetStream::Client.new
      client.userstream do |status|
        next unless status.text
        next unless @lang.include?(status.user.lang)
        get_message(status)
      end
    end

    def get_message(status)
      record = Hash.new
      record.store('message', status.text)
      record.store('geo', status.geo)
      record.store('place', status.place)
      record.store('created_at', status.created_at)
      record.store('user_name', status.user.name)
      record.store('user_screen_name', status.user.screen_name)
      record.store('user_profile_image_url', status.user.profile_image_url)
      record.store('user_time_zone', status.user.time_zone)
      record.store('user_lang', status.user.lang)
      Engine.emit(@tag, Engine.now, record)
    end
  end
end
