require 'pathname'

module Sablon
  module DOM
    # Adds new relationships to the entry's corresponding relionships file
    class Relationships
      #
      # extends the Model class so it now has an "add_relationship" method
      def self.extend_model(model_klass)
        model_klass.instance_eval do
          #
          # determines the proper rels file based on the entry name
          define_method(:fetch_rels_file) do |entry|
            par_dir = Pathname.new(File.dirname(entry))
            par_dir.join('_rels', "#{File.basename(entry)}.rels").to_s
          end
          #
          # adds a relationship to the rels file for the current entry
          define_method(:add_relationship) do |rel_attr|
            rels_entry = fetch_rels_file(@current_entry)
            # this wil fail if the rels file doesn't exist yet
            @dom[rels_entry].add_relationship(rel_attr)
          end
        end
      end

      # Sets up the class instance to handle new relationships for a document.
      # I only care about tags that have an integer component
      def initialize(xml_node)
        @relationships = xml_node.root
        @max_rid = @relationships.css('Relationship').inject(0) do |max, node|
          next max unless (match = node.attr(:Id).match(/rId(\d+)/))
          [max, match[1].to_i].max
        end
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
