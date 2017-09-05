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
    assert_equal @config.permitted_html_tags[:test_tag], tag
    assert_equal tag.name, :test_tag
    assert_equal tag.type, :inline
    assert_equal tag.ast_class, Sablon::HTMLConverter::Paragraph
    assert_equal tag.attributes, dummy: 'value'
    assert_equal tag.properties, pstyle: 'ListBullet'
    assert_equal tag.allowed_children, %i[_inline ol ul li]

    # test initialization with type
    tag = @config.register_html_tag('test_tag2', :block, **options)
    assert_equal @config.permitted_html_tags[:test_tag2], tag
    assert_equal tag.name, :test_tag2
    assert_equal tag.type, :block
  end

  def test_remove_tag
    tag = @config.register_html_tag(:test)
    assert_equal @config.remove_html_tag(:test), tag
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
    args = ['a', 'inline', ast_class: Sablon::HTMLConverter::Run]
    tag = Sablon::Configuration::HTMLTag.new(*args)
    assert_equal tag.name, :a
    assert_equal tag.type, :inline
    assert_equal tag.ast_class, Sablon::HTMLConverter::Run
    #
    options = {
      ast_class: :run,
      attributes: { dummy: 'value1' },
      properties: { dummy2: 'value2' },
      allowed_children: 'text'
    }
    tag = Sablon::Configuration::HTMLTag.new('a', 'inline', **options)
    #
    assert_equal tag.name, :a
    assert_equal tag.type, :inline
    assert_equal tag.ast_class, Sablon::HTMLConverter::Run
    assert_equal tag.attributes, dummy: 'value1'
    assert_equal tag.properties, dummy2: 'value2'
    assert_equal tag.allowed_children, [:text]
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
    assert div.allowed_child?(olist) # tag name is included even though it is bock leve
    assert_equal div.allowed_child?(div), false # other block elms are not allowed

    # test olist with allowances for all blocks but no inline
    assert olist.allowed_child?(div) # all block elements allowed
    assert_equal olist.allowed_child?(text), false # no inline elements
  end
end
