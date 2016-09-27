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

  def test_recognizes_html_keys
    transformed = Sablon::Context.transform({"html:mykey" => "**yay**", "otherkey" => "<nope>"})
    assert_equal({ "mykey"=>Sablon.content(:html, "**yay**"),
                   "otherkey"=>"<nope>"}, transformed)
  end

  def test_does_not_wrap_html_and_wordml_with_nil_value
    transformed = Sablon::Context.transform({"html:mykey" => nil, "word_ml:otherkey" => nil, "normalkey" => nil})
    assert_equal({ "mykey" => nil,
                   "otherkey" => nil,
                   "normalkey" => nil}, transformed)
  end


  def test_values_of_single_element
    base_path = Pathname.new(File.expand_path("../", __FILE__))
    image = Sablon::Image.create_by_path(base_path + "fixtures/images/c-3po.jpg", 1)

    context = {
      test: 'result',
      image: image
    }

    result = Sablon::Context.values_of(context, Sablon::Image::Definition)

    assert_equal [image], result
  end

  def test_values_of_nested
    base_path = Pathname.new(File.expand_path("../", __FILE__))
    image = Sablon::Image.create_by_path(base_path + "fixtures/images/c-3po.jpg", 2)

    context = {
      image: image,
      nested: OpenStruct.new(
        item: {
          id: 10,
          image: image
        }
      ),
      other: [
        image,
        image
      ]
    }

    result = Sablon::Context.values_of(context, Sablon::Image::Definition)

    assert_equal [image, image, image, image], result
  end

  def test_values_of_empty
    context = {
      test: "result"
    }

    result = Sablon::Context.values_of(context, Sablon::Image::Definition)

    assert_empty result
  end  
end
