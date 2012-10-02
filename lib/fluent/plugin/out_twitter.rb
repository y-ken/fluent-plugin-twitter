class Fluent::TwitterOutput < Fluent::Output
  Fluent::Plugin.register_output('twitter', self)

  config_param :consumer_key, :string
  config_param :consumer_secret, :string
  config_param :oauth_token, :string
  config_param :oauth_token_secret, :string

  def initialize
    super
    require 'twitter'
  end

  def configure(conf)
    super

    @twitter = Twitter::Client.new(
      :consumer_key => conf['consumer_key'],
      :consumer_secret => conf['consumer_secret'],
      :oauth_token => conf['oauth_token'],
      :oauth_token_secret => conf['oauth_token_secret']
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

