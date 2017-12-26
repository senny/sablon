module Sablon
  # Handles storing referenced relationships in the document.xml file and
  # writing them to the document.xml.rels file
  class Relationship
    attr_accessor :relationships

    def initialize
      @relationships = []
    end

    def add_found_relationships(content, output_stream)
      output_stream.put_next_entry('word/_rels/document.xml.rels')
      #
      unless @relationships.empty?
        rels_doc = Nokogiri::XML(content)
        rels_doc_root = rels_doc.root
        # convert new rels to nodes
        node_set = convert_relationships_to_node_set(rels_doc)
        @relationships = []
        # add new nodes to XML content
        rels_doc_root.last_element_child.after(node_set)
        content = rels_doc.to_xml(indent: 0, save_with: 0)
      end
      #
      output_stream.write(content)
    end

    private

    # Builds a set of Relationship XML nodes from the stored relationships
    def convert_relationships_to_node_set(doc)
      node_set = Nokogiri::XML::NodeSet.new(doc)
      @relationships.each do |relationship|
        rel_tag = "<Relationship#{relationship_attributes(relationship)}/>"
        node_set << Nokogiri::XML.fragment(rel_tag).children.first
      end
      #
      node_set
    end

    # Builds the attribute string for the relationship XML node
    def relationship_attributes(relationship)
      return '' if relationship.nil? || relationship.empty?
      ' ' + relationship.map { |k, v| %(#{k}="#{v}") }.join(' ')
    end
  end
end
