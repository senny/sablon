module Sablon
  module Content
    class << self
      def wrap(value)
        case value
        when Sablon::Content
          value
        else
          if type = type_wrapping(value)
            type.new(value)
          else
            raise ArgumentError, "Could not find Sablon content type to wrap #{value.inspect}"
          end
        end
      end

      def make(type_id, *args)
        if types.key?(type_id)
          types[type_id].new(*args)
        else
          raise ArgumentError, "Could not find Sablon content type with id '#{type_id}'"
        end
      end

      def register(content_type)
        types[content_type.id] = content_type
      end

      def remove(content_type_or_id)
        types.delete_if {|k,v| k == content_type_or_id || v == content_type_or_id }
      end

      private
      def type_wrapping(value)
        types.values.reverse.detect { |type| type.wraps?(value) }
      end

      def types
        @types ||= {}
      end
    end

    # Handles simple text replacement of fields in the template
    class String < Struct.new(:string)
      include Sablon::Content
      def self.id; :string end
      def self.wraps?(value)
        value.respond_to?(:to_s)
      end

      def initialize(value)
        super value.to_s
      end

      def append_to(paragraph, display_node, env)
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

    # handles direct addition of WordML to the document template
    class WordML < Struct.new(:xml)
      include Sablon::Content
      def self.id; :word_ml end
      def self.wraps?(value) false end

      def append_to(paragraph, display_node, env)
        Nokogiri::XML.fragment(xml).children.reverse.each do |child|
          paragraph.add_next_sibling child
        end
        paragraph.remove
      end
    end

    # Handles conversion of HTML -> WordML and addition into template
    class HTML < Struct.new(:html_content)
      include Sablon::Content
      def self.id; :html end
      def self.wraps?(value) false end

      def initialize(value)
        super value
      end

      def append_to(paragraph, display_node, env)
        converter = HTMLConverter.new
        word_ml = WordML.new(converter.process(html_content, env))
        word_ml.append_to(paragraph, display_node, env)
      end
    end

    register Sablon::Content::String
    register Sablon::Content::WordML
    register Sablon::Content::HTML
  end
end
