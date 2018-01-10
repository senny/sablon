require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require "bundler/setup"
require "minitest/autorun"
require "minitest/mock"
require "xmlsimple"
require "json"
require "pathname"


if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

$: << File.expand_path('../../lib', __FILE__)
require "sablon"
require "sablon/test"

class Sablon::TestCase < MiniTest::Test
  def teardown
    super
  end

  class MockTemplate
    attr_reader :document

    def initialize
      @path = nil
      @document = MockDomModel.new
    end
  end

  # catch all for method stubs that are needed during testing
  class MockDomModel
    attr_reader :current_rid

    def initialize
      @current_rid = 1234
      @current_rid_start = @current_rid
    end

    def add_relationship(*)
      "rId#{@current_rid += 1}"
    end

    def reset
      @current_rid = @current_rid_start
    end
  end
end
