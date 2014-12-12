# -*- coding: utf-8 -*-
module Sablon
  module Statement
    class Insertion < Struct.new(:expr, :field)
      def evaluate(context)
        field.replace(expr.evaluate(context))
      end
    end

    class Loop < Struct.new(:list_expr, :iterator_name, :block)
      def evaluate(context)
        value = list_expr.evaluate(context)
        raise ContextError, "The expression #{list_expr.inspect} should evaluate to an enumerable but was: #{value.inspect}" unless value.is_a? Enumerable

        content = value.flat_map do |item|
          iteration_context = context.merge(iterator_name => item)
          block.process(iteration_context)
        end
        block.replace(content.reverse)
      end
    end

    class Condition < Struct.new(:conditon_expr, :block, :predicate)
      def evaluate(context)
        value = conditon_expr.evaluate(context)
        if truthy?(predicate ? value.public_send(predicate) : value)
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

      def inspect
        "«#{name}»"
      end
    end

    class LookupOrMethodCall < Struct.new(:receiver_expr, :expression)
      def evaluate(context)
        if receiver = receiver_expr.evaluate(context)
          expression.split(".").inject(receiver) do |local, m|
            ( local[m.to_sym] || local[m.to_s] if local.respond_to?( :[] )    ) ||
            ( local.public_send(m.to_sym)      if local.respond_to?(m.to_sym) )
          end
        end
      end

      def inspect
        "«#{receiver_expr.name}.#{expression}»"
      end
    end

    def self.parse(expression)
      if expression.include?(".")
        parts = expression.split(".")
        LookupOrMethodCall.new(Variable.new(parts.shift), parts.join("."))
      else
        Variable.new(expression)
      end
    end
  end
end
