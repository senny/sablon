module Sablon
  module Context
    def self.transform(hash)
      transform_hash(hash)
    end

    def self.transform_hash(hash)
      Hash[hash.map{|k,v| transform_pair(k.to_s, v) }]
    end

    def self.transform_pair(key, value)
      if key =~ /\A([^:]+):(.+)\z/
        if value.nil?
          [$2, value]
        else
          [$2, Sablon.content($1.to_sym, value)]
        end
      else
        transform_standard_key(key, value)
      end
    end

    def self.transform_standard_key(key, value)
      case value
      when Hash
        [key, transform_hash(value)]
      else
        [key, value]
      end
    end
  end
end
