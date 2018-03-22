module Sablon
  module Processor
    class Document
      # This class is used to setup field handlers to process different
      # merge field expressions based on the expression text. The #handles?
      # and #build_statement methods form the standard FieldHandler API and can
      # be implemented however they are needed to be as long as the call
      # signature stays the same.
      class FieldHandler
        # Used when registering processors. The pattern tells the handler
        # what expression text to search for.
        def initialize(pattern)
          @pattern = pattern
        end

        # Returns a non-nil value if the field expression matches the pattern
        def handles?(field)
          field.expression.match(@pattern)
        end

        # Uses the provided arguments to construct a Statement object.
        # The constructor is an instance of the OperationConstruction class,
        # the field is the current merge field being evaluated and the options
        # hash defines any other parameters passed in during
        # OperationConstruction#consume. Currently the only option passed is
        # `:allow_insertion`.
        def build_statement(constructor, field, options = {}); end
      end

      # Handles simple text insertion
      class InsertionHandler < FieldHandler
        def initialize
          super(/^=/)
        end

        def build_statement(_constructor, field, options = {})
          return unless options[:allow_insertion]
          #
          expr = Expression.parse(field.expression.gsub(/^=/, ''))
          Statement::Insertion.new(expr, field)
        end
      end

      # Handles each loops in the template
      class EachLoopHandler < FieldHandler
        def initialize
          super(/([^ ]+):each\(([^ ]+)\)/)
        end

        def build_statement(constructor, field, _options = {})
          expr_name, item_name = field.expression.match(@pattern).to_a[1..2]
          block = constructor.consume_block("#{expr_name}:endEach")
          Statement::Loop.new(Expression.parse(expr_name), item_name, block)
        end
      end

      # Handles conditional blocks in the template
      class ConditionalHandler < FieldHandler
        def initialize
          super(/([^ ]+):if(?:\(([^)]+)\))?/)
        end

        def build_statement(constructor, field, _options = {})
          expr_name, pred = field.expression.match(@pattern).to_a[1..2]
          block = constructor.consume_block("#{expr_name}:endIf")
          Statement::Condition.new(Expression.parse(expr_name), block, pred)
        end
      end

      # Handles image insertion fields
      class ImageHandler < FieldHandler
        def initialize
          super(/^@([^ ]+):start/)
        end

        def build_statement(constructor, field, _options = {})
          expr_name = field.expression.match(@pattern).to_a[1]
          block = constructor.consume_block("@#{expr_name}:end")
          Statement::Image.new(Expression.parse(expr_name), block)
        end
      end

      # Handles comment blocks in the template
      class CommentHandler < FieldHandler
        def initialize
          super(/^comment$/)
        end

        def build_statement(constructor, _field, _options = {})
          block = constructor.consume_block('endComment')
          Statement::Comment.new(block)
        end
      end
    end
  end
end
