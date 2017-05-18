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
  end

  def test_generate_document_from_template_with_images
    output_path = @base_path + "sandbox/images.docx"
    template = Sablon.template @template_path
    srand 123
    context = {
      items: [
        {
          title: "C-3PO",
          'image:image' => @base_path + "fixtures/images/c3pO.jpg"
        },
        {
          title: "R2-D2",
          'image:image' => @base_path + "fixtures/images/r2d2.jpg"
        }
      ]
    }

    template.render_to_file output_path, context
    assert_docx_equal @sample_path, output_path
  end
end
