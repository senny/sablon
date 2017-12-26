require "bundler/setup"

require "minitest/autorun"
require "minitest/mock"
require "xmlsimple"
require "json"
require "pathname"

$: << File.expand_path('../../lib', __FILE__)
require "sablon"
require "sablon/test"

class Sablon::TestCase < MiniTest::Test
  def teardown
    super
  end

  class UIDTestGenerator
    def initialize
      @current_id = 1234
      @current_id_start = @current_id
    end

    def new_uid
      @current_id += 1
      @current_id.to_s
    end

    def reset
      @current_id = @current_id_start
    end
  end
end
