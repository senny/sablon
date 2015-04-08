module Sablon
  module Context
    def self.transform(hash)
      stringify_keys(hash)
    end

    def self.stringify_keys(hash)
      Hash[hash.map{|k,v| v.is_a?(Hash) ? [k.to_s, stringify_keys(v)] : [k.to_s, v] }]
    end
  end
end
