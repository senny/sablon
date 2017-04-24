module Sablon
  class Numbering
    attr_reader :definitions

    Definition = Struct.new(:numid, :style) do
      def inspect
        "#<Numbering #{numid}:#{style}"
      end
    end

    def initialize
      @numid = 1000
      @definitions = []
    end

    def register(style)
      @numid += 1
      definition = Definition.new(@numid, style)
      @definitions << definition
      definition
    end
  end
end
