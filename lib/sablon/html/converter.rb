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
      # set default styles based on HTML element
      styles = { 'div' => 'Normal', 'p' => 'Paragraph', 'h' => 'Heading',
                 'ul' => 'ListBullet', 'ol' => 'ListNumber' }
      styles['li'] = @definition.style if @definition

      # set the node class attribute based on the style, num allows h1,h2,..
      tag, num = node.name.match(/([a-z]+)(\d*)/)[1..2]
      unless styles[tag]
        raise ArgumentError, "Don't know how to handle node: #{node.inspect}"
      end
      #
      properties = process_style(node['style'])
      properties['pStyle'] = styles[tag] + num
      properties
    end

    # Adds properties to the run, from the parent, the style node attributes
    # and finally any element specfic properties. A modified properties hash
    # is returned
    def prepare_run(node, properties)
      # HTML element based styles
      styles = {
        'span' => {}, 'strong' => { 'b' => nil },
        'b' => { 'b' => nil }, 'em' => { 'i' => nil },
        'i' => { 'i' => nil }, 'u' => { 'u' => 'single' }
      }

      unless styles.key?(node.name)
        raise ArgumentError, "Don't know how to handle node: #{node.inspect}"
      end
      # Process any styles, return the new hash to avoid mutation of original
      properties = properties.merge(process_style(node['style']))

      # Set the element specific attributes, overriding any other values
      properties.merge(styles[node.name])
    end

    # maps the CSS style property to it's OpenXML equivalent. Not all CSS
    # properties have an equivalent, nor are valid for both a Paragraph and Run.
    # TODO: When processing a paragraph return the styles that need passed onto
    # runs within with the added complexity of above it may make more sense to
    # move this over to the Node class
    def process_style(style_str)
      #
      return {} unless style_str
      # styles without an entry are passed "as is" to the node attributes
      attr_map = {
        'background-color' => lambda { |v|
          return 'shd', { val: 'clear', fill: v.delete('#') }
        },
        'color' => ->(v) { return 'color', v.delete('#') },
        'font-size' => lambda { |v|
          return 'sz', (2 * Float(v.gsub(/[^\d.]/, '')).ceil).to_s
        },
        'font-style' => lambda { |v|
          return 'b', nil if v =~ /bold/
          return 'i', nil if v =~ /italic/
        },
        'font-weight' => ->(v) { return 'b', nil if v =~ /bold/ },
        'text-align' => ->(v) { return 'jc', v },
        'text-decoration' => lambda { |v|
          supported = %w[line-through underline]
          props = v.split
          return props[0], 'true' unless supported.include? props[0]
          return 'strike', 'true' if props[0] == 'line-through'
          return 'u', 'single' if props.length == 1
          return 'u', { val: props[1], color: 'auto' } if props.length == 2
          return 'u', { val: props[1], color: props[2].delete('#') }
        },
        'vertical-align' => lambda { |v|
          return 'vertAlign', 'subscript' if v =~ /sub/
          return 'vertAlign', 'superscript' if v =~ /super/
        }
      }
      #
      styles = style_str.split(';').map { |pair| pair.split(':') }

      # process the styles as a hash and store values
      style_attrs = {}
      Hash[styles].each do |key, value|
        key = key.strip
        value = value.strip
        key, value = attr_map[key].call(value) if attr_map[key]
        style_attrs[key] = value if key
      end
      style_attrs
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
      @builder.emit Paragraph.new(properties, ast_runs(node.children, properties))
    end

    def ast_runs(nodes, properties)
      runs = nodes.flat_map do |node|
        if node.text?
          Run.new(node.text, properties)
        elsif node.name == 'br'
          Newline.new
        else
          begin
            local_props = prepare_run(node, properties)
            ast_runs(node.children, local_props).nodes
          rescue ArgumentError
            raise unless %w[ul ol p div].include?(node.name)
            merge_node_attributes(node, node.parent.attributes)
            @builder.push(node)
            nil
          end
        end
      end
      Collection.new(runs.compact)
    end
  end
end
