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
end
