module Sablon
  # manipulates use supplied hash maps to be suitable for content replacement
  # inside a docx template file.
  module Context
    class << self
      def transform_hash(hash)
        Hash[hash.map { |k, v| transform_pair(k.to_s, v) }]
      end

      private

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
            [Regexp.last_match[2], Content.make(key_sym, value)]
          end
        else
          transform_standard_key(key, value)
        end
      end
    end
  end

  # Combines the user supplied context and template into a single object
  # to manage data during template processing.
  class Environment
    attr_reader :template
    attr_reader :context

    # returns a new environment with merged contexts
    def alter_context(context = {})
      new_context = @context.merge(context)
      Environment.new(@template, new_context)
    end

    private

    def initialize(template, context = {})
      @template = template
      @context = Context.transform_hash(context)
    end
  end
end
