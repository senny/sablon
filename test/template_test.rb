# frozen_string_literal: true

require "test_helper"

class SablonTemplateTest < Sablon::TestCase
  def setup
    super
    @template_path = File.expand_path("fixtures/loops_template.docx", File.dirname(__FILE__))
    @rendered_document = Sablon.template(template_path).render_to_string(
      fruits: [{ name: "Piña" }],
      cars: [{ name: "Camión" }]
    ).b
  end

  def test_small_entries_do_not_use_zip64_in_local_or_central_headers
    headers.each do |header|
      refute_includes extra_field_ids(header[:extra]), 0x0001,
                      "Unexpected ZIP64 extra field in #{header[:description]}"
    end
  end

  def test_small_entries_only_require_zip_version_20
    headers.each do |header|
      assert_equal 20, header[:version],
                   "Unexpected version needed to extract in #{header[:description]}"
    end
  end

  def test_rendering_preserves_multibyte_text_and_binary_entries
    Zip::File.open_buffer(StringIO.new(rendered_document)) do |output|
      text = Nokogiri::XML(output.read("word/document.xml")).text
      assert_includes text, "Piña"
      assert_includes text, "Camión"

      Zip::File.open(template_path) do |input|
        binary_entries = input.entries.select do |entry|
          entry.file? && entry.name !~ /\.(xml|rels)$/
        end
        refute_empty binary_entries

        binary_entries.each do |entry|
          assert_equal input.read(entry.name).b, output.read(entry.name).b, entry.name
        end
      end
    end
  end

  private

  attr_reader :template_path, :rendered_document

  # XML comparisons discard the ZIP metadata that affects document-reader compatibility.
  def headers
    result = []
    end_offset = rendered_document.rindex("PK\x05\x06".b)
    central_offset = rendered_document.byteslice(end_offset + 16, 4).unpack('V').first

    Zip::File.open_buffer(StringIO.new(rendered_document)) do |zip|
      zip.each do |entry|
        local_offset = entry.local_header_offset
        assert_equal "PK\x03\x04".b, rendered_document.byteslice(local_offset, 4)
        name_size, extra_size = rendered_document.byteslice(local_offset + 26, 4).unpack('vv')
        result << {
          description: "local header for #{entry.name}",
          version: rendered_document.byteslice(local_offset + 4, 2).unpack('v').first,
          extra: rendered_document.byteslice(local_offset + 30 + name_size, extra_size)
        }

        assert_equal "PK\x01\x02".b, rendered_document.byteslice(central_offset, 4)
        name_size, extra_size, comment_size = rendered_document.byteslice(central_offset + 28, 6).unpack('vvv')
        result << {
          description: "central header for #{entry.name}",
          version: rendered_document.byteslice(central_offset + 6, 2).unpack('v').first,
          extra: rendered_document.byteslice(central_offset + 46 + name_size, extra_size)
        }
        central_offset += 46 + name_size + extra_size + comment_size
      end
    end
    result
  end

  def extra_field_ids(data)
    ids = []
    offset = 0
    while offset < data.bytesize
      id, size = data.byteslice(offset, 4).unpack('vv')
      ids << id
      offset += 4 + size
    end
    ids
  end
end
