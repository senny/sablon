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
    end
  end
end
