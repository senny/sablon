module Sablon
  class HTMLConverter
    class Visitor
      def visit(node)
        method_name = "visit_#{node.class.node_name}"
        if respond_to? method_name
          public_send method_name, node
        end
      end
    end

    class GrepVisitor
      attr_reader :result
      def initialize(pattern)
        @pattern = pattern
        @result = []
      end

      def visit(node)
        if @pattern === node
          @result << node
        end
      end
    end
  end
end
