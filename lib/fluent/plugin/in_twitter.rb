module Fluent
  class TwitterInput < Fluent::Input
    TIMELINE_TYPE = %w(userstream sampling)
    FORMAT_TYPE = %w(compact raw)
    Plugin.register_input('twitter', self)

    config_param :consumer_key, :string
    config_param :consumer_secret, :string
    config_param :oauth_token, :string
    config_param :oauth_token_secret, :string
    config_param :tag, :string
    config_param :timeline, :string
    config_param :keyword, :string, :default => nil
    config_param :lang, :string, :default => ''
    config_param :format, :string, :default => 'compact'

    def initialize
      super
      require 'tweetstream'
    end

    def configure(conf)
      super

      raise Fluent::ConfigError, "timeline value undefined #{@timeline}" if !TIMELINE_TYPE.include?(@timeline)
      raise Fluent::ConfigError, "format value undefined #{@format}" if !FORMAT_TYPE.include?(@format)

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
          get_message(hash) if is_message?(hash)
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
      client.on_anything(&@any)
      client.track(@keyword)
    end

    def start_twitter_sample
      $log.info "starting twitter sampled streaming. tag:#{@tag} lang:#{@lang}"
      client = TweetStream::Client.new
      client.on_anything(&@any)
      client.sample
    end

    def start_twitter_userstream
      $log.info "starting twitter userstream tracking. tag:#{@tag} lang:#{@lang}"
      client = TweetStream::Client.new
      client.on_anything(&@any)
      client.userstream
    end

    def is_message?(status)
      if status.instance_of?(Hash)
        return false if !status.include?(:text)
        return false if !status.include?(:user)
        return false if @lang.size > 0 && !@lang.include?(status[:user][:lang])
      end
      return true
    end

    def get_message(status)
      case @format
      when 'raw'
        record = status.inject({}){|f,(k,v)| f[k.to_s] = v; f}
      when 'compact'
        record = Hash.new
        record.store('message', status[:text])
        record.store('geo', status[:geo])
        record.store('place', status[:place])
        record.store('created_at', status[:place])
        record.store('user_name', status[:user][:name])
        record.store('user_screen_name', status[:user][:screen_name])
        record.store('user_profile_image_url', status[:user][:profile_image_url])
        record.store('user_time_zone', status[:user][:time_zone])
        record.store('user_lang', status[:user][:lang])
      end
      Engine.emit(@tag, Engine.now, record)
    end
  end
end
