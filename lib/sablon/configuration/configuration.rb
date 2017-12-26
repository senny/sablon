require 'singleton'
require 'sablon/configuration/html_tag'

module Sablon
  # Handles storing configuration data for the sablon module
  class Configuration
    include Singleton

    attr_accessor :permitted_html_tags, :defined_style_conversions

    def initialize
      initialize_html_tags
      initialize_css_style_conversion
    end

    # Adds a new tag to the permitted tags hash or replaces an existing one
    def register_html_tag(tag_name, type = :inline, **options)
      tag = HTMLTag.new(tag_name, type, **options)
      @permitted_html_tags[tag.name] = tag
    end

    # Removes a tag from the permitted tgs hash, returning it
    def remove_html_tag(tag_name)
      @permitted_html_tags.delete(tag_name)
    end

    # Adds a new style property converter for the specified ast class and
    # CSS property name. The ast_class variable should be the class name
    # in lowercased snakecase as a symbol, i.e. MyClass -> :my_class.
    # The converter passed in must be a proc that accepts
    # a single argument (the value) and returns two values: the WordML property
    # name and its value. The converted property value can be a string, hash
    # or array.
    def register_style_converter(ast_node, prop_name, converter)
      # create a new ast node hash if needed
      unless @defined_style_conversions[ast_node]
        @defined_style_conversions[ast_node] = {}
      end
      # add the style converter to the node's hash
      @defined_style_conversions[ast_node][prop_name] = converter
    end

    # Deletes a CSS converter from the hash by specifying the AST class
    # in lowercased snake case and the property name.
    def remove_style_converter(ast_node, prop_name)
      @defined_style_conversions[ast_node].delete(prop_name)
    end

    private

    # Defines all of the initial HTML tags to be used by HTMLconverter
    def initialize_html_tags
      @permitted_html_tags = {}
      tags = {
        # special tag used for elements with no parent, i.e. top level
        '#document-fragment' => { type: :block, ast_class: :root, allowed_children: :_block },

        # block level tags
        table: { type: :block, ast_class: :table, allowed_children: %i[caption thead tbody tfoot tr ]},
        tr: { type: :block, ast_class: :table_row, allowed_children: %i[th td] },
        th: { type: :block, ast_class: :table_cell, properties: { b: nil, jc: 'center' }, allowed_children: %i[_block _inline] },
        td: { type: :block, ast_class: :table_cell, allowed_children: %i[_block _inline] },
        div: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Normal' }, allowed_children: :_inline },
        p: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Paragraph' }, allowed_children: :_inline },
        caption: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Caption' }, allowed_children: :_inline },
        h1: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading1' }, allowed_children: :_inline },
        h2: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading2' }, allowed_children: :_inline },
        h3: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading3' }, allowed_children: :_inline },
        h4: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading4' }, allowed_children: :_inline },
        h5: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading5' }, allowed_children: :_inline },
        h6: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading6' }, allowed_children: :_inline },
        ol: { type: :block, ast_class: :list, properties: { pStyle: 'ListNumber' }, allowed_children: %i[ol li] },
        ul: { type: :block, ast_class: :list, properties: { pStyle: 'ListBullet' }, allowed_children: %i[ul li] },
        li: { type: :block, ast_class: :list_paragraph },

        # inline style tags for tables
        thead: { type: :inline, ast_class: nil, properties: { tblHeader: nil }, allowed_children: :tr },
        tbody: { type: :inline, ast_class: nil, properties: {}, allowed_children: :tr },
        tfoot: { type: :inline, ast_class: nil, properties: {}, allowed_children: :tr },

        # inline style tags
        span: { type: :inline, ast_class: nil, properties: {} },
        strong: { type: :inline, ast_class: nil, properties: { b: nil } },
        b: { type: :inline, ast_class: nil, properties: { b: nil } },
        em: { type: :inline, ast_class: nil, properties: { i: nil } },
        i: { type: :inline, ast_class: nil, properties: { i: nil } },
        u: { type: :inline, ast_class: nil, properties: { u: 'single' } },
        s: { type: :inline, ast_class: nil, properties: { strike: 'true' } },
        sub: { type: :inline, ast_class: nil, properties: { vertAlign: 'subscript' } },
        sup: { type: :inline, ast_class: nil, properties: { vertAlign: 'superscript' } },

        # inline content tags
        a: { type: :inline, ast_class: :hyperlink, properties: { rStyle: 'Hyperlink' } },
        text: { type: :inline, ast_class: :run, properties: {}, allowed_children: [] },
        br: { type: :inline, ast_class: :newline, properties: {}, allowed_children: [] }
      }
      # add all tags to the config object
      tags.each do |tag_name, settings|
        type = settings.delete(:type)
        register_html_tag(tag_name, type, **settings)
      end
    end

    # Defines an initial set of CSS -> WordML conversion lambdas stored in
    # a nested hash structure where the first key is the AST class and the
    # second is the conversion lambda
    def initialize_css_style_conversion
      @defined_style_conversions = {
        # styles shared or common logic across all node types go here.
        # Special conversion lambdas such as :_border can be
        # defined here for reuse across several AST nodes. Care must
        # be taken to avoid possible naming conflicts, hence the underscore.
        # AST class keys should be stored with their names converted from
        # camelcase to lowercased snakecase, i.e. TestCase = test_case
        node: {
          'background-color' => lambda { |v|
            return 'shd', { val: 'clear', fill: v.delete('#') }
          },
          _border: lambda { |v|
            props = { sz: 2, val: 'single', color: '000000' }
            vals = v.split
            vals[1] = 'single' if vals[1] == 'solid'
            #
            props[:sz] = @defined_style_conversions[:node][:_sz].call(vals[0])
            props[:val] = vals[1] if vals[1]
            props[:color] = vals[2].delete('#') if vals[2]
            #
            return props
          },
          _sz: lambda { |v|
            return nil unless v
            (2 * Float(v.gsub(/[^\d.]/, '')).ceil).to_s
          },
          'text-align' => ->(v) { return 'jc', v }
        },
        # Styles specific to the Table AST class
        table: {
          'border' => lambda { |v|
            props = @defined_style_conversions[:node][:_border].call(v)
            #
            return 'tblBorders', [
              { top: props }, { start: props }, { bottom: props },
              { end: props }, { insideH: props }, { insideV: props }
            ]
          },
          'margin' => lambda { |v|
            vals = v.split.map do |s|
              @defined_style_conversions[:node][:_sz].call(s)
            end
            #
            props = [vals[0], vals[0], vals[0], vals[0]] if vals.length == 1
            props = [vals[0], vals[1], vals[0], vals[1]] if vals.length == 2
            props = [vals[0], vals[1], vals[2], vals[1]] if vals.length == 3
            props = [vals[0], vals[1], vals[2], vals[3]] if vals.length > 3
            return 'tblCellMar', [
              { top: { w: props[0], type: 'dxa' } },
              { end: { w: props[1], type: 'dxa' } },
              { bottom: { w: props[2], type: 'dxa' } },
              { start: { w: props[3], type: 'dxa' } }
            ]
          },
          'cellspacing' => lambda { |v|
            v = @defined_style_conversions[:node][:_sz].call(v)
            return 'tblCellSpacing', { w: v, type: 'dxa' }
          },
          'width' => lambda { |v|
            v = @defined_style_conversions[:node][:_sz].call(v)
            return 'tblW', { w: v, type: 'dxa' }
          }
        },
        # Styles specific to the TableCell AST class
        table_cell: {
          'border' => lambda { |v|
            value = @defined_style_conversions[:table]['border'].call(v)[1]
            return 'tcBorders', value
          },
          'colspan' => ->(v) { return 'gridSpan', v },
          'margin' => lambda { |v|
            value = @defined_style_conversions[:table]['margin'].call(v)[1]
            return 'tcMar', value
          },
          'rowspan' => lambda { |v|
            return 'vMerge', 'restart' if v == 'start'
            return 'vMerge', v if v == 'continue'
            return 'vMerge', nil if v == 'end'
          },
          'vertical-align' => ->(v) { return 'vAlign', v },
          'white-space' => lambda { |v|
            return 'noWrap', nil if v == 'nowrap'
            return 'tcFitText', 'true' if v == 'fit'
          },
          'width' => lambda { |v|
            value = @defined_style_conversions[:table]['width'].call(v)[1]
            return 'tcW', value
          }
        },
        # Styles specific to the Paragraph AST class
        paragraph: {
          'border' => lambda { |v|
            props = @defined_style_conversions[:node][:_border].call(v)
            #
            return 'pBdr', [
              { top: props }, { bottom: props },
              { left: props }, { right: props }
            ]
          },
          'vertical-align' => ->(v) { return 'textAlignment', v }
        },
        # Styles specific to a run of text
        run: {
          'color' => ->(v) { return 'color', v.delete('#') },
          'font-size' => lambda { |v|
            return 'sz', @defined_style_conversions[:node][:_sz].call(v)
          },
          'font-style' => lambda { |v|
            return 'b', nil if v =~ /bold/
            return 'i', nil if v =~ /italic/
          },
          'font-weight' => ->(v) { return 'b', nil if v =~ /bold/ },
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
      }
    end
  end
end
