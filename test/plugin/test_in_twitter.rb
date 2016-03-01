require 'helper'

class TwitterInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    consumer_key        CONSUMER_KEY
    consumer_secret     CONSUMER_SECRET
    oauth_token         OAUTH_TOKEN
    oauth_token_secret  OAUTH_TOKEN_SECRET
    tag                 input.twitter
    timeline            sampling
  ]

  def create_driver(conf=CONFIG,tag='test',use_v1=false)
    Fluent::Test::OutputTestDriver.new(Fluent::TwitterInput, tag).configure(conf,use_v1)
  end

  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    d = create_driver %[
      consumer_key        CONSUMER_KEY
      consumer_secret     CONSUMER_SECRET
      oauth_token         OAUTH_TOKEN
      oauth_token_secret  OAUTH_TOKEN_SECRET
      tag                 input.twitter
      timeline            tracking
      keyword             ${hashtag}fluentd,fluentd lang:ja
    ]
    assert_equal 'CONSUMER_KEY', d.instance.consumer_key
    assert_equal 'CONSUMER_SECRET', d.instance.consumer_secret
    assert_equal 'OAUTH_TOKEN', d.instance.oauth_token
    assert_equal 'OAUTH_TOKEN_SECRET', d.instance.oauth_token_secret
    assert_equal '#fluentd,fluentd lang:ja', d.instance.keyword
  end

  def test_v1_multi_keyword
    assert_raise(Fluent::ConfigError) {
      d = create_driver('', 'test', true)
    }
    d = create_driver(%[
      consumer_key        CONSUMER_KEY
      consumer_secret     CONSUMER_SECRET
      oauth_token         OAUTH_TOKEN
      oauth_token_secret  OAUTH_TOKEN_SECRET
      tag                 input.twitter
      timeline            tracking
      keyword             'treasuredata,treasure data,#treasuredata,fluentd,#fluentd'
    ], 'test', true)
    assert_equal 'CONSUMER_KEY', d.instance.consumer_key
    assert_equal 'CONSUMER_SECRET', d.instance.consumer_secret
    assert_equal 'OAUTH_TOKEN', d.instance.oauth_token
    assert_equal 'OAUTH_TOKEN_SECRET', d.instance.oauth_token_secret
    assert_equal 'treasuredata,treasure data,#treasuredata,fluentd,#fluentd', d.instance.keyword
  end
end
