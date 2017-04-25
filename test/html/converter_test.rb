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
  <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
  <w:r><w:t xml:space="preserve">Lorem ipsum dolor sit amet</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)
  end

  def test_convert_text_inside_p
    input = '<p>Lorem ipsum dolor sit amet</p>'
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
  <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
  <w:r><w:t xml:space="preserve">Lorem ipsum</w:t></w:r>
</w:p>
<w:p>
  <w:pPr><w:pStyle w:val="Normal" /></w:pPr>
  <w:r><w:t xml:space="preserve">dolor sit amet</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)
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
    assert_equal normalize_wordml(expected_output), @converter.process(input)
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
    assert_equal normalize_wordml(expected_output), @converter.process(input)
  end

  def test_convert_u_tags_inside_p
    input = '<p>Lorem&nbsp;<u>ipsum dolor</u>&nbsp;sit amet</div>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>
  <w:r><w:t xml:space="preserve">Lorem </w:t></w:r>
  <w:r>
    <w:rPr><w:u w:val="single"/></w:rPr>
    <w:t xml:space="preserve">ipsum dolor</w:t>
  </w:r>
  <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), @converter.process(input)
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
    assert_equal normalize_wordml(expected_output), @converter.process(input)
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
    assert_equal normalize_wordml(expected_output), @converter.process(input)
  end

  def test_convert_h1
    input = '<h1>Lorem ipsum dolor</h1>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr><w:pStyle w:val="Heading1" /></w:pPr>
  <w:r><w:t xml:space="preserve">Lorem ipsum dolor</w:t></w:r>
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

  def test_div
    input = '<div>Lorem ipsum dolor sit amet</div>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Paragraph{Normal}: [<Text{}: Lorem ipsum dolor sit amet>]>]>', ast.inspect
  end

  def test_p
    input = '<p>Lorem ipsum dolor sit amet</p>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Paragraph{Paragraph}: [<Text{}: Lorem ipsum dolor sit amet>]>]>', ast.inspect
  end

  def test_b
    input = '<p>Lorem <b>ipsum dolor sit amet</b></p>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Paragraph{Paragraph}: [<Text{}: Lorem >, <Text{bold}: ipsum dolor sit amet>]>]>', ast.inspect
  end

  def test_i
    input = '<p>Lorem <i>ipsum dolor sit amet</i></p>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Paragraph{Paragraph}: [<Text{}: Lorem >, <Text{italic}: ipsum dolor sit amet>]>]>', ast.inspect
  end

  def test_br_in_strong
    input = '<div><strong>Lorem<br />ipsum<br />dolor</strong></div>'
    par = @converter.processed_ast(input).grep(Sablon::HTMLConverter::Paragraph).first
    assert_equal "[<Text{bold}: Lorem>, <Newline>, <Text{bold}: ipsum>, <Newline>, <Text{bold}: dolor>]", par.runs.inspect
  end

  def test_br_in_em
    input = '<div><em>Lorem<br />ipsum<br />dolor</em></div>'
    par = @converter.processed_ast(input).grep(Sablon::HTMLConverter::Paragraph).first
    assert_equal "[<Text{italic}: Lorem>, <Newline>, <Text{italic}: ipsum>, <Newline>, <Text{italic}: dolor>]", par.runs.inspect
  end

  def test_nested_strong_and_em
    input = '<div><strong>Lorem <em>ipsum</em> dolor</strong></div>'
    par = @converter.processed_ast(input).grep(Sablon::HTMLConverter::Paragraph).first
    assert_equal "[<Text{bold}: Lorem >, <Text{bold|italic}: ipsum>, <Text{bold}:  dolor>]", par.runs.inspect
  end

  def test_ignore_last_br_in_div
    input = '<div>Lorem ipsum dolor sit amet<br /></div>'
    par = @converter.processed_ast(input).grep(Sablon::HTMLConverter::Paragraph).first
    assert_equal "[<Text{}: Lorem ipsum dolor sit amet>]", par.runs.inspect
  end

  def test_ignore_br_in_blank_div
    input = '<div><br /></div>'
    par = @converter.processed_ast(input).grep(Sablon::HTMLConverter::Paragraph).first
    assert_equal "[]", par.runs.inspect
  end

  def test_headings
    input = '<h1>First</h1><h2>Second</h2><h3>Third</h3>'
    ast = @converter.processed_ast(input)
    assert_equal "<Root: [<Paragraph{Heading1}: [<Text{}: First>]>, <Paragraph{Heading2}: [<Text{}: Second>]>, <Paragraph{Heading3}: [<Text{}: Third>]>]>", ast.inspect
  end

  def test_h_with_formatting
    input = '<h1><strong>Lorem</strong> ipsum dolor <em>sit <u>amet</u></em></h1>'
    ast = @converter.processed_ast(input)
    assert_equal "<Root: [<Paragraph{Heading1}: [<Text{bold}: Lorem>, <Text{}:  ipsum dolor >, <Text{italic}: sit >, <Text{italic|underline}: amet>]>]>", ast.inspect
  end

  def test_ul
    input = '<ul><li>Lorem</li><li>ipsum</li></ul>'
    ast = @converter.processed_ast(input)
    assert_equal "<Root: [<Paragraph{ListBullet}: [<Text{}: Lorem>]>, <Paragraph{ListBullet}: [<Text{}: ipsum>]>]>", ast.inspect
  end

  def test_ol
    input = '<ol><li>Lorem</li><li>ipsum</li></ol>'
    ast = @converter.processed_ast(input)
    assert_equal "<Root: [<Paragraph{ListNumber}: [<Text{}: Lorem>]>, <Paragraph{ListNumber}: [<Text{}: ipsum>]>]>", ast.inspect
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
