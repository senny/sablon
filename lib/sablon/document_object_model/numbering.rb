require 'sablon/document_object_model/file_handler'

module Sablon
  module DOM
    # Manages the creation of new list definitions
    class Numbering < FileHandler
      Definition = Struct.new(:numid, :abstract_id, :style)

      # extends the Model class using instance eval with a block argument
      def self.extend_model(model_klass, &block)
        super do
          #
          # adds a list definition to the numbering.xml file
          define_method(:add_list_definition) do |style|
            @dom['word/numbering.xml'].add_list_definition(style)
          end
        end
      end

      # Sets up the class to add new list definitions to the number.xml
      # file
      def initialize(xml_node)
        super
        #
        @numbering = xml_node.root
        #
        @max_numid = max_attribute_value('//w:num', 'w:numId')
        #
        selector = '//w:abstractNum'
        @max_abstract_id = max_attribute_value(selector, 'w:abstractNumId')
      end

      # adds a new relationship and returns the corresponding rId for it
      def add_list_definition(style)
        definition = create_definition(style)
        #
        # update numbering file with new definitions
        node = @numbering.xpath('//w:abstractNum').last
        node.add_next_sibling(abstract_tag(definition))
        #
        node = @numbering.xpath('//w:num').last
        node.add_next_sibling(definition_tag(definition))
        #
        definition
      end

      private

      # Finds the maximum value of an attribute by converting it to an
      # integer. Non numeric portions of values are ignored.
      def max_attribute_value(selector, attr_name)
        super(@numbering, selector, attr_name)
      end

      # Creates a new list definition tag to define a list
      def definition_tag(definition)
        <<-XML.gsub(/^\s+|\n/, '')
          <w:num w:numId="#{definition.numid}">
            <w:abstractNumId w:val="#{definition.abstract_id}" />
          </w:num>
        XML
      end

      # Creates a new abstract numbering definition tag to style a list
      def abstract_tag(definition)
        abstract_num = find_abstract_definition(definition.style)
        abstract_num['w:abstractNumId'] = definition.abstract_id
        abstract_num.xpath('./w:nsid').each(&:remove)
        #
        abstract_num
      end

      # Locates and copies the first abstract numbering definition with
      # the expected style. If one can not be found an error is raised.
      def find_abstract_definition(style)
        path = "//w:abstractNum[descendant-or-self::*[w:pStyle[@w:val='#{style}']]]"
        unless (abstract_num = @numbering.at_xpath(path))
          msg = "Could not find w:abstractNum definition for style: '#{style}'"
          raise ArgumentError, msg
        end
        #
        abstract_num.dup
      end

      # Creates a new instance of the Definition struct, after incrementing
      # the max id values
      def create_definition(style)
        @max_numid += 1
        @max_abstract_id += 1
        Definition.new(@max_numid, @max_abstract_id, style)
      end
    end
  end
end
