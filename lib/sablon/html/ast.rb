require "sablon/html/ast_builder"
require "sablon/html/node_properties"

module Sablon
  class HTMLConverter
    # A top level abstract class to handle common logic for all AST nodes
    class Node
      PROPERTIES = [].freeze

      def self.node_name
        @node_name ||= name.split('::').last
      end

      # Returns the type of node this AST class represents. Block level nodes
      # can stand on their own
      def self.node_type
        :block
      end

      # Returns a hash defined on the configuration object by default. However,
      # this method can be overridden by subclasses to return a different
      # node's style conversion config (i.e. :run) or a hash unrelated to the
      # config itself. The config object is used for all built-in classes to
      # allow for end-user customization via the configuration object
      def self.style_conversion
        # converts camelcase to underscored
        key = node_name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
        Sablon::Configuration.instance.defined_style_conversions.fetch(key, {})
      end

      # maps the CSS style property to it's OpenXML equivalent. Not all CSS
      # properties have an equivalent, nor share the same behavior when
      # defined on different node types (Paragraph, Table and Run).
      def self.process_properties(properties)
        # process the styles as a hash and store values
        style_attrs = {}
        properties.each do |key, value|
          unless key.is_a? Symbol
            key, value = *convert_style_property(key.strip, value.strip)
          end
          style_attrs[key] = value if key
        end
        style_attrs
      end

      # handles conversion of a single attribute allowing recursion through
      # super classes. If the key exists and conversion is succesful a
      # symbol is returned to avoid conflicts with a CSS prop sharing the
      # same name. Keys without a conversion class are returned as is
      def self.convert_style_property(key, value)
        if style_conversion.key?(key)
          key, value = style_conversion[key].call(value)
          key = key.to_sym if key
          [key, value]
        elsif self == Node
          [key, value]
        else
          superclass.convert_style_property(key, value)
        end
      end

      def initialize(_env, _node, _properties)
        @attributes ||= {}
      end

      def accept(visitor)
        visitor.visit(self)
      end

      # Simplifies usage at call sites by only requiring them to supply
      # the tag name to use and any child AST nodes to render
      def to_docx(tag)
        prop_str = @properties.to_docx if @properties
        #
        "<#{tag}#{attributes_to_docx}>#{prop_str}#{children_to_docx}</#{tag}>"
      end

      private

      # Simplifies usage at call sites
      def transferred_properties
        @properties.transferred_properties
      end

      # Gracefully handles conversion of an attributes hash into a
      # string
      def attributes_to_docx
        return '' if @attributes.nil? || @attributes.empty?
        ' ' + @attributes.map { |k, v| %(#{k}="#{v}") }.join(' ')
      end

      # Acts like an abstract method allowing subclases full flexibility to
      # define any content inside the tags.
      def children_to_docx
        ''
      end
    end

    # A container for an array of AST nodes with convenience methods to
    # work with the internal array as if it were a regular node
    class Collection < Node
      attr_reader :nodes
      def initialize(nodes)
        @nodes = nodes
      end

      def accept(visitor)
        super
        @nodes.each do |node|
          node.accept(visitor)
        end
      end

      def to_docx
        nodes.map(&:to_docx).join
      end

      def inspect
        "[#{nodes.map(&:inspect).join(', ')}]"
      end
    end

    # Stores all of the AST nodes from the current fragment of HTML being
    # parsed
    class Root < Collection
      def initialize(env, node)
        # strip text nodes from the root level element, these are typically
        # extra whitespace from indenting the markup
        node.search('./text()').remove

        # convert children from HTML to AST nodes
        super(ASTBuilder.html_to_ast(env, node.children, {}))
      end

      def grep(pattern)
        visitor = GrepVisitor.new(pattern)
        accept(visitor)
        visitor.result
      end

      def inspect
        "<Root: #{super}>"
      end
    end

    # An AST node representing the top level content container for a word
    # document. These cannot be nested within other paragraph elements
    class Paragraph < Node
      PROPERTIES = %w[framePr ind jc keepLines keepNext numPr
                      outlineLvl pBdr pStyle rPr sectPr shd spacing
                      tabs textAlignment].freeze
      attr_accessor :runs

      def initialize(env, node, properties)
        super
        properties = self.class.process_properties(properties)
        @properties = NodeProperties.paragraph(properties)
        #
        trans_props = transferred_properties
        @runs = ASTBuilder.html_to_ast(env, node.children, trans_props)
        @runs = Collection.new(@runs)
      end

      def to_docx
        super('w:p')
      end

      def accept(visitor)
        super
        runs.accept(visitor)
      end

      def inspect
        "<Paragraph{#{@properties[:pStyle]}}: #{runs.inspect}>"
      end

      private

      def children_to_docx
        runs.to_docx
      end
    end

    # Manages the child nodes of a list type tag
    class List < Collection
      def initialize(env, node, properties)
        # intialize values
        @list_tag = node.name
        #
        if node.ancestors(".//#{@list_tag}").length.zero?
          # Only register a definition when upon the first list tag encountered
          @definition = env.numbering.register(properties[:pStyle])
        end

        # update attributes of all child nodes
        transfer_node_attributes(node.children, node.attributes)

        # Move any list tags that are a child of a list item up one level
        process_child_nodes(node)

        # strip text nodes from the list level element, this is typically
        # extra whitespace from indenting the markup
        node.search('./text()').remove

        # convert children from HTML to AST nodes
        super(ASTBuilder.html_to_ast(env, node.children, properties))
      end

      def inspect
        "<List: #{super}>"
      end

      private

      # handles passing all attributes on the parent down to children
      def transfer_node_attributes(nodes, attributes)
        nodes.each do |child|
          # update all attributes
          merge_attributes(child, attributes)

          # set attributes specific to list items
          if @definition
            child['pStyle'] = @definition.style
            child['numId'] = @definition.numid
          end
          child['ilvl'] = child.ancestors(".//#{@list_tag}").length - 1
        end
      end

      # merges parent and child attributes together, preappending the parent's
      # values to allow the child node to override it if the value is already
      # defined on the child node.
      def merge_attributes(child, parent_attributes)
        parent_attributes.each do |name, par_attr|
          child_attr = child[name] ? child[name].split(';') : []
          child[name] = par_attr.value.split(';').concat(child_attr).join('; ')
        end
      end

      # moves any list tags that are a child of a list item tag up one level
      # so they become a sibling instead of a child
      def process_child_nodes(node)
        node.xpath("./li/#{@list_tag}").each do |list|
          # transfer attributes from parent now because the list tag will
          # no longer be a child and won't inheirit them as usual
          transfer_node_attributes(list.children, list.parent.attributes)
          list.parent.add_next_sibling(list)
        end
      end
    end

    # Sets list item specific attributes registered on the node to properly
    # generate a list paragraph
    class ListParagraph < Paragraph
      def initialize(env, node, properties)
        list_props = {
          pStyle: node['pStyle'],
          numPr: [{ ilvl: node['ilvl'] }, { numId: node['numId'] }]
        }
        properties = properties.merge(list_props)
        super
      end

      private

      def transferred_properties
        super
      end
    end

    # Builds a table from html table tags
    class Table < Node
      PROPERTIES = %w[jc shd tblBorders tblCaption tblCellMar tblCellSpacing
                      tblInd tblLayout tblLook tblOverlap tblpPr tblStyle
                      tblStyleColBandSize tblStyleRowBandSize tblW].freeze

      def initialize(env, node, properties)
        super

        # Process properties
        properties = self.class.process_properties(properties)
        @properties = NodeProperties.table(properties)
        trans_props = transferred_properties

        # Pull out the caption node if it exists and convert it separately.
        # If multiple caption tags are defined, only the first one is kept.
        @caption = node.xpath('./caption').remove
        @caption = nil if @caption.empty?
        if @caption
          cap_side_pat = /caption-side: ?(top|bottom)/
          @cap_side = @caption.attr('style').to_s.match(cap_side_pat).to_a[1]
          node.add_previous_sibling @caption
          @caption = ASTBuilder.html_to_ast(env, @caption, trans_props)[0]
        end

        # convert remaining child nodes and pass on transferrable properties
        @children = ASTBuilder.html_to_ast(env, node.children, trans_props)
        @children = Collection.new(@children)
      end

      def to_docx
        if @caption && @cap_side == 'bottom'
          super('w:tbl') + @caption.to_docx
        elsif @caption
          # caption always goes above table unless explicitly set to "bottom"
          @caption.to_docx + super('w:tbl')
        else
          super('w:tbl')
        end
      end

      def accept(visitor)
        super
        @children.accept(visitor)
      end

      def inspect
        if @caption && @cap_side == 'bottom'
          "<Table{#{@properties.inspect}}: #{@children.inspect}, #{@caption.inspect}>"
        elsif @caption
          "<Table{#{@properties.inspect}}: #{@caption.inspect}, #{@children.inspect}>"
        else
          "<Table{#{@properties.inspect}}: #{@children.inspect}>"
        end
      end

      private

      def children_to_docx
        @children.to_docx
      end
    end

    # Converts html table rows into wordML table rows
    class TableRow < Node
      PROPERTIES = %w[cantSplit hidden jc tblCellSpacing tblHeader
                      trHeight tblPrEx].freeze

      def initialize(env, node, properties)
        super
        properties = self.class.process_properties(properties)
        @properties = NodeProperties.table_row(properties)
        #
        trans_props = transferred_properties
        @children = ASTBuilder.html_to_ast(env, node.children, trans_props)
        @children = Collection.new(@children)
      end

      def to_docx
        super('w:tr')
      end

      def accept(visitor)
        super
        @children.accept(visitor)
      end

      def inspect
        "<TableRow{#{@properties.inspect}}: #{@children.inspect}>"
      end

      private

      def children_to_docx
        @children.to_docx
      end
    end

    # Converts html table cells into wordML table cells
    class TableCell < Node
      PROPERTIES = %w[gridSpan hideMark noWrap shd tcBorders tcFitText
                      tcMar tcW vAlign vMerge].freeze

      def initialize(env, node, properties)
        super
        properties = self.class.process_properties(properties)
        @properties = NodeProperties.table_cell(properties)
        # this works in the simple case but fails if the user wants to
        # nest other block level content in the table cell. According the
        # spec a table cell can hold any other block level content such as
        # tables, paragraphs and lists. Ideally, I'd wrap any plain text
        # in a paragraph and then handle block level elements through the
        # regular AST conversion process.
        @children = Paragraph.new(env, node, transferred_properties)
      end

      def to_docx
        super('w:tc')
      end

      def accept(visitor)
        super
        @children.accept(visitor)
      end

      def inspect
        "<TableCell{#{@properties.inspect}}: #{@children.inspect}>"
      end

      private

      def children_to_docx
        @children.to_docx
      end
    end

    # Create a run of text in the document, runs cannot be nested within
    # each other
    class Run < Node
      PROPERTIES = %w[b i caps color dstrike emboss imprint highlight outline
                      rStyle shadow shd smallCaps strike sz u vanish
                      vertAlign].freeze

      def self.node_type
        :inline
      end

      def initialize(_env, node, properties)
        super
        properties = self.class.process_properties(properties)
        @properties = NodeProperties.run(properties)
        @string = node.to_s # using `text` doesn't reconvert HTML entities
      end

      def to_docx
        super('w:r')
      end

      def inspect
        "<Run{#{@properties.inspect}}: #{@string}>"
      end

      private

      def children_to_docx
        content = @string.tr("\u00A0", ' ')
        "<w:t xml:space=\"preserve\">#{content}</w:t>"
      end
    end

    # Creates a blank line in the word document
    class Newline < Run
      def initialize(*); end

      def inspect
        "<Newline>"
      end

      private

      def children_to_docx
        "<w:br/>"
      end
    end
  end
end
