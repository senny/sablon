require "sablon/version"
require "sablon/template"
require "sablon/processor"
require "sablon/processor/section_properties"
require "sablon/parser/mail_merge"
require "sablon/operations"
require 'zip'
require 'nokogiri'

module Sablon
  class ContextError < ArgumentError; end

  def self.template(path)
    Template.new(path)
  end
end
