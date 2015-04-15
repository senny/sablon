# -*- coding: utf-8 -*-
require "test_helper"

class ContextTest < Sablon::TestCase
  def test_converts_symbol_keys_to_string_keys
    transformed = Sablon::Context.transform({a: 1, b: {c: 2, "d" => 3}})
    assert_equal({"a"=>1, "b"=>{"c" =>2, "d"=>3}}, transformed)
  end

  def test_recognizes_wordml_keys
    transformed = Sablon::Context.transform({"word_ml:mykey" => "<w:p><w:p>", "otherkey" => "<nope>"})
    assert_equal({ "mykey"=>Sablon.content(:word_ml, "<w:p><w:p>"),
                   "otherkey"=>"<nope>"}, transformed)
  end

  def test_recognizes_markdown_keys
    transformed = Sablon::Context.transform({"markdown:mykey" => "**yay**", "otherkey" => "<nope>"})
    assert_equal({ "mykey"=>Sablon.content(:markdown, "**yay**"),
                   "otherkey"=>"<nope>"}, transformed)
  end

  def test_does_not_wrap_markdown_and_wordml_with_nil_value
    transformed = Sablon::Context.transform({"markdown:mykey" => nil, "word_ml:otherkey" => nil, "normalkey" => nil})
    assert_equal({ "mykey" => nil,
                   "otherkey" => nil,
                   "normalkey" => nil}, transformed)
  end
end
