require "test_helper"
require "support/document_xml_helper"

class SectionPropertiesTest < Sablon::TestCase
  include DocumentXMLHelper

  def setup
    @env = Sablon::Environment.new(nil, {})
  end

  def test_process
    xml = <<-XML
      <w:body>
        <w:sectPr w:rsidR="00FC1AFD" w:rsidSect="006745DF">
          <w:pgSz w:w="11900" w:h="16840"/>
          <w:pgMar w:top="1440" w:right="1800" w:bottom="1440" w:left="1800" w:header="708" w:footer="708" w:gutter="0"/>
          <w:pgNumType w:start="1"/>
          <w:cols w:space="708"/>
          <w:docGrid w:linePitch="360"/>
        </w:sectPr>
      </w:body>
    XML
    expected = xml.gsub(/w:start="1"/, 'w:start="123"')
    xml = wrap(xml)
    #
    @env.section_properties = { start_page_number: 123 }
    Sablon::Processor::SectionProperties.process(xml, @env)
    #
    assert_xml_equal expected, xml.to_s
  end

  def test_assign_start_page_number_with_pgNumType_tag
    xml = wrap <<-XML
      <w:body>
        <w:sectPr w:rsidR="00FC1AFD" w:rsidSect="006745DF">
          <w:pgSz w:w="11900" w:h="16840"/>
          <w:pgMar w:top="1440" w:right="1800" w:bottom="1440" w:left="1800" w:header="708" w:footer="708" w:gutter="0"/>
          <w:pgNumType w:start="1"/>
          <w:cols w:space="708"/>
          <w:docGrid w:linePitch="360"/>
        </w:sectPr>
      </w:body>
    XML
    #
    properties = Sablon::Processor::SectionProperties.new(xml)
    assert_equal "1", properties.start_page_number
    properties.start_page_number = "23"
    assert_equal "23", properties.start_page_number
  end

  def test_assign_start_page_number_without_pgNumType_tag
    xml = wrap <<-XML
      <w:body>
        <w:sectPr w:rsidR="00FC1AFD" w:rsidSect="006745DF">
          <w:pgSz w:w="11900" w:h="16840"/>
          <w:pgMar w:top="1440" w:right="1800" w:bottom="1440" w:left="1800" w:header="708" w:footer="708" w:gutter="0"/>
          <w:cols w:space="708"/>
          <w:docGrid w:linePitch="360"/>
        </w:sectPr>
      </w:body>
    XML
    #
    properties = Sablon::Processor::SectionProperties.new(xml)
    assert_nil properties.start_page_number
    properties.start_page_number = "16"
    assert_equal "16", properties.start_page_number
  end
end
