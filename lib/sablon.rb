require 'singleton'
require 'zip'
require 'nokogiri'

require "sablon/version"
require "sablon/numbering"
require "sablon/context"
require "sablon/template"
require "sablon/processor"
require "sablon/processor/section_properties"
require "sablon/processor/numbering"
require "sablon/parser/mail_merge"
require "sablon/operations"
require "sablon/html/converter"
require "sablon/content"

require 'redcarpet'
require "sablon/redcarpet/render/word_ml"

module Sablon
  class TemplateError < ArgumentError; end
  class ContextError < ArgumentError; end

  def self.template(path)
    Template.new(path)
  end

  def self.content(type, *args)
    Content.make(type, *args)
  end
end
