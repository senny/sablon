# -*- coding: utf-8 -*-
require "test_helper"

class HTMLConverterASTBuilderTest < Sablon::TestCase
  def setup
    super
    @env = Sablon::Environment.new(nil)
  end

  def test_fetch_tag
    @bulider = new_builder
    tag = Sablon::Configuration.instance.permitted_html_tags[:span]
    assert_equal @bulider.send(:fetch_tag, :span), tag
    # check that strings are converted into symbols
    assert_equal @bulider.send(:fetch_tag, 'span'), tag
    # test uknown tag raises error
    e = assert_raises ArgumentError do
      @bulider.send(:fetch_tag, :unknown_tag)
    end
    assert_equal "Don't know how to handle HTML tag: unknown_tag", e.message
  end

  def test_validate_structure
    @bulider = new_builder
    root = Sablon::Configuration.instance.permitted_html_tags['#document-fragment'.to_sym]
    div = Sablon::Configuration.instance.permitted_html_tags[:div]
    span = Sablon::Configuration.instance.permitted_html_tags[:span]
    # test valid relationship
    assert_nil @bulider.send(:validate_structure, div, span)
    # test inverted relationship
    e = assert_raises ArgumentError do
      @bulider.send(:validate_structure, span, div)
    end
    assert_equal "Invalid HTML structure: div is not a valid child element of span.", e.message
    # test inline tag with no parent
    e = assert_raises ArgumentError do
      @bulider.send(:validate_structure, root, span)
    end
    assert_equal "Invalid HTML structure: span needs to be wrapped in a block level tag.", e.message
  end

  private

  def new_builder(nodes = [], properties = {})
    Sablon::HTMLConverter::ASTBuilder.new(@env, nodes, properties)
  end
end
