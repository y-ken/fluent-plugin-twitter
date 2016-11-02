require 'helper'
require 'fluent/plugin/in_twitter'
require 'fluent/test/driver/input'

class TwitterInputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    consumer_key        CONSUMER_KEY
    consumer_secret     CONSUMER_SECRET
    access_token        ACCESS_TOKEN
    access_token_secret ACCESS_TOKEN_SECRET
    tag                 input.twitter
    timeline            sampling
  ]

  def create_driver(conf = CONFIG, syntax: :v1)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::TwitterInput).configure(conf, syntax: syntax)
  end

  sub_test_case "v0 syntax" do
  def test_configure
    assert_raise(Fluent::ConfigError) {
      d = create_driver('', syntax: :v0)
    }
    d = create_driver %[
      consumer_key        CONSUMER_KEY
      consumer_secret     CONSUMER_SECRET
      access_token        ACCESS_TOKEN
      access_token_secret ACCESS_TOKEN_SECRET
      tag                 input.twitter
      timeline            tracking
      keyword             ${hashtag}fluentd,fluentd lang:ja
    ]
    assert_equal 'CONSUMER_KEY', d.instance.consumer_key
    assert_equal 'CONSUMER_SECRET', d.instance.consumer_secret
    assert_equal 'ACCESS_TOKEN', d.instance.access_token
    assert_equal 'ACCESS_TOKEN_SECRET', d.instance.access_token_secret
    assert_equal '#fluentd,fluentd lang:ja', d.instance.keyword
  end
  end

  sub_test_case "v1 syntax" do
  def test_v1_multi_keyword
    assert_raise(Fluent::ConfigError) {
      d = create_driver('')
    }
    d = create_driver(%[
      consumer_key        CONSUMER_KEY
      consumer_secret     CONSUMER_SECRET
      access_token        ACCESS_TOKEN
      access_token_secret ACCESS_TOKEN_SECRET
      tag                 input.twitter
      timeline            tracking
      keyword             'treasuredata,treasure data,#treasuredata,fluentd,#fluentd'
    ])
    assert_equal 'CONSUMER_KEY', d.instance.consumer_key
    assert_equal 'CONSUMER_SECRET', d.instance.consumer_secret
    assert_equal 'ACCESS_TOKEN', d.instance.access_token
    assert_equal 'ACCESS_TOKEN_SECRET', d.instance.access_token_secret
    assert_equal 'treasuredata,treasure data,#treasuredata,fluentd,#fluentd', d.instance.keyword
  end
  end
end
