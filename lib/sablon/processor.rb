module Sablon
  class Processor
    def self.process(xml_node, context, properties = {})
      processor = new(parser)
      processor.manipulate xml_node, context
      processor.write_properties xml_node, properties if properties.any?
      xml_node
    end

    def self.parser
      @parser ||= Sablon::Parser::MailMerge.new
    end

    def initialize(parser)
      @parser = parser
    end

    def manipulate(xml_node, context)
      operations = build_operations(@parser.parse_fields(xml_node))
      operations.each do |step|
        step.evaluate context
      end
      xml_node
    end

    def write_properties(xml_node, properties)
      if properties.key? :start_page_number
        section_properties = SectionProperties.from_document(xml_node)
        section_properties.start_page_number = properties[:start_page_number]
      end
    end

    private
    def build_operations(fields)
      OperationConstruction.new(fields).operations
    end

    class Block < Struct.new(:start_field, :end_field)
      def self.enclosed_by(start_field, end_field)
        @blocks ||= [RowBlock, ParagraphBlock]
        block_class = @blocks.detect { |klass| klass.possible?(start_field) && klass.possible?(end_field) }
        block_class.new start_field, end_field
      end

      def process(context)
        replaced_node = Nokogiri::XML::Node.new("tmp", start_node.document)
        replaced_node.children = Nokogiri::XML::NodeSet.new(start_node.document, body.map(&:dup))
        Processor.process replaced_node, context
        replaced_node.children
      end

      def replace(content)
        content.each { |n| start_node.add_next_sibling n }

        body.each &:remove
        start_node.remove
        end_node.remove
      end

      def body
        return @body if defined?(@body)
        @body = []
        node = start_node
        while (node = node.next_element) && node != end_node
          @body << node
        end
        @body
      end

      def start_node
        @start_node ||= self.class.parent(start_field).first
      end

      def end_node
        @end_node ||= self.class.parent(end_field).first
      end

      def self.possible?(node)
        parent(node).any?
      end
    end

    class RowBlock < Block
      def self.parent(node)
        node.ancestors ".//w:tr"
      end
    end

    class ParagraphBlock < Block
      def self.parent(node)
        node.ancestors ".//w:p"
      end
    end

    class OperationConstruction
      def initialize(fields)
        @fields = fields
        @operations = []
      end

      def operations
        while @fields.any?
          @operations << consume(true)
        end
        @operations.compact
      end

      def consume(allow_insertion)
        @field = @fields.shift
        return unless @field
        case @field.expression
        when /^=/
          if allow_insertion
            Statement::Insertion.new(Expression.parse(@field.expression[1..-1]), @field)
          end
        when /([^ ]+):each\(([^ ]+)\)/
          block = consume_block("#{$1}:endEach")
          Statement::Loop.new(Expression.parse($1), $2, block)
        when /([^ ]+):if/
          block = consume_block("#{$1}:endIf")
          Statement::Condition.new(Expression.parse($1), block)
        end
      end

      def consume_block(end_expression)
        start_field = end_field = @field
        while end_field && end_field.expression != end_expression
          consume(false)
          end_field = @field
        end

        if end_field
          Block.enclosed_by start_field, end_field
        else
          raise "no end field for #{start_field.expression}. Was looking for #{end_expression}"
        end
      end
    end
  end
end
