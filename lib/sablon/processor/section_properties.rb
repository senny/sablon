module Sablon
  module Processor
    class SectionProperties
      def self.from_document(document_xml)
        new document_xml.at_xpath(".//w:sectPr")
      end

      def initialize(properties_node)
        @properties_node = properties_node
      end

      def start_page_number
        pg_num_type && pg_num_type["w:start"]
      end

      def start_page_number=(number)
        find_or_add_pg_num_type["w:start"] = number
      end

      private
      def find_or_add_pg_num_type
        pg_num_type || begin
                         node = Nokogiri::XML::Node.new "w:pgNumType", @properties_node.document
                         @properties_node.children.after node
                         node
                       end
      end

      def pg_num_type
        @pg_num_type ||= @properties_node.at_xpath(".//w:pgNumType")
      end
    end
  end
end
