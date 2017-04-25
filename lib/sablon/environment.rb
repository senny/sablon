module Sablon
  # Combines the user supplied context and template into a single object
  # to manage data during template processing.
  class Environment
    attr_reader :template
    attr_reader :numbering
    attr_reader :context

    # returns a new environment with merged contexts
    def alter_context(context = {})
      new_context = @context.merge(context)
      Environment.new(@template, new_context, @numbering)
    end

    private

    def initialize(template, context = {}, numbering=nil)
      @template = template
      @numbering = (numbering || Sablon::Numbering.new)
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
        if value
          key_sym = Regexp.last_match[1].to_sym
          value = Sablon::Content.make(key_sym, value)
        end
        [Regexp.last_match[2], value]
      else
        transform_standard_key(key, value)
      end
    end
  end
end
