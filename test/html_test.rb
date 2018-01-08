# -*- coding: utf-8 -*-
require "test_helper"
require "support/html_snippets"

class SablonHTMLTest < Sablon::TestCase
  include Sablon::Test::Assertions
  include HTMLSnippets

  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))

    @sample_path = @base_path + "fixtures/html_sample.docx"
  end

  def test_generate_document_from_template_with_styles_and_html
    uid_generator = UIDTestGenerator.new
    template_path = @base_path + "fixtures/insertion_template.docx"
    output_path = @base_path + "sandbox/html.docx"
    template = Sablon.template template_path
    context = {
      'html:content' => content,
      inline_content: {
        'html:should' => '<b><span style="color: #123456">should</span></b>',
        'html:github' => '<a href="http://www.github.com" style="color: #0000FF">GitHub</a>'
      }
    }
    SecureRandom.stub(:uuid, uid_generator.method(:new_uid)) do
      template.render_to_file output_path, context
    end
    #
    assert_docx_equal @sample_path, output_path
  end

  def test_generate_document_from_template_without_styles_and_html
    template_path = @base_path + "fixtures/insertion_template_no_styles.docx"
    output_path = @base_path + "sandbox/html_no_styles.docx"
    template = Sablon.template template_path
    context = { 'html:content' => content }

    e = assert_raises(ArgumentError) do
      template.render_to_file output_path, context
    end
    assert_equal 'Could not find w:abstractNum definition for style: "ListNumber"', e.message

    skip 'implement default styles'
  end

  private

  def content
    html_str = snippet('html_test_content')
    # combine all white space
    html_str = html_str.gsub(/\s+/, ' ')
    # clear any white space between block level tags and other content
    html_str.gsub(%r{\s*<(/?(?:h\d|div|p|br|ul|ol|li).*?)>\s*}, '<\1>')
  end
end
