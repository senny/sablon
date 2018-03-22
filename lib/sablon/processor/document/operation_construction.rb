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
      end
    end
  end
end
