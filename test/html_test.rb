# -*- coding: utf-8 -*-
require "test_helper"
require "support/xml_snippets"

class SablonHTMLTest < Sablon::TestCase
  include Sablon::Test::Assertions

  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))

    @sample_path = @base_path + "fixtures/html_sample.docx"
  end

  def test_generate_document_from_template_with_styles_and_html
    template_path = @base_path + "fixtures/insertion_template.docx"
    output_path = @base_path + "sandbox/html.docx"
    template = Sablon.template template_path
    context = {'html:content' => content}
    template.render_to_file output_path, context

    assert_docx_equal @sample_path, output_path
  end

  def test_generate_document_from_template_without_styles_and_html
    template_path = @base_path + "fixtures/insertion_template_no_styles.docx"
    output_path = @base_path + "sandbox/html_no_styles.docx"
    template = Sablon.template template_path
    context = {'html:content' => content}

    e = assert_raises(ArgumentError) do
      template.render_to_file output_path, context
    end
    assert_equal 'Could not find w:abstractNum definition for style: "ListNumber"', e.message

    skip 'implement default styles'
  end

  private
  def content
    <<-HTML
<h1>Sablon HTML insertion</h1>
<h2>Text</h2>
<div>Lorem&nbsp;<strong>ipsum</strong>&nbsp;<em>dolor</em>&nbsp;<strong>sit</strong>&nbsp;<em>amet</em>,&nbsp;<strong>consectetur adipiscing elit</strong>.&nbsp;<em>Suspendisse a tempus turpis</em>. Duis urna justo, vehicula vitae ultricies vel, congue at sem. Fusce turpis turpis, aliquet id pulvinar aliquam, iaculis non elit. Nulla feugiat lectus nulla, in dictum ipsum cursus ac. Quisque at odio neque. Sed ac tortor iaculis, bibendum leo ut, malesuada velit. Donec iaculis sed urna eget pharetra. <u>Praesent ornare fermentum turpis</u>, placerat iaculis urna bibendum vitae. Nunc in quam consequat, tristique tellus in, commodo turpis. Curabitur ullamcorper odio purus, lobortis egestas magna laoreet vitae. Nunc fringilla velit ante, eu aliquam nisi cursus vitae. Suspendisse sit amet dui egestas, volutpat nisi vel, mattis justo. Nullam pellentesque, ipsum eget blandit pharetra, augue elit aliquam mauris, vel mollis nisl augue ut ipsum.</div>
<h2>Lists</h2>
<ol><li>Vestibulum&nbsp;<ol><li>ante ipsum primis&nbsp;</li></ol></li><li>in faucibus orci luctus&nbsp;<ol><li>et ultrices posuere cubilia Curae;&nbsp;<ol><li>Aliquam vel dolor&nbsp;</li><li>sed sem maximus&nbsp;</li></ol></li><li>fermentum in non odio.&nbsp;<ol><li>Fusce hendrerit ornare mollis.&nbsp;</li></ol></li><li>Nunc scelerisque nibh nec turpis tempor pulvinar.&nbsp;</li></ol></li><li>Donec eros turpis,&nbsp;</li><li>aliquet vel volutpat sit amet,&nbsp;<ol><li>semper eu purus.&nbsp;</li><li>Proin ac erat nec urna efficitur vulputate.&nbsp;<ol><li>Quisque varius convallis ultricies.&nbsp;</li><li>Nullam vel fermentum eros.&nbsp;</li></ol></li></ol></li></ol><div>Pellentesque nulla leo, auctor ornare erat sed, rhoncus congue diam. Duis non porttitor nulla, ut eleifend enim. Pellentesque non tempor sem.</div><div>Mauris auctor egestas arcu,&nbsp;</div><ol><li>id venenatis nibh dignissim id.&nbsp;</li><li>In non placerat metus.&nbsp;</li></ol><ul><li>Nunc sed consequat metus.&nbsp;</li><li>Nulla consectetur lorem consequat,&nbsp;</li><li>malesuada dui at, lacinia lectus.&nbsp;</li></ul><ol><li>Aliquam efficitur&nbsp;</li><li>lorem a mauris feugiat,&nbsp;</li><li>at semper eros pellentesque.&nbsp;</li></ol><div>Nunc lacus diam, consectetur ut odio sit amet, placerat pharetra erat. Sed commodo ut sem id congue. Sed eget neque elit. Curabitur at erat tortor. Maecenas eget sapien vitae est sagittis accumsan et nec orci. Integer luctus at nisl eget venenatis. Nunc nunc eros, consectetur at tortor et, tristique ultrices elit. Nulla in turpis nibh.</div><ul><li>Nam consectetur&nbsp;<ul><li>venenatis tempor.&nbsp;</li></ul></li><li>Aenean&nbsp;<ul><li>blandit<ul><li>porttitor massa,&nbsp;<ul><li>non efficitur&nbsp;<ul><li>metus.&nbsp;</li></ul></li></ul></li></ul></li></ul></li><li>Duis faucibus nunc nec venenatis faucibus.&nbsp;</li><li>Aliquam erat volutpat.&nbsp;</li></ul><div><strong>Quisque non neque ut lacus eleifend volutpat quis sed lacus.<br />Praesent ultrices purus eu quam elementum, sit amet faucibus elit interdum. In lectus orci,<br /> elementum quis dictum ac, porta ac ante. Fusce tempus ac mauris id cursus. Phasellus a erat nulla. <em>Mauris dolor orci</em>, malesuada auctor dignissim non, <u>posuere nec odio</u>. Etiam hendrerit justo nec diam ullamcorper, nec blandit elit sodales.</strong></div>
HTML
  end
end
