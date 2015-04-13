require "sablon/version"
require "sablon/context"
require "sablon/template"
require "sablon/processor"
require "sablon/processor/section_properties"
require "sablon/parser/mail_merge"
require "sablon/operations"
require "sablon/content"

require 'zip'
require 'nokogiri'

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
