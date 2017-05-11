module Sablon
  class HTMLConverter
    class Node
      def accept(visitor)
        visitor.visit(self)
      end

      def self.node_name
        @node_name ||= name.split('::').last
      end

      private

      # processes attributes defined on the node into wordML property syntax
      def process_properties
        properties = []
        @properties.each do |key, value|
          properties.push transform_attr(key, value)
        end
        properties.join
      end

      def transform_attr(key, value)
        # attributes that have bracketed values get nested in tags
        if value.is_a? Array
          sub_attrs = value.map do |sub_prop|
            sub_prop.map { |k, v| transform_attr(k, v)}
          end
          "<w:#{key}>#{sub_attrs.join}</w:#{key}>"
        else
          format('<w:%s w:val="%s" />', key, value)
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
        @properties = properties
        @runs = runs
      end

      def to_docx
        "<w:p><w:pPr>#{ppr_docx}</w:pPr>#{runs.to_docx}</w:p>"
      end

      def accept(visitor)
        super
        runs.accept(visitor)
      end

      def inspect
        "<Paragraph{#{@properties['pStyle']}}: #{runs.inspect}>"
      end

      private

      def ppr_docx
        process_properties
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
