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
end
