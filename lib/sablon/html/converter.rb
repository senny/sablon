require "sablon/html/ast"
require "sablon/html/visitor"

module Sablon
  class HTMLConverter
    class ASTBuilder
      Layer = Struct.new(:items, :ilvl)

      def initialize(nodes)
        @layers = [Layer.new(nodes, false)]
        @root = Root.new([])
      end

      def to_ast
        @root
      end

      def new_layer(ilvl: false)
        @layers.push Layer.new([], ilvl)
      end

      def next
        current_layer.items.shift
      end

      def push(node)
        @layers.last.items.push node
      end

      def push_all(nodes)
        nodes.each(&method(:push))
      end

      def done?
        !current_layer.items.any?
      end

      def nested?
        ilvl > 0
      end

      def ilvl
        @layers.select { |layer| layer.ilvl }.size - 1
      end

      def emit(node)
        @root.nodes << node
      end

      private

      def current_layer
        if @layers.any?
          last_layer = @layers.last
          if last_layer.items.any?
            last_layer
          else
            @layers.pop
            current_layer
          end
        else
          Layer.new([], false)
        end
      end
    end

    def process(input, env)
      @numbering = env.numbering
      processed_ast(input).to_docx
    end

    def processed_ast(input)
      ast = build_ast(input)
      ast.accept LastNewlineRemoverVisitor.new
      ast
    end

    def build_ast(input)
      doc = Nokogiri::HTML.fragment(input)
      @builder = ASTBuilder.new(doc.children)

      while !@builder.done?
        ast_next_paragraph
      end
      @builder.to_ast
    end

    private

    def initialize
      @numbering = nil
    end

    # Adds the appropriate style class to the node
    def prepare_paragraph(node)
      # set default styles based on node name
      styles = { 'div' => 'Normal', 'p' => 'Paragraph', 'h' => 'Heading',
                 'ul' => 'ListBullet', 'ol' => 'ListNumber' }
      styles['li'] = @definition.style if @definition

      # set the node class attribute based on the style, num allows h1,h2,..
      tag, num = node.name.match(/([a-z]+)(\d*)/)[1..2]
      unless styles[tag]
        raise ArgumentError, "Don't know how to handle node: #{node.inspect}"
      end
      #
      properties = {}
      properties['pStyle'] = styles[tag] + num
      properties
    end

    def ast_next_paragraph
      node = @builder.next
      return if node.text?

      properties = prepare_paragraph(node)

      # handle special cases
      if node.name =~ /ul|ol/
        @builder.new_layer ilvl: true
        unless @builder.nested?
          @definition = @numbering.register(properties['pStyle'])
        end
        @builder.push_all(node.children)
        return
      elsif node.name == 'li'
        properties['numPr'] = [
          { 'ilvl' => @builder.ilvl }, { 'numId' => @definition.numid }
        ]
      end

      # create word_ml node
      @builder.new_layer
      @builder.emit Paragraph.new(properties, ast_text(node.children))
    end

    def ast_text(nodes, format: TextFormat.default)
      runs = nodes.flat_map do |node|
        if node.text?
          Text.new(node.text, format)
        elsif node.name == 'br'
          Newline.new
        elsif node.name == 'span'
          ast_text(node.children).nodes
        elsif node.name == 'strong' || node.name == 'b'
          ast_text(node.children, format: format.with_bold).nodes
        elsif node.name == 'em' || node.name == 'i'
          ast_text(node.children, format: format.with_italic).nodes
        elsif node.name == 'u'
          ast_text(node.children, format: format.with_underline).nodes
        elsif ['ul', 'ol', 'p', 'div'].include?(node.name)
          @builder.push(node)
          nil
        else
          raise ArgumentError, "Don't know how to handle node: #{node.inspect}"
        end
      end
      Collection.new(runs.compact)
    end
  end
end
