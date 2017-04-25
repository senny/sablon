module Sablon
  # Combines the user supplied context and template into a single object
  # to manage data during template processing.
  class Environment
    attr_reader :template
    attr_reader :context

    private

    def initialize(template, context = {})
      @template = template
      @context = transform_hash(context)
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
