module Sablon
  module Processor
    class SectionProperties
      def self.process(xml_node, env)
        processor = new(xml_node)
        processor.write_properties(env.section_properties)
      end

      def initialize(xml_node)
        @properties_node = xml_node.at_xpath(".//w:sectPr")
      end

      def write_properties(properties)
        return unless properties["start_page_number"]
        find_or_add_pg_num_type["w:start"] = properties["start_page_number"]
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
