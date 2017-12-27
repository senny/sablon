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

  def test_convert_hyperlink_inside_div
    uid_generator = UIDTestGenerator.new
    SecureRandom.stub(:uuid, uid_generator.method(:new_uid)) do |secure_random_instance|

      input = '<div>Lorem ipsum dolor sit amet; search it at <a href="http://www.google.com">google</a></div>'
      expected_output = <<-DOCX.strip
<w:p>
  <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
  <w:r><w:t xml:space="preserve">Lorem ipsum dolor sit amet; search it at </w:t></w:r>
  <w:hyperlink r:id=\"rId#{secure_random_instance.uuid}\">
    <w:r>
      <w:rPr>
        <w:rStyle w:val=\"Hyperlink\" />
      </w:rPr>
      <w:t xml:space=\"preserve\">google</w:t>
    </w:r>
  </w:hyperlink>
</w:p>
      DOCX
      uid_generator.reset
      assert_equal normalize_wordml(expected_output), process(input)
    end
  end

  def test_convert_hyperlink_inside_p
    uid_generator = UIDTestGenerator.new
    SecureRandom.stub(:uuid, uid_generator.method(:new_uid)) do |secure_random_instance|
      input = '<p>Lorem ipsum dolor sit amet; search it at <a href="http://www.google.com">google</a></p>'
      expected_output = <<-DOCX.strip
  <w:p>
    <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
    <w:r><w:t xml:space="preserve">Lorem ipsum dolor sit amet; search it at </w:t></w:r>
    <w:hyperlink r:id=\"rId#{secure_random_instance.uuid}\">
        <w:r>
          <w:rPr>
            <w:rStyle w:val=\"Hyperlink\" />
          </w:rPr>
          <w:t xml:space=\"preserve\">google</w:t>
        </w:r>
    </w:hyperlink>
  </w:p>
      DOCX
      uid_generator.reset
      assert_equal normalize_wordml(expected_output), process(input)
    end
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

  def test_anchor_tag
    uid_generator = UIDTestGenerator.new
    input = '<p><a href="www.github.com">GitHub</a></p>'
    SecureRandom.stub(:uuid, uid_generator.method(:new_uid)) do |secure_random_instance|
      expected_output = <<-DOCX.strip
        <w:p>
          <w:pPr>
          <w:pStyle w:val="Paragraph" />
          </w:pPr>
          <w:hyperlink r:id="rId#{secure_random_instance.uuid}">
            <w:r>
            <w:rPr>
              <w:rStyle w:val="Hyperlink" />
            </w:rPr>
            <w:t xml:space="preserve">GitHub</w:t>
            </w:r>
          </w:hyperlink>
        </w:p>
      DOCX
      uid_generator.reset
      assert_equal normalize_wordml(expected_output), process(input)
    end
  end

  def test_table_tag
    input = '<table></table>'
    expected_output = '<w:tbl></w:tbl>'
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_with_table_row
    # This would generate an invalid docu
    input = '<table><tr></tr><tr></tr></table>'
    expected_output = '<w:tbl><w:tr></w:tr><w:tr></w:tr></w:tbl>'
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_with_table_row_and_table_cell
    # This would generate an invalid docu
    input = '<table><tr><td>Content</td></tr></table>'
    expected_output = <<-DOCX.strip
      <w:tbl>
        <w:tr>
          <w:tc>
            <w:p>
              <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
              <w:r><w:t xml:space="preserve">Content</w:t></w:r>
            </w:p>
          </w:tc>
        </w:tr>
      </w:tbl>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_with_table_row_and_table_header_cell
    # This would generate an invalid docu
    input = '<table><tr><th>Content</th></tr></table>'
    expected_output = <<-DOCX.strip
      <w:tbl>
        <w:tr>
          <w:tc>
            <w:p>
              <w:pPr>
                <w:jc w:val="center" />
                <w:pStyle w:val="Paragraph" />
              </w:pPr>
              <w:r>
                <w:rPr><w:b /></w:rPr>
                <w:t xml:space="preserve">Content</w:t>
              </w:r>
            </w:p>
          </w:tc>
        </w:tr>
      </w:tbl>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_with_table_row_table_header_cell_and_caption
    # This would generate an invalid docu
    input = '<table><caption>Table Title</caption><tr><th>Content</th></tr></table>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr>
          <w:pStyle w:val="Caption" />
        </w:pPr>
        <w:r>
          <w:t xml:space="preserve">Table Title</w:t>
        </w:r>
      </w:p>
      <w:tbl>
        <w:tr>
          <w:tc>
            <w:p>
              <w:pPr>
                <w:jc w:val="center" />
                <w:pStyle w:val="Paragraph" />
              </w:pPr>
              <w:r>
                <w:rPr><w:b /></w:rPr>
                <w:t xml:space="preserve">Content</w:t>
              </w:r>
            </w:p>
          </w:tc>
        </w:tr>
      </w:tbl>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_with_table_row_table_header_cell_thead_tbody_and_tfoot
    # This would generate an invalid docu
    input = <<-HTML.strip
      <table>
        <thead><tr><th>Head</th></tr></thead>
        <tbody><tr><td>Body</td></tr></tbody>
        <tfoot><tr><td>Foot</td></tr></tfoot>
      </table>
    HTML
    expected_output = <<-DOCX.strip
      <w:tbl>
        <w:tr>
          <w:trPr>
            <w:tblHeader />
          </w:trPr>
          <w:tc>
            <w:p>
              <w:pPr>
                <w:jc w:val="center" />
                <w:pStyle w:val="Paragraph" />
              </w:pPr>
              <w:r>
                <w:rPr><w:b /></w:rPr>
                <w:t xml:space="preserve">Head</w:t>
              </w:r>
            </w:p>
          </w:tc>
        </w:tr>
        <w:tr>
          <w:tc>
            <w:p>
              <w:pPr>
                <w:pStyle w:val="Paragraph" />
              </w:pPr>
              <w:r>
                <w:t xml:space="preserve">Body</w:t>
              </w:r>
            </w:p>
          </w:tc>
        </w:tr>
        <w:tr>
          <w:tc>
            <w:p>
              <w:pPr>
                <w:pStyle w:val="Paragraph" />
              </w:pPr>
              <w:r>
                <w:t xml:space="preserve">Foot</w:t>
              </w:r>
            </w:p>
          </w:tc>
        </w:tr>
      </w:tbl>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)
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
