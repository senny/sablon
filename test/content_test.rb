# -*- coding: utf-8 -*-
require "test_helper"

class ContentTest < Sablon::TestCase
  def test_can_build_content_objects
    content = Sablon.content(:string, "a string")
    assert_instance_of Sablon::Content::String, content
  end

  def test_raises_error_when_building_non_registered_type
    e = assert_raises ArgumentError do
      Sablon.content :nope, "this should not work"
    end
    assert_equal "Could not find Sablon content type with id 'nope'", e.message
  end

  def test_wraps_string_objects
    content = Sablon::Content.wrap(67)
    assert_instance_of Sablon::Content::String, content
    assert_equal "67", content.string
  end

  def test_raises_an_error_if_no_wrapping_type_was_found
    Sablon::Content.remove Sablon::Content::String

    e = assert_raises ArgumentError do
      Sablon::Content.wrap(43)
    end
    assert_equal "Could not find Sablon content type to wrap 43", e.message
  ensure
    Sablon::Content.register Sablon::Content::String
  end

  def test_does_not_wrap_content_objects
    original_content = Sablon.content(:word_ml, "<w:p></w:p>")
    content = Sablon::Content.wrap(original_content)
    assert_instance_of Sablon::Content::WordML, content
    assert_equal original_content.object_id, content.object_id
  end
end

class CustomContentTest < Sablon::TestCase
  class MyContent < Struct.new(:numeric)
    include Sablon::Content
    def self.id; :custom end
    def self.wraps?(value); Numeric === value end

    def append_to(paragraph, display_node)
    end
  end

  def setup
    Sablon::Content.register MyContent
  end

  def teardown
    Sablon::Content.remove MyContent
  end

  def test_can_build_custom_content
    content = Sablon.content(:custom, 42)
    assert_instance_of MyContent, content
  end

  def test_wraps_custom_content
    content = Sablon::Content.wrap(31)
    assert_instance_of MyContent, content
    assert_equal 31, content.numeric
  end
end

module ContentTestSetup
  def setup
    super
    @template_text = '<w:p><span>template</span></w:p><w:p>AFTER</w:p>'
    @document = Nokogiri::XML.fragment(@template_text)
    @paragraph = @document.children.first
    @node = @document.css("span").first
    @env = Sablon::Environment.new(nil)
  end

  private
  def assert_xml_equal(expected, document)
    assert_equal expected, document.to_xml(indent: 0, save_with: 0)
  end
end

class ContentStringTest < Sablon::TestCase
  include ContentTestSetup

  def test_single_line_string
    Sablon.content(:string, "a normal string").append_to @paragraph, @node, @env

    output = <<-XML.strip
<w:p><span>template</span><span>a normal string</span></w:p><w:p>AFTER</w:p>
    XML
    assert_xml_equal output, @document
  end

  def test_numeric_string
    Sablon.content(:string, 42).append_to @paragraph, @node, @env

    output = <<-XML.strip
<w:p><span>template</span><span>42</span></w:p><w:p>AFTER</w:p>
    XML
    assert_xml_equal output, @document
  end

  def test_string_with_newlines
    Sablon.content(:string, "a\nmultiline\n\nstring").append_to @paragraph, @node, @env

    output = <<-XML.strip.gsub("\n", "")
<w:p>
<span>template</span>
<span>a</span>
<w:br/>
<span>multiline</span>
<w:br/>
<w:br/>
<span>string</span>
</w:p>
<w:p>AFTER</w:p>
    XML

    assert_xml_equal output, @document
  end

  def test_blank_string
    Sablon.content(:string, "").append_to @paragraph, @node, @env

    assert_xml_equal @template_text, @document
  end
end

class ContentWordMLTest < Sablon::TestCase
  include ContentTestSetup

  def test_blank_word_ml
    Sablon.content(:word_ml, "").append_to @paragraph, @node, @env

    assert_xml_equal "<w:p>AFTER</w:p>", @document
  end

  def test_inserts_word_ml_into_the_document
    @word_ml = '<w:p><w:r><w:t xml:space="preserve">a </w:t></w:r></w:p>'
    Sablon.content(:word_ml, @word_ml).append_to @paragraph, @node, @env

    output = <<-XML.strip.gsub("\n", "")
<w:p>
<w:r><w:t xml:space=\"preserve\">a </w:t></w:r>
</w:p>
<w:p>AFTER</w:p>
    XML

    assert_xml_equal output, @document
  end

  def test_inserting_word_ml_multiple_times_into_same_paragraph
    skip "Content::WordML currently removes the paragraph..."
  end
end
