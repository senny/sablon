module Sablon
  class HTMLConverter
    class Node
      PROPERTIES = [].freeze
      # styles shared or common logic across all node types go here. Any
      # undefined styles are passed straight through "as is" to the
      # properties hash. Keys that are symbols will not get called directly
      # when processing the style string and are suitable for internal-only
      # usage across different classes.
      STYLE_CONVERSION = {
        'background-color' => lambda { |v|
          return 'shd', { val: 'clear', fill: v.delete('#') }
        },
        border: lambda { |v|
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
      }
      # This proc is used to allow unmapped styles to pass through
      STYLE_CONVERSION.default_proc = proc do |hash, key|
        ->(v) { return key, v }
      end
      STYLE_CONVERSION.freeze

      def accept(visitor)
        visitor.visit(self)
      end

      # maps the CSS style property to it's OpenXML equivalent. Not all CSS
      # properties have an equivalent, nor share the same behavior when
      # defined on different node types (Paragraph, Table and Run).
      def self.process_style(style_str)
        return {} unless style_str
        #
        styles = style_str.split(';').map { |pair| pair.split(':') }
        # process the styles as a hash and store values
        style_attrs = {}
        Hash[styles].each do |key, value|
          key, value = convert_style_attr(key.strip, value.strip)
          style_attrs[key] = value if key
        end
        style_attrs
      end

      # handles conversion of a single attribute allowing recursion through
      # super classes
      def self.convert_style_attr(key, value)
        if self::STYLE_CONVERSION[key]
          self::STYLE_CONVERSION[key].call(value)
        else
          superclass.convert_style_attr(key, value)
        end
      end

      # Simplifies usage at call sites
      def self.transferred_properties(properties)
        NodeProperties.transferred_properties(properties, self::PROPERTIES)
      end

      def self.node_name
        @node_name ||= name.split('::').last
      end
    end

    class NodeProperties
      def self.paragraph(properties)
        new('w:pPr', properties, Paragraph::PROPERTIES)
      end

      def self.run(properties)
        new('w:rPr', properties, Run::PROPERTIES)
      end

      # creates a hash of all properties that aren't consumed by the node
      # so they can be propagated to child nodes
      def self.transferred_properties(properties, whitelist)
        props = properties.map do |key, value|
          next if whitelist.include? key
          [key, value]
        end
        # filter out nils and return hash
        Hash[props.compact]
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

      def to_docx
        "<#{@tagname}>#{process}</#{@tagname}>" unless @properties.empty?
      end

      private

      def filter(properties, whitelist)
        props = properties.map do |key, value|
          next unless whitelist.include? key
          [key, value]
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
          props = Node::STYLE_CONVERSION[:border].call(v)
          #
          return 'pBdr', [
            { top: props }, { bottom: props },
            { left: props }, { right: props }
          ]
        },
        'vertical-align' => ->(v) { return 'textAlignment', v }
      }.freeze
      attr_accessor :runs

      def initialize(properties, runs)
        @properties = NodeProperties.paragraph(properties)
        @runs = runs
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

      def initialize(properties, string)
        @properties = NodeProperties.run(properties)
        @string = string
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

    class Newline < Node
      def to_docx
        "<w:r><w:br/></w:r>"
      end

      def inspect
        "<Newline>"
      end
    end
  end
end
