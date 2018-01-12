module Sablon
  module DOM
    # An abstract class used to setup other file handling classes
    class FileHandler
      #
      # extends the Model class using instance eval with a block argument
      def self.extend_model(model_klass, &block)
        model_klass.instance_eval(&block)
      end

      # All subclasses should be initialized only accepting the content
      # as a single argument.
      def initialize(content); end

      # Finds the maximum value of an attribute by converting it to an
      # integer. Non numeric portions of values are ignored. The method can
      # be either xpath or css, xpath being the default.
      def max_attribute_value(xml_node, selector, attr_name, query_method: :xpath)
        xml_node.send(query_method, selector).map.inject(0) do |max, node|
          next max unless (match = node.attr(attr_name).match(/(\d+)/))
          [max, match[1].to_i].max
        end
      end
    end
  end
end
