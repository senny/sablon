# -*- coding: utf-8 -*-
require "test_helper"

class ExecutableTest < Sablon::TestCase
  include Sablon::Test::Assertions

  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))
    @output_path = @base_path + "sandbox/shopping_list.docx"
  end

  def test_generate_document_from_template
    template_path = @base_path + "fixtures/shopping_list_template.docx"
    context_path = @base_path + "fixtures/shopping_list_context.json"

    executable_path = @base_path + '../bin/sablon'

    `cat #{context_path} | #{executable_path} #{template_path} #{@output_path}`

    assert_docx_equal @base_path + "fixtures/shopping_list_sample.docx", @output_path
  end
end
