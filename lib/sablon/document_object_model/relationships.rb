require 'pathname'
require 'sablon/document_object_model/file_handler'

module Sablon
  module DOM
    # Adds new relationships to the entry's corresponding relionships file
    class Relationships < FileHandler
      #
      # extends the Model class so it now has an "add_relationship" method
      def self.extend_model(model_klass)
        super do
          #
          # adds a relationship to the rels file for the current entry
          define_method(:add_relationship) do |rel_attr|
            # detemine name of rels file to augment
            rels_name = Relationships.rels_entry_name_for(@current_entry)

            # create the file if needed and update DOM
            create_entry_if_not_exist(rels_name, Relationships.file_template)
            @dom[rels_name].add_relationship(rel_attr)
          end
          #
          # adds file to the /word/media folder without overwriting an
          # existing file
          define_method(:add_media) do |name, data, rel_attr|
            rel_attr[:Target] = "media/#{name}"
            if @zip_contents["word/#{rel_attr[:Target]}"]
              names = @zip_contents.keys.map { |n| File.basename(n) }
              pattern = "^(\\d+)-#{name}"
              max_val = names.collect { |n| n.match(pattern).to_a[1].to_i }.max
              rel_attr[:Target] = "media/#{max_val + 1}-#{name}"
            end
            #
            # add the content to the zip and create the relationship
            @zip_contents["word/#{rel_attr[:Target]}"] = data
            add_relationship(rel_attr)
          end
        end
      end

      def self.file_template
        <<-XML.gsub(/^\s+|\n/, '')
          <?xml version="1.0" encoding="UTF-8"?>
          <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          </Relationships>
        XML
      end

      def self.rels_entry_name_for(entry_name)
        par_dir = Pathname.new(File.dirname(entry_name))
        par_dir.join('_rels', "#{File.basename(entry_name)}.rels").to_s
      end

      # Sets up the class instance to handle new relationships for a document.
      # I only care about tags that have an integer component
      def initialize(xml_node)
        super
        #
        @relationships = xml_node.root
        @max_rid = max_attribute_value('Relationship', 'Id')
      end

      # Finds the maximum value of an attribute by converting it to an
      # integer. Non numeric portions of values are ignored.
      def max_attribute_value(selector, attr_name)
        super(@relationships, selector, attr_name, query_method: :css)
      end

      # adds a new relationship and returns the corresponding rId for it
      def add_relationship(rel_attr)
        rel_attr['Id'] = "rId#{next_rid}"
        @relationships << relationship_tag(rel_attr)
        #
        rel_attr['Id']
      end

      private

      # increments the max rid and returns it
      def next_rid
        @max_rid += 1
      end

      # Builds the relationship WordML tag and returns it
      def relationship_tag(rel_attr)
        attr_str = rel_attr.map { |k, v| %(#{k}="#{v}") }.join(' ')
        "<Relationship #{attr_str}/>"
      end
    end
  end
end
