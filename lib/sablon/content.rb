module Sablon
  module Content
    class String < Struct.new(:string)
      include Sablon::Content

      def append_to(node)
        string.scan(/[^\n]+|\n/).reverse.each do |part|
          if part == "\n"
            node.add_next_sibling Nokogiri::XML::Node.new "w:br", node.document
          else
            text_part = node.dup
            text_part.content = part
            node.add_next_sibling text_part
          end
        end
      end
    end

    class WordML < Struct.new(:xml)
      include Sablon::Content

      def append_to(node)
        Nokogiri::XML.fragment(xml).children.reverse.each do |child|
          node.add_next_sibling child
        end
      end
    end
  end
end
