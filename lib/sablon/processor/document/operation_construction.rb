module Sablon
  module Processor
    class Document
      class OperationConstruction
        def initialize(fields, field_handlers, default_handler)
          @fields = fields
          @field_handlers = field_handlers
          @default_handler = default_handler
          @operations = []
        end

        def operations
          @operations << consume(true) while @fields.any?
          @operations.compact
        end

        def consume(allow_insertion)
          return unless (@field = @fields.shift)
          #
          # step over provided handlers to see if any can process the field
          handler = @field_handlers.detect(proc { @default_handler }) do |fh|
            fh.handles?(@field)
          end
          return if handler.nil?
          #
          # process and return
          handler.build_statement(self, @field, allow_insertion: allow_insertion)
        end

        def consume_block(end_expression)
          start_field = end_field = @field
          while end_field && end_field.expression != end_expression
            consume(false)
            end_field = @field
          end

          unless end_field
            raise TemplateError, "Could not find end field for «#{start_field.expression}». Was looking for «#{end_expression}»"
          end
          Block.enclosed_by(start_field, end_field) if end_field
        end

        # Creates multiple blocks based on the sub expression patterns supplied
        # while searching for the end expression. The start and end fields
        # of adjacent blocks are shared. For example in an if-else-endif
        # block the else field is the end for the if clause block and the
        # start of the else clause block.
        def consume_multi_block(end_expression, *sub_expr_patterns)
          start_field = end_field = @field
          blocks = []
          while end_field && end_field.expression != end_expression
            consume(false)
            break unless (end_field = @field)
            if sub_expr_patterns.any? { |pat| end_field.expression =~ pat }
              blocks << Block.enclosed_by(start_field, end_field)
              start_field = end_field
            end
          end

          # raise error if no final end field
          unless end_field
            raise TemplateError, "Could not find end field for «#{start_field.expression}». Was looking for «#{end_expression}»"
          end

          # add final block and return
          blocks << Block.enclosed_by(start_field, end_field)
        end
      end
    end
  end
end
