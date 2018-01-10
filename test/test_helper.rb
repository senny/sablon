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
      #
      # Parse document archives and generate a diff
      xml_diffs = diff_docx_files(expected_path, actual_path)
      #
      # build error message
      msg = 'The generated document does not match the sample. Please investigate file(s): '
      msg += xml_diffs.keys.sort.join(', ')
      xml_diffs.each do |name, diff_text|
        msg += "\n#{'-' * 72}\nFile: #{name}\n#{diff_text}\n"
      end
      msg += '-' * 72 + "\n"
      msg += "If the generated document is correct, the sample needs to be updated:\n"
      msg += "\t cp #{actual_path} #{expected_path}"
      #
      raise Minitest::Assertion, msg unless xml_diffs.empty?
    end

    # Returns a hash of all XML files that differ in the docx file. This
    # only checks files that have the extension ".xml" or ".rels".
    def diff_docx_files(expected_path, actual_path)
      expected = parse_docx(expected_path)
      actual = parse_docx(actual_path)
      xml_diffs = {}
      #
      expected.each do |entry_name, expect|
        next unless entry_name =~ /.xml$|.rels$/
        next unless expect != actual[entry_name]
        #
        xml_diffs[entry_name] = diff(expect, actual[entry_name])
      end
      #
      xml_diffs
    end

    def parse_docx(path)
      contents = {}
      #
      # step over all entries adding them to the hash to diff against
      Zip::File.open(path).each do |entry|
        next unless entry.file?
        content = entry.get_input_stream.read
        # normalize xml content
        if entry.name =~ /.xml$|.rels$/
          content = Nokogiri::XML(content).to_xml(indent: 2)
        end
        contents[entry.name] = content
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
      @current_numid = 0
      @current_numid_start = @current_numid
    end

    def add_relationship(*)
      "rId#{@current_rid += 1}"
    end

    def add_list_definition(style)
      @current_numid += 1
      Struct.new(:style, :numid).new(style, @current_numid)
    end

    def reset
      @current_rid = @current_rid_start
      @current_numid = @current_numid_start
    end
  end
end
