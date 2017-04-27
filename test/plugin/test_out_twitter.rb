require 'helper'
require 'fluent/test/driver/output'
require 'fluent/plugin/out_twitter'

class TwitterOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    consumer_key        CONSUMER_KEY
    consumer_secret     CONSUMER_SECRET
    access_token        ACCESS_TOKEN
    access_token_secret ACCESS_TOKEN_SECRET
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::TwitterOutput).configure(conf)
  end

  sub_test_case "configure" do
    def test_empty
      assert_raise(Fluent::ConfigError) {
        create_driver('')
      }
    end

    def test_configure
      d = create_driver %[
        consumer_key        CONSUMER_KEY
        consumer_secret     CONSUMER_SECRET
        access_token        ACCESS_TOKEN
        access_token_secret ACCESS_TOKEN_SECRET
      ]
      assert_equal 'CONSUMER_KEY', d.instance.consumer_key
      assert_equal 'CONSUMER_SECRET', d.instance.consumer_secret
      assert_equal 'ACCESS_TOKEN', d.instance.access_token
      assert_equal 'ACCESS_TOKEN_SECRET', d.instance.access_token_secret
    end

    def test_proxy
      conf = %[
        consumer_key        CONSUMER_KEY
        consumer_secret     CONSUMER_SECRET
        access_token        ACCESS_TOKEN
        access_token_secret ACCESS_TOKEN_SECRET
        <proxy>
          host proxy.example.com
          port 8080
          username proxyuser
          password proxypass
        </proxy>
      ]
      d = create_driver(conf)
      expected = {
        host: "proxy.example.com",
        port: "8080",
        username: "proxyuser",
        password: "proxypass"
      }
      assert_equal(expected, d.instance.proxy.to_h)
    end

    def test_multi_proxy
      conf = %[
        consumer_key        CONSUMER_KEY
        consumer_secret     CONSUMER_SECRET
        access_token        ACCESS_TOKEN
        access_token_secret ACCESS_TOKEN_SECRET
        <proxy>
          host proxy.example.com
          port 8080
          username proxyuser
          password proxypass
        </proxy>
        <proxy>
          host proxy.example.com
          port 8081
          username proxyuser
          password proxypass
        </proxy>
      ]
      assert_raise(Fluent::ConfigError) do
        create_driver(conf)
      end
    end
  end
end
