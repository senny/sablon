# -*- coding: utf-8 -*-
require "test_helper"

module ContentTestSetup
  def setup
    super
    @template_text = '<w:p><span>template</span></w:p><w:p>AFTER</w:p>'
    @document = Nokogiri::XML.fragment(@template_text)
    @paragraph = @document.children.first
    @node = @document.css("span").first
  end

  private
  def assert_xml_equal(expected, document)
    assert_equal expected, document.to_xml(indent: 0, save_with: 0)
  end
end

class ContentStringTest < Sablon::TestCase
  include ContentTestSetup

  def test_single_line_string
    Sablon.string("a normal string").append_to @paragraph, @node

    output = <<-XML.strip
<w:p><span>template</span><span>a normal string</span></w:p><w:p>AFTER</w:p>
    XML
    assert_xml_equal output, @document
  end

  def test_numeric_string
    Sablon.string(42).append_to @paragraph, @node

    output = <<-XML.strip
<w:p><span>template</span><span>42</span></w:p><w:p>AFTER</w:p>
    XML
    assert_xml_equal output, @document
  end

  def test_string_with_newlines
    Sablon.string("a\nmultiline\n\nstring").append_to @paragraph, @node

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
    Sablon.string("").append_to @paragraph, @node

    assert_xml_equal @template_text, @document
  end
end

class ContentWordMLTest < Sablon::TestCase
  include ContentTestSetup

  def test_blank_word_ml
    Sablon.word_ml("").append_to @paragraph, @node

    assert_xml_equal "<w:p>AFTER</w:p>", @document
  end

  def test_inserts_word_ml_into_the_document
    @word_ml = '<w:p><w:r><w:t xml:space="preserve">a </w:t></w:r></w:p>'
    Sablon.word_ml(@word_ml).append_to @paragraph, @node

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
