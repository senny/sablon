module Sablon
  class Template
    def initialize(path)
      @path = path
    end

    # Same as +render_to_string+ but writes the processed template to +output_path+.
    def render_to_file(output_path, context, properties = {})
      File.open(output_path, 'wb') do |f|
        f.write render_to_string(context, properties)
      end
    end

    # Process the template. The +context+ hash will be available in the template.
    def render_to_string(context, properties = {})
      render(context, properties).string
    end

    private
    def render(context, properties = {})
      Sablon::Numbering.instance.reset!
      Zip.sort_entries = true # required to process document.xml before numbering.xml
      Zip::OutputStream.write_buffer(StringIO.new) do |out|
        Zip::File.open(@path).each do |entry|
          entry_name = entry.name
          out.put_next_entry(entry_name)
          content = entry.get_input_stream.read
          if entry_name == 'word/document.xml'
            out.write(process(content, context, properties))
          elsif entry_name =~ /word\/header\d*\.xml/ || entry_name =~ /word\/footer\d*\.xml/
            out.write(process(content, context))
          elsif entry_name == 'word/numbering.xml'
            out.write(Processor::Numbering.process(Nokogiri::XML(content)).to_xml(indent: 0, save_with: 0))
          else
            out.write(content)
          end
        end
      end
    end

    # process the sablon xml template with the given +context+.
    #
    # IMPORTANT: Open Office does not ignore whitespace around tags.
    # We need to render the xml without indent and whitespace.
    def process(content, context, *args)
      document = Nokogiri::XML(content)
      Processor.process(document, context, *args).to_xml(indent: 0, save_with: 0)
    end
  end
end
