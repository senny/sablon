require 'sablon/document_object_model/file_handler'

module Sablon
  module DOM
    # Provides helpers for resolving Word style metadata.
    class Styles < FileHandler
      def self.extend_model(*)
      end

      def initialize(xml_node)
        @styles = xml_node.root
      end

      def style_id_for_name(name)
        style = @styles.at_xpath("//w:style[w:name[@w:val='#{name}']]")
        style && style['w:styleId']
      end
    end
  end
end
