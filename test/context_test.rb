# -*- coding: utf-8 -*-
require "test_helper"

class EnvironmentTest < Sablon::TestCase
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
    img_path = "#{base_path}/fixtures/images/c3pO.jpg"
    context = {
      test: 'result',
      'image:image' =>  img_path
    }
    # need to fix random number generation to generate identical image names
    srand 123
    context = Sablon::Context.transform_hash(context)

    srand 123
    assert_equal({ "test" => "result",
                   "image" => Sablon.content(:image, img_path) },
                 context)
  end
end
