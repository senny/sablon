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

    class NumIdVisitor < Visitor
      def visit_Paragraph(node)
        @definition = nil
      end

      def visit_ListParagraph(node)
        @definition = nil if @definition && (node.style != @definition.style)
        @definition ||= Sablon::Numbering.instance.register(node.style)
        node.numid = @definition.numid
      end
    end
  end
end
