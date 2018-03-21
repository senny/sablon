module Sablon
  module Processor
    class Document
      class OperationConstruction
        def initialize(fields)
          @fields = fields
          @operations = []
        end

        def operations
          @operations << consume(true) while @fields.any?
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

          unless end_field
            raise TemplateError, "Could not find end field for «#{start_field.expression}». Was looking for «#{end_expression}»"
          end
          Block.enclosed_by(start_field, end_field) if end_field
        end
      end
    end
  end
end
