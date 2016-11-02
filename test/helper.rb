require 'bundler/setup'
require 'test/unit'

$LOAD_PATH.unshift(__dir__, '..', 'lib')
$LOAD_PATH.unshift(__dir__)
require 'fluent/test'
unless ENV.has_key?('VERBOSE')
  nulllogger = Object.new
  nulllogger.instance_eval {|obj|
    def method_missing(method, *args)
      # pass
    end
  }
  $log = nulllogger
end

require 'fluent/plugin/in_twitter'

class Test::Unit::TestCase
end
