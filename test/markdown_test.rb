# -*- coding: utf-8 -*-
require "test_helper"
require "support/xml_snippets"

class SablonMarkdownTest < Sablon::TestCase
  include Sablon::Test::Assertions

  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))

    @sample_path = @base_path + "fixtures/markdown_sample.docx"
  end

  def test_generate_document_from_template_with_styles_and_markdown
    template_path = @base_path + "fixtures/insertion_template.docx"
    output_path = @base_path + "sandbox/markdown.docx"
    template = Sablon.template template_path
    context = {'markdown:content' => content}
    template.render_to_file output_path, context

    assert_docx_equal @sample_path, output_path
  end

  private
  def content
    <<-MARKDOWN
# Sablon Markdown insertion

## Text

**_Lorem ipsum_ dolor sit amet, consectetur adipiscing elit. Suspendisse at libero at elit posuere convallis ac vitae augue. Morbi pretium diam et leo pulvinar, sit amet placerat mauris scelerisque.** Vivamus sollicitudin ante ligula, non egestas diam molestie at.

Nunc tincidunt massa id libero mollis bibendum.
Sed vel arcu blandit, scelerisque ex ut, semper justo.
Nunc tempor velit a tortor lacinia, vel mattis diam sollicitudin.
Etiam eget faucibus enim.

Curabitur rutrum vestibulum nisi, vel posuere ligula commodo a. Sed nibh odio, convallis vitae orci a, cursus venenatis tellus. Duis consequat auctor elementum. Quisque blandit augue id faucibus dignissim. Aenean malesuada placerat turpis. Mauris tincidunt lorem sit amet est ultricies, eu tristique arcu dapibus. Nam ultrices vulputate tellus, quis feugiat ante faucibus non. Donec lectus est, suscipit in arcu molestie, pharetra cursus massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

## Lists

* Etiam vulputate elementum mi, at porta est malesuada sit amet.
* Praesent porttitor arcu id justo dignissim, vitae dignissim lectus pharetra.
* Curabitur efficitur mauris ac justo porta dignissim. Integer sed dui justo.

Donec finibus lectus a erat pharetra dapibus.

1. Nulla facilisis aliquet ex.
1. Mauris eget ante sed purus dictum tempus eu non dolor.
1. Aliquam finibus, leo at rutrum euismod, urna quam scelerisque ante, eu finibus dolor lectus vel ipsum.

Ut id condimentum ante, eget convallis justo. Quisque accumsan porta interdum. Integer sit amet luctus felis.

Nunc imperdiet, massa id ultricies porttitor, felis magna tincidunt augue, a egestas orci neque sed odio.

1. Suspendisse
  1. tempor
    1. turpis
      1. turpis
    1. vitae
  1. tristique
    1. nulla
      1. pulvinar
1. nec.

* Suspendisse
  * potenti
    * In condimentum
    * enim ut nibh cursus imperdiet.
  * Aliquam
  * lacinia
    * scelerisque
* tristique.

Phasellus consectetur placerat ornare. Nulla facilisi. Morbi fringilla est vitae pulvinar dictum. Praesent quis malesuada ex. Pellentesque posuere facilisis molestie.

Maecenas pretium erat vitae neque convallis consectetur. Cras ultricies mi nec mauris consectetur, eu blandit purus mattis. Quisque ante nulla, sagittis sed interdum non, eleifend quis augue. Curabitur vestibulum quam sed blandit rhoncus. Morbi eget vestibulum felis. Nulla vitae molestie elit. Etiam sagittis lorem elit, sit amet rhoncus eros dapibus non. Praesent nec dignissim dui. Quisque quis vehicula turpis, sit amet aliquet leo. Ut urna magna, malesuada eget fringilla ut, laoreet sed diam. Maecenas a ipsum varius, efficitur eros quis, vulputate mauris.
MARKDOWN
  end
end
