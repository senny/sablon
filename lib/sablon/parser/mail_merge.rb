module Sablon
  module Parser
    class MailMerge
      class MergeField
        KEY_PATTERN = /^\s*MERGEFIELD\s+([^ ]+)\s+\\\*\s+MERGEFORMAT\s*$/

        def valid?
          expression
        end

        def expression
          $1 if @raw_expression =~ KEY_PATTERN
        end

        private
        def replace_field_display(node, content)
          paragraph = node.ancestors(".//w:p").first
          display_node = node.search(".//w:t").first
          content.append_to(paragraph, display_node)
          display_node.remove
        end
      end

      class ComplexField < MergeField
        def initialize(nodes)
          @nodes = nodes
          @raw_expression = @nodes.flat_map {|n| n.search(".//w:instrText").map(&:content) }.join
        end

        def valid?
          separate_node && expression
        end

        def replace(content)
          replace_field_display(pattern_node, content)
          (@nodes - [pattern_node]).each(&:remove)
        end

        def ancestors(*args)
          @nodes.first.ancestors(*args)
        end

        private
        def pattern_node
          separate_node.next_element
        end

        def separate_node
          @nodes.detect {|n| !n.search(".//w:fldChar[@w:fldCharType='separate']").empty? }
        end
      end

      class SimpleField < MergeField

        attr_reader :node

        def initialize(node)
          @node = node
          @raw_expression = @node["w:instr"]
        end

        def replace(content)
          replace_field_display(@node, content)
          @node.replace(@node.children)
        end

        def ancestors(*args)
          @node.ancestors(*args)
        end
      end

      def parse_fields(xml)
        fields = []
        xml.traverse do |node|
          if node.name == "fldSimple"
            field = SimpleField.new(node)
          elsif node.name == "fldChar" && node["w:fldCharType"] == "begin"
            field = build_complex_field(node)
          end
          fields << field if field && field.valid?
        end
        fields
      end

      private
      def build_complex_field(node)
        possible_field_node = node.parent
        field_nodes = [possible_field_node]
        while possible_field_node && possible_field_node.search(".//w:fldChar[@w:fldCharType='end']").empty?
          possible_field_node = possible_field_node.next_element
          field_nodes << possible_field_node
        end
        ComplexField.new(field_nodes)
      end
    end
  end
end
