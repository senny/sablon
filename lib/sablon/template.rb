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
      Zip::OutputStream.write_buffer(StringIO.new) do |out|
        Zip::File.open(@path).each do |entry|
          entry_name = entry.name
          out.put_next_entry(entry_name)
          content = entry.get_input_stream.read
          if entry_name == 'word/document.xml'
            out.write(Processor.process(Nokogiri::XML(content), context, properties).to_xml)
          elsif entry_name =~ /word\/header\d*\.xml/ || entry_name =~ /word\/footer\d*\.xml/
            out.write(Processor.process(Nokogiri::XML(content), context).to_xml)
          else
            out.write(content)
          end
        end
      end
    end
  end
end
