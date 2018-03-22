module Sablon
  # Combines the user supplied context and template into a single object
  # to manage data during template processing.
  class Environment
    attr_reader :template
    attr_reader :context
    attr_reader :section_properties
    attr_accessor :inherit_styles, :keep_merge_fields, :remove_fields_only

    # returns a new environment with merged contexts
    def alter_context(context = {})
      new_context = @context.merge(context)
      Environment.new(template, new_context)
    end

    # reader method for the DOM::Model instance stored on the template
    def document
      @template.document
    end

    def section_properties=(properties)
      @section_properties = Context.transform_hash(properties)
    end

    private

    def initialize(template, context = {})
      @template = template
      @context = Context.transform_hash(context)
      @inherit_styles = true
      @keep_merge_fields = false
      @remove_fields_only = false
    end
  end
end
