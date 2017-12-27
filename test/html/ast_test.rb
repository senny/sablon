# -*- coding: utf-8 -*-
require "test_helper"
require 'securerandom'

class HTMLConverterASTTest < Sablon::TestCase
  def setup
    super
    @converter = Sablon::HTMLConverter.new
    @converter.instance_variable_set(:@env, Sablon::Environment.new(nil))
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

  def test_a
    input = '<p>Lorem <a href="http://www.google.com">google</a></p>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Paragraph{Paragraph}: [<Run{}: Lorem >, <Hyperlink{target:http://www.google.com}: [<Run{rStyle=Hyperlink}: google>]>]>]>', ast.inspect
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
    assert_equal "<Root: [<List: [<Paragraph{ListBullet}: [<Run{}: Lorem>]>, <Paragraph{ListBullet}: [<Run{}: ipsum>]>]>]>", ast.inspect
  end

  def test_ol
    input = '<ol><li>Lorem</li><li>ipsum</li></ol>'
    ast = @converter.processed_ast(input)
    assert_equal "<Root: [<List: [<Paragraph{ListNumber}: [<Run{}: Lorem>]>, <Paragraph{ListNumber}: [<Run{}: ipsum>]>]>]>", ast.inspect
  end

  def test_num_id
    ast = @converter.processed_ast('<ol><li>Some</li><li>Lorem</li></ol><ul><li>ipsum</li></ul><ol><li>dolor</li><li>sit</li></ol>')
    assert_equal %w[1001 1001 1002 1003 1003], get_numpr_prop_from_ast(ast, :numId)
  end

  def test_nested_lists_have_the_same_numid
    ast = @converter.processed_ast('<ul><li>Lorem<ul><li>ipsum<ul><li>dolor</li></ul></li></ul></li></ul>')
    assert_equal %w[1001 1001 1001], get_numpr_prop_from_ast(ast, :numId)
  end

  def test_keep_nested_list_order
    input = '<ul><li>1<ul><li>1.1<ul><li>1.1.1</li></ul></li><li>1.2</li></ul></li><li>2<ul><li>1.3<ul><li>1.3.1</li></ul></li></ul></li></ul>'
    ast = @converter.processed_ast(input)
    assert_equal %w[1001], get_numpr_prop_from_ast(ast, :numId).uniq
    assert_equal %w[0 1 2 1 0 1 2], get_numpr_prop_from_ast(ast, :ilvl)
  end

  def test_table_tag
    input='<table></table>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Table{}: []>]>', ast.inspect
  end

  def test_table_with_table_row
    input='<table><tr></tr></table>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Table{}: [<TableRow{}: []>]>]>', ast.inspect
  end

  def test_table_with_table_row_and_table_cell
    input='<table><tr><td>Content</td></tr></table>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Table{}: [<TableRow{}: [<TableCell{}: [<Paragraph{Paragraph}: [<Run{}: Content>]>]>]>]>]>', ast.inspect
  end

  def test_table_with_table_row_and_table_cell_and_caption
    input='<table><caption>Table Title</caption><tr><td>Content</td></tr></table>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Table{}: <Paragraph{Caption}: [<Run{}: Table Title>]>, [<TableRow{}: [<TableCell{}: [<Paragraph{Paragraph}: [<Run{}: Content>]>]>]>]>]>', ast.inspect
    #
    input='<table><caption style="caption-side: bottom">Table Title</caption><tr><td>Content</td></tr></table>'
    ast = @converter.processed_ast(input)
    assert_equal '<Root: [<Table{}: [<TableRow{}: [<TableCell{}: [<Paragraph{Paragraph}: [<Run{}: Content>]>]>]>], <Paragraph{Caption}: [<Run{}: Table Title>]>>]>', ast.inspect
  end

  private

  # returns the numid attribute from paragraphs
  def get_numpr_prop_from_ast(ast, key)
    values = []
    ast.grep(Sablon::HTMLConverter::ListParagraph).each do |para|
      numpr = para.instance_variable_get('@properties')[:numPr]
      numpr.each { |val| values.push(val[key]) if val[key] }
    end
    values
  end
end
