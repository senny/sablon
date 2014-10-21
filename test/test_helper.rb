require "bundler/setup"

require "minitest/autorun"
require "minitest/mock"
require "xmlsimple"
require "json"
require "pathname"

$: << File.expand_path('../../lib', __FILE__)
require "sablon"

class Sablon::TestCase < MiniTest::Test
end
