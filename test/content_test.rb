# -*- coding: utf-8 -*-
require "test_helper"

module XmlContentTestSetup
  def setup
    super
    @template_text = '<w:p><w:r><w:t>template</w:t></w:r></w:p><w:p>AFTER</w:p>'
    #
    @document = Nokogiri::XML(doc_wrapper(@template_text))
    @paragraph = @document.xpath('//w:p').first
    @node = @paragraph.xpath('.//w:r').first.at_xpath('./w:t')
    @env = Sablon::Environment.new(nil)
  end

  private

  def doc_wrapper(content)
    doc = <<-XML.gsub(/^\s+|\n/, '')
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:body>
          %<content>s
        </w:body>
      </w:document>
    XML
    format(doc, content: content)
  end

  def assert_xml_equal(expected, document)
    expected = Nokogiri::XML(doc_wrapper(expected)).to_xml(indent: 0, save_with: 0)
    assert_equal expected, document.to_xml(indent: 0, save_with: 0)
  end
end

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

class ContentStringTest < Sablon::TestCase
  include XmlContentTestSetup

  def test_single_line_string
    Sablon.content(:string, 'a normal string').append_to @paragraph, @node, @env

    output = <<-XML.strip
      <w:p><w:r><w:t>template</w:t><w:t>a normal string</w:t></w:r></w:p><w:p>AFTER</w:p>
    XML
    assert_xml_equal output, @document
  end

  def test_numeric_string
    Sablon.content(:string, 42).append_to @paragraph, @node, @env

    output = <<-XML.strip
      <w:p><w:r><w:t>template</w:t><w:t>42</w:t></w:r></w:p><w:p>AFTER</w:p>
    XML
    assert_xml_equal output, @document
  end

  def test_string_with_newlines
    Sablon.content(:string, "a\nmultiline\n\nstring").append_to @paragraph, @node, @env

    output = <<-XML.gsub(/\s/, '')
      <w:p>
        <w:r>
          <w:t>template</w:t>
          <w:t>a</w:t>
          <w:br/>
          <w:t>multiline</w:t>
          <w:br/>
          <w:br/>
          <w:t>string</w:t>
        </w:r>
      </w:p><w:p>AFTER</w:p>
    XML

    assert_xml_equal output, @document
  end

  def test_blank_string
    Sablon.content(:string, '').append_to @paragraph, @node, @env

    assert_xml_equal @template_text, @document
  end
end

class ContentWordMLTest < Sablon::TestCase
  include XmlContentTestSetup

  def test_blank_word_ml
    # blank strings in word_ml are an odd corner case, they get treated
    # as inline so the paragraph is retained but the display node is still
    # removed with nothing being inserted in it's place. Nokogiri automatically
    # collapsed the empty <w:p></w:P> tag into a <w:/p> form.
    Sablon.content(:word_ml, '').append_to @paragraph, @node, @env
    assert_xml_equal "<w:p/><w:p>AFTER</w:p>", @document
  end

  def test_plain_text_word_ml
    # text isn't a valid child element of a w:p tag, so the whole paragraph
    # gets replaced.
    Sablon.content(:word_ml, "test").append_to @paragraph, @node, @env
    assert_xml_equal "test<w:p>AFTER</w:p>", @document
  end

  def test_inserts_paragraph_word_ml_into_the_document
    @word_ml = '<w:p><w:r><w:t xml:space="preserve">a </w:t></w:r></w:p>'
    Sablon.content(:word_ml, @word_ml).append_to @paragraph, @node, @env

    output = <<-XML.gsub(/^\s+|\n/, '')
      <w:p>
        <w:r><w:t xml:space=\"preserve\">a </w:t></w:r>
      </w:p>
      <w:p>AFTER</w:p>
    XML

    assert_xml_equal output, @document
  end

  def test_inserts_inline_word_ml_into_the_document
    @word_ml = '<w:r><w:t xml:space="preserve">inline text </w:t></w:r>'
    Sablon.content(:word_ml, @word_ml).append_to @paragraph, @node, @env

    output = <<-XML.gsub(/^\s+|\n/, '')
      <w:p>
        <w:r><w:t xml:space="preserve">inline text </w:t></w:r>
      </w:p>
      <w:p>AFTER</w:p>
    XML

    assert_xml_equal output, @document
  end

  def test_inserting_word_ml_multiple_times_into_same_paragraph
    @word_ml = '<w:r><w:t xml:space="preserve">inline text </w:t></w:r>'
    Sablon.content(:word_ml, @word_ml).append_to @paragraph, @node, @env
    @word_ml = '<w:r><w:t xml:space="preserve">inline text2 </w:t></w:r>'
    Sablon.content(:word_ml, @word_ml).append_to @paragraph, @node, @env
    @word_ml = '<w:r><w:t xml:space="preserve">inline text3 </w:t></w:r>'
    Sablon.content(:word_ml, @word_ml).append_to @paragraph, @node, @env

    # Only a single insertion should work because the node that we insert
    # the content afer contains a merge field that needs removed. That means
    # in the next two appends the @node variable doesn't exist on the document
    # tree
    output = <<-XML.gsub(/^\s+|\n/, '')
      <w:p>
        <w:r><w:t xml:space="preserve">inline text </w:t></w:r>
      </w:p>
      <w:p>AFTER</w:p>
    XML

    assert_xml_equal output, @document
  end

  def test_inserting_multiple_runs_into_same_paragraph
    @word_ml = <<-XML.gsub(/^\s+|\n/, '')
      <w:r><w:t xml:space="preserve">inline text </w:t></w:r>
      <w:r><w:t xml:space="preserve">inline text2 </w:t></w:r>
      <w:r><w:t xml:space="preserve">inline text3 </w:t></w:r>
    XML
    Sablon.content(:word_ml, @word_ml).append_to @paragraph, @node, @env

    # This works because all three runs are added as a single insertion
    # event
    output = <<-XML.gsub(/^\s+|\n/, '')
      <w:p>
        <w:r><w:t xml:space="preserve">inline text </w:t></w:r>
        <w:r><w:t xml:space="preserve">inline text2 </w:t></w:r>
        <w:r><w:t xml:space="preserve">inline text3 </w:t></w:r>
      </w:p>
      <w:p>AFTER</w:p>
    XML

    assert_xml_equal output, @document
  end
end
