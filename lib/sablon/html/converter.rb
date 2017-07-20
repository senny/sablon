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
      # set default styles based on HTML element allowing for h1, h2, etc.
      styles = Hash.new do |hash, key|
        tag, num = key.match(/([a-z]+)(\d*)/)[1..2]
        { 'pStyle' => hash[tag]['pStyle'] + num } if hash.key?(tag)
      end
      styles.merge!('div' => 'Normal', 'p' => 'Paragraph', 'h' => 'Heading',
                    'ul' => 'ListBullet', 'ol' => 'ListNumber')
      styles['li'] = @definition.style if @definition
      styles.each { |k, v| styles[k] = { 'pStyle' => v } }
      unless styles[node.name]
        raise ArgumentError, "Don't know how to handle node: #{node.inspect}"
      end
      #
      merge_node_properties(node, {}, styles[node.name], Paragraph)
    end

    # Adds properties to the run, from the parent, the style node attributes
    # and finally any element specfic properties. A modified properties hash
    # is returned
    def prepare_run(node, properties)
      # HTML element based styles
      styles = {
        'span' => {}, 'text' => {}, 'br' => {},
        'strong' => { 'b' => nil }, 'b' => { 'b' => nil },
        'em' => { 'i' => nil }, 'i' => { 'i' => nil },
        'u' => { 'u' => 'single' }
      }

      unless styles.key?(node.name)
        raise ArgumentError, "Don't know how to handle node: #{node.inspect}"
      end
      # combine all properties, return the new hash
      merge_node_properties(node, properties, styles[node.name], Run)
    end

    def merge_node_properties(node, par_props, elm_props, ast_class)
      # perform an initial conversion for any leftover CSS props passed
      # in from the node's parent
      properties = par_props.map do |k, v|
        ast_class.convert_style_attr(k, v)
      end
      properties = Hash[properties]

      # Process any styles, defined on the node
      properties.merge!(ast_class.process_style(node['style']))

      # Set the element specific attributes, overriding any other values
      properties.merge(elm_props)
    end

    # handles passing all attributes on the parent down to children
    # preappending parent attributes so child can overwrite if present
    def merge_node_attributes(node, attributes)
      node.children.each do |child|
        attributes.each do |name, atr|
          catr = child[name] ? child[name] : ''
          child[name] = atr.value.split(';').concat(catr.split(';')).join('; ')
        end
      end
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
        merge_node_attributes(node, node.attributes)
        @builder.push_all(node.children)
        return
      elsif node.name == 'li'
        properties['numPr'] = [
          { 'ilvl' => @builder.ilvl }, { 'numId' => @definition.numid }
        ]
      end

      # create word_ml node
      @builder.new_layer
      trans_props = Paragraph.transferred_properties(properties)
      @builder.emit Paragraph.new(properties, ast_runs(node.children, trans_props))
    end

    def ast_runs(nodes, properties)
      runs = nodes.flat_map do |node|
        begin
          local_props = prepare_run(node, properties)
        rescue ArgumentError
          raise unless %w[ul ol p div].include?(node.name)
          merge_node_attributes(node, node.parent.attributes)
          @builder.push(node)
          next nil
        end
        #
        if node.text?
          Run.new(local_props, node.text)
        elsif node.name == 'br'
          Newline.new
        else
          ast_runs(node.children, local_props).nodes
        end
      end
      Collection.new(runs.compact)
    end
  end
end
