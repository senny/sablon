module Sablon
  # Combines the user supplied context and template into a single object
  # to manage data during template processing.
  class Environment
    attr_reader :template
    attr_reader :context

    # returns a new environment with merged contexts
    def alter_context(context = {})
      new_context = @context.merge(context)
      Environment.new(nil, new_context, self)
    end

    # reader method for the DOM::Model instance stored on the template
    def document
      @template.document
    end

    private

    def initialize(template, context = {}, parent_env = nil)
      # pass attributes of the supplied environment to the new one or
      # create new references

      # I can replace this by just always passing in a valid template
      # in alter_context
      @template = parent_env ? parent_env.template : template
      @context = Context.transform_hash(context)
    end
  end
end
