# -*- coding: utf-8 -*-
require "test_helper"
require "support/document_xml_helper"

module MailMergeParser
  module SharedBehavior
    include DocumentXMLHelper
    def setup
      super
      @parser = Sablon::Parser::MailMerge.new
    end

    def fields
      @document = xml
      @parser.parse_fields(@document)
    end

    def body_xml
      @document.search(".//w:body").children.map(&:to_xml).join.strip
    end
  end

  class FldSimpleTest < Sablon::TestCase
    include SharedBehavior

    def test_recognizes_expression
      assert_equal ["=first_name"], fields.map(&:expression)
    end

    def test_replace
      field = fields.first
      field.replace("Hello")
      assert_equal <<-body_xml.strip, body_xml
<w:r w:rsidR=\"004B49F0\">
    <w:rPr><w:noProof/></w:rPr>
    <w:t>Hello</w:t>
  </w:r>
body_xml
    end

    def test_replace_with_newlines
      field = fields.first
      field.replace("First\nSecond\n\nThird")

      assert_equal <<-body_xml.strip, body_xml
<w:r w:rsidR=\"004B49F0\">
    <w:rPr><w:noProof/></w:rPr>
    <w:t>First</w:t><w:br/><w:t>Second</w:t><w:br/><w:br/><w:t>Third</w:t>
  </w:r>
body_xml
    end

    private
    def xml
      wrap(<<-xml)
<w:fldSimple w:instr=" MERGEFIELD =first_name \\* MERGEFORMAT ">
  <w:r w:rsidR="004B49F0">
    <w:rPr><w:noProof/></w:rPr>
    <w:t>«=first_name»</w:t>
  </w:r>
</w:fldSimple>
      xml
    end
  end

  class FldCharTest < Sablon::TestCase
    include SharedBehavior

    def test_recognizes_expression
      assert_equal ["=last_name"], fields.map(&:expression)
    end

    def test_replace
      field = fields.first
      field.replace("Hello")
      assert_equal <<-body_xml.strip, body_xml
<w:r w:rsidR="004B49F0">
  <w:rPr>
    <w:b/>
    <w:noProof/>
  </w:rPr>
  <w:t>Hello</w:t>
</w:r>
body_xml
    end

    def test_replace_with_newlines
      field = fields.first
      field.replace("First\nSecond\n\nThird")

      assert_equal <<-body_xml.strip, body_xml
<w:r w:rsidR="004B49F0">
  <w:rPr>
    <w:b/>
    <w:noProof/>
  </w:rPr>
  <w:t>First</w:t><w:br/><w:t>Second</w:t><w:br/><w:br/><w:t>Third</w:t>
</w:r>
body_xml
    end

    private
    def xml
      wrap(<<-xml)
<w:r w:rsidR="00BE47B1" w:rsidRPr="00BE47B1">
  <w:rPr><w:b/></w:rPr>
  <w:fldChar w:fldCharType="begin"/>
</w:r>
<w:r w:rsidR="00BE47B1" w:rsidRPr="00BE47B1">
  <w:rPr><w:b/></w:rPr>
  <w:instrText xml:space="preserve"> MERGEFIELD =last_name \\* MERGEFORMAT </w:instrText>
</w:r>
<w:r w:rsidR="00BE47B1" w:rsidRPr="00BE47B1">
  <w:rPr><w:b/></w:rPr>
  <w:fldChar w:fldCharType="separate"/>
</w:r>
<w:r w:rsidR="004B49F0">
  <w:rPr>
    <w:b/>
    <w:noProof/>
  </w:rPr>
  <w:t>«=last_name»</w:t>
</w:r>
<w:r w:rsidR="00BE47B1" w:rsidRPr="00BE47B1">
  <w:rPr><w:b/></w:rPr>
  <w:fldChar w:fldCharType="end"/>
</w:r>
      xml
    end
  end
end
