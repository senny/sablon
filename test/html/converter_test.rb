# -*- coding: utf-8 -*-
require "test_helper"

class HTMLConverterTest < Sablon::TestCase
  def setup
    super
    @env = Sablon::Environment.new(nil)
    @numbering = @env.numbering
    @converter = Sablon::HTMLConverter.new
  end

  def test_convert_text_inside_div
    input = '<div>Lorem ipsum dolor sit amet</div>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem ipsum dolor sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_text_inside_p
    input = '<p>Lorem ipsum dolor sit amet</p>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem ipsum dolor sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_text_inside_multiple_divs
    input = '<div>Lorem ipsum</div><div>dolor sit amet</div>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem ipsum</w:t></w:r>
      </w:p>
      <w:p>
        <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
        <w:r><w:t xml:space="preserve">dolor sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_newline_inside_div
    input = '<div>Lorem ipsum<br>dolor sit amet</div>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem ipsum</w:t></w:r>
        <w:r><w:br/></w:r>
        <w:r><w:t xml:space="preserve">dolor sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_strong_tags_inside_div
    input = '<div>Lorem&nbsp;<strong>ipsum dolor</strong>&nbsp;sit amet</div>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem </w:t></w:r>
        <w:r><w:rPr><w:b /></w:rPr><w:t xml:space="preserve">ipsum dolor</w:t></w:r>
        <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_span_tags_inside_p
    input = '<p>Lorem&nbsp;<span>ipsum dolor</span>&nbsp;sit amet</p>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem </w:t></w:r>
        <w:r><w:t xml:space="preserve">ipsum dolor</w:t></w:r>
        <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_u_tags_inside_p
    input = '<p>Lorem&nbsp;<u>ipsum dolor</u>&nbsp;sit amet</p>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem </w:t></w:r>
        <w:r>
          <w:rPr><w:u w:val="single" /></w:rPr>
          <w:t xml:space="preserve">ipsum dolor</w:t>
        </w:r>
        <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_em_tags_inside_div
    input = '<div>Lorem&nbsp;<em>ipsum dolor</em>&nbsp;sit amet</div>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem </w:t></w:r>
        <w:r><w:rPr><w:i /></w:rPr><w:t xml:space="preserve">ipsum dolor</w:t></w:r>
        <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_s_tags_inside_p
    input = '<p>Lorem&nbsp;<s>ipsum dolor</s>&nbsp;sit amet</p>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem </w:t></w:r>
        <w:r>
          <w:rPr><w:strike w:val="true" /></w:rPr>
          <w:t xml:space="preserve">ipsum dolor</w:t>
        </w:r>
        <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_sub_tags_inside_p
    input = '<p>Lorem&nbsp;<sub>ipsum dolor</sub>&nbsp;sit amet</p>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem </w:t></w:r>
        <w:r>
          <w:rPr><w:vertAlign w:val="subscript" /></w:rPr>
          <w:t xml:space="preserve">ipsum dolor</w:t>
        </w:r>
        <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_sup_tags_inside_p
    input = '<p>Lorem&nbsp;<sup>ipsum dolor</sup>&nbsp;sit amet</p>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem </w:t></w:r>
        <w:r>
          <w:rPr><w:vertAlign w:val="superscript" /></w:rPr>
          <w:t xml:space="preserve">ipsum dolor</w:t>
        </w:r>
        <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_br_tags_inside_strong
    input = '<div><strong><br />Lorem ipsum<br />dolor sit amet</strong></div>'
    expected_output = <<-DOCX
      <w:p>
        <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
        <w:r><w:br/></w:r>
        <w:r>
          <w:rPr><w:b /></w:rPr>
          <w:t xml:space="preserve">Lorem ipsum</w:t></w:r>
          <w:r><w:br/></w:r>
          <w:r>
            <w:rPr><w:b /></w:rPr>
            <w:t xml:space="preserve">dolor sit amet</w:t>
          </w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_convert_h1
    input = '<h1>Lorem ipsum dolor</h1>'
      expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr><w:pStyle w:val="Heading1" /></w:pPr>
        <w:r><w:t xml:space="preserve">Lorem ipsum dolor</w:t></w:r>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
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
    assert_equal normalize_wordml(expected_output), process(input)
    assert_equal [Sablon::Numbering::Definition.new(1001, 'ListBullet')], @numbering.definitions
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
    assert_equal normalize_wordml(expected_output), process(input)
    assert_equal [Sablon::Numbering::Definition.new(1001, 'ListNumber')], @numbering.definitions
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
    assert_equal normalize_wordml(expected_output), process(input)
    assert_equal [Sablon::Numbering::Definition.new(1001, 'ListNumber'),
                  Sablon::Numbering::Definition.new(1002, 'ListBullet'),
                  Sablon::Numbering::Definition.new(1003, 'ListNumber')], @numbering.definitions
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
    assert_equal normalize_wordml(expected_output), process(input)
    assert_equal [Sablon::Numbering::Definition.new(1001, 'ListBullet')], @numbering.definitions
  end

  def test_unknown_tag
    e = assert_raises ArgumentError do
      process('<badtag/>')
    end
    assert_match(/Don't know how to handle HTML tag:/, e.message)
  end

  private

  def process(input)
    @converter.process(input, @env)
  end

  def normalize_wordml(wordml)
    wordml.gsub(/^\s+/, '').tr("\n", '')
  end
end
