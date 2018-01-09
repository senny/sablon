module Sablon
  # Adds new relationships to the entry's corresponding relionships file
  class Relationship
    attr_accessor :relationships

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
