# -*- coding: utf-8 -*-
require "test_helper"

class SablonTest < Sablon::TestCase
  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))
    @output_path = @base_path + "sandbox/sablon.docx"
  end

  def test_generate_document_from_template
    template = Sablon.template(@base_path + "fixtures/sablon_template.docx")
    person = OpenStruct.new "first_name" => "Ronald", "last_name" => "Anderson"
    item = Struct.new(:index, :label, :rating)
    position = Struct.new(:duration, :label, :description)
    language = Struct.new(:name, :skill)
    context = {
      "title" => "Letter of application",
      "person" => person,
      "items" => [item.new("1.", "Ruby", "★" * 5), item.new("2.", "Java", "★" * 1), item.new("3.", "Python", "★" * 3)],
      "career" => [position.new("1999 - 2006", "Junior Java Engineer", "Lorem ipsum dolor\nsit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."),
                   position.new("2006 - 2013", "Senior Ruby Developer", "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.")],
      "technologies" => ["HTML", "CSS", "SASS", "LESS", "JavaScript"],
      "languages" => [language.new("German", "native speaker"), language.new("English", "fluent")],
      "training" => "At vero eos et accusam et justo duo dolores et ea rebum.\n\nStet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
    }
    properties = {
      start_page_number: 7
    }
    template.render_to_file @output_path, context, properties

    assert_docx_equal @base_path + "fixtures/sablon_sample.docx", @output_path
  end

  private
  def assert_docx_equal(expected_path, actual_path)
    if get_document_xml(expected_path) != get_document_xml(actual_path)
      msg = <<-error
The generated document does not match the sample. Please investigate.

If the generated document is correct, the sample needs to be updated:
\t cp #{actual_path} #{expected_path}
      error
      fail msg
    end
  end

  def get_document_xml(path)
    document_xml_entry = Zip::File.open(path).get_entry("word/document.xml")
    document_xml_entry.get_input_stream.read
  end
end
