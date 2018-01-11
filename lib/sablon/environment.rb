module Sablon
  # Combines the user supplied context and template into a single object
  # to manage data during template processing.
  class Environment
    attr_reader :template
    attr_reader :context

    # returns a new environment with merged contexts
    def alter_context(context = {})
      new_context = @context.merge(context)
      Environment.new(template, new_context)
    end

    # reader method for the DOM::Model instance stored on the template
    def document
      @template.document
    end

    private

    def initialize(template, context = {})
      @template = template
      @context = Context.transform_hash(context)
    end
  end
end
