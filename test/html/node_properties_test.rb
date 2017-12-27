# -*- coding: utf-8 -*-
require "test_helper"

class NodePropertiesTest < Sablon::TestCase
  def setup
    # struct to simplify prop whitelisting during tests
    @inc_props = Struct.new(:props) do
      def include?(*)
        true
      end
    end
  end

  def test_empty_node_properties_converison
    # test empty properties
    props = Sablon::HTMLConverter::NodeProperties.new('w:pPr', {}, @inc_props.new)
    assert_equal props.inspect, ''
    assert_nil props.to_docx
  end

  def test_simple_node_property_converison
    props = { 'pStyle' => 'Paragraph' }
    props = Sablon::HTMLConverter::NodeProperties.new('w:pPr', props, @inc_props.new)
    assert_equal props.inspect, 'pStyle=Paragraph'
    assert_equal props.to_docx, '<w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>'
  end

  def test_node_property_with_nil_value_converison
    props = { 'b' => nil }
    props = Sablon::HTMLConverter::NodeProperties.new('w:rPr', props, @inc_props.new)
    assert_equal props.inspect, 'b'
    assert_equal props.to_docx, '<w:rPr><w:b /></w:rPr>'
  end

  def test_node_property_with_hash_value_converison
    props = { 'shd' => { color: 'clear', fill: '123456', test: nil } }
    props = Sablon::HTMLConverter::NodeProperties.new('w:rPr', props, @inc_props.new)
    assert_equal props.inspect, 'shd={:color=>"clear", :fill=>"123456", :test=>nil}'
    assert_equal props.to_docx, '<w:rPr><w:shd w:color="clear" w:fill="123456" /></w:rPr>'
  end

  def test_node_property_with_array_value_converison
    props = { 'numPr' => [{ 'ilvl' => 1 }, { 'numId' => 34 }] }
    props = Sablon::HTMLConverter::NodeProperties.new('w:pPr', props, @inc_props.new)
    assert_equal props.inspect, 'numPr=[{"ilvl"=>1}, {"numId"=>34}]'
    assert_equal props.to_docx, '<w:pPr><w:numPr><w:ilvl w:val="1" /><w:numId w:val="34" /></w:numPr></w:pPr>'
  end

  def test_complex_node_properties_conversion
    props = {
      'top1' => 'val1',
      'top2' => [
        { 'mid0' => nil },
        { 'mid1' => [
          { 'bottom1' => { key1: 'abc' } },
          { 'bottom2' => 'xyz' }
        ] },
        { 'mid2' => 'val2' }
      ],
      'top3' => { key1: 1, key2: '2', key3: nil, key4: true, key5: false }
    }
    output = <<-DOCX.gsub(/^\s*/, '').delete("\n")
      <w:pPr>
        <w:top1 w:val="val1" />
        <w:top2>
          <w:mid0 />
          <w:mid1>
            <w:bottom1 w:key1="abc" />
            <w:bottom2 w:val="xyz" />
          </w:mid1>
          <w:mid2 w:val="val2" />
        </w:top2>
        <w:top3 w:key1="1" w:key2="2" w:key4="true" />
      </w:pPr>
    DOCX
    props = Sablon::HTMLConverter::NodeProperties.new('w:pPr', props, @inc_props.new)
    assert_equal props.to_docx, output
  end

  def test_setting_property_value
    props = {}
    props = Sablon::HTMLConverter::NodeProperties.new('w:pPr', props, @inc_props.new)
    props['rStyle'] = 'FootnoteText'
    assert_equal({ 'rStyle' => 'FootnoteText' }, props.instance_variable_get(:@properties))
  end

  def test_properties_filtered_on_init
    props = { 'pStyle' => 'Paragraph', 'rStyle' => 'EndnoteText' }
    props = Sablon::HTMLConverter::NodeProperties.new('w:rPr', props, %w[rStyle])
    assert_equal({ 'rStyle' => 'EndnoteText' }, props.instance_variable_get(:@properties))
  end

  def test_transferred_properties
    props = { 'pStyle' => 'Paragraph', 'rStyle' => 'EndnoteText' }
    props = Sablon::HTMLConverter::NodeProperties.new(nil, props, %w[pStyle])
    trans = props.transferred_properties
    assert_equal({ 'rStyle' => 'EndnoteText' }, trans)
  end

  def test_node_properties_paragraph_factory
    props = { 'pStyle' => 'Paragraph' }
    props = Sablon::HTMLConverter::NodeProperties.paragraph(props)
    assert_equal 'pStyle=Paragraph', props.inspect
    assert_equal props.to_docx, '<w:pPr><w:pStyle w:val="Paragraph" /></w:pPr>'
  end

  def test_node_properties_table_factory
    props = { 'tblStyle' => 'Classic' }
    props = Sablon::HTMLConverter::NodeProperties.table(props)
    assert_equal 'tblStyle=Classic', props.inspect
    assert_equal props.to_docx, '<w:tblPr><w:tblStyle w:val="Classic" /></w:tblPr>'
  end

  def test_node_properties_table_row_factory
    props = { 'jc' => 'left' }
    props = Sablon::HTMLConverter::NodeProperties.table_row(props)
    assert_equal 'jc=left', props.inspect
    assert_equal props.to_docx, '<w:trPr><w:jc w:val="left" /></w:trPr>'
  end

  def test_node_properties_table_cell_factory
    props = { 'tcFitText' => 'true' }
    props = Sablon::HTMLConverter::NodeProperties.table_cell(props)
    assert_equal 'tcFitText=true', props.inspect
    assert_equal props.to_docx, '<w:tcPr><w:tcFitText w:val="true" /></w:tcPr>'
  end

  def test_node_properties_run_factory
    props = { 'color' => 'FF00FF' }
    props = Sablon::HTMLConverter::NodeProperties.run(props)
    assert_equal 'color=FF00FF', props.inspect
    assert_equal '<w:rPr><w:color w:val="FF00FF" /></w:rPr>', props.to_docx
  end
end
