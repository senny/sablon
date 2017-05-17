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
  end
end
