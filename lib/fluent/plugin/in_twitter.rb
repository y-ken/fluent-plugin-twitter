module Fluent
  class TwitterInput < Fluent::Input
    TIMELINE_TYPE = %w(userstream sampling tracking)
    OUTPUT_FORMAT_TYPE = %w(nest flat simple)
    Plugin.register_input('twitter', self)

    config_param :consumer_key, :string, :secret => true
    config_param :consumer_secret, :string, :secret => true
    config_param :oauth_token, :string, :secret => true
    config_param :oauth_token_secret, :string, :secret => true
    config_param :tag, :string
    config_param :timeline, :string
    config_param :keyword, :string, :default => nil
    config_param :follow_ids, :string, :default => nil
    config_param :lang, :string, :default => nil
    config_param :output_format, :string, :default => 'simple'
    config_param :flatten_separator, :string, :default => '_'

    def initialize
      super
      require 'tweetstream'
      require 'nkf'
      require 'string/scrub' if RUBY_VERSION.to_f < 2.1
    end

    def configure(conf)
      super

      if !TIMELINE_TYPE.include?(@timeline)
        raise Fluent::ConfigError, "timeline value undefined #{@timeline}"
      end
      if !OUTPUT_FORMAT_TYPE.include?(@output_format)
        raise Fluent::ConfigError, "output_format value undefined #{@output_format}"
      end

      @keyword = @keyword.gsub('${hashtag}', '#') unless @keyword.nil?

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
      if ['sampling', 'tracking'].include?(@timeline) && @keyword
        client.track(@keyword)
      elsif @timeline == 'tracking' && @follow_ids
        client.follow(@follow_ids)
      elsif @timeline == 'sampling' && @keyword.nil? && @follow_ids.nil?
        client.sample
      elsif @timeline == 'userstream'
        client.userstream
      end
    end

    def get_twitter_connection
      notice = "twitter: starting Twitter Streaming API for #{@timeline}."
      notice << " tag:#{@tag}"
      notice << " lang:#{@lang}" unless @lang.nil?
      notice << " keyword:#{@keyword}" unless @keyword.nil?
      notice << " follow:#{@follow_ids}" unless @follow_ids.nil? && !@keyword.nil?
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
      if @timeline == 'userstream' && (!@keyword.nil? && @keyword != '')
        pattern = NKF::nkf('-WwZ1', @keyword).gsub(/,\s?/, '|')
        tweet = NKF::nkf('-WwZ1', status[:text])
        return false if !Regexp.new(pattern, Regexp::IGNORECASE).match(tweet)
      end
      return true
    end

    def get_message(status)
      case @output_format
      when 'nest'
        record = hash_key_to_s(status)
      when 'flat'
        record = hash_flatten(status)
      when 'simple'
        record = Hash.new
        record.store('message', status[:text]).scrub('')
        record.store('geo', status[:geo])
        record.store('place', status[:place])
        record.store('created_at', status[:created_at])
        record.store('user_name', status[:user][:name])
        record.store('user_screen_name', status[:user][:screen_name])
        record.store('user_profile_image_url', status[:user][:profile_image_url])
        record.store('user_time_zone', status[:user][:time_zone])
        record.store('user_lang', status[:user][:lang])
      end
      router.emit(@tag, Engine.now, record)
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
        if v.instance_of?(Hash) then
          newhash[k.to_s] = hash_key_to_s(v)
        elsif v.instance_of?(Array) then
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
        if v.instance_of?(Hash) then
          hash_key_to_s(v)
        elsif v.instance_of?(Array) then
          array_key_to_s(v)
        elsif v.instance_of?(String) then
          v.scrub('')
        else
          v
        end
      end
    end
  end
end
