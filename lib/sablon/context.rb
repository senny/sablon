module Sablon
  # A context represents the user supplied arguments to render a
  # template.
  #
  # This module contains transformation functions to turn a
  # user supplied hash into a data structure suitable for rendering the
  # docx template.
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
        when Array
          [key, value.map { |v| v.is_a?(Hash) ? transform_hash(v) : v }]
        else
          [key, value]
        end
      end

      def transform_pair(key, value)
        if key =~ /\A([^:]+):(.+)\z/
          regex_match = Regexp.last_match
          new_key = regex_match[2]

          if value.nil?
            [new_key, value]
          else
            prefix = regex_match[1].to_sym
            new_value = Content.make(prefix, value)
            if new_value.respond_to?(:key)
              new_key = new_value.key(regex_match)
            end
            [new_key, new_value]
          end
        else
          transform_standard_key(key, value)
        end
      end
    end
  end
end
