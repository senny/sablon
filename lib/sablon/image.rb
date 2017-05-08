module Sablon
  class Image
    include Singleton
    attr_reader :definitions

    Definition = Struct.new(:name, :data, :rid) do
      def inspect
        "#<Image #{name}:#{rid}"
      end
    end

    def self.create_by_path(path, random = nil)
      image_name = "#{random || Random.new_seed}-#{File.extname(path)}"
      Sablon::Image::Definition.new(image_name, IO.binread(path))
    end
  end
end
