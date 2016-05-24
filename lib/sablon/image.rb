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
      Sablon::Image::Definition.new(Pathname.new(path).basename.to_s, IO.binread(path))
    end
  end
end
