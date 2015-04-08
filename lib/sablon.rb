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

  def self.word_ml(xml)
    Sablon::Content::WordML.new(xml)
  end

  def self.string(object)
    Sablon::Content::String.new(object.to_s)
  end
end
