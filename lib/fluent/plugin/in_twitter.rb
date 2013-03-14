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
    config_param :lang, :string, :default => nil
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
      client = get_twitter_connection
      if @timeline == 'sampling' && @keyword
        client.track(@keyword)
      elsif @timeline == 'sampling' && @keyword.nil?
        client.sample
      elsif @timeline == 'userstream'
        client.userstream
      #elsif @timeline == 'follow'
      #  client.follow(@follow_ids)
      end
    end

    def get_twitter_connection
      notice = "twitter: starting Twitter Streaming API for #{@timeline}."
      notice << " tag:#{@tag}"
      notice << " lang:#{@lang}" unless @lang.nil?
      notice << " keyword:#{@keyword}" unless @keyword.nil?
      $log.info notice
      client = TweetStream::Client.new
      client.on_anything(&@any)
      client.on_error do |message|
        $log.info "twitter: unexpected error has occured. #{message}"
      end
      return client
    end

    def is_message?(status)
      return false if !status.include?(:text)
      return false if !status.include?(:user)
      return false if (!@lang.nil? && @lang != '') && !@lang.include?(status[:user][:lang])
      return true
    end

    def get_message(status)
      case @format
      when 'nest'
        record = status.inject({}){|f,(k,v)| f[k.to_s] = v; f}
      when 'flat'
        # TODO
      when 'simple'
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
