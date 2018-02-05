require 'sablon/document_object_model/file_handler'

module Sablon
  module DOM
    # Adds new content types to the document
    class ContentTypes < FileHandler
      #
      # extends the Model class so it now has an "add_content_type" method
      def self.extend_model(model_klass)
        super do
          define_method(:add_content_type) do |extension, type|
            @dom['[Content_Types].xml'].add_content_type(extension, type)
          end
        end
      end

      # Sets up the class instance to handle new relationships for a document.
      # I only care about tags that have an integer component
      def initialize(xml_node)
        super
        #
        @types = xml_node.root
      end

      # Adds a new content type to the file
      def add_content_type(extension, type)
        #
        # don't add duplicate extensions to the document
        return unless @types.css(%(Default[Extension="#{extension}"])).empty?
        #
        @types << %(<Default Extension="#{extension}" ContentType="#{type}"/>)
      end
    end
  end
end
