# -*- coding: utf-8 -*-
require "test_helper"

class HTMLConverterStyleTest < Sablon::TestCase
  def setup
    super
    @template = MockTemplate.new
    @env = Sablon::Environment.new(@template)
    @converter = Sablon::HTMLConverter.new
  end

  def teardown
    @template.document.reset
  end

  # testing direct CSS style -> WordML conversion for paragraphs

  def test_paragraph_with_background_color
    input = '<p style="background-color: #123456"></p>'
    expected_output = para_with_ppr('<w:shd w:val="clear" w:fill="123456" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_paragraph_with_borders
    # Basic single line black border
    input = '<p style="border: 1px"></p>'
    ppr = <<-DOCX.strip
      <w:pBdr>
        <w:top w:sz="2" w:val="single" w:color="000000" />
        <w:bottom w:sz="2" w:val="single" w:color="000000" />
        <w:left w:sz="2" w:val="single" w:color="000000" />
        <w:right w:sz="2" w:val="single" w:color="000000" />
      </w:pBdr>
    DOCX
    expected_output = para_with_ppr(ppr)
    assert_equal normalize_wordml(expected_output), process(input)
    # border with a line style
    input = '<p style="border: 1px wavy"></p>'
    ppr = <<-DOCX.strip
      <w:pBdr>
        <w:top w:sz="2" w:val="wavy" w:color="000000" />
        <w:bottom w:sz="2" w:val="wavy" w:color="000000" />
        <w:left w:sz="2" w:val="wavy" w:color="000000" />
        <w:right w:sz="2" w:val="wavy" w:color="000000" />
      </w:pBdr>
    DOCX
    expected_output = para_with_ppr(ppr)
    assert_equal normalize_wordml(expected_output), process(input)
    # border with line style and color
    input = '<p style="border: 1px wavy #123456"></p>'
    ppr = <<-DOCX.strip
      <w:pBdr>
        <w:top w:sz="2" w:val="wavy" w:color="123456" />
        <w:bottom w:sz="2" w:val="wavy" w:color="123456" />
        <w:left w:sz="2" w:val="wavy" w:color="123456" />
        <w:right w:sz="2" w:val="wavy" w:color="123456" />
      </w:pBdr>
    DOCX
    expected_output = para_with_ppr(ppr)
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_paragraph_with_text_align
    input = '<p style="text-align: both"></p>'
    expected_output = para_with_ppr('<w:jc w:val="both" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_paragraph_with_vertical_align
    input = '<p style="vertical-align: baseline"></p>'
    expected_output = para_with_ppr('<w:textAlignment w:val="baseline" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_paragraph_with_unsupported_property
    input = '<p style="unsupported: true"></p>'
    expected_output = para_with_ppr('')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  # test that styles defined on the <a> tag are passed down to runs
  def test_hyperlink_with_font_style
    input = '<p><a href="http://www.google.com" style="font-style: italic">Google</a></p>'
    expected_output = hyperlink_with_rpr('<w:i />', @template.document.current_rid + 1)
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

    # test italics
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
          <w:pStyle w:val="Paragraph" />
          <w:jc w:val="center" />
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

  def test_inline_style_overrides_tag_style
    # Note: a toggle property can not be removed once it becomes a symbol
    # unless there is a specific CSS style that will set it to false. This
    # is because CSS styles can only override parent properties not remove them.
    input = '<p><u style="text-decoration: underline wavyDouble">test</u></p>'
    expected_output = run_with_rpr('<w:u w:val="wavyDouble" w:color="auto" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_conversion_of_a_registered_tag_without_ast_class
    # This registers a new tag with the configuration object and then tries
    # to convert it
    Sablon.configure do |config|
      config.register_html_tag(:bgcyan, :inline, properties: { 'highlight' => { val: 'cyan' } })
    end
    #
    input = '<p><bgcyan>test</bgcyan></p>'
    expected_output = run_with_rpr('<w:highlight w:val="cyan" />')
    assert_equal normalize_wordml(expected_output), process(input)

    # remove the tag to avoid any accidental side effects
    Sablon.configure do |config|
      config.remove_html_tag(:bgcyan)
    end
  end

  def test_conversion_of_a_registered_tag_with_ast_class
    Sablon.configure do |config|
      # create the AST class and then pass it onto the register tag method
      ast_class = Class.new(Sablon::HTMLConverter::Node) do
        def self.name
          'TestInstr'
        end

        def initialize(_env, node, _properties)
          @content = node.text
        end

        def inspect
          @content
        end

        def to_docx
          "<w:instrText xml:space=\"preserve\"> #{@content} </w:instrText>"
        end
      end
      #
      config.register_html_tag(:test_instr, :inline, ast_class: ast_class)
    end
    #
    input = '<p><test_instr>test</test_instr></p>'
    expected_output = <<-DOCX.strip
      <w:p>
        <w:pPr>
          <w:pStyle w:val="Paragraph" />
        </w:pPr>
        <w:instrText xml:space="preserve"> test </w:instrText>
      </w:p>
    DOCX
    assert_equal normalize_wordml(expected_output), process(input)

    # remove the tag to avoid any accidental side effects
    Sablon.configure do |config|
      config.remove_html_tag(:test_instr)
    end
  end

  def test_conversion_of_registered_style_attribute
    Sablon.configure do |config|
      converter = ->(v) { return :highlight, v }
      config.register_style_converter(:run, 'test-highlight', converter)
    end
    #
    input = '<p><span style="test-highlight: green">test</span></p>'
    expected_output = run_with_rpr('<w:highlight w:val="green" />')
    assert_equal normalize_wordml(expected_output), process(input)
    #
    Sablon.configure do |config|
      config.remove_style_converter(:run, 'test-highlight')
    end
  end

  def test_table_border_conversion
    input = '<table style="border: 1px dotted #eaf"><tr><td></td></tr></table>'
    props = <<-DOCX.strip
      <w:tblBorders>
        <w:top w:sz="2" w:val="dotted" w:color="eaf" />
        <w:start w:sz="2" w:val="dotted" w:color="eaf" />
        <w:bottom w:sz="2" w:val="dotted" w:color="eaf" />
        <w:end w:sz="2" w:val="dotted" w:color="eaf" />
        <w:insideH w:sz="2" w:val="dotted" w:color="eaf" />
        <w:insideV w:sz="2" w:val="dotted" w:color="eaf" />
      </w:tblBorders>
    DOCX
    expected_output = table_with_props(props)
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_margin_conversion
    # test with single value
    input = '<table style="margin: 2"><tr><td></td></tr></table>'
    props = <<-DOCX.strip
      <w:tblCellMar>
        <w:top w:w="4" w:type="dxa" />
        <w:end w:w="4" w:type="dxa" />
        <w:bottom w:w="4" w:type="dxa" />
        <w:start w:w="4" w:type="dxa" />
      </w:tblCellMar>
    DOCX
    expected_output = table_with_props(props)
    assert_equal normalize_wordml(expected_output), process(input)

    # test with two values
    input = '<table style="margin: 2 4"><tr><td></td></tr></table>'
    props = <<-DOCX.strip
      <w:tblCellMar>
        <w:top w:w="4" w:type="dxa" />
        <w:end w:w="8" w:type="dxa" />
        <w:bottom w:w="4" w:type="dxa" />
        <w:start w:w="8" w:type="dxa" />
      </w:tblCellMar>
    DOCX
    expected_output = table_with_props(props)
    assert_equal normalize_wordml(expected_output), process(input)

    # test with three values
    input = '<table style="margin: 2 4 8"><tr><td></td></tr></table>'
    props = <<-DOCX.strip
      <w:tblCellMar>
        <w:top w:w="4" w:type="dxa" />
        <w:end w:w="8" w:type="dxa" />
        <w:bottom w:w="16" w:type="dxa" />
        <w:start w:w="8" w:type="dxa" />
      </w:tblCellMar>
    DOCX
    expected_output = table_with_props(props)
    assert_equal normalize_wordml(expected_output), process(input)

    # test with four values
    input = '<table style="margin: 2 4 8 16"><tr><td></td></tr></table>'
    props = <<-DOCX.strip
      <w:tblCellMar>
        <w:top w:w="4" w:type="dxa" />
        <w:end w:w="8" w:type="dxa" />
        <w:bottom w:w="16" w:type="dxa" />
        <w:start w:w="32" w:type="dxa" />
      </w:tblCellMar>
    DOCX
    expected_output = table_with_props(props)
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_cellspacing_conversion
    input = '<table style="cellspacing: 1"><tr><td></td></tr></table>'
    expected_output = table_with_props('<w:tblCellSpacing w:w="2" w:type="dxa" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_width_conversion
    input = '<table style="width: 1"><tr><td></td></tr></table>'
    expected_output = table_with_props('<w:tblW w:w="2" w:type="dxa" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_cell_borders_conversion
    input = '<table><tr><td style="border: 1px dotted #eaf"></td></tr></table>'
    props = <<-DOCX.strip
      <w:tcBorders>
        <w:top w:sz="2" w:val="dotted" w:color="eaf" />
        <w:start w:sz="2" w:val="dotted" w:color="eaf" />
        <w:bottom w:sz="2" w:val="dotted" w:color="eaf" />
        <w:end w:sz="2" w:val="dotted" w:color="eaf" />
        <w:insideH w:sz="2" w:val="dotted" w:color="eaf" />
        <w:insideV w:sz="2" w:val="dotted" w:color="eaf" />
      </w:tcBorders>
    DOCX
    expected_output = table_with_props('', '', props)
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_cell_colspan_conversion
    input = '<table><tr><td style="colspan: 2"></td></tr></table>'
    expected_output = table_with_props('', '', '<w:gridSpan w:val="2" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_cell_margin_conversion
    # test with four values
    input = '<table><tr><td style="margin: 2 4 8 16"></td></tr></table>'
    props = <<-DOCX.strip
      <w:tcMar>
        <w:top w:w="4" w:type="dxa" />
        <w:end w:w="8" w:type="dxa" />
        <w:bottom w:w="16" w:type="dxa" />
        <w:start w:w="32" w:type="dxa" />
      </w:tcMar>
    DOCX
    expected_output = table_with_props('', '', props)
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_cell_rowspan_conversion
    input = '<table><tr><td style="rowspan: start"></td></tr></table>'
    expected_output = table_with_props('', '', '<w:vMerge w:val="restart" />')
    assert_equal normalize_wordml(expected_output), process(input)
    #
    input = '<table><tr><td style="rowspan: continue"></td></tr></table>'
    expected_output = table_with_props('', '', '<w:vMerge w:val="continue" />')
    assert_equal normalize_wordml(expected_output), process(input)
    #
    input = '<table><tr><td style="rowspan: end"></td></tr></table>'
    expected_output = table_with_props('', '', '<w:vMerge />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_cell_vertical_align_conversion
    input = '<table><tr><td style="vertical-align: top"></td></tr></table>'
    expected_output = table_with_props('', '', '<w:vAlign w:val="top" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_cell_white_space_conversion
    input = '<table><tr><td style="white-space: nowrap"></td></tr></table>'
    expected_output = table_with_props('', '', '<w:noWrap />')
    assert_equal normalize_wordml(expected_output), process(input)
    #
    input = '<table><tr><td style="white-space: fit"></td></tr></table>'
    expected_output = table_with_props('', '', '<w:tcFitText w:val="true" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  def test_table_cell_width_conversion
    input = '<table><tr><td style="width: 100"></td></tr></table>'
    expected_output = table_with_props('', '', '<w:tcW w:w="200" w:type="dxa" />')
    assert_equal normalize_wordml(expected_output), process(input)
  end

  private

  def process(input)
    @converter.process(input, @env)
  end

  def table_with_props(tbl_pr_str, tr_pr_str = '', tc_pr_str = '')
    tbl_str = <<-DOCX.strip
      <w:tbl>
          %s
        <w:tr>
          %s
          <w:tc>
            %s
            <w:p><w:pPr><w:pStyle w:val="Paragraph" /></w:pPr></w:p>
          </w:tc>
        </w:tr>
      </w:tbl>
    DOCX
    tbl_pr_str = "<w:tblPr>#{tbl_pr_str}</w:tblPr>" unless tbl_pr_str == ''
    tr_pr_str = "<w:trPr>#{tr_pr_str}</w:trPr>" unless tr_pr_str == ''
    tc_pr_str = "<w:tcPr>#{tc_pr_str}</w:tcPr>" unless tc_pr_str == ''
    format(tbl_str, tbl_pr_str, tr_pr_str, tc_pr_str)
  end

  def para_with_ppr(ppr_str)
    para_str = '<w:p><w:pPr><w:pStyle w:val="Paragraph" />%s</w:pPr></w:p>'
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

  def hyperlink_with_rpr(rpr_str, id)
    para_str = <<-DOCX.strip
      <w:p>
        <w:pPr>
        <w:pStyle w:val="Paragraph" />
        </w:pPr>
      <w:hyperlink r:id="rId#{id}">
        <w:r>
        <w:rPr>
          <w:rStyle w:val="Hyperlink" />
          %s
        </w:rPr>
        <w:t xml:space="preserve">Google</w:t>
        </w:r>
      </w:hyperlink>
    </w:p>
    DOCX
    format(para_str, rpr_str)
  end

  def normalize_wordml(wordml)
    wordml.gsub(/^\s+/, '').tr("\n", '')
  end
end
