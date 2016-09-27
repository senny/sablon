# -*- coding: utf-8 -*-
module Sablon
  module Processor
    class Document
      def self.process(xml_node, context, properties = {})
        processor = new(parser)
        processor.manipulate xml_node, Sablon::Context.transform(context)
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
        cleanup(xml_node)
        xml_node
      end

      def write_properties(xml_node, properties)
        if start_page_number = properties[:start_page_number] || properties["start_page_number"]
          section_properties = SectionProperties.from_document(xml_node)
          section_properties.start_page_number = start_page_number
        end
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

      class Block < Struct.new(:start_field, :end_field)
        def self.enclosed_by(start_field, end_field)
          @blocks ||= [ImageBlock, RowBlock, ParagraphBlock, InlineParagraphBlock]
          block_class = @blocks.detect { |klass| klass.encloses?(start_field, end_field) }
          block_class.new start_field, end_field
        end

        def process(context)
          replaced_node = Nokogiri::XML::Node.new("tmp", start_node.document)
          replaced_node.children = Nokogiri::XML::NodeSet.new(start_node.document, body.map(&:dup))
          Processor::Document.process replaced_node, context
          replaced_node.children
        end

        def replace(content)
          content.each { |n| start_node.add_next_sibling n }
          remove_control_elements
        end

        def remove_control_elements
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

        def self.encloses?(start_field, end_field)
          parent(start_field).any? && parent(end_field).any?
        end
      end

      class RowBlock < Block
        def self.parent(node)
          node.ancestors ".//w:tr"
        end

        def self.encloses?(start_field, end_field)
          super && parent(start_field) != parent(end_field)
        end
      end

      class ParagraphBlock < Block
        def self.parent(node)
          node.ancestors ".//w:p"
        end

        def self.encloses?(start_field, end_field)
          super && parent(start_field) != parent(end_field)
        end
      end

      class ImageBlock < ParagraphBlock
        def self.encloses?(start_field, end_field)
          start_field.expression.start_with?('@')
        end

        def replace(content)
          name = content.first.name
          pic_prop = self.class.parent(start_field).at_xpath('.//pic:cNvPr', pic: Sablon::Processor::Image::PICTURE_NS_URI)
          pic_prop.attributes['name'].value = name
          blip = self.class.parent(start_field).at_xpath('.//a:blip', a: Sablon::Processor::Image::MAIN_NS_URI)
          new_rid = Sablon::Processor::Image.list_ids[name.match(/(.*)\.[^.]+$/)[1]]
          blip.attributes['embed'].value = "rId#{new_rid}"
          start_field.remove
          end_field.remove
        end
      end

      class InlineParagraphBlock < Block
        def self.parent(node)
          node.ancestors ".//w:p"
        end

        def remove_control_elements
          body.each &:remove
          start_field.remove
          end_field.remove
        end

        def start_node
          @start_node ||= start_field.end_node
        end

        def end_node
          @end_node ||= end_field.start_node
        end

        def self.encloses?(start_field, end_field)
          super && parent(start_field) == parent(end_field)
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
          when /comment/
            block = consume_block("endComment")
            Statement::Comment.new(block)
          when /^@([^ ]+):start/
            block = consume_block("@#{$1}:end")
            Statement::Image.new(Expression.parse($1), block)
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
