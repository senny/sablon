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
      created_dirs = []
      relations_file_content = nil
      env = Sablon::Environment.new(self, context)
      Zip.sort_entries = true # required to process document.xml before numbering.xml
      Zip::OutputStream.write_buffer(StringIO.new) do |out|
        Zip::File.open(@path).each do |entry|
          entry_name = entry.name
          created_dirs = create_dirs_in_zipfile(created_dirs, entry_name, out)
          out.put_next_entry(entry_name)
          content = entry.get_input_stream.read
          if entry_name == 'word/document.xml'
            out.write(process(Processor::Document, content, env, properties))
          elsif entry_name =~ /word\/header\d*\.xml/ || entry_name =~ /word\/footer\d*\.xml/
            out.write(process(Processor::Document, content, env))
          elsif entry_name == 'word/numbering.xml'
            out.write(process(Processor::Numbering, content, env))
          elsif entry_name == 'word/_rels/document.xml.rels'
            relations_file_content = content
          else
            out.write(content)
          end
        end
        if relations_file_content
          Sablon::Relationship.instance.add_found_relationships(relations_file_content, out)
        end
      end
    end

    # creates directories of the unzipped docx file in the newly created docx file e.g. in case of
    # word/_rels/document.xml.rels it creates word/ and _rels directories to apply recursive zipping.
    # This is a hack to fix the issue of getting a corrupted file when any referencing between the
    # xml files happen like in the case of implementing hyperlinks
    #
    def create_dirs_in_zipfile(previous_created_dirs, entry_name, output_stream)
      created_dirs = previous_created_dirs
      entry_name_tokens = entry_name.split('/')
      entry_name_tokens.pop()
      if entry_name_tokens.length > 1
        prev_dir = ''
        entry_name_tokens.each do |dir_name|
          prev_dir += dir_name + '/'
          unless created_dirs.include? prev_dir
            output_stream.put_next_entry(prev_dir)
            created_dirs << prev_dir
          end
        end
      end
      created_dirs
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
