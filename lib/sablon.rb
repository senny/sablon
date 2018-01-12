require 'zip'
require 'nokogiri'

require "sablon/version"
require "sablon/configuration/configuration"

require "sablon/context"
require "sablon/environment"
require "sablon/template"
require "sablon/processor/document"
require "sablon/processor/section_properties"
require "sablon/parser/mail_merge"
require "sablon/operations"
require "sablon/html/converter"
require "sablon/content"

module Sablon
  class TemplateError < ArgumentError; end
  class ContextError < ArgumentError; end

  def self.configure
    yield(Configuration.instance) if block_given?
  end

  def self.template(path)
    Template.new(path)
  end

  def self.content(type, *args)
    Content.make(type, *args)
  end
end
