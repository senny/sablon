module Sablon
  class Images
    attr_reader :definitions

    Definition = Struct.new(:name, :data, :rid) do
      def inspect
        "#<Image #{name}:#{rid}"
      end
    end

    def initialize
      @definitions = []
    end

    def register(name, data)
      definition = Definition.new(name, data)
      @definitions << definition
      definition
    end

    def add_images_to_zip!(zip_out)
      @defintions.each do |image|
        zip_out.put_next_entry(File.join('word', 'media', image.name))
        zip_out.write(image.data)
      end
    end
  end
end
