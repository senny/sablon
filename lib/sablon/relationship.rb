module Sablon
  # Handles storing referenced relationships in the document.xml file and writing them
  # down in the document.xml.rels file
  class Relationship

    attr_accessor :relationships

    def initialize
      @relationships = []
    end

    def add_found_relationships(content, output_stream)
      output_stream.put_next_entry('word/_rels/document.xml.rels')
      if @relationships.length > 0
        rels_doc = Nokogiri::XML(content)
        rels_doc_root = rels_doc.root
        node_set = Nokogiri::XML::NodeSet.new(rels_doc)
        @relationships.each do |relationship|
          relationship_tag = "<Relationship#{relationship_attributes(relationship)}/>"
          node_set << Nokogiri::XML.fragment(relationship_tag).children.first
        end

        rels_doc_root.last_element_child.after(node_set)

        output_stream.write(rels_doc.to_xml(indent: 0, save_with: 0))
        @relationships = []
      else
        output_stream.write(content)
      end
    end

    private

    def relationship_attributes(relationship)
      return '' if relationship.nil? || relationship.empty?
      ' ' + relationship.map { |k, v| %(#{k}="#{v}") }.join(' ')
    end

  end
end
