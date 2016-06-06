module Sablon
  class Image
    include Singleton
    attr_reader :definitions

    Definition = Struct.new(:name, :data, :rid) do
      def inspect
        "#<Image #{name}:#{data}:#{rid}"
      end
    end

    def self.create_by_path(path)
      image_name = "#{Random.new_seed}-#{Pathname.new(path).basename.to_s}"
      Sablon::Image::Definition.new(image_name, IO.binread(path))
    end
  end
end
