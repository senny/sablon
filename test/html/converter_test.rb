# -*- coding: utf-8 -*-
require "test_helper"

class HTMLConverterTest < Sablon::TestCase
  def setup
    super
    @converter = Sablon::HTMLConverter.new
  end

  def test_convert_text_inside_div
    input = '<div>Lorem ipsum dolor sit amet</div>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
  <w:r><w:t xml:space="preserve">Lorem ipsum dolor sit amet</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)
  end

  def test_convert_text_inside_multiple_divs
    input = '<div>Lorem ipsum</div><div>dolor sit amet</div>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
  <w:r><w:t xml:space="preserve">Lorem ipsum</w:t></w:r>
</w:p>
<w:p>
  <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
  <w:r><w:t xml:space="preserve">dolor sit amet</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)
  end

  def test_convert_newline_inside_div
    input = '<div>Lorem ipsum<br>dolor sit amet</div>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
  <w:r><w:t xml:space="preserve">Lorem ipsum</w:t></w:r>
  <w:r><w:br/></w:r>
  <w:r><w:t xml:space="preserve">dolor sit amet</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)
  end

  def test_convert_strong_tags_inside_div
    input = '<div>Lorem&nbsp;<strong>ipsum dolor</strong>&nbsp;sit amet</div>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
  <w:r><w:t xml:space="preserve">Lorem </w:t></w:r>
  <w:r><w:rPr><w:b /></w:rPr><w:t xml:space="preserve">ipsum dolor</w:t></w:r>
  <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)
  end

  def test_convert_em_tags_inside_div
    input = '<div>Lorem&nbsp;<em>ipsum dolor</em>&nbsp;sit amet</div>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
  <w:r><w:t xml:space="preserve">Lorem </w:t></w:r>
  <w:r><w:rPr><w:i /></w:rPr><w:t xml:space="preserve">ipsum dolor</w:t></w:r>
  <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)
  end

  def test_unorderd_lists
    input = '<ul><li>Lorem</li><li>ipsum</li><li>dolor</li></ul>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr>
    <w:pStyle w:val="ListBullet" />
    <w:numPr>
      <w:ilvl w:val="0" />
      <w:numId w:val="1001" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">Lorem</w:t></w:r>
</w:p>

<w:p>
  <w:pPr>
    <w:pStyle w:val="ListBullet" />
    <w:numPr>
      <w:ilvl w:val="0" />
      <w:numId w:val="1001" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">ipsum</w:t></w:r>
</w:p>

<w:p>
  <w:pPr>
    <w:pStyle w:val="ListBullet" />
    <w:numPr>
      <w:ilvl w:val="0" />
      <w:numId w:val="1001" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">dolor</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)

    assert_equal [Sablon::Numbering::Definition.new(1001, 'ListBullet')], Sablon::Numbering.instance.definitions
  end

  def test_ordered_lists
    input = '<ol><li>Lorem</li><li>ipsum</li><li>dolor</li></ol>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr>
    <w:pStyle w:val="ListNumber" />
    <w:numPr>
      <w:ilvl w:val="0" />
      <w:numId w:val="1001" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">Lorem</w:t></w:r>
</w:p>

<w:p>
  <w:pPr>
    <w:pStyle w:val="ListNumber" />
    <w:numPr>
      <w:ilvl w:val="0" />
      <w:numId w:val="1001" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">ipsum</w:t></w:r>
</w:p>

<w:p>
  <w:pPr>
    <w:pStyle w:val="ListNumber" />
    <w:numPr>
      <w:ilvl w:val="0" />
      <w:numId w:val="1001" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">dolor</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)

    assert_equal [Sablon::Numbering::Definition.new(1001, 'ListNumber')], Sablon::Numbering.instance.definitions
  end

  def test_mixed_lists
    input = '<ol><li>Lorem</li></ol><ul><li>ipsum</li></ul><ol><li>dolor</li></ol>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr>
    <w:pStyle w:val="ListNumber" />
    <w:numPr>
      <w:ilvl w:val="0" />
      <w:numId w:val="1001" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space=\"preserve\">Lorem</w:t></w:r>
</w:p>

<w:p>
  <w:pPr>
    <w:pStyle w:val="ListBullet" />
    <w:numPr>
      <w:ilvl w:val="0" />
      <w:numId w:val="1002" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">ipsum</w:t></w:r>
</w:p>

<w:p>
  <w:pPr>
    <w:pStyle w:val="ListNumber" />
    <w:numPr>
      <w:ilvl w:val="0" />
      <w:numId w:val="1003" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">dolor</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)

    assert_equal [Sablon::Numbering::Definition.new(1001, 'ListNumber'),
                  Sablon::Numbering::Definition.new(1002, 'ListBullet'),
                  Sablon::Numbering::Definition.new(1003, 'ListNumber')], Sablon::Numbering.instance.definitions
  end

  def test_nested_unordered_lists
    input = '<ul><li>Lorem<ul><li>ipsum<ul><li>dolor</li></ul></li></ul></li></ul>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr>
    <w:pStyle w:val="ListBullet" />
    <w:numPr>
      <w:ilvl w:val="0" />
      <w:numId w:val="1001" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">Lorem</w:t></w:r>
</w:p>

<w:p>
  <w:pPr>
    <w:pStyle w:val="ListBullet" />
    <w:numPr>
      <w:ilvl w:val="1" />
      <w:numId w:val="1001" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">ipsum</w:t></w:r>
</w:p>

<w:p>
  <w:pPr>
    <w:pStyle w:val="ListBullet" />
    <w:numPr>
      <w:ilvl w:val="2" />
      <w:numId w:val="1001" />
    </w:numPr>
  </w:pPr>
  <w:r><w:t xml:space="preserve">dolor</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)

    assert_equal [Sablon::Numbering::Definition.new(1001, 'ListBullet')], Sablon::Numbering.instance.definitions
  end

  private
  def normalize_wordml(wordml)
    wordml.gsub(/^\s+/, '').tr("\n", '')
  end
end

class HTMLConverterASTTest < Sablon::TestCase
  def setup
    super
    @converter = Sablon::HTMLConverter.new
  end

  def test_num_id
    ast = @converter.processed_ast('<ol><li>Some</li><li>Lorem</li></ol><ul><li>ipsum</li></ul><ol><li>dolor</li><li>sit</li></ol>')
    assert_equal [1001, 1001, 1002, 1003, 1003], ast.grep(Sablon::HTMLConverter::ListParagraph).map(&:numid)
  end

  def test_nested_lists_have_the_same_numid
    ast = @converter.processed_ast('<ul><li>Lorem<ul><li>ipsum<ul><li>dolor</li></ul></li></ul></li></ul>')
    assert_equal [1001, 1001, 1001], ast.grep(Sablon::HTMLConverter::ListParagraph).map(&:numid)
  end

  def test_keep_nested_list_order
    input = '<ul><li>1<ul><li>1.1<ul><li>1.1.1</li></ul></li><li>1.2</li></ul></li><li>2<ul><li>1.3<ul><li>1.3.1</li></ul></li></ul></li></ul>'
    ast = @converter.processed_ast(input)
    list_p = ast.grep(Sablon::HTMLConverter::ListParagraph)
    assert_equal [1001], list_p.map(&:numid).uniq
    assert_equal [0, 1, 2, 1, 0, 1, 2], list_p.map(&:ilvl)
  end
end
