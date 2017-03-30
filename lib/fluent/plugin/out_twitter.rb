require "twitter"
require "fluent/plugin/output"

class Fluent::Plugin::TwitterOutput < Fluent::Plugin::Output
  Fluent::Plugin.register_output('twitter', self)

  config_param :consumer_key, :string, secret: true
  config_param :consumer_secret, :string, secret: true
  config_param :access_token, :string, secret: true
  config_param :access_token_secret, :string, secret: true

  def initialize
    super
  end

  def configure(conf)
    super

    @twitter = Twitter::REST::Client.new(
      consumer_key: @consumer_key,
      consumer_secret: @consumer_secret,
      access_token: @access_token,
      access_token_secret: @access_token_secret
    )
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
