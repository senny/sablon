require 'sablon/processor/document/blocks'

module Sablon
  module Processor
    # This class manages processing of the XML portions of a word document
    # that can contain mailmerge fields
    class Document
      def self.process(xml_node, env)
        processor = new(parser)
        processor.manipulate xml_node, env
      end

      def self.parser
        @parser ||= Sablon::Parser::MailMerge.new
      end

      def initialize(parser)
        @parser = parser
      end

      def manipulate(xml_node, env)
        operations = build_operations(@parser.parse_fields(xml_node))
        operations.each do |step|
          step.evaluate env
        end
        cleanup(xml_node)
        xml_node
      end

      private

      def build_operations(fields)
        OperationConstruction.new(fields).operations
      end

      def cleanup(xml_node)
        fill_empty_table_cells xml_node
      end

      def fill_empty_table_cells(xml_node)
        xml_node.xpath("//w:tc[count(*[name() = 'w:p'])=0 or not(*)]").each do |blank_cell|
          filler = Nokogiri::XML::Node.new("w:p", xml_node.document)
          blank_cell.add_child filler
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
          when /([^ ]+):if\(([^)]+)\)/
            block = consume_block("#{$1}:endIf")
            Statement::Condition.new(Expression.parse($1), block, $2)
          when /([^ ]+):if/
            block = consume_block("#{$1}:endIf")
            Statement::Condition.new(Expression.parse($1), block)
          when /^@([^ ]+):start/
            block = consume_block("@#{$1}:end")
            Statement::Image.new(Expression.parse($1), block)
          when /^comment$/
            block = consume_block("endComment")
            Statement::Comment.new(block)
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
            raise TemplateError, "Could not find end field for «#{start_field.expression}». Was looking for «#{end_expression}»"
          end
        end
      end
    end
  end
end
