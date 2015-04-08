# -*- coding: utf-8 -*-
require "test_helper"

module ContentTestSetup
  def setup
    super
    @template_text = '<span>template</span>'
    @document = Nokogiri::XML.fragment(@template_text)
    @node = @document.children.first
  end
end

class ContentStringTest < Sablon::TestCase
  include ContentTestSetup

  def test_single_line_string
    Sablon.string("a normal string").append_to @node

    assert_equal @template_text + "<span>a normal string</span>", @document.to_xml
  end

  def test_numeric_string
    Sablon.string(42).append_to @node

    assert_equal @template_text + "<span>42</span>", @document.to_xml
  end

  def test_string_with_newlines
    Sablon.string("a\nmultiline\n\nstring").append_to @node

    assert_equal(@template_text +
                 "<span>a</span><w:br/><span>multiline</span><w:br/><w:br/><span>string</span>",
                 @document.to_xml)
  end

  def test_blank_string
    Sablon.string("").append_to @node

    assert_equal(@template_text, @document.to_xml)
  end
end

class ContentWordMLTest < Sablon::TestCase
  include ContentTestSetup

  def test_blank_word_ml
    Sablon.word_ml("").append_to @node

    assert_equal(@template_text, @document.to_xml)
  end

  def test_inserts_word_ml_into_the_document
    @word_ml = '<w:r><w:t xml:space="preserve">a </w:t></w:r>'
    Sablon.word_ml(@word_ml).append_to @node

    assert_equal(<<-XML.strip, @document.to_xml)
<span>template</span><w:r>
  <w:t xml:space=\"preserve\">a </w:t>
</w:r>
XML
  end
end
