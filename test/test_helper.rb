require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

require "bundler/setup"
require 'minitest/assertions'
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

module Minitest
  module Assertions
    def assert_docx_equal(expected_path, actual_path)
      msg = <<-MSG.gsub(/^ +/, '')
        The generated document does not match the sample. Please investigate file(s): %s.

        If the generated document is correct, the sample needs to be updated:
        \t cp #{actual_path} #{expected_path}
      MSG
      #
      expected_contents = parse_docx(expected_path)
      actual_contents = parse_docx(actual_path)
      #
      mismatch = []
      expected_contents.each do |entry_name, exp_cnt|
        next unless exp_cnt != actual_contents[entry_name]
        mismatch << entry_name
        next unless entry_name =~ /.xml$|.rels$/
        puts diff Nokogiri::XML(exp_cnt).to_xml, Nokogiri::XML(actual_contents[entry_name]).to_xml
      end
      #
      msg = format(msg, mismatch.join(', '))
      raise Minitest::Assertion, msg unless mismatch.empty?
    end

    def parse_docx(path)
      contents = {}
      Zip::File.open(path) do |zip_file|
        zip_file.each do |entry|
          next unless entry.file?
          contents[entry.name] = entry.get_input_stream.read
        end
      end
      #
      contents
    end
  end
end

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
