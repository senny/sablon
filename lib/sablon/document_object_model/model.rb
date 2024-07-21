require 'sablon/document_object_model/file_handler'
require 'sablon/document_object_model/content_types'
require 'sablon/document_object_model/numbering'
require 'sablon/document_object_model/relationships'

module Sablon
  # Stores classes used to build and interact with the template by treating
  # it as a full document model instead of disparate components that are
  # packaged together.
  module DOM
    class << self
      # Allows new handlers to be registered for different components of
      # the MS Word document. The pattern passed in is used to determine
      # if a file in the entry set should be handled by the class.
      def register_dom_handler(pattern, klass)
        handlers[pattern] = klass
        klass.extend_model(Sablon::DOM::Model)
      end

      def wrap_with_handler(entry_name, content)
        key = handlers.keys.detect { |pat| entry_name =~ pat }
        if key
          handlers[key].new(content)
        else
          Sablon::DOM::FileHandler.new(content)
        end
      end

      private

      def handlers
        @handlers ||= {}
      end
    end

    # Object to represent an entire template and it's XML contents
    class Model
      attr_accessor :current_entry
      attr_reader :zip_contents

      # setup the DOM by reading and storing all XML files in the template
      # in memory
      def initialize(zip_io_stream)
        @current_entry = nil
        @zip_contents = {}
        zip_io_stream.each do |entry|
          next unless entry.file?
          content = entry.get_input_stream.read
          @zip_contents[entry.name] = wrap_entry(entry.name, content)
        end
        #
        @dom = build_dom(@zip_contents)
      end

      # Returns the corresponding DOM handled file
      def [](entry_name)
        @dom[entry_name]
      end

      private

      # Determines how the content in the zip file entry should be wrapped
      def wrap_entry(entry_name, content)
        if entry_name =~ /\.(?:xml|rels)$/
          Nokogiri::XML(content)
        else
          content
        end
      end

      # constructs the dom model using helper classes defined under this
      # namespace.
      def build_dom(entries)
        key_values = entries.map do |entry_name, content|
          [entry_name, Sablon::DOM.wrap_with_handler(entry_name, content)]
        end
        #
        Hash[key_values]
      end

      def create_entry_if_not_exist(name, init_content = '')
        return unless @zip_contents[name].nil?
        #
        # create the entry and add it to the dom
        @zip_contents[name] = wrap_entry(name, init_content)
        @dom[name] = Sablon::DOM.wrap_with_handler(name, @zip_contents[name])
      end
    end

    register_dom_handler(%r{word/numbering.xml}, Sablon::DOM::Numbering)
    register_dom_handler(/.rels$/, Sablon::DOM::Relationships)
    register_dom_handler(/Content_Types/, Sablon::DOM::ContentTypes)
  end
end
