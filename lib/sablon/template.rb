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
      env = Sablon::Environment.new(self, context)
      Zip.sort_entries = true # required to process document.xml before numbering.xml
      Zip::OutputStream.write_buffer(StringIO.new) do |out|
        Sablon::Processor::Image.add_images_to_zip!(context, out)
        Zip::File.open(@path).each do |entry|
          entry_name = entry.name
          out.put_next_entry(entry_name)
          content = entry.get_input_stream.read
          if entry_name == 'word/document.xml'
            out.write(process(Processor::Document, content, env, properties))
          elsif entry_name =~ /word\/header\d*\.xml/ || entry_name =~ /word\/footer\d*\.xml/
            out.write(process(Processor::Document, content, env))
          elsif entry_name == 'word/numbering.xml'
            out.write(process(Processor::Numbering, content, env))
          elsif entry_name == 'word/_rels/document.xml.rels'
            out.write(process(Processor::Image, content, properties, out))
          elsif entry_name == '[Content_Types].xml'
            out.write(process(Processor::ContentType, content, properties, out))
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
    def process(processor, content, *args)
      document = Nokogiri::XML(content)
      processor.process(document, *args).to_xml(indent: 0, save_with: 0)
    end
  end
end
