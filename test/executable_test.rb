require "test_helper"

class ExecutableTest < Sablon::TestCase
  include Sablon::Test::Assertions

  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))
    @output_path = @base_path + "sandbox/shopping_list.docx"
    @template_path = @base_path + "fixtures/shopping_list_template.docx"
    @context_path = @base_path + "fixtures/shopping_list_context.json"
    @executable_path = @base_path + '../bin/sablon'

    @output_path.delete if @output_path.exist?
  end

  def test_generate_document_from_template_output_to_file
    `cat #{@context_path} | #{@executable_path} #{@template_path} #{@output_path}`

    assert_docx_equal @base_path + "fixtures/shopping_list_sample.docx", @output_path
  end

  def test_generate_document_from_template_output_to_stdout
    `cat #{@context_path} | #{@executable_path} #{@template_path} > #{@output_path}`

    assert_docx_equal @base_path + "fixtures/shopping_list_sample.docx", @output_path
  end
end
