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
        # reading all entries into a hash to prevent doc corruption
        # https://github.com/rubyzip/rubyzip/issues/330
        zip_contents = {}
        Zip::File.open(@path).each do |entry|
          zip_contents[entry.name] = entry.get_input_stream.read
        end
        # get initial rid of all files
        env.relationships.initialize_rids(zip_contents)
        # step through and process each file
        zip_contents.each do |entry_name, content|
          env.current_entry = entry_name
          if entry_name == 'word/document.xml'
            zip_contents[entry_name] = process(Processor::Document, content, env, properties)
          elsif entry_name =~ /word\/header\d*\.xml/ || entry_name =~ /word\/footer\d*\.xml/
            zip_contents[entry_name] = process(Processor::Document, content, env)
          elsif entry_name == 'word/numbering.xml'
            zip_contents[entry_name] = process(Processor::Numbering, content, env)
          elsif entry_name == '[Content_Types].xml'
            zip_contents[entry_name] = process(Processor::ContentType, content)
          end
        end
        # update relationships
        env.relationships.output_new_rids(zip_contents)
        # output updated zip and add images
        zip_contents.each do |entry_name, content|
          out.put_next_entry(entry_name)
          out.write(content)
        end
        env.images.add_images_to_zip!(out)
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
