# -*- coding: utf-8 -*-
require "test_helper"
require "support/xml_snippets"

class SablonImageTest < Sablon::TestCase
  include Sablon::Test::Assertions

  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))

    @template_path = @base_path + "fixtures/image_template.docx"
    @sample_path = @base_path + "fixtures/image_sample.docx"
    @images = [
      Sablon::Image.create_by_path(@base_path + "fixtures/images/c-3po.jpg", 1),
      Sablon::Image.create_by_path(@base_path + "fixtures/images/r2-d2.png", 2)
    ]
  end

  def test_generate_document_from_template_with_images
    output_path = @base_path + "sandbox/images.docx"
    template = Sablon.template @template_path
    context = {
      items: [
        {
          title: "C-3PO",
          image: @images[0]
        },
        {
          title: "R2-D2",
          image: @images[1]
        }
      ]
    }

    template.render_to_file output_path, context

    assert_docx_equal @sample_path, output_path
  end

  def test_get_all_images_simple_image
    image = Sablon::Image.create_by_path(@base_path + "fixtures/images/c-3po.jpg", 1)

    context = {
      test: 'result',
      image: image
    }

    result = Sablon::Processor::Image.get_all_images(context)

    assert_equal [image], result
  end

  def test_get_all_images_nested
    image = Sablon::Image.create_by_path(@base_path + "fixtures/images/c-3po.jpg", 2)

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

    result = Sablon::Processor::Image.get_all_images(context)

    assert_equal [image, image, image, image], result
  end

  def test_get_all_images_empty
    context = {
      test: "result"
    }

    result = Sablon::Processor::Image.get_all_images(context)

    assert_empty result
  end
end