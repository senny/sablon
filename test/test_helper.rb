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
    Sablon::Numbering.instance.reset!
  end
end
