# -*- coding: utf-8 -*-
require "test_helper"

class ContextTest < Sablon::TestCase
  def test_converts_symbol_keys_to_string_keys
    transformed = Sablon::Context.transform({a: 1, b: {c: 2, "d" => 3}})
    assert_equal({"a"=>1, "b"=>{"c" =>2, "d"=>3}}, transformed)
  end

  def test_recognizes_wordml_keys
    transformed = Sablon::Context.transform({"wordml:mykey" => "<w:p><w:p>", "otherkey" => "<nope>"})
    assert_equal({ "mykey"=>Sablon.word_ml("<w:p><w:p>"),
                   "otherkey"=>"<nope>"}, transformed)
  end
end
