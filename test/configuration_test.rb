# -*- coding: utf-8 -*-
require "test_helper"

class ConfigurationTest < Sablon::TestCase
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
    assert_equal tag.attributes, { dummy: 'value1' }
    assert_equal tag.properties, { dummy2: 'value2' }
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
