module Sablon
  module Statement
    class Insertion < Struct.new(:expr, :field)
      def evaluate(context)
        field.replace(expr.evaluate(context))
      end
    end

    class Loop < Struct.new(:list_expr, :iterator_name, :block)
      def evaluate(context)
        content = list_expr.evaluate(context).flat_map do |item|
          iteration_context = context.merge(iterator_name => item)
          block.process(iteration_context)
        end
        block.replace(content.reverse)
      end
    end

    class Condition < Struct.new(:conditon_expr, :block)
      def evaluate(context)
        if truthy?(conditon_expr.evaluate(context))
          block.replace(block.process(context).reverse)
        else
          block.replace([])
        end
      end

      def truthy?(value)
        case value
        when Array;
          !value.empty?
        else
          !!value
        end
      end
    end
  end

  module Expression
    class Variable < Struct.new(:name)
      def evaluate(context)
        context[name]
      end
    end

    class SimpleMethodCall < Struct.new(:receiver, :method)
      def evaluate(context)
        receiver.evaluate(context).public_send method
      end
    end

    def self.parse(expression)
      if expression.include?(".")
        parts = expression.split(".")
        SimpleMethodCall.new(Variable.new(parts.first), parts.last)
      else
        Variable.new(expression)
      end
    end
  end
end
