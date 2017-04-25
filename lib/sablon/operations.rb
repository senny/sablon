# -*- coding: utf-8 -*-
module Sablon
  module Statement
    class Insertion < Struct.new(:expr, :field)
      def evaluate(env)
        if content = expr.evaluate(env.context)
          field.replace(Sablon::Content.wrap(content))
        else
          field.remove
        end
      end
    end

    class Loop < Struct.new(:list_expr, :iterator_name, :block)
      def evaluate(env)
        value = list_expr.evaluate(env.context)
        value = value.to_ary if value.respond_to?(:to_ary)
        raise ContextError, "The expression #{list_expr.inspect} should evaluate to an enumerable but was: #{value.inspect}" unless value.is_a?(Enumerable)

        content = value.flat_map do |item|
          iteration_context = env.context.merge(iterator_name => item)
          block.process(iteration_context)
        end
        block.replace(content.reverse)
      end
    end

    class Condition < Struct.new(:conditon_expr, :block, :predicate)
      def evaluate(env)
        value = conditon_expr.evaluate(env.context)
        if truthy?(predicate ? value.public_send(predicate) : value)
          block.replace(block.process(env).reverse)
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

    class Comment < Struct.new(:block)
      def evaluate(_env)
        block.replace []
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
            case local
            when Hash
              local[m]
            else
              local.public_send m if local.respond_to?(m)
            end
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
