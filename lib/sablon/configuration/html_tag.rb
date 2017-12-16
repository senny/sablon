module Sablon
  class Configuration
    # Stores the information for a single HTML tag. This information
    # is used by the HTMLConverter. An optional AST class can be defined,
    # and if so conversion stops there and it is assumed the AST class
    # will handle any child nodes unless the element is a block level tag.
    # In the case of a block level tag the child nodes are processed by the
    # AST builder again. If the AST class is omitted it is assumed the node
    # should be "passed through" only transferring it's properties onto
    # children. A block level tag must have an AST class associated with
    # it. The block and inline status of tags is not affected by CSS.
    # Permitted child tags are specified using the :allowed_children optional
    # arg. The default value is [:_inline, :ul, :ol]. :_inline is a special
    # reference to all inline type tags, :_block is equivalent for block
    # type tags.
    #
    # == Parameters
    #  * name - symbol or string of the HTML element tag name
    #  * type - The type of HTML tag needs to be :inline or :block
    #  * ast_class - class instance or symbol, the AST class or it's name
    #                used to process the HTML node
    #  * options - collects all other keyword arguments, Current kwargs are
    #              `:properties`, `:attributes` and `:allowed_children`.
    #
    # Example
    #  HTMLTag.new(:div, :block, ast_class: Sablon::HTMLConverter::Paragraph,
    #              properties: { pStyle: 'Normal' })
    class HTMLTag
      attr_reader :name, :type, :ast_class, :attributes, :properties,
                  :allowed_children

      # Setup HTML tag information
      def initialize(name, type, ast_class: nil, **options)
        # Set basic params converting some args to symbols for consistency
        @name = name.to_sym
        @type = type.to_sym
        @ast_class = nil
        # use self.ast_class to trigger setter method
        self.ast_class = ast_class if ast_class

        # Ensure block level tags have an AST class
        if @type == :block && @ast_class.nil?
          raise ArgumentError, "Block level tag #{name} must have an AST class."
        end

        # Set attributes from optinos hash, currently unused during AST generation
        @attributes = options.fetch(:attributes, {})
        # WordML properties defined by the tag, i.e. <w:b /> for the <b> tag,
        # etc. All the keys need to be symbols to avoid getting reparsed
        # with the element's CSS attributes.
        @properties = options.fetch(:properties, {})
        @properties = Hash[@properties.map { |k, v| [k.to_sym, v] }]
        # Set permitted child tags or tag groups
        self.allowed_children = options[:allowed_children]
      end

      # checks if the given tag is a permitted child element
      def allowed_child?(tag)
        if @allowed_children.include?(tag.name)
          true
        elsif @allowed_children.include?(:_inline) && tag.type == :inline
          true
        elsif @allowed_children.include?(:_block) && tag.type == :block
          true
        else
          false
        end
      end

      private

      def allowed_children=(value)
        if value.nil?
          @allowed_children = %i[_inline ol ul]
          return
        else
          value = [value] unless value.is_a? Array
        end
        @allowed_children = value.map(&:to_sym)
      end

      # converts a string or symbol to a class defined under
      # Sablon::HTMLConverter
      def ast_class=(value)
        if value.is_a? Class
          @ast_class = value
          return
        else
          value = value.to_s
        end
        # camel case the word and get class, similar logic to
        # ActiveSupport::Inflector.constantize but refactored to be specific
        # to the HTMLConverter class
        value.gsub!(/(?:^|_)([a-z])/) { Regexp.last_match[1].capitalize }
        @ast_class = Sablon::HTMLConverter.const_get(value)
      end
    end
  end
end
