require "bundler/setup"
require 'minitest/assertions'
require "minitest/autorun"
require "minitest/mock"
require "xmlsimple"
require "json"
require "pathname"

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
    attr_accessor :current_entry
    attr_reader :current_rid, :zip_contents

    # Simple class to reload mock document components from fixtures on demand
    class ZipContents
      def [](entry_name)
        load_mock_content(entry_name)
      end

      private

      # Loads and parses individual files to build the mock document
      def load_mock_content(entry_name)
        root = Pathname.new(File.dirname(__FILE__))
        xml_path = root.join('fixtures', 'xml', 'mock_document', entry_name)
        Nokogiri::XML(File.read(xml_path))
      end
    end

    def initialize
      @current_entry = nil
      @current_rid = 1234
      @current_rid_start = @current_rid
      @current_numid = 0
      @current_numid_start = @current_numid
      @zip_contents = ZipContents.new
    end

    # Returns the corresponding DOM handled file
    def [](entry_name)
      Sablon::DOM.wrap_with_handler(entry_name, @zip_contents[entry_name])
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

    alias add_media add_relationship
  end
end
