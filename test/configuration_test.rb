# -*- coding: utf-8 -*-
require "test_helper"

class ConfigurationTest < Sablon::TestCase
  def setup
    super
    @config = Sablon::Configuration.send(:new)
  end

  def test_register_tag
    options = {
      ast_class: :paragraph,
      attributes: { dummy: 'value' },
      properties: { pstyle: 'ListBullet' },
      allowed_children: %i[_inline ol ul li]
    }
    # test initialization without type
    tag = @config.register_html_tag(:test_tag, **options)
    assert_equal tag, @config.permitted_html_tags[:test_tag]
    assert_equal :test_tag, tag.name
    assert_equal :inline, tag.type
    assert_equal Sablon::HTMLConverter::Paragraph, tag.ast_class
    assert_equal({ dummy: 'value' }, tag.attributes)
    assert_equal({ 'pstyle' => 'ListBullet' }, tag.properties)
    assert_equal %i[_inline ol ul li], tag.allowed_children

    # test initialization with type
    tag = @config.register_html_tag('test_tag2', :block, **options)
    assert_equal tag, @config.permitted_html_tags[:test_tag2]
    assert_equal :test_tag2, tag.name
    assert_equal :block, tag.type
  end

  def test_remove_tag
    tag = @config.register_html_tag(:test)
    assert_equal tag, @config.remove_html_tag(:test)
    assert_nil @config.permitted_html_tags[:test]
  end

  def test_register_style_converter_on_existing_ast_class
    converter = ->(v) { return "test-attr-#{v}" }
    @config.register_style_converter(:run, 'my-test-attr', converter)
    #
    assert @config.defined_style_conversions[:run]['my-test-attr'], 'converter should be stored in hash'
    assert_equal 'test-attr-123', @config.defined_style_conversions[:run]['my-test-attr'].call(123)
  end

  def test_register_style_converter_on_newast_class
    converter = ->(v) { return "test-attr-#{v}" }
    @config.register_style_converter(:unset_ast_class, 'my-test-attr', converter)
    #
    assert @config.defined_style_conversions[:unset_ast_class]['my-test-attr'], 'converter should be stored in hash'
  end

  def test_remove_style_converter
    converter = ->(v) { return "test-attr-#{v}" }
    converter = @config.register_style_converter(:run, 'my-test-attr', converter)
    #
    assert_equal converter, @config.remove_style_converter(:run, 'my-test-attr')
    assert_nil @config.defined_style_conversions[:run]['my-test-attr']
  end
end

class ConfigurationHTMLTagTest < Sablon::TestCase
  # test basic instantiation of an HTMLTag
  def test_html_tag_defaults
    tag = Sablon::Configuration::HTMLTag.new(:a, :inline)
    assert_equal tag.name, :a
    assert_equal tag.type, :inline
    assert_nil tag.ast_class
    assert_equal tag.attributes, {}
    assert_equal tag.properties, {}
    assert_equal tag.allowed_children, %i[_inline ol ul]
  end

  # Exercising more of the logic used to conform args into valid
  def test_html_tag_full_init
    args = ['a', 'inline']
    kwargs = { ast_class: Sablon::HTMLConverter::Run }
    tag = Sablon::Configuration::HTMLTag.new(*args, **kwargs)
    assert_equal :a, tag.name
    assert_equal :inline, tag.type
    assert_equal Sablon::HTMLConverter::Run, tag.ast_class
    #
    options = {
      ast_class: :run,
      attributes: { dummy: 'value1' },
      properties: { dummy2: 'value2' },
      allowed_children: 'text'
    }
    tag = Sablon::Configuration::HTMLTag.new('a', 'inline', **options)
    #
    assert_equal :a, tag.name
    assert_equal :inline, tag.type
    assert_equal Sablon::HTMLConverter::Run, tag.ast_class
    assert_equal({ dummy: 'value1' }, tag.attributes)
    assert_equal({ 'dummy2' => 'value2' }, tag.properties)
    assert_equal [:text], tag.allowed_children
  end

  def test_html_tag_init_block_without_class
    e = assert_raises ArgumentError do
      Sablon::Configuration::HTMLTag.new(:form, :block)
    end
    assert_equal "Block level tag form must have an AST class.", e.message
  end

  def test_html_tag_allowed_children
    # define different tags for testing
    text = Sablon::Configuration::HTMLTag.new(:text, :inline)
    div = Sablon::Configuration::HTMLTag.new(:div, :block, ast_class: :paragraph)
    olist = Sablon::Configuration::HTMLTag.new(:ol, :block, ast_class: :paragraph, allowed_children: %i[_block])

    # test default allowances
    assert div.allowed_child?(text) # all inline elements allowed
    assert div.allowed_child?(olist) # tag name is included even though it is block level
    assert_equal false, div.allowed_child?(div) # other block elms are not allowed

    # test olist with allowances for all blocks but no inline
    assert olist.allowed_child?(div) # all block elements allowed
    assert_equal false, olist.allowed_child?(text) # no inline elements
  end
end
