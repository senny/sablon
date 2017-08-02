require "sablon/html/ast"
require "sablon/html/ast/builder"
require "sablon/html/visitor"

module Sablon
  class HTMLConverter
    # Converts a nokogiri HTML fragment into an equivalent AST structure
    class ASTBuilder2
      def self.html_to_ast(env, nodes)
        new(env, nodes)
      end

      private

      def initialize(env, nodes)
        @env = env
        @nodes = nodes
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

      # Validates that the current tag is permitted, that the structure of
      # the HTML markup is correct and processes the style attribute of the
      # node.
      def prepare_node(node, properties)
        parent_tag = fetch_tag(node.parent.name) if node.parent.name
        tag = fetch_tag(node.name)

        # check node hierarchy
        validate_structure(parent_tag, tag)

        # merge and return updated properties
        ast_class = tag.ast_class || (tag.type == :block ? Paragraph : Run)
        merge_node_properties(node, properties, elm_props, ast_class)
      end

      # Parses the inline style string and returns a hash of properties
      def process_style(style_str)
        return {} unless style_str
        #
        styles = style_str.split(';').map { |pair| pair.split(':') }
        Hash[styles]
      end
    end



    def process(input, env)
      @numbering = env.numbering
      processed_ast(input).to_docx
    end

    def processed_ast(input)
      ast = build_ast(input)
      ast.accept LastNewlineRemoverVisitor.new
      ast
    end

    def build_ast(input)
      doc = Nokogiri::HTML.fragment(input)
      @builder = ASTBuilder.new(doc.children)

      while !@builder.done?
        ast_next_paragraph
      end
      @builder.to_ast
    end

    private

    # Validates that the current tag is permitted, that the structure of
    # the HTML markup is correct and processes the style attribute of the
    # node.
    def prepare_node(node, properties)
      parent_tag = fetch_tag(node.parent.name) if node.parent.name
      tag = fetch_tag(node.name)
      # check node hierarchy
      validate_structure(parent_tag, tag)
      #
      # I'll need to figure out how to transfer the ul/ol style down to the li
      # tag now that I will be using a config module. Creating a List Collection
      # in the AST file might be the best route using the allowed children
      # to whitelist content.
      elm_props = tag.properties
      if node.name == 'li'
        elm_props[:pStyle] = @definition.style if @definition
        elm_props[:numPr] = [
          { 'ilvl' => @builder.ilvl },
          { 'numId' => @definition.numid }
        ]
      elsif node.name =~ /ul|ol/
        merge_node_attributes(node, node.parent.attributes) if parent_tag.name == :li
        merge_node_attributes(node, node.attributes)
      end
      #
      # merge and return updated properties
      ast_class = tag.ast_class || (tag.type == :block ? Paragraph : Run)
      merge_node_properties(node, properties, elm_props, ast_class)
    end

    def merge_node_properties(node, par_props, elm_props, ast_class)
      # perform an initial conversion for any leftover CSS props passed
      # in from the node's parent
      properties = par_props.map do |k, v|
        ast_class.convert_style_attr(k, v)
      end
      properties = Hash[properties]

      # Process any styles, defined on the node
      properties.merge!(ast_class.process_style(node['style']))

      # Set the element specific attributes, overriding any other values
      properties.merge(elm_props)
    end


    def ast_next_paragraph
      node = @builder.next
      return if node.text?

      properties = prepare_node(node, {})

      # handle special cases
      if node.name =~ /ul|ol/
        @builder.new_layer ilvl: true
        unless @builder.nested?
          @definition = @numbering.register(properties[:pStyle])
        end
        @builder.push_all(node.children)
        return
      end

      # create word_ml node
      @builder.new_layer
      trans_props = Paragraph.transferred_properties(properties)
      @builder.emit Paragraph.new(properties, ast_runs(node.children, trans_props))
    end

    def ast_runs(nodes, properties)
      runs = nodes.flat_map do |node|
        if %w[ul ol].include?(node.name)
          @builder.push(node)
          next nil
        else
          local_props = prepare_node(node, properties)
        end
        #
        if node.text?
          Run.new(local_props, node.text)
        elsif node.name == 'br'
          Newline.new
        else
          ast_runs(node.children, local_props).nodes
        end
      end
      Collection.new(runs.compact)
    end
  end
end
