# -*- coding: utf-8 -*-
require "test_helper"
require "support/document_xml_helper"

module MailMergeParser
  module SharedBehavior
    include DocumentXMLHelper
    def setup
      super
      @env = Sablon::Environment.new(nil)
      @parser = Sablon::Parser::MailMerge.new
    end

    def field
      @field ||= fields.first
    end

    def fields
      @parser.parse_fields(document)
    end

    def body_xml
      document.search(".//w:body").children.map(&:to_xml).map(&:strip).join
    end

    def document
      @document ||= xml
    end
  end

  class FldSimpleTest < Sablon::TestCase
    include SharedBehavior

    def test_recognizes_expression
      assert_equal ["=first_name"], fields.map(&:expression)
    end

    def test_replace
      field.replace(Sablon.content(:string, "Hello"), @env)
      xml = <<-xml.strip
<w:p>
<w:r w:rsidR=\"004B49F0\">
<w:rPr><w:noProof/></w:rPr>
<w:t>Hello</w:t>
</w:r>
</w:p>
xml
    assert_equal xml, body_xml
    end

    private

    def xml
      xml = <<-xml.strip
<w:p><w:fldSimple w:instr=" MERGEFIELD =first_name \\* MERGEFORMAT ">
<w:r w:rsidR="004B49F0">
<w:rPr><w:noProof/></w:rPr>
<w:t>«=first_name»</w:t>
</w:r>
</w:fldSimple></w:p>
xml
      wrap(xml)
    end
  end

  class FldCharTest < Sablon::TestCase
    include SharedBehavior

    def test_recognizes_expression
      assert_equal ["=last_name"], fields.map(&:expression)
    end

    def test_replace
      field.replace(Sablon.content(:string, "Hello"), @env)
      xml = <<-xml.strip
<w:p>


<w:r w:rsidR="004B49F0">
<w:rPr>
<w:b/>
<w:noProof/>
</w:rPr>
<w:t>Hello</w:t>
</w:r>
</w:p>
xml
      assert_equal body_xml.strip, xml.strip
    end

    private

    def xml
      xml = <<-xml.strip
<w:p><w:r w:rsidR="00BE47B1" w:rsidRPr="00BE47B1">
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
</w:r></w:p>
xml
      wrap(xml)
    end
  end

  class InvalidFldCharTest < Sablon::TestCase
    include SharedBehavior

    def test_is_ignored
      assert_equal [], fields.map(&:class)
    end

    private
    def xml
      xml = <<-xml.strip
<w:p><w:r w:rsidR="00BE47B1" w:rsidRPr="00BE47B1">
<w:rPr><w:b/></w:rPr>
<w:fldChar w:fldCharType="begin"/>
</w:r>
<w:r w:rsidR="00BE47B1" w:rsidRPr="00BE47B1">
<w:rPr><w:b/></w:rPr>
<w:instrText xml:space="preserve"> MERGEFIELD =last_name \\* MERGEFORMAT </w:instrText>
</w:r>
<w:r w:rsidR="00BE47B1" w:rsidRPr="00BE47B1">
<w:rPr><w:b/></w:rPr>
<w:fldChar w:fldCharType="end"/>
</w:r></w:p>
xml
      wrap(xml)
    end
  end

  class FldCharWithoutDisplayNodeTest < Sablon::TestCase
    include SharedBehavior

    def test_is_ignoredd
      assert_equal [], fields.map(&:class)
    end

    private
    def xml
      xml = <<-xml.strip
<w:p>
<w:r w:rsidR="00AE229C">
<w:rPr></w:rPr>
<w:fldChar w:fldCharType="begin"/>
</w:r>
<w:r w:rsidR="00AE229C">
<w:rPr></w:rPr>
<w:instrText xml:space="preserve"> MERGEFIELD  =client.lname  \\* MERGEFORMAT </w:instrText>
</w:r>
<w:r w:rsidR="00AE229C">
<w:rPr></w:rPr>
<w:fldChar w:fldCharType="separate"/>
</w:r>
<w:r w:rsidR="00AE229C">
<w:rPr></w:rPr>
<w:fldChar w:fldCharType="end"/>
</w:r>
</w:p>
xml
      wrap(xml)
    end
  end

  class NonSablonFieldTest < Sablon::TestCase
    include SharedBehavior

    def test_is_ignored
      assert_equal [], fields.map(&:class)
    end

    private

    def xml
      xml = <<-xml
  <w:p w14:paraId="0CF428D7" w14:textId="77777777" w:rsidR="00043618" w:rsidRDefault="00043618" w:rsidP="00B960C2">
    <w:pPr>
      <w:pStyle w:val="Footer" />
      <w:framePr w:wrap="around" w:vAnchor="text" w:hAnchor="margin" w:xAlign="right" w:y="1" />
      <w:rPr>
        <w:rStyle w:val="PageNumber" />
      </w:rPr>
    </w:pPr>
    <w:r>
      <w:rPr>
        <w:rStyle w:val="PageNumber" />
      </w:rPr>
      <w:fldChar w:fldCharType="begin" />
    </w:r>
    <w:r>
      <w:rPr>
        <w:rStyle w:val="PageNumber" />
      </w:rPr>
      <w:instrText xml:space="preserve">PAGE  </w:instrText>
    </w:r>
    <w:r>
      <w:rPr>
        <w:rStyle w:val="PageNumber" />
      </w:rPr>
      <w:fldChar w:fldCharType="separate" />
    </w:r>
    <w:r w:rsidR="00326FC5">
      <w:rPr>
        <w:rStyle w:val="PageNumber" />
        <w:noProof />
      </w:rPr>
      <w:t>1</w:t>
    </w:r>
    <w:r>
      <w:rPr>
        <w:rStyle w:val="PageNumber" />
      </w:rPr>
      <w:fldChar w:fldCharType="end" />
    </w:r>
  </w:p>
xml
      wrap(xml)
    end
  end

  class FieldWithWhitespaceTest < Sablon::TestCase
    include SharedBehavior

    def test_recognizes_expression
      assert_equal ["=title"], fields.map(&:expression)
    end

    def xml
      xml = <<-xml
<w:p><w:fldSimple w:instr="  MERGEFIELD    =title    \\*   MERGEFORMAT    ">
<w:r w:rsidR="004B49F0">
<w:rPr><w:noProof/></w:rPr>
<w:t>«=title»</w:t>
</w:r>
</w:fldSimple></w:p>
xml
      wrap(xml)
    end
  end
end
