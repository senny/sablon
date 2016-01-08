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
      attr_accessor :style, :runs
      def initialize(style, runs)
        @style, @runs = style, runs
      end

      PATTERN = <<-XML.gsub("\n", "")
<w:p>
<w:pPr>
<w:pStyle w:val="%s" />
%s
</w:pPr>
%s
</w:p>
XML

      def to_docx
        PATTERN % [style, ppr_docx, runs.to_docx]
      end

      def accept(visitor)
        super
        runs.accept(visitor)
      end

      def inspect
        "<Paragraph{#{style}}: #{runs.inspect}>"
      end

      private
      def ppr_docx
      end
    end

    class ListParagraph < Paragraph
      LIST_STYLE = <<-XML.gsub("\n", "")
<w:numPr>
<w:ilvl w:val="%s" />
<w:numId w:val="%s" />
</w:numPr>
XML
      attr_accessor :numid, :ilvl
      def initialize(style, runs, numid, ilvl)
        super style, runs
        @numid = numid
        @ilvl = ilvl
      end

      private
      def ppr_docx
        LIST_STYLE % [@ilvl, numid]
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
