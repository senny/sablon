module Sablon
  module Content
    class String < Struct.new(:string)
      include Sablon::Content

      def append_to(paragraph, display_node)
        string.scan(/[^\n]+|\n/).reverse.each do |part|
          if part == "\n"
            display_node.add_next_sibling Nokogiri::XML::Node.new "w:br", display_node.document
          else
            text_part = display_node.dup
            text_part.content = part
            display_node.add_next_sibling text_part
          end
        end
      end
    end

    class WordML < Struct.new(:xml)
      include Sablon::Content

      def append_to(paragraph, display_node)
        Nokogiri::XML.fragment(xml).children.reverse.each do |child|
          paragraph.add_next_sibling child
        end
        paragraph.remove
      end
    end
  end
end
