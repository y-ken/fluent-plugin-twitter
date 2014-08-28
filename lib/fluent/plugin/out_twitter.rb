class Fluent::TwitterOutput < Fluent::Output
  Fluent::Plugin.register_output('twitter', self)

  config_param :consumer_key, :string
  config_param :consumer_secret, :string
  config_param :oauth_token, :string, :default => nil
  config_param :oauth_token_secret, :string, :default => nil
  config_param :access_token, :string, :default => nil
  config_param :access_token_secret, :string, :default => nil

  def initialize
    super
    require 'twitter'
  end

  def configure(conf)
    super

    @access_token = @access_token || @oauth_token
    @access_token_secret = @access_token_secret || @oauth_token_secret
    if !@consumer_key or !@consumer_secret or !@access_token or !@access_token_secret
      raise Fluent::ConfigError, "missing values in consumer_key or consumer_secret or oauth_token or oauth_token_secret"
    end

    @twitter = Twitter::REST::Client.new(
      :consumer_key => @consumer_key,
      :consumer_secret => @consumer_secret,
      :access_token => @access_token,
      :access_token_secret => @access_token_secret
    )
  end

  def emit(tag, es, chain)
    es.each do |time,record|
      tweet(record['message'])
    end

    chain.next
  end

  def tweet(message)
    begin
      @twitter.update(message)
    rescue Twitter::Error => e
      $log.error("Twitter Error: #{e.message}")
    end
  end
end

