module Sablon
  # tracks images that need to be added to the document.
  class Images
    Definition = Struct.new(:name, :data, :rid) do
      def inspect
        "#<Image #{name}:#{rid}"
      end
    end

    def initialize
      @definitions = []
    end

    def register(name, data, rid)
      definition = Definition.new(name, data, rid)
      @definitions << definition
    end

    def add_images_to_zip!(zip_out)
      @definitions.each do |image|
        zip_out.put_next_entry(File.join('word', 'media', image.name))
        zip_out.write(image.data)
      end
    end
  end
end
