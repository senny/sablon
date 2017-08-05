module Sablon
  class HTMLConverter
    # Converts a nokogiri HTML fragment into an equivalent AST structure
    class ASTBuilder
      attr_reader :nodes

      def self.html_to_ast(env, nodes, properties)
        builder = new(env, nodes, properties)
        builder.nodes
      end

      private

      def initialize(env, nodes, properties)
        @env = env
        @nodes = process_nodes(nodes, properties).compact
      end

      # Loops over HTML nodes converting them to their configured AST class
      def process_nodes(html_nodes, properties)
        html_nodes.flat_map do |node|
          # get tags from config
          parent_tag = fetch_tag(node.parent.name) if node.parent.name
          tag = fetch_tag(node.name)

          # check node hierarchy
          validate_structure(parent_tag, tag)

          # merge properties
          local_props = merge_node_properties(node, tag, properties)
          if tag.ast_class
            tag.ast_class.new(@env, node, local_props)
          else
            process_nodes(node.children, local_props)
          end
        end
      end

      # retrieves a HTMLTag instance from the cpermitted_html_tags hash or
      # raises an ArgumentError if the tag is not registered in the hash
      def fetch_tag(tag_name)
        tag_name = tag_name.to_sym
        unless Sablon::Configuration.instance.permitted_html_tags[tag_name]
          raise ArgumentError, "Don't know how to handle HTML tag: #{tag_name}"
        end
        Sablon::Configuration.instance.permitted_html_tags[tag_name]
      end

      # Checking that the current tag is an allowed child of the parent_tag.
      # If the parent tag is nil then a block level tag is required.
      def validate_structure(parent, child)
        if parent.ast_class == Root && child.type == :inline
          msg = "#{child.name} needs to be wrapped in a block level tag."
        elsif parent && !parent.allowed_child?(child)
          msg = "#{child.name} is not a valid child element of #{parent.name}."
        else
          return
        end
        raise ContextError, "Invalid HTML structure: #{msg}"
      end

      # Merges node properties in a sppecifc
      def merge_node_properties(node, tag, parent_properties)
        # Process any styles, defined on the node into a hash
        if node['style']
          style_props = node['style'].split(';').map do |prop|
            prop.split(':').map(&:strip)
          end
          style_props = Hash[style_props]
        else
          style_props = {}
        end
        # allow inline styles to override parent styles passed down
        parent_properties.merge(tag.properties).merge(style_props)
      end
    end
  end
end
