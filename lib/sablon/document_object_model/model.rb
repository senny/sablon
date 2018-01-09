module Sablon
  # Stores classes used to build and interact with the template by treating
  # it as a full document model instead of disparate components that are
  # packaged together.
  module DOM
    # Object to represent an entire template and it's XML contents
    class Model
      attr_reader :zip_contents, :current_entry

      # setup the DOM by reading and storing all XML files in the template
      # in memory
      def initialize(zip_io_stream)
        @current_entry = nil
        @zip_contents = {}
        zip_io_stream.each do |entry|
          content = entry.get_input_stream.read
          @zip_contents[entry.name] = wrap_entry(entry.name, content)
        end
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
    end
  end
end
