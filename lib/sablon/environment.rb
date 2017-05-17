module Sablon
  # Combines the user supplied context and template into a single object
  # to manage data during template processing.
  class Environment
    attr_reader :template
    attr_reader :images
    attr_reader :numbering
    attr_reader :relationships
    attr_reader :context

    attr_reader :current_entry
    attr_writer :current_entry

    # abstraction of the after Relationships.register_relationship method
    def register_relationship(type_uri, target)
      attr_hash = { 'Id' => nil, 'Type' => type_uri, 'Target' => target }
      @relationships.register_relationship(@current_entry, attr_hash)
    end

    # returns a new environment with merged contexts
    def alter_context(context = {})
      new_context = @context.merge(context)
      Environment.new(nil, new_context, self)
    end

    private

    def initialize(template, context = {}, parent_env = nil)
      # pass attributes of the supplied environment to the new one or
      # create new references
      if parent_env
        @current_entry = parent_env.current_entry
        @template = parent_env.template
        @images = parent_env.images
        @numbering = parent_env.numbering
        @relationships = parent_env.relationships
      else
        @current_entry = nil
        @template = template
        @images = Images.new
        @numbering = Numbering.new
        @relationships = Sablon::Processor::Relationships.new
      end
      #
      @context = Context.transform_hash(context)
    end
  end
end
