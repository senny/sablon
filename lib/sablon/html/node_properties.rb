module Sablon
  class HTMLConverter
    # Manages the properties for an AST node, includes factory methods
    # for easy use at calling sites.
    class NodeProperties
      attr_reader :transferred_properties

      def self.paragraph(properties)
        new('w:pPr', properties, Paragraph::PROPERTIES)
      end

      def self.table(properties)
        new('w:tblPr', properties, Table::PROPERTIES)
      end

      def self.table_row(properties)
        new('w:trPr', properties, TableRow::PROPERTIES)
      end

      def self.table_cell(properties)
        new('w:tcPr', properties, TableCell::PROPERTIES)
      end

      def self.run(properties)
        new('w:rPr', properties, Run::PROPERTIES)
      end

      def initialize(tagname, properties, whitelist)
        @tagname = tagname
        filter_properties(properties, whitelist)
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
        "<#{@tagname}>#{properties_word_ml}</#{@tagname}>" unless @properties.empty?
      end

      private

      # processes properties adding those on the whitelist to the
      # properties instance variable and those not to the transferred_properties
      # isntance variable
      def filter_properties(properties, whitelist)
        @transferred_properties = {}
        @properties = {}
        #
        properties.each do |key, value|
          if whitelist.include? key.to_s
            @properties[key] = value
          else
            @transferred_properties[key] = value
          end
        end
      end

      # processes attributes defined on the node into wordML property syntax
      def properties_word_ml
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
  end
end
