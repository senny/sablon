# -*- coding: utf-8 -*-
require "test_helper"

class ContextTest < Sablon::TestCase
  def test_converts_symbol_keys_to_string_keys
    env = Sablon::Environment.new(nil, {a: 1, b: {c: 2, "d" => 3}})
    assert_equal({"a"=>1, "b"=>{"c" =>2, "d"=>3}}, env.context)
  end

  def test_recognizes_wordml_keys
    env = Sablon::Environment.new(nil, {"word_ml:mykey" => "<w:p><w:p>", "otherkey" => "<nope>"})
    assert_equal({ "mykey"=>Sablon.content(:word_ml, "<w:p><w:p>"),
                   "otherkey"=>"<nope>"}, env.context)
  end

  def test_recognizes_html_keys
    env = Sablon::Environment.new(nil, {"html:mykey" => "**yay**", "otherkey" => "<nope>"})
    assert_equal({ "mykey"=>Sablon.content(:html, "**yay**"),
                   "otherkey"=>"<nope>"}, env.context)
  end

  def test_does_not_wrap_html_and_wordml_with_nil_value
    env = Sablon::Environment.new(nil, {"html:mykey" => nil, "word_ml:otherkey" => nil, "normalkey" => nil})
    assert_equal({ "mykey" => nil,
                   "otherkey" => nil,
                   "normalkey" => nil}, env.context)
  end
end
