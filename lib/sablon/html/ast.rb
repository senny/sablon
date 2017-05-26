require "sablon/html/ast_builder"

module Sablon
  class HTMLConverter
    # A top level abstract class to handle common logic for all AST nodes
    class Node
      PROPERTIES = [].freeze

      def self.node_name
        @node_name ||= name.split('::').last
      end

      # Returns a hash defined on the configuration object by default. However,
      # this method can be overridden by subclasses to return a different
      # node's style conversion config (i.e. :run) or a hash unrelated to the
      # config itself. The config object is used for all built-in classes to
      # allow for end-user customization via the configuration object
      def self.style_conversion
        # converts camelcase to underscored
        key = node_name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
        Sablon::Configuration.instance.defined_style_conversions.fetch(key, {})
      end

      # maps the CSS style property to it's OpenXML equivalent. Not all CSS
      # properties have an equivalent, nor share the same behavior when
      # defined on different node types (Paragraph, Table and Run).
      def self.process_properties(properties)
        # process the styles as a hash and store values
        style_attrs = {}
        properties.each do |key, value|
          unless key.is_a? Symbol
            key, value = *convert_style_property(key.strip, value.strip)
          end
          style_attrs[key] = value if key
        end
        style_attrs
      end

      # handles conversion of a single attribute allowing recursion through
      # super classes. If the key exists and conversion is succesful a
      # symbol is returned to avoid conflicts with a CSS prop sharing the
      # same name. Keys without a conversion class are returned as is
      def self.convert_style_property(key, value)
        if style_conversion.key?(key)
          key, value = style_conversion[key].call(value)
          key = key.to_sym if key
          [key, value]
        elsif self == Node
          [key, value]
        else
          superclass.convert_style_property(key, value)
        end
      end

      def initialize(_env, _node, _properties)
        @properties ||= nil
        @attributes ||= {}
      end

      def accept(visitor)
        visitor.visit(self)
      end

      # Simplifies usage at call sites by only requiring them to supply
      # the tag name to use and any child AST nodes to render
      def to_docx(tag)
        prop_str = @properties.to_docx if @properties
        #
        "<#{tag}#{attributes_to_docx}>#{prop_str}#{children_to_docx}</#{tag}>"
      end

      private

      # Simplifies usage at call sites
      def transferred_properties
        @properties.transferred_properties
      end

      # Gracefully handles conversion of an attributes hash into a
      # string
      def attributes_to_docx
        return '' if @attributes.nil? || @attributes.empty?
        ' ' + @attributes.map { |k, v| %(#{k}="#{v}") }.join(' ')
      end

      # Acts like an abstract method allowing subclases full flexibility to
      # define any content inside the tags.
      def children_to_docx
        ''
      end
    end

    # Manages the properties for an AST node
    class NodeProperties
      attr_reader :transferred_properties

      def self.paragraph(properties)
        new('w:pPr', properties, Paragraph::PROPERTIES)
      end

      def self.run(properties)
        new('w:rPr', properties, Run::PROPERTIES)
      end

      def initialize(tagname, properties, whitelist)
        @tagname = tagname
        filter_properties(properties, whitelist)
      end

      def inspect
        @properties.map { |k, v| v ? "#{k}=#{v}" : k }.join(';')
      end

      def [](key)
        @properties[key]
      end

      def []=(key, value)
        @properties[key] = value
      end

      def to_docx
        "<#{@tagname}>#{properties_word_ml}</#{@tagname}>" unless @properties.empty?
      end

      private

      # processes properties adding those on the whitelist to the
      # properties instance variable and those not to the transferred_properties
      # isntance variable
      def filter_properties(properties, whitelist)
        @transferred_properties = {}
        @properties = {}
        #
        properties.each do |key, value|
          if whitelist.include? key.to_s
            @properties[key] = value
          else
            @transferred_properties[key] = value
          end
        end
      end

      # processes attributes defined on the node into wordML property syntax
      def properties_word_ml
        @properties.map { |k, v| transform_attr(k, v) }.join
      end

      # properties that have a list as the value get nested in tags and
      # each entry in the list is transformed. When a value is a hash the
      # keys in the hash are used to explicitly build the XML tag attributes.
      def transform_attr(key, value)
        if value.is_a? Array
          sub_attrs = value.map do |sub_prop|
            sub_prop.map { |k, v| transform_attr(k, v) }
          end
          "<w:#{key}>#{sub_attrs.join}</w:#{key}>"
        elsif value.is_a? Hash
          props = value.map { |k, v| format('w:%s="%s"', k, v) if v }
          "<w:#{key} #{props.compact.join(' ')} />"
        else
          value = format('w:val="%s" ', value) if value
          "<w:#{key} #{value}/>"
        end
      end
    end

    # A container for an array of AST nodes with convenience methods to
    # work with the internal array as if it were a regular node
    class Collection < Node
      attr_reader :nodes
      def initialize(nodes)
        @properties ||= nil
        @attributes ||= {}
        @nodes = nodes
      end

      def accept(visitor)
        super
        @nodes.each do |node|
          node.accept(visitor)
        end
      end

      def to_docx
        nodes.map(&:to_docx).join
      end

      def inspect
        "[#{nodes.map(&:inspect).join(', ')}]"
      end
    end

    # Stores all of the AST nodes from the current fragment of HTML being
    # parsed
    class Root < Collection
      def initialize(env, node)
        # strip text nodes from the root level element, these are typically
        # extra whitespace from indenting the markup
        node.search('./text()').remove

        # convert children from HTML to AST nodes
        super(ASTBuilder.html_to_ast(env, node.children, {}))
      end

      def grep(pattern)
        visitor = GrepVisitor.new(pattern)
        accept(visitor)
        visitor.result
      end

      def inspect
        "<Root: #{super}>"
      end
    end

    # An AST node representing the top level content container for a word
    # document. These cannot be nested within other paragraph elements
    class Paragraph < Node
      PROPERTIES = %w[framePr ind jc keepLines keepNext numPr
                      outlineLvl pBdr pStyle rPr sectPr shd spacing
                      tabs textAlignment].freeze
      attr_accessor :runs

      def initialize(env, node, properties)
        super
        properties = self.class.process_properties(properties)
        @properties = NodeProperties.paragraph(properties)
        #
        trans_props = transferred_properties
        @runs = ASTBuilder.html_to_ast(env, node.children, trans_props)
        @runs = Collection.new(@runs)
      end

      def to_docx
        super('w:p')
      end

      def accept(visitor)
        super
        runs.accept(visitor)
      end

      def inspect
        "<Paragraph{#{@properties[:pStyle]}}: #{runs.inspect}>"
      end

      private

      def children_to_docx
        runs.to_docx
      end
    end

    # Manages the child nodes of a list type tag
    class List < Collection
      def initialize(env, node, properties)
        # intialize values
        @list_tag = node.name
        #
        @definition = nil
        if node.ancestors(".//#{@list_tag}").length.zero?
          # Only register a definition when upon the first list tag encountered
          @definition = env.numbering.register(properties[:pStyle])
        end

        # update attributes of all child nodes
        transfer_node_attributes(node.children, node.attributes)

        # Move any list tags that are a child of a list item up one level
        process_child_nodes(node)

        # strip text nodes from the list level element, this is typically
        # extra whitespace from indenting the markup
        node.search('./text()').remove

        # convert children from HTML to AST nodes
        super(ASTBuilder.html_to_ast(env, node.children, properties))
      end

      def inspect
        "<List: #{super}>"
      end

      private

      # handles passing all attributes on the parent down to children
      def transfer_node_attributes(nodes, attributes)
        nodes.each do |child|
          # update all attributes
          merge_attributes(child, attributes)

          # set attributes specific to list items
          if @definition
            child['pStyle'] = @definition.style
            child['numId'] = @definition.numid
          end
          child['ilvl'] = child.ancestors(".//#{@list_tag}").length - 1
        end
      end

      # merges parent and child attributes together, preappending the parent's
      # values to allow the child node to override it if the value is already
      # defined on the child node.
      def merge_attributes(child, parent_attributes)
        parent_attributes.each do |name, par_attr|
          child_attr = child[name] ? child[name].split(';') : []
          child[name] = par_attr.value.split(';').concat(child_attr).join('; ')
        end
      end

      # moves any list tags that are a child of a list item tag up one level
      # so they become a sibling instead of a child
      def process_child_nodes(node)
        node.xpath("./li/#{@list_tag}").each do |list|
          # transfer attributes from parent now because the list tag will
          # no longer be a child and won't inheirit them as usual
          transfer_node_attributes(list.children, list.parent.attributes)
          list.parent.add_next_sibling(list)
        end
      end
    end

    # Sets list item specific attributes registered on the node to properly
    # generate a list paragraph
    class ListParagraph < Paragraph
      def initialize(env, node, properties)
        list_props = {
          pStyle: node['pStyle'],
          numPr: [{ ilvl: node['ilvl'] }, { numId: node['numId'] }]
        }
        properties = properties.merge(list_props)
        super
      end

      private

      def transferred_properties
        super
      end
    end

    # Create a run of text in the document, runs cannot be nested within
    # each other
    class Run < Node
      PROPERTIES = %w[b i caps color dstrike emboss imprint highlight outline
                      rStyle shadow shd smallCaps strike sz u vanish
                      vertAlign].freeze

      def initialize(_env, node, properties)
        super
        properties = self.class.process_properties(properties)
        @properties = NodeProperties.run(properties)
        @string = node.to_s # using `text` doesn't reconvert HTML entities
      end

      def to_docx
        super('w:r')
      end

      def inspect
        "<Run{#{@properties.inspect}}: #{@string}>"
      end

      private

      def children_to_docx
        content = @string.tr("\u00A0", ' ')
        "<w:t xml:space=\"preserve\">#{content}</w:t>"
      end
    end

    # Creates a blank line in the word document
    class Newline < Run
      def initialize(*)
        @properties = nil
        @attributes = {}
      end

      def inspect
        "<Newline>"
      end

      private

      def children_to_docx
        "<w:br/>"
      end
    end
  end
end
