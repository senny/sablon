require 'singleton'
require 'sablon/configuration/html_tag'

module Sablon
  # Handles storing configuration data for the sablon module
  class Configuration
    include Singleton

    attr_accessor :permitted_html_tags

    def initialize
      initialize_html_tags
    end

    # Adds a new tag to the permitted tags hash or replaces an existing one
    def register_html_tag(tag_name, type = :inline, **options)
      tag = HTMLTag.new(tag_name, type, **options)
      @permitted_html_tags[tag.name] = tag
    end

    # Removes a tag from the permitted tgs hash, returning it
    def remove_html_tag(tag_name)
      @permitted_html_tags.delete(tag_name)
    end

    private

    # Defines all of the initial HTML tags to be used by HTMLconverter
    def initialize_html_tags
      @permitted_html_tags = {}
      tags = {
        # special tag used for elements with no parent, i.e. top level
        '#document-fragment' => { type: :block, ast_class: :root, allowed_children: :_block },
        # block level tags
        div: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Normal' } },
        p: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Paragraph' } },
        h1: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading1' } },
        h2: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading2' } },
        h3: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading3' } },
        h4: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading4' } },
        h5: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading5' } },
        h6: { type: :block, ast_class: :paragraph, properties: { pStyle: 'Heading6' } },
        ol: { type: :block, ast_class: :list, properties: { pStyle: 'ListNumber' }, allowed_children: %i[ol li] },
        ul: { type: :block, ast_class: :list, properties: { pStyle: 'ListBullet' }, allowed_children: %i[ul li] },
        li: { type: :block, ast_class: :list_paragraph },
        # inline style tags
        span: { type: :inline, ast_class: nil, properties: {} },
        strong: { type: :inline, ast_class: nil, properties: { b: nil } },
        b: { type: :inline, ast_class: nil, properties: { b: nil } },
        em: { type: :inline, ast_class: nil, properties: { i: nil } },
        i: { type: :inline, ast_class: nil, properties: { i: nil } },
        u: { type: :inline, ast_class: nil, properties: { u: 'single' } },
        # inline content tags
        text: { type: :inline, ast_class: :run, properties: {}, allowed_children: [] },
        br: { type: :inline, ast_class: :newline, properties: {}, allowed_children: [] }
      }
      # add all tags to the config object
      tags.each do |tag_name, settings|
        type = settings.delete(:type)
        register_html_tag(tag_name, type, **settings)
      end
    end
  end
end
