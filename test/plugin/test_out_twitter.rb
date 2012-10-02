require 'helper'

class TwitterOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    consumer_key        CONSUMER_KEY
    consumer_secret     CONSUMER_SECRET
    oauth_token         OAUTH_TOEKN
    oauth_token_secret  OAUTH_TOEKN_SECRET
  ]

  def create_driver(conf=CONFIG,tag='test')
    Fluent::Test::OutputTestDriver.new(Fluent::TwitterOutput, tag).configure(conf)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    d = create_driver %[
      consumer_key        CONSUMER_KEY
      consumer_secret     CONSUMER_SECRET
      oauth_token         OAUTH_TOEKN
      oauth_token_secret  OAUTH_TOEKN_SECRET
    ]
    d.instance.inspect
    assert_equal 'CONSUMER_KEY', d.instance.consumer_key
    assert_equal 'CONSUMER_SECRET', d.instance.consumer_secret
    assert_equal 'OAUTH_TOEKN', d.instance.oauth_token
    assert_equal 'OAUTH_TOEKN_SECRET', d.instance.oauth_token_secret
  end

  def test_emit
    d1 = create_driver(CONFIG, 'input.access')
    time = Time.parse("2012-01-02 13:14:15").to_i
    d1.run do
      d1.emit({'message' => 'sample message'})
    end
    emits = d1.emits
    assert_equal 0, emits.length
  end
end

