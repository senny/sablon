module Sablon
  module Parser
    class MailMerge
      class MergeField
        KEY_PATTERN = /^\s*MERGEFIELD ([^ ]+)\s+\\\* MERGEFORMAT\s*$/
        def expression
          $1 if @raw_expression =~ KEY_PATTERN
        end

        private
        def replace_field_display(node, text)
          display_node = node.search(".//w:t").first
          text.to_s.scan(/[^\n]+|\n/).reverse.each do |part|
            if part == "\n"
              display_node.add_next_sibling Nokogiri::XML::Node.new "w:br", display_node.document
            else
              text_part = display_node.dup
              text_part.content = part
              display_node.add_next_sibling text_part
            end
          end
          display_node.remove
        end
      end

      class ComplexField < MergeField
        def initialize(nodes)
          @nodes = nodes
          @raw_expression = @nodes.flat_map {|n| n.search(".//w:instrText").map(&:content) }.join
        end

        def replace(value)
          replace_field_display(pattern_node, value)
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
        def initialize(node)
          @node = node
          @raw_expression = @node["w:instr"]
        end

        def replace(value)
          replace_field_display(@node, value)
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
            possible_field_node = node.parent
            field_nodes = [possible_field_node]
            while possible_field_node && possible_field_node.search(".//w:fldChar[@w:fldCharType='end']").empty?
              possible_field_node = possible_field_node.next_element
              field_nodes << possible_field_node
            end
            field = ComplexField.new(field_nodes)
          end
          fields << field if field && field.expression
        end
        fields
      end
    end
  end
end
