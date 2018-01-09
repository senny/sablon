require 'sablon/document_object_model/model'

module Sablon
  class Template
    attr_reader :document

    def initialize(path)
      @path = path
      @document = Sablon::DOM::Model.new(Zip::File.open(@path))
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
      # initialize environment
      env = Sablon::Environment.new(self, context)
      #
      # process files
      process(%r{word/document.xml}, env, properties)
      process(%r{word/(?:header|footer)\d*\.xml}, env)
      process(%r{word/numbering.xml}, env)
      #
      content = @document.zip_contents['word/_rels/document.xml.rels']
      env.relationship.add_found_relationships(content)
      #
      Zip::OutputStream.write_buffer(StringIO.new) do |out|
        generate_output_file(out, @document.zip_contents)
      end
    end

    def get_processor(entry_name)
      if entry_name == 'word/document.xml'
        Processor::Document
      elsif entry_name =~ %r{word/(?:header|footer)\d*\.xml}
        Processor::Document
      elsif entry_name == 'word/numbering.xml'
        Processor::Numbering
      end
    end

    def process(entry_pattern, env, *args)
      @document.zip_contents.each do |entry_name, content|
        next unless entry_name =~ entry_pattern
        @document.current_entry = entry_name
        processor = get_processor(entry_name)
        processor.process(content, env, *args)
      end
    end

    # IMPORTANT: Open Office does not ignore whitespace around tags.
    # We need to render the xml without indent and whitespace.
    def generate_output_file(zip_out, contents)
      # output entries to zip file
      created_dirs = []
      contents.each do |entry_name, content|
        create_dirs_in_zipfile(created_dirs, File.dirname(entry_name), zip_out)
        zip_out.put_next_entry(entry_name)
        #
        # convert Nokogiri XML to string
        if content.instance_of? Nokogiri::XML::Document
          content = content.to_xml(indent: 0, save_with: 0)
        end
        #
        zip_out.write(content)
      end
    end

    # creates directories of the unzipped docx file in the newly created
    # docx file e.g. in case of word/_rels/document.xml.rels it creates
    # word/ and _rels directories to apply recursive zipping. This is a
    # hack to fix the issue of getting a corrupted file when any referencing
    # between the xml files happen like in the case of implementing hyperlinks.
    # The created_dirs array is augmented in place using '<<'
    def create_dirs_in_zipfile(created_dirs, entry_path, output_stream)
      entry_path_tokens = entry_path.split('/')
      return created_dirs unless entry_path_tokens.length > 1
      #
      prev_dir = ''
      entry_path_tokens.each do |dir_name|
        prev_dir += dir_name + '/'
        next if created_dirs.include? prev_dir
        #
        output_stream.put_next_entry(prev_dir)
        created_dirs << prev_dir
      end
    end
  end
end
