require "sablon/html/ast_builder"

module Sablon
  class HTMLConverter
    # A top level abstract class to handle common logic for all AST nodes
    class Node
      PROPERTIES = [].freeze
      # styles shared or common logic across all node types go here. Any
      # undefined styles are passed straight through "as is" to the
      # properties hash. Special conversion procs such as :_border can be
      # defined here for reuse across several AST nodes as well. Care must
      # be taken to avoid possible naming conflicts, hence the underscore
      STYLE_CONVERSION = {
        'background-color' => lambda { |v|
          return 'shd', { val: 'clear', fill: v.delete('#') }
        },
        _border: lambda { |v|
          props = { sz: 2, val: 'single', color: '000000' }
          vals = v.split
          vals[1] = 'single' if vals[1] == 'solid'
          #
          props[:sz] = (2 * Float(vals[0].gsub(/[^\d.]/, '')).ceil).to_s if vals[0]
          props[:val] = vals[1] if vals[1]
          props[:color] = vals[2].delete('#') if vals[2]
          #
          return props
        },
        'text-align' => ->(v) { return 'jc', v }
      }.freeze

      def self.node_name
        @node_name ||= name.split('::').last
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
        if self::STYLE_CONVERSION.key?(key)
          key, value = self::STYLE_CONVERSION[key].call(value)
          key = key.to_sym if key
          [key, value]
        elsif self.class == Node
          [key, value]
        else
          superclass.convert_style_property(key, value)
        end
      end

      def accept(visitor)
        visitor.visit(self)
      end

      # Simplifies usage at call sites
      def transferred_properties
        @properties.transferred_properties(self.class::PROPERTIES)
      end
    end

    class NodeProperties
      def self.paragraph(properties)
        new('w:pPr', properties, Paragraph::PROPERTIES)
      end

      def self.run(properties)
        new('w:rPr', properties, Run::PROPERTIES)
      end

      def initialize(tagname, properties, whitelist)
        @tagname = tagname
        @properties = filter(properties, whitelist)
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

      # creates a hash of all properties that aren't consumed by the node
      # so they can be propagated to child nodes
      def transferred_properties(whitelist)
        props = @properties.map do |key, value|
          next if whitelist.include? key.to_s
          [key, value]
        end
        # filter out nils and return hash
        Hash[props.compact]
      end

      def to_docx
        "<#{@tagname}>#{process}</#{@tagname}>" unless @properties.empty?
      end

      private

      def filter(properties, whitelist)
        props = properties.map do |key, value|
          next unless whitelist.include? key.to_s
          [key.to_sym, value]
        end
        # filter out nils and return hash
        Hash[props.compact]
      end

      # processes attributes defined on the node into wordML property syntax
      def process
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

    class Collection < Node
      attr_reader :nodes
      def initialize(nodes)
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

    class Paragraph < Node
      PROPERTIES = %w[framePr ind jc keepLines keepNext numPr
                      outlineLvl pBdr pStyle rPr sectPr shd spacing
                      tabs textAlignment].freeze
      STYLE_CONVERSION = {
        'border' => lambda { |v|
          props = Node::STYLE_CONVERSION[:_border].call(v)
          #
          return 'pBdr', [
            { top: props }, { bottom: props },
            { left: props }, { right: props }
          ]
        },
        'vertical-align' => ->(v) { return 'textAlignment', v }
      }.freeze
      attr_accessor :runs

      def initialize(env, node, properties)
        properties = self.class.process_properties(properties)
        @properties = NodeProperties.paragraph(properties)
        #
        trans_props = transferred_properties
        @runs = ASTBuilder.html_to_ast(env, node.children, trans_props)
        @runs = Collection.new(@runs)
      end

      def to_docx
        "<w:p>#{@properties.to_docx}#{runs.to_docx}</w:p>"
      end

      def accept(visitor)
        super
        runs.accept(visitor)
      end

      def inspect
        "<Paragraph{#{@properties['pStyle']}}: #{runs.inspect}>"
      end
    end

    # Manages the child nodes of a list type tag
    class List < Collection
      def initialize(env, node, properties)
        # intialize values
        @list_tag = node.name
        @definition = env.numbering.register(properties[:pStyle])

        # update attributes of all child nodes
        transfer_node_attributes(node.children, node.attributes)

        # strip text nodes from the list level element, this is typically
        # extra whitespace from indenting the markup
        node.search('./text()').remove

        # convert children from HTML to AST nodes
        super(ASTBuilder.html_to_ast(env, node.children, properties))
      end

      private

      # handles passing all attributes on the parent down to children
      def transfer_node_attributes(nodes, attributes)
        nodes.each do |child|
          # update all attributes
          merge_attributes(child, attributes)

          # set attributes specific to list items
          next unless child.name == 'li'
          child['pStyle'] = @definition.style
          child['ilvl'] = child.ancestors(".//#{@list_tag}").length - 1
          child['numId'] = @definition.numid
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
    end

    # Sets list item specific attributes registered on the node
    class ListParagraph < Paragraph
      def initialize(env, node, properties)
        list_props = {
          pStyle: node['pStyle'],
          numPr: [{ ilvl: node['ilvl'] }, { numId: node['numId'] }]
        }
        properties = properties.merge(list_props)
        super
      end
    end

    # Create a run of text in the document
    class Run < Node
      PROPERTIES = %w[b i caps color dstrike emboss imprint highlight outline
                      rStyle shadow shd smallCaps strike sz u vanish
                      vertAlign].freeze
      STYLE_CONVERSION = {
        'color' => ->(v) { return 'color', v.delete('#') },
        'font-size' => lambda { |v|
          return 'sz', (2 * Float(v.gsub(/[^\d.]/, '')).ceil).to_s
        },
        'font-style' => lambda { |v|
          return 'b', nil if v =~ /bold/
          return 'i', nil if v =~ /italic/
        },
        'font-weight' => ->(v) { return 'b', nil if v =~ /bold/ },
        'text-decoration' => lambda { |v|
          supported = %w[line-through underline]
          props = v.split
          return props[0], 'true' unless supported.include? props[0]
          return 'strike', 'true' if props[0] == 'line-through'
          return 'u', 'single' if props.length == 1
          return 'u', { val: props[1], color: 'auto' } if props.length == 2
          return 'u', { val: props[1], color: props[2].delete('#') }
        },
        'vertical-align' => lambda { |v|
          return 'vertAlign', 'subscript' if v =~ /sub/
          return 'vertAlign', 'superscript' if v =~ /super/
        }
      }.freeze
      attr_reader :string

      def initialize(_env, node, properties)
        properties = self.class.process_properties(properties)
        @properties = NodeProperties.run(properties)
        @string = node.text
      end

      def to_docx
        "<w:r>#{@properties.to_docx}#{text}</w:r>"
      end

      def inspect
        "<Run{#{@properties.inspect}}: #{string}>"
      end

      private

      def text
        content = @string.tr("\u00A0", ' ')
        "<w:t xml:space=\"preserve\">#{content}</w:t>"
      end
    end

    # Creates a blank line in the word document
    class Newline < Node
      def initialize(*); end

      def to_docx
        "<w:r><w:br/></w:r>"
      end

      def inspect
        "<Newline>"
      end
    end
  end
end
