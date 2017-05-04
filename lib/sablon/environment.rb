module Sablon
  # Combines the user supplied context and template into a single object
  # to manage data during template processing.
  class Environment
    attr_reader :template
    attr_reader :numbering
    attr_reader :context

    # returns a new environment with merged contexts
    def alter_context(context = {})
      new_context = @context.merge(context)
      Environment.new(@template, new_context, @numbering)
    end

    private

    def initialize(template, context = {}, numbering=nil)
      @template = template
      @numbering = (numbering || Sablon::Numbering.new)
      @context = Context.transform_hash(context)
    end
  end
end
