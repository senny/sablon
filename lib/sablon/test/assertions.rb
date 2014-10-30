module Sablon
  module Test
    module Assertions
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
  end
end
