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
    config_param :raw_json, :bool, :default => false

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
      @any = Proc.new do |hash|
        if @raw_json
          get_message(hash) if is_message?(hash)
        end
      end
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
      client.on_anything(&@any) if @raw_json
      client.track(@keyword) do |status|
        next unless is_message?(status)
        get_message(status) if !@raw_json
      end
    end

    def start_twitter_sample
      $log.info "starting twitter sampled streaming. tag:#{@tag} lang:#{@lang}"
      client = TweetStream::Client.new
      client.on_anything(&@any) if @raw_json
      client.sample do |status|
        next unless is_message?(status)
        get_message(status) if !@raw_json
      end
    end

    def start_twitter_userstream
      $log.info "starting twitter userstream tracking. tag:#{@tag} lang:#{@lang}"
      client = TweetStream::Client.new
      client.on_anything(&@any) if @raw_json
      client.userstream do |status|
        next unless is_message?(status)
        get_message(status) if !@raw_json
      end
    end

    def is_message?(status)
      if status.instance_of?(Twitter::Tweet)
        return false if !status.text
        return false if @lang.size > 0 && !@lang.include?(status.user.lang)
      elsif @raw_json && status.instance_of?(Hash)
        return false if !status.include?(:text)
        return false if !status.include?(:user)
        return false if @lang.size > 0 && !@lang.include?(status[:user][:lang])
      end
      return true
    end

    def get_message(status)
      if @raw_json
        record = status.inject({}){|f,(k,v)| f[k.to_s] = v; f}
      else
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
      end
      Engine.emit(@tag, Engine.now, record)
    end
  end
end
