# -*- coding: utf-8 -*-
require "test_helper"

# Tests some low level private methods in the ASTBuilder class. #process_nodes
# and self.html_to_ast are covered extensively in converter_test.rb
class HTMLConverterASTBuilderTest < Sablon::TestCase
  def setup
    super
    @env = Sablon::Environment.new(nil)
  end

  def test_fetch_tag
    @builder = new_builder
    tag = Sablon::Configuration.instance.permitted_html_tags[:span]
    assert_equal @builder.send(:fetch_tag, :span), tag
    # check that strings are converted into symbols
    assert_equal @builder.send(:fetch_tag, 'span'), tag
    # test unknown tag raises error
    e = assert_raises ArgumentError do
      @builder.send(:fetch_tag, :unknown_tag)
    end
    assert_equal "Don't know how to handle HTML tag: unknown_tag", e.message
  end

  def test_validate_structure
    @builder = new_builder
    root = Sablon::Configuration.instance.permitted_html_tags['#document-fragment'.to_sym]
    div = Sablon::Configuration.instance.permitted_html_tags[:div]
    span = Sablon::Configuration.instance.permitted_html_tags[:span]
    # test valid relationship
    assert_nil @builder.send(:validate_structure, div, span)
    # test inverted relationship
    e = assert_raises ArgumentError do
      @builder.send(:validate_structure, span, div)
    end
    assert_equal "Invalid HTML structure: div is not a valid child element of span.", e.message
  end

  def test_merge_properties
    @builder = new_builder
    node = Nokogiri::HTML.fragment('<span style="color: #F00; text-decoration: underline wavy">Test</span>').children[0]
    tag = Struct.new(:properties).new({ rStyle: 'Normal' })
    # test that properties are merged across all three arguments
    props = @builder.send(:merge_node_properties, node, tag, 'background-color' => '#00F')
    assert_equal({ 'background-color' => '#00F', rStyle: 'Normal', 'color' => '#F00', 'text-decoration' => 'underline wavy' }, props)
    # test that parent properties are overridden by tag properties
    props = @builder.send(:merge_node_properties, node, tag, rStyle: 'Citation', 'background-color' => '#00F')
    assert_equal({ 'background-color' => '#00F', rStyle: 'Normal', 'color' => '#F00', 'text-decoration' => 'underline wavy' }, props)
    # test that inline properties override parent styles
    node = Nokogiri::HTML.fragment('<span style="color: #F00">Test</span>').children[0]
    props = @builder.send(:merge_node_properties, node, tag, 'color' => '#00F')
    assert_equal({ rStyle: 'Normal', 'color' => '#F00' }, props)
  end

  private

  def new_builder(nodes = [], properties = {})
    Sablon::HTMLConverter::ASTBuilder.new(@env, nodes, properties)
  end
end
