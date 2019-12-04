module Sablon
  module Test
    module Assertions
      def assert_docx_equal(expected_path, actual_path)
        #
        # Parse document archives and generate a diff
        xml_diffs = diff_docx_files(expected_path, actual_path)
        #
        # build error message
        msg = 'The generated document does not match the sample. Please investigate file(s): '
        msg += xml_diffs.keys.sort.join(', ')
        xml_diffs.each do |name, diff_text|
          msg += "\n#{'-' * 72}\nFile: #{name}\n#{diff_text}\n"
        end
        msg += '-' * 72 + "\n"
        msg += "If the generated document is correct, the sample needs to be updated:\n"
        msg += "\t cp #{actual_path} #{expected_path}"
        #
        raise Minitest::Assertion, msg unless xml_diffs.empty?
      end


          # Returns a hash of all XML files that differ in the docx file. This
          # only checks files that have the extension ".xml" or ".rels".
          def diff_docx_files(expected_path, actual_path)
            expected = parse_docx(expected_path)
            actual = parse_docx(actual_path)
            xml_diffs = {}
            #
            expected.each do |entry_name, expect|
              next unless entry_name =~ /.xml$|.rels$/
              next unless expect != actual[entry_name]
              #
              xml_diffs[entry_name] = diff(expect, actual[entry_name])
            end
            #
            xml_diffs
          end

          private

          def parse_docx(path)
            contents = {}
            #
            # step over all entries adding them to the hash to diff against
            Zip::File.open(path).each do |entry|
              next unless entry.file?
              content = entry.get_input_stream.read
              # normalize xml content
              if entry.name =~ /.xml$|.rels$/
                content = Nokogiri::XML(content).to_xml(indent: 2)
              end
              contents[entry.name] = content
            end
            #
            contents
          end
    end
  end
end
