module Sablon
  class Context < Hash
    attr_reader :template
    attr_reader :numbering

    private

    def initialize(template, hash = {})
      @template = template
      @numbering = Sablon::Numbering.new
      hash.each do |key, value|
        key, value = transform_pair(key.to_s, value)
        self[key] = value
      end
    end

    def transform_hash(hash)
      Hash[hash.map { |k, v| transform_pair(k.to_s, v) }]
    end

    def transform_standard_key(key, value)
      case value
      when Hash
        [key, transform_hash(value)]
      else
        [key, value]
      end
    end

    def transform_pair(key, value)
      if key =~ /\A([^:]+):(.+)\z/
        if value.nil?
          [Regexp.last_match[2], value]
        else
          key_sym = Regexp.last_match[1].to_sym
          [Regexp.last_match[2], Sablon.content(key_sym, value)]
        end
      else
        transform_standard_key(key, value)
      end
    end
  end
end
