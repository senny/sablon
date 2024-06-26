require "bundler/setup"
require 'minitest/assertions'
require "minitest/autorun"
require "minitest/mock"
require "xmlsimple"
require "json"
require "pathname"
require "ostruct"

$: << File.expand_path('../../lib', __FILE__)
require "sablon"
require "sablon/test/assertions"

class Sablon::TestCase < Minitest::Test
  include Sablon::Test::Assertions

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
