module Sablon
  class HTMLConverter
    class Node
      def accept(visitor)
        visitor.visit(self)
      end

      def self.node_name
        @node_name ||= name.split('::').last
      end
    end

    class NodeProperties
      def self.paragraph(properties)
        new('w:pPr', properties)
      end

      def initialize(tagname, properties)
        @tagname = tagname
        @properties = properties
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

      # processes attributes defined on the node into wordML property syntax
      def process
        @properties.map { |k, v| transform_attr(k, v) }.join
      end

      # properties that have a list as the value get nested in tags and
      # each entry in the list is transformed. When a value is a hash the
      # keys in the hash are used to explicitly buld the XML tag attributes.
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

    class TextFormat
      def initialize(bold, italic, underline)
        @bold = bold
        @italic = italic
        @underline = underline
      end

      def inspect
        parts = []
        parts << 'bold' if @bold
        parts << 'italic' if @italic
        parts << 'underline' if @underline
        parts.join('|')
      end

      def to_docx
        styles = []
        styles << '<w:b />' if @bold
        styles << '<w:i />' if @italic
        styles << '<w:u w:val="single"/>' if @underline
        if styles.any?
          "<w:rPr>#{styles.join}</w:rPr>"
        else
          ''
        end
      end

      def self.default
        @default ||= new(false, false, false)
      end

      def with_bold
        TextFormat.new(true, @italic, @underline)
      end

      def with_italic
        TextFormat.new(@bold, true, @underline)
      end

      def with_underline
        TextFormat.new(@bold, @italic, true)
      end
    end

    class Text < Node
      attr_reader :string
      def initialize(string, format)
        @string = string
        @format = format
      end

      def to_docx
        "<w:r>#{@format.to_docx}<w:t xml:space=\"preserve\">#{normalized_string}</w:t></w:r>"
      end

      def inspect
        "<Text{#{@format.inspect}}: #{string}>"
      end

      private
      def normalized_string
        string.tr("\u00A0", ' ')
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
