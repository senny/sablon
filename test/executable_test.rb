require "test_helper"

class ExecutableTest < Sablon::TestCase
  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))
    @output_path = @base_path + "sandbox/recipe.docx"
    @template_path = @base_path + "fixtures/recipe_template.docx"
    @localized_template_path = @base_path + "fixtures/recipe_template_it.docx"
    @sample_path = @base_path + "fixtures/recipe_sample.docx"
    @context_path = @base_path + "fixtures/recipe_context.json"
    @executable_path = @base_path + '../exe/sablon'
    @output_path.delete if @output_path.exist?
  end

  def test_generate_document_from_template_output_to_file
    `cat #{@context_path} | #{@executable_path} #{@template_path} #{@output_path}`

    assert_docx_equal @sample_path, @output_path
  end

  def test_generate_document_from_localized_template_output_to_file
    `cat #{@context_path} | #{@executable_path} #{@localized_template_path} #{@output_path}`

    assert $?.success?, "Expected executable to succeed"

    document_xml = docx_entry(@output_path, 'word/document.xml')
    assert_includes document_xml, 'w:val="Numeroelenco"'
    assert_includes document_xml, 'w:val="Puntoelenco"'
  end

  def test_generate_document_from_template_output_to_stdout
    `cat #{@context_path} | #{@executable_path} #{@template_path} > #{@output_path}`

    assert_docx_equal @sample_path, @output_path
  end

  private

  def docx_entry(path, entry_name)
    Zip::File.open(path) do |zip|
      zip.find_entry(entry_name).get_input_stream.read
    end
  end
end
