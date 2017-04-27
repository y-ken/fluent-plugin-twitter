require "twitter"
require "fluent/plugin/output"

class Fluent::Plugin::TwitterOutput < Fluent::Plugin::Output
  Fluent::Plugin.register_output('twitter', self)

  config_param :consumer_key, :string, secret: true
  config_param :consumer_secret, :string, secret: true
  config_param :access_token, :string, secret: true
  config_param :access_token_secret, :string, secret: true

  config_section :proxy, multi: false do
    config_param :host, :string
    config_param :port, :string
    config_param :username, :string, default: nil
    config_param :password, :string, default: nil, secret: true
  end

  def initialize
    super
  end

  def configure(conf)
    super

    @twitter = Twitter::REST::Client.new do |config|
      config.consumer_key = @consumer_key
      config.consumer_secret = @consumer_secret
      config.access_token = @access_token
      config.access_token_secret = @access_token_secret
      config.proxy = @proxy.to_h if @proxy
    end
  end

  def process(tag, es)
    es.each do |_time, record|
      tweet(record['message'])
    end
  end

  def tweet(message)
    begin
      @twitter.update(message)
    rescue Twitter::Error => e
      log.error("Twitter Error: #{e.message}")
    end
  end
end
