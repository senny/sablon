# -*- coding: utf-8 -*-
require "test_helper"

class RedcarpetRenderWordMLTest < Sablon::TestCase
  def setup
    @redcarpet = ::Redcarpet::Markdown.new(Sablon::Redcarpet::Render::WordML)
  end

  def test_normal_text
    word_ml = <<-XML.gsub("\n", "")
<w:p>
<w:r><w:t xml:space=\"preserve\">normal</w:t></w:r>
</w:p>
XML
    assert_equal word_ml, @redcarpet.render("normal")
  end

  def test_empty_string
    assert_equal "", @redcarpet.render("")
  end

  def test_blank_string_with_newline
    assert_equal "", @redcarpet.render("\n")
  end

  def test_newline_in_a_paragraph_starts_new_paragraph
    word_ml = <<-XML.gsub("\n", "")
<w:p>
<w:r><w:t xml:space=\"preserve\">some  </w:t></w:r>
</w:p>
<w:p>
<w:r><w:t xml:space=\"preserve\">text</w:t></w:r>
</w:p>
XML
    assert_equal word_ml, @redcarpet.render("some  \ntext")
  end

  def test_bold_text
    word_ml = <<-XML.gsub("\n", "")
<w:p>
<w:r>
<w:rPr><w:b /></w:rPr>
<w:t xml:space="preserve">bold</w:t>
</w:r>
</w:p>
XML
    assert_equal word_ml, @redcarpet.render("**bold**")
  end

  def test_italic_text
    word_ml = <<-XML.gsub("\n", "")
<w:p>
<w:r>
<w:rPr><w:i /></w:rPr>
<w:t xml:space="preserve">italic</w:t>
</w:r>
</w:p>
XML
    assert_equal word_ml, @redcarpet.render("*italic*")
  end

  def test_single_line_mixed_text
    word_ml = <<-XML.gsub("\n", "")
<w:p>

<w:r><w:t xml:space="preserve">some </w:t></w:r>

<w:r>
<w:rPr><w:i /></w:rPr>
<w:t xml:space="preserve">random</w:t>
</w:r>

<w:r><w:t xml:space="preserve"> </w:t></w:r>
<w:r>
<w:rPr><w:b /></w:rPr>
<w:t xml:space="preserve">text</w:t>
</w:r>
</w:p>
XML
    assert_equal word_ml, @redcarpet.render("some *random* **text**")
  end

  def test_unordered_lists
    word_ml = <<-XML.gsub("\n", "")
<w:p>
<w:pPr><w:pStyle w:val="ListBullet" /></w:pPr>
<w:r><w:t xml:space="preserve">first</w:t></w:r>
</w:p>

<w:p>
<w:pPr><w:pStyle w:val="ListBullet" /></w:pPr>
<w:r><w:t xml:space="preserve">second</w:t></w:r>
</w:p>

<w:p>
<w:pPr><w:pStyle w:val="ListBullet" /></w:pPr>
<w:r><w:t xml:space="preserve">third</w:t></w:r>
</w:p>
XML

    assert_equal word_ml, @redcarpet.render("- first\n- second\n- third")
  end
end
