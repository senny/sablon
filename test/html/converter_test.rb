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
  <w:r><w:t xml:space="preserve"> sit amet</w:t></w:r></w:p>
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

  private

  def process(input)
    @converter.process(input, @env)
  end

  def normalize_wordml(wordml)
    wordml.gsub(/^\s+/, '').tr("\n", '')
  end
end

class HTMLConverterStyleTest < Sablon::TestCase
  def setup
    super
    @env = Sablon::Environment.new(nil)
    @converter = Sablon::HTMLConverter.new
  end

  # testing direct CSS style -> WordML conversion for paragraphs

  def test_paragraph_with_background_color
    input = '<p style="background-color: #123456"></p>'
    expected_output = para_with_ppr('<w:shd w:val="clear" w:fill="123456" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_paragraph_with_text_align
    input = '<p style="text-align: both"></p>'
    expected_output = para_with_ppr('<w:jc w:val="both" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_paragraph_with_unsupported_property
    input = '<p style="unsupported: true"></p>'
    expected_output = para_with_ppr('')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_run_with_background_color
    input = '<p><span style="background-color: #123456">test</span></p>'
    expected_output = run_with_rpr('<w:shd w:val="clear" w:fill="123456" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_run_with_color
    input = '<p><span style="color: #123456">test</span></p>'
    expected_output = run_with_rpr('<w:color w:val="123456" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_run_with_font_size
    input = '<p><span style="font-size: 20">test</span></p>'
    expected_output = run_with_rpr('<w:sz w:val="40" />')
    assert_equal normalize_wordml(expected_output), process(input)

    # test that non-numeric are ignored
    input = '<p><span style="font-size: 20pts">test</span></p>'
    assert_equal normalize_wordml(expected_output), process(input)

    # test that floats round up
    input = '<p><span style="font-size: 19.1pts">test</span></p>'
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_run_with_font_style
    input = '<p><span style="font-style: bold">test</span></p>'
    expected_output = run_with_rpr('<w:b />')
    assert_equal normalize_wordml(expected_output), process(input)

    # test that non-numeric are ignored
    input = '<p><span style="font-style: italic">test</span></p>'
    expected_output = run_with_rpr('<w:i />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_run_with_font_wieght
    input = '<p><span style="font-weight: bold">test</span></p>'
    expected_output = run_with_rpr('<w:b />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_run_with_text_decoration
    # testing underline configurations
    input = '<p><span style="text-decoration: underline">test</span></p>'
    expected_output = run_with_rpr('<w:u w:val="single" />')
    assert_equal normalize_wordml(expected_output), process(input)

    input = '<p><span style="text-decoration: underline dash">test</span></p>'
    expected_output = run_with_rpr('<w:u w:val="dash" w:color="auto" />')
    assert_equal normalize_wordml(expected_output), process(input)

    input = '<p><span style="text-decoration: underline dash #123456">test</span></p>'
    expected_output = run_with_rpr('<w:u w:val="dash" w:color="123456" />')
    assert_equal normalize_wordml(expected_output), process(input)

    # testing line-through
    input = '<p><span style="text-decoration: line-through">test</span></p>'
    expected_output = run_with_rpr('<w:strike w:val="true" />')
    assert_equal normalize_wordml(expected_output), process(input)

    # testing that unsupported values are passed through as a toggle
    input = '<p><span style="text-decoration: strike">test</span></p>'
    expected_output = run_with_rpr('<w:strike w:val="true" />')
    assert_equal normalize_wordml(expected_output), process(input)

    input = '<p><span style="text-decoration: emboss">test</span></p>'
    expected_output = run_with_rpr('<w:emboss w:val="true" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_run_with_vertical_align
    input = '<p><span style="vertical-align: subscript">test</span></p>'
    expected_output = run_with_rpr('<w:vertAlign w:val="subscript" />')
    assert_equal normalize_wordml(expected_output), process(input)

    input = '<p><span style="vertical-align: superscript">test</span></p>'
    expected_output = run_with_rpr('<w:vertAlign w:val="superscript" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_run_with_unsupported_property
    input = '<p><span style="unsupported: true">test</span></p>'
    expected_output = '<w:p><w:pPr><w:pStyle w:val="Paragraph" /></w:pPr><w:r><w:t xml:space="preserve">test</w:t></w:r></w:p>'
    assert_equal normalize_wordml(expected_output), process(input)
  end

  # tests with nested runs and styles

  def test_paragraph_props_passed_to_runs
    input = '<p style="color: #123456"><b>Lorem</b><span>ipsum</span></p>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr>
    <w:pStyle w:val="Paragraph" />
  </w:pPr>
  <w:r>
    <w:rPr>
       <w:color w:val="123456" />
      <w:b />
    </w:rPr>
    <w:t xml:space="preserve">Lorem</w:t>
  </w:r>
  <w:r>
    <w:rPr>
      <w:color w:val="123456" />
    </w:rPr>
    <w:t xml:space="preserve">ipsum</w:t>
  </w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_run_prop_override_paragraph_prop
    input = '<p style="text-align: center; color: #FF0000">Lorem<span style="color: blue;">ipsum</span></p>'
    expected_output = <<-DOCX.strip
<w:p>
  <w:pPr>
    <w:jc w:val="center" />
    <w:pStyle w:val="Paragraph" />
  </w:pPr>
  <w:r>
    <w:rPr>
      <w:color w:val="FF0000" />
    </w:rPr>
    <w:t xml:space="preserve">Lorem</w:t>
  </w:r>
  <w:r>
    <w:rPr>
      <w:color w:val="blue" />
    </w:rPr>
    <w:t xml:space="preserve">ipsum</w:t>
  </w:r>
</w:p>
DOCX
    assert_equal normalize_wordml(expected_output), process(input)
  end

  private

  def process(input)
    @converter.process(input, @env)
  end

  def para_with_ppr(ppr_str)
    para_str = '<w:p><w:pPr>%s<w:pStyle w:val="Paragraph" /></w:pPr></w:p>'
    format(para_str, ppr_str)
  end

  def run_with_rpr(rpr_str)
    para_str = <<-DOCX.strip
    <w:p>
      <w:pPr>
        <w:pStyle w:val="Paragraph" />
      </w:pPr>
      <w:r>
        <w:rPr>
          %s
        </w:rPr>
        <w:t xml:space="preserve">test</w:t>
      </w:r>
    </w:p>
DOCX
    format(para_str, rpr_str)
  end

  def normalize_wordml(wordml)
    wordml.gsub(/^\s+/, '').tr("\n", '')
  end
end

class HTMLConverterASTTest < Sablon::TestCase
  def setup
    super
    @converter = Sablon::HTMLConverter.new
    @converter.instance_variable_set(:@numbering, Sablon::Environment.new(nil).numbering)
  end

  def test_div
    input = '<div>Lorem ipsum dolor sit amet</div>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Paragraph{Normal}: [<Run{}: Lorem ipsum dolor sit amet>]>]>', ast.inspect
  end

  def test_p
    input = '<p>Lorem ipsum dolor sit amet</p>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Paragraph{Paragraph}: [<Run{}: Lorem ipsum dolor sit amet>]>]>', ast.inspect
  end

  def test_b
    input = '<p>Lorem <b>ipsum dolor sit amet</b></p>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Paragraph{Paragraph}: [<Run{}: Lorem >, <Run{b}: ipsum dolor sit amet>]>]>', ast.inspect
  end

  def test_i
    input = '<p>Lorem <i>ipsum dolor sit amet</i></p>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Paragraph{Paragraph}: [<Run{}: Lorem >, <Run{i}: ipsum dolor sit amet>]>]>', ast.inspect
  end

  def test_br_in_strong
    input = '<div><strong>Lorem<br />ipsum<br />dolor</strong></div>'
    par = @converter.processed_ast(input).grep(Sablon::HTMLConverter::Paragraph).first
    assert_equal "[<Run{b}: Lorem>, <Newline>, <Run{b}: ipsum>, <Newline>, <Run{b}: dolor>]", par.runs.inspect
  end

  def test_br_in_em
    input = '<div><em>Lorem<br />ipsum<br />dolor</em></div>'
    par = @converter.processed_ast(input).grep(Sablon::HTMLConverter::Paragraph).first
    assert_equal "[<Run{i}: Lorem>, <Newline>, <Run{i}: ipsum>, <Newline>, <Run{i}: dolor>]", par.runs.inspect
  end

  def test_nested_strong_and_em
    input = '<div><strong>Lorem <em>ipsum</em> dolor</strong></div>'
    par = @converter.processed_ast(input).grep(Sablon::HTMLConverter::Paragraph).first
    assert_equal "[<Run{b}: Lorem >, <Run{b;i}: ipsum>, <Run{b}:  dolor>]", par.runs.inspect
  end

  def test_ignore_last_br_in_div
    input = '<div>Lorem ipsum dolor sit amet<br /></div>'
    par = @converter.processed_ast(input).grep(Sablon::HTMLConverter::Paragraph).first
    assert_equal "[<Run{}: Lorem ipsum dolor sit amet>]", par.runs.inspect
  end

  def test_ignore_br_in_blank_div
    input = '<div><br /></div>'
    par = @converter.processed_ast(input).grep(Sablon::HTMLConverter::Paragraph).first
    assert_equal "[]", par.runs.inspect
  end

  def test_headings
    input = '<h1>First</h1><h2>Second</h2><h3>Third</h3>'
    ast = @converter.processed_ast(input)
    assert_equal "<Root: [<Paragraph{Heading1}: [<Run{}: First>]>, <Paragraph{Heading2}: [<Run{}: Second>]>, <Paragraph{Heading3}: [<Run{}: Third>]>]>", ast.inspect
  end

  def test_h_with_formatting
    input = '<h1><strong>Lorem</strong> ipsum dolor <em>sit <u>amet</u></em></h1>'
    ast = @converter.processed_ast(input)
    assert_equal "<Root: [<Paragraph{Heading1}: [<Run{b}: Lorem>, <Run{}:  ipsum dolor >, <Run{i}: sit >, <Run{i;u=single}: amet>]>]>", ast.inspect
  end

  def test_ul
    input = '<ul><li>Lorem</li><li>ipsum</li></ul>'
    ast = @converter.processed_ast(input)
    assert_equal "<Root: [<Paragraph{ListBullet}: [<Run{}: Lorem>]>, <Paragraph{ListBullet}: [<Run{}: ipsum>]>]>", ast.inspect
  end

  def test_ol
    input = '<ol><li>Lorem</li><li>ipsum</li></ol>'
    ast = @converter.processed_ast(input)
    assert_equal "<Root: [<Paragraph{ListNumber}: [<Run{}: Lorem>]>, <Paragraph{ListNumber}: [<Run{}: ipsum>]>]>", ast.inspect
  end

  def test_num_id
    ast = @converter.processed_ast('<ol><li>Some</li><li>Lorem</li></ol><ul><li>ipsum</li></ul><ol><li>dolor</li><li>sit</li></ol>')
    assert_equal [1001, 1001, 1002, 1003, 1003], get_numpr_prop_from_ast(ast, 'numId')
  end

  def test_nested_lists_have_the_same_numid
    ast = @converter.processed_ast('<ul><li>Lorem<ul><li>ipsum<ul><li>dolor</li></ul></li></ul></li></ul>')
    assert_equal [1001, 1001, 1001], get_numpr_prop_from_ast(ast, 'numId')
  end

  def test_keep_nested_list_order
    input = '<ul><li>1<ul><li>1.1<ul><li>1.1.1</li></ul></li><li>1.2</li></ul></li><li>2<ul><li>1.3<ul><li>1.3.1</li></ul></li></ul></li></ul>'
    ast = @converter.processed_ast(input)
    assert_equal [1001], get_numpr_prop_from_ast(ast, 'numId').uniq
    assert_equal [0, 1, 2, 1, 0, 1, 2], get_numpr_prop_from_ast(ast, 'ilvl')
  end

  private

  # returns the numid attribute from paragraphs
  def get_numpr_prop_from_ast(ast, key)
    values = []
    ast.grep(Sablon::HTMLConverter::Paragraph).each do |para|
      numpr = para.instance_variable_get('@properties')['numPr']
      numpr.each { |val| values.push(val[key]) if val[key] }
    end
    values
  end
end
