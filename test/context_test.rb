# -*- coding: utf-8 -*-
require "test_helper"

class ContextTest < Sablon::TestCase
  def test_converts_symbol_keys_to_string_keys
    context = Sablon::Context.transform_hash(a: 1, b: { c: 2, "d" => 3 })
    assert_equal({ "a" => 1, "b" => { "c" => 2, "d" => 3 } }, context)
  end

  def test_recognizes_wordml_keys
    context = Sablon::Context.transform_hash("word_ml:mykey" => "<w:p><w:p>", "otherkey" => "<nope>")
    assert_equal({ "mykey" => Sablon.content(:word_ml, "<w:p><w:p>"),
                   "otherkey" => "<nope>"}, context)
  end

  def test_recognizes_html_keys
    context = Sablon::Context.transform_hash("html:mykey" => "**yay**", "otherkey" => "<nope>")
    assert_equal({ "mykey" => Sablon.content(:html, "**yay**"),
                   "otherkey" => "<nope>"}, context)
  end

  def test_does_not_wrap_html_and_wordml_with_nil_value
    context = Sablon::Context.transform_hash("html:mykey" => nil, "word_ml:otherkey" => nil, "normalkey" => nil)
    assert_equal({ "mykey" => nil,
                   "otherkey" => nil,
                   "normalkey" => nil}, context)
  end

  def test_recognizes_image_keys
    base_path = Pathname.new(File.expand_path("../", __FILE__))
    img_path = "#{base_path}/fixtures/images/c3po.jpg"
    context = {
      test: 'result',
      'image:image' =>  img_path
    }
    #
    context = Sablon::Context.transform_hash(context)
    assert_equal({ "test" => "result",
                   "image" => Sablon.content(:image, img_path) },
                 context)
  end

  def test_converts_hashes_nested_in_arrays
    input_context = {
      test: 'result',
      items: [
        { name: 'Key1', value: 'Value1'  },
        { 'name' => 'Key2', 'html:value' => '<b>Test</b>' }
      ],
      'word_ml:runs' => '<w:r><w:t>Text</w:t><w:r>'
    }
    expected_context = {
      'test' => 'result',
      'items' => [
        { 'name' => 'Key1', 'value' => 'Value1'  },
        { 'name' => 'Key2', 'value' => Sablon.content(:html, '<b>Test</b>') }
      ],
      'runs' => Sablon.content(:word_ml, '<w:r><w:t>Text</w:t><w:r>')
    }
    #
    context = Sablon::Context.transform_hash(input_context)
    assert_equal expected_context, context
  end

  def test_tune_typed_content_regex
    input_context = {
      default: "string",
      "word_ml:runs" => "<w:r><w:t>Text</w:t><w:r>",
      "urn:some:example" => "string as well"
    }
    expected_context = {
      "default" => "string",
      "runs" => Sablon.content(:word_ml, "<w:r><w:t>Text</w:t><w:r>"),
      "urn:some:example" => "string as well"
    }

    original_regex = Sablon::Context.content_regex
    begin
      Sablon::Context.content_regex = /\A((?!urn:)[^:]+):(.+)\z/
      context = Sablon::Context.transform_hash(input_context)
      assert_equal expected_context, context
    ensure
      Sablon::Context.content_regex = original_regex
    end
  end
end
