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
      Sablon::Image.create_by_path(@base_path + "fixtures/images/c-3po.jpg"),
      Sablon::Image.create_by_path(@base_path + "fixtures/images/r2-d2.png")
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

    # Important Note: Images should have same order in the properties and in the ocurrence in the document (Sux, I known)
    template.render_to_file output_path, context, {images: @images}

    assert_docx_equal @sample_path, output_path
  end
end
