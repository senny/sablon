# -*- coding: utf-8 -*-
require "test_helper"
require "support/document_xml_helper"

class ProcessorTest < Sablon::TestCase
  include DocumentXMLHelper

  def setup
    super
    @processor = Sablon::Processor
  end

  def test_simple_field_replacement
    result = process(<<-documentxml, {"first_name" => "Jack"})
      <w:r><w:t xml:space="preserve">Hello! My Name is </w:t></w:r>
      <w:fldSimple w:instr=" MERGEFIELD =first_name \\* MERGEFORMAT ">
        <w:r w:rsidR="004B49F0">
          <w:rPr><w:noProof/></w:rPr>
          <w:t>«=first_name»</w:t>
        </w:r>
      </w:fldSimple>
      <w:r w:rsidR="00BE47B1"><w:t xml:space="preserve">, nice to meet you.</w:t></w:r>
    documentxml


    assert_equal "Hello! My Name is Jack , nice to meet you.", text(result)
    assert_xml_equal <<-document, result
      <w:r><w:t xml:space="preserve">Hello! My Name is </w:t></w:r>
        <w:r w:rsidR="004B49F0">
          <w:rPr><w:noProof/></w:rPr>
          <w:t>Jack</w:t>
        </w:r>
      <w:r w:rsidR="00BE47B1"><w:t xml:space="preserve">, nice to meet you.</w:t></w:r>
    document
  end

  def test_context_can_contain_string_and_symbol_keys
    result = process(<<-documentxml, {"first_name" => "Jack", last_name: "Davis"})
      <w:fldSimple w:instr=" MERGEFIELD =first_name \\* MERGEFORMAT ">
        <w:r w:rsidR="004B49F0">
          <w:rPr><w:noProof/></w:rPr>
          <w:t>«=first_name»</w:t>
        </w:r>
      </w:fldSimple>
      <w:fldSimple w:instr=" MERGEFIELD =last_name \\* MERGEFORMAT ">
        <w:r w:rsidR="004B49F0">
          <w:rPr><w:noProof/></w:rPr>
          <w:t>«=last_name»</w:t>
        </w:r>
      </w:fldSimple>
    documentxml

    assert_equal "Jack Davis", text(result)
  end

  def test_complex_field_replacement
    result = process(<<-documentxml, {"last_name" => "Zane"})
      <w:r><w:t xml:space="preserve">Hello! My Name is </w:t></w:r>
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
        <w:rPr><w:b/><w:noProof/></w:rPr>
        <w:t>«=last_name»</w:t>
      </w:r>
      <w:r w:rsidR="00BE47B1" w:rsidRPr="00BE47B1">
        <w:rPr><w:b/></w:rPr>
        <w:fldChar w:fldCharType="end"/>
      </w:r>
      <w:r w:rsidR="00BE47B1"><w:t xml:space="preserve">, nice to meet you.</w:t></w:r>
    documentxml

    assert_equal "Hello! My Name is Zane , nice to meet you.", text(result)
    assert_xml_equal <<-document, result
      <w:r><w:t xml:space="preserve">Hello! My Name is </w:t></w:r>
      <w:r w:rsidR="004B49F0">
        <w:rPr><w:b/><w:noProof/></w:rPr>
        <w:t>Zane</w:t>
      </w:r>
      <w:r w:rsidR="00BE47B1"><w:t xml:space="preserve">, nice to meet you.</w:t></w:r>
    document
  end

  def test_complex_field_replacement_with_split_field
    result = process(<<-documentxml, {"first_name" => "Daniel"})
      <w:r>
        <w:t xml:space="preserve">Hello! My Name is </w:t>
      </w:r>
      <w:r w:rsidR="003C4780">
        <w:fldChar w:fldCharType="begin" />
      </w:r>
      <w:r w:rsidR="003C4780">
        <w:instrText xml:space="preserve"> MERGEFIELD </w:instrText>
      </w:r>
      <w:r w:rsidR="003A4504">
        <w:instrText>=</w:instrText>
      </w:r>
      <w:r w:rsidR="003C4780">
        <w:instrText xml:space="preserve">first_name \\* MERGEFORMAT </w:instrText>
      </w:r>
      <w:r w:rsidR="003C4780">
        <w:fldChar w:fldCharType="separate" />
      </w:r>
      <w:r w:rsidR="00441382">
        <w:rPr><w:noProof /></w:rPr>
        <w:t>«=person.first_name»</w:t>
      </w:r>
      <w:r w:rsidR="003C4780">
        <w:fldChar w:fldCharType="end" />
      </w:r>
    <w:r w:rsidR="00BE47B1"><w:t xml:space="preserve">, nice to meet you.</w:t></w:r>
    documentxml

    assert_equal "Hello! My Name is Daniel , nice to meet you.", text(result)
    assert_xml_equal <<-document, result
      <w:r><w:t xml:space="preserve">Hello! My Name is </w:t></w:r>
      <w:r w:rsidR="00441382">
        <w:rPr><w:noProof/></w:rPr>
        <w:t>Daniel</w:t>
      </w:r>
      <w:r w:rsidR="00BE47B1"><w:t xml:space="preserve">, nice to meet you.</w:t></w:r>
    document
  end

  def test_paragraph_block_replacement
    result = process(<<-document, {"technologies" => ["Ruby", "Rails"]})
      <w:p w14:paraId="6CB29D92" w14:textId="164B70F4" w:rsidR="007F5CDE" w:rsidRDefault="007F5CDE" w:rsidP="007F5CDE">
         <w:pPr>
            <w:pStyle w:val="ListParagraph" />
            <w:numPr>
               <w:ilvl w:val="0" />
               <w:numId w:val="1" />
            </w:numPr>
         </w:pPr>
         <w:fldSimple w:instr=" MERGEFIELD technologies:each(technology) \\* MERGEFORMAT ">
            <w:r>
               <w:rPr><w:noProof /></w:rPr>
               <w:t>«technologies:each(technology)»</w:t>
            </w:r>
         </w:fldSimple>
      </w:p>
      <w:p w14:paraId="1081E316" w14:textId="3EAB5FDC" w:rsidR="00380EE8" w:rsidRDefault="00380EE8" w:rsidP="007F5CDE">
         <w:pPr>
            <w:pStyle w:val="ListParagraph" />
            <w:numPr>
               <w:ilvl w:val="0" />
               <w:numId w:val="1" />
            </w:numPr>
         </w:pPr>
         <w:r>
            <w:fldChar w:fldCharType="begin" />
         </w:r>
         <w:r>
            <w:instrText xml:space="preserve"> </w:instrText>
         </w:r>
         <w:r w:rsidR="009F01DA">
            <w:instrText>MERGEFIELD =technology</w:instrText>
         </w:r>
         <w:r>
            <w:instrText xml:space="preserve"> \\* MERGEFORMAT </w:instrText>
         </w:r>
         <w:r>
            <w:fldChar w:fldCharType="separate" />
         </w:r>
         <w:r w:rsidR="009F01DA">
            <w:rPr><w:noProof /></w:rPr>
            <w:t>«=technology»</w:t>
         </w:r>
         <w:r>
            <w:fldChar w:fldCharType="end" />
         </w:r>
      </w:p>
      <w:p w14:paraId="7F936853" w14:textId="078377AD" w:rsidR="00380EE8" w:rsidRPr="007F5CDE" w:rsidRDefault="00380EE8" w:rsidP="007F5CDE">
         <w:pPr>
            <w:pStyle w:val="ListParagraph" />
            <w:numPr>
               <w:ilvl w:val="0" />
               <w:numId w:val="1" />
            </w:numPr>
         </w:pPr>
         <w:fldSimple w:instr=" MERGEFIELD technologies:endEach \\* MERGEFORMAT ">
            <w:r>
               <w:rPr><w:noProof /></w:rPr>
               <w:t>«technologies:endEach»</w:t>
            </w:r>
         </w:fldSimple>
      </w:p>
    document

    assert_equal "Ruby Rails", text(result)
    assert_xml_equal <<-document, result
      <w:p w14:paraId="1081E316" w14:textId="3EAB5FDC" w:rsidR="00380EE8" w:rsidRDefault="00380EE8" w:rsidP="007F5CDE">
         <w:pPr>
            <w:pStyle w:val="ListParagraph"/>
            <w:numPr>
               <w:ilvl w:val="0"/>
               <w:numId w:val="1"/>
            </w:numPr>
         </w:pPr>
         <w:r w:rsidR="009F01DA">
            <w:rPr><w:noProof/></w:rPr>
            <w:t>Ruby</w:t>
         </w:r>
      </w:p><w:p w14:paraId="1081E316" w14:textId="3EAB5FDC" w:rsidR="00380EE8" w:rsidRDefault="00380EE8" w:rsidP="007F5CDE">
         <w:pPr>
            <w:pStyle w:val="ListParagraph"/>
            <w:numPr>
               <w:ilvl w:val="0"/>
               <w:numId w:val="1"/>
            </w:numPr>
         </w:pPr>
         <w:r w:rsidR="009F01DA">
            <w:rPr><w:noProof/></w:rPr>
            <w:t>Rails</w:t>
         </w:r>
      </w:p>
    document
  end

  def test_paragraph_block_within_table_cell
    result = process(<<-document, {"technologies" => ["Puppet", "Chef"]})
    <w:tbl>
      <w:tblGrid>
        <w:gridCol w:w="2202"/>
      </w:tblGrid>
      <w:tr w:rsidR="00757DAD">
        <w:tc>
          <w:p>
            <w:fldSimple w:instr=" MERGEFIELD technologies:each(technology) \\* MERGEFORMAT ">
              <w:r w:rsidR="004B49F0">
                <w:rPr><w:noProof/></w:rPr>
                <w:t>«technologies:each(technology)»</w:t>
              </w:r>
            </w:fldSimple>
          </w:p>
          <w:p>
            <w:fldSimple w:instr=" MERGEFIELD =technology \\* MERGEFORMAT ">
              <w:r w:rsidR="004B49F0">
                <w:rPr><w:noProof/></w:rPr>
                <w:t>«=technology»</w:t>
              </w:r>
            </w:fldSimple>
          </w:p>
          <w:p>
            <w:fldSimple w:instr=" MERGEFIELD technologies:endEach \\* MERGEFORMAT ">
              <w:r w:rsidR="004B49F0">
                <w:rPr><w:noProof/></w:rPr>
                <w:t>«technologies:endEach»</w:t>
              </w:r>
            </w:fldSimple>
          </w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
    document

    assert_equal "Puppet Chef", text(result)
    assert_xml_equal <<-document, result
    <w:tbl>
      <w:tblGrid>
        <w:gridCol w:w="2202"/>
      </w:tblGrid>
      <w:tr w:rsidR="00757DAD">
        <w:tc>
          <w:p>
            <w:r w:rsidR="004B49F0">
              <w:rPr><w:noProof/></w:rPr>
              <w:t>Puppet</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:r w:rsidR="004B49F0">
              <w:rPr><w:noProof/></w:rPr>
              <w:t>Chef</w:t>
            </w:r>
          </w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
    document
  end

  def test_single_row_table_loop
    item = Struct.new(:index, :label, :rating)
    result = process(<<-document, {"items" => [item.new("1.", "Milk", "***"), item.new("2.", "Sugar", "**")]})
    <w:tbl>
      <w:tblPr>
        <w:tblStyle w:val="TableGrid"/>
        <w:tblW w:w="0" w:type="auto"/>
        <w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="2202"/>
        <w:gridCol w:w="4285"/>
        <w:gridCol w:w="2029"/>
      </w:tblGrid>
      <w:tr w:rsidR="00757DAD" w14:paraId="229B7A39" w14:textId="77777777" w:rsidTr="006333C3">
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="2202" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="3D472BF1" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:fldChar w:fldCharType="begin"/>
            </w:r>
            <w:r>
              <w:instrText xml:space="preserve"> MERGEFIELD items:each(item) \\* MERGEFORMAT </w:instrText>
            </w:r>
            <w:r>
              <w:fldChar w:fldCharType="separate"/>
            </w:r>
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>«items:each(item)»</w:t>
            </w:r>
            <w:r>
              <w:fldChar w:fldCharType="end"/>
            </w:r>
          </w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="4285" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="6E6D8DB2" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3"/>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="2029" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="7BE1DB00" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3"/>
        </w:tc>
      </w:tr>
      <w:tr w:rsidR="00757DAD" w14:paraId="1BD2E50A" w14:textId="77777777" w:rsidTr="006333C3">
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="2202" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="41ACB3D9" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:fldChar w:fldCharType="begin"/>
            </w:r>
            <w:r>
              <w:instrText xml:space="preserve"> MERGEFIELD =item.index \\* MERGEFORMAT </w:instrText>
            </w:r>
            <w:r>
              <w:fldChar w:fldCharType="separate"/>
            </w:r>
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>«=item.index»</w:t>
            </w:r>
            <w:r>
              <w:fldChar w:fldCharType="end"/>
            </w:r>
          </w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="4285" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="197C6F31" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:fldChar w:fldCharType="begin"/>
            </w:r>
            <w:r>
              <w:instrText xml:space="preserve"> MERGEFIELD =item.label \\* MERGEFORMAT </w:instrText>
            </w:r>
            <w:r>
              <w:fldChar w:fldCharType="separate"/>
            </w:r>
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>«=item.label»</w:t>
            </w:r>
            <w:r>
              <w:fldChar w:fldCharType="end"/>
            </w:r>
          </w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="2029" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="55C258BB" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:fldChar w:fldCharType="begin"/>
            </w:r>
            <w:r>
              <w:instrText xml:space="preserve"> MERGEFIELD =item.rating \\* MERGEFORMAT </w:instrText>
            </w:r>
            <w:r>
              <w:fldChar w:fldCharType="separate"/>
            </w:r>
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>«=item.rating»</w:t>
            </w:r>
            <w:r>
              <w:fldChar w:fldCharType="end"/>
            </w:r>
          </w:p>
        </w:tc>
      </w:tr>
      <w:tr w:rsidR="00757DAD" w14:paraId="2D3C09BC" w14:textId="77777777" w:rsidTr="006333C3">
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="2202" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="04A961B7" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:fldChar w:fldCharType="begin"/>
            </w:r>
            <w:r>
              <w:instrText xml:space="preserve"> MERGEFIELD items:endEach \\* MERGEFORMAT </w:instrText>
            </w:r>
            <w:r>
              <w:fldChar w:fldCharType="separate"/>
            </w:r>
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>«items:endEach»</w:t>
            </w:r>
            <w:r>
              <w:fldChar w:fldCharType="end"/>
            </w:r>
          </w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="4285" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="71165BFB" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3"/>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="2029" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="01D3965C" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3"/>
        </w:tc>
      </w:tr>
    </w:tbl>
    document

    assert_xml_equal <<-document, result
    <w:tbl>
      <w:tblPr>
        <w:tblStyle w:val="TableGrid"/>
        <w:tblW w:w="0" w:type="auto"/>
        <w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/>
      </w:tblPr>
      <w:tblGrid>
        <w:gridCol w:w="2202"/>
        <w:gridCol w:w="4285"/>
        <w:gridCol w:w="2029"/>
      </w:tblGrid>
      <w:tr w:rsidR="00757DAD" w14:paraId="1BD2E50A" w14:textId="77777777" w:rsidTr="006333C3">
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="2202" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="41ACB3D9" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>1.</w:t>
            </w:r>
          </w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="4285" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="197C6F31" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>Milk</w:t>
            </w:r>
          </w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="2029" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="55C258BB" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>***</w:t>
            </w:r>
          </w:p>
        </w:tc>
      </w:tr><w:tr w:rsidR="00757DAD" w14:paraId="1BD2E50A" w14:textId="77777777" w:rsidTr="006333C3">
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="2202" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="41ACB3D9" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>2.</w:t>
            </w:r>
          </w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="4285" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="197C6F31" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>Sugar</w:t>
            </w:r>
          </w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="2029" w:type="dxa"/>
          </w:tcPr>
          <w:p w14:paraId="55C258BB" w14:textId="77777777" w:rsidR="00757DAD" w:rsidRDefault="00757DAD" w:rsidP="006333C3">
            <w:r>
              <w:rPr><w:noProof/></w:rPr>
              <w:t>**</w:t>
            </w:r>
          </w:p>
        </w:tc>
      </w:tr>
    </w:tbl>

    document
  end

  def test_multi_row_table_loop
    item = Struct.new(:index, :label, :body)
    context = {"foods" => [item.new("1.", "Milk", "Milk is a white liquid."),
                           item.new("2.", "Sugar", "Sugar is the generalized name for carbohydrates.")]}
    result = process(<<-document, context)
      <w:tbl>
         <w:tr w:rsidR="00F23752" w14:paraId="3FF89DEC" w14:textId="77777777" w:rsidTr="00213ACD">
            <w:tc>
               <w:tcPr>
                  <w:tcW w:w="2235" w:type="dxa" />
                  <w:shd w:val="clear" w:color="auto" w:fill="auto" />
               </w:tcPr>
               <w:p w14:paraId="7630A6C6" w14:textId="699D0C71" w:rsidR="00F23752" w:rsidRDefault="00F23752" w:rsidP="003F16E3">
                  <w:fldSimple w:instr=" MERGEFIELD foods:each(food) \\* MERGEFORMAT ">
                     <w:r w:rsidR="00213ACD">
                        <w:rPr><w:noProof /></w:rPr>
                        <w:t>«foods:each(food)»</w:t>
                     </w:r>
                  </w:fldSimple>
               </w:p>
            </w:tc>
            <w:tc>
               <w:tcPr>
                  <w:tcW w:w="6287" w:type="dxa" />
                  <w:shd w:val="clear" w:color="auto" w:fill="auto" />
               </w:tcPr>
               <w:p w14:paraId="437AFC74" w14:textId="77777777" w:rsidR="00F23752" w:rsidRDefault="00F23752" w:rsidP="003F16E3" />
            </w:tc>
         </w:tr>
         <w:tr w:rsidR="00F23752" w14:paraId="320AE02B" w14:textId="77777777" w:rsidTr="00213ACD">
            <w:tc>
               <w:tcPr>
                  <w:tcW w:w="2235" w:type="dxa" />
                  <w:shd w:val="clear" w:color="auto" w:fill="8DB3E2" w:themeFill="text2" w:themeFillTint="66" />
               </w:tcPr>
               <w:p w14:paraId="3FCF3855" w14:textId="38FA7F3B" w:rsidR="00F23752" w:rsidRDefault="00F23752" w:rsidP="00F23752">
                  <w:fldSimple w:instr=" MERGEFIELD =food.index \\* MERGEFORMAT ">
                     <w:r w:rsidR="00213ACD">
                        <w:rPr><w:noProof /></w:rPr>
                        <w:t>«=food.index»</w:t>
                     </w:r>
                  </w:fldSimple>
               </w:p>
            </w:tc>
            <w:tc>
               <w:tcPr>
                  <w:tcW w:w="6287" w:type="dxa" />
                  <w:shd w:val="clear" w:color="auto" w:fill="8DB3E2" w:themeFill="text2" w:themeFillTint="66" />
               </w:tcPr>
               <w:p w14:paraId="0BB0E74E" w14:textId="4FA0D282" w:rsidR="00F23752" w:rsidRPr="00F576DA" w:rsidRDefault="00F23752" w:rsidP="00F23752">
                  <w:r w:rsidRPr="00F576DA">
                     <w:fldChar w:fldCharType="begin" />
                  </w:r>
                  <w:r w:rsidRPr="00F576DA">
                     <w:instrText xml:space="preserve"> MERGEFIELD =</w:instrText>
                  </w:r>
                  <w:r>
                     <w:instrText>food</w:instrText>
                  </w:r>
                  <w:r w:rsidRPr="00F576DA">
                     <w:instrText xml:space="preserve">.label \\* MERGEFORMAT </w:instrText>
                  </w:r>
                  <w:r w:rsidRPr="00F576DA">
                     <w:fldChar w:fldCharType="separate" />
                  </w:r>
                  <w:r w:rsidR="00213ACD">
                     <w:rPr>
                        <w:rFonts w:ascii="Comic Sans MS" w:hAnsi="Comic Sans MS" />
                        <w:noProof />
                     </w:rPr>
                     <w:t>«=food.label»</w:t>
                  </w:r>
                  <w:r w:rsidRPr="00F576DA">
                     <w:fldChar w:fldCharType="end" />
                  </w:r>
               </w:p>
            </w:tc>
         </w:tr>
         <w:tr w:rsidR="00213ACD" w14:paraId="1EA188ED" w14:textId="77777777" w:rsidTr="00213ACD">
            <w:tc>
               <w:tcPr>
                  <w:tcW w:w="8522" w:type="dxa" />
                  <w:gridSpan w:val="2" />
                  <w:shd w:val="clear" w:color="auto" w:fill="auto" />
               </w:tcPr>
               <w:p w14:paraId="3E9FF163" w14:textId="0F37CDFB" w:rsidR="00213ACD" w:rsidRDefault="00213ACD" w:rsidP="003F16E3">
                  <w:fldSimple w:instr=" MERGEFIELD =food.body \\* MERGEFORMAT ">
                     <w:r>
                        <w:rPr><w:noProof /></w:rPr>
                        <w:t>«=food.body»</w:t>
                     </w:r>
                  </w:fldSimple>
               </w:p>
            </w:tc>
         </w:tr>
         <w:tr w:rsidR="00213ACD" w14:paraId="34315A41" w14:textId="77777777" w:rsidTr="00213ACD">
            <w:tc>
               <w:tcPr>
                  <w:tcW w:w="2235" w:type="dxa" />
                  <w:shd w:val="clear" w:color="auto" w:fill="auto" />
               </w:tcPr>
               <w:p w14:paraId="1CA83F76" w14:textId="2622C490" w:rsidR="00213ACD" w:rsidRDefault="00213ACD" w:rsidP="003F16E3">
                  <w:r>
                     <w:fldChar w:fldCharType="begin" />
                  </w:r>
                  <w:r>
                     <w:instrText xml:space="preserve"> MERGEFIELD foods:endEach \\* MERGEFORMAT </w:instrText>
                  </w:r>
                  <w:r>
                     <w:fldChar w:fldCharType="separate" />
                  </w:r>
                  <w:r>
                     <w:rPr><w:noProof /></w:rPr>
                     <w:t>«foods:endEach»</w:t>
                  </w:r>
                  <w:r>
                     <w:fldChar w:fldCharType="end" />
                  </w:r>
               </w:p>
            </w:tc>
            <w:tc>
               <w:tcPr>
                  <w:tcW w:w="6287" w:type="dxa" />
                  <w:shd w:val="clear" w:color="auto" w:fill="auto" />
               </w:tcPr>
               <w:p w14:paraId="7D976602" w14:textId="77777777" w:rsidR="00213ACD" w:rsidRDefault="00213ACD" w:rsidP="003F16E3" />
            </w:tc>
         </w:tr>
      </w:tbl>
    document

    assert_equal "1. Milk Milk is a white liquid. 2. Sugar Sugar is the generalized name for carbohydrates.", text(result)
  end

  def test_conditional
    document = <<-documentxml
      <w:r><w:t xml:space="preserve">Anthony</w:t></w:r>
      <w:p>
        <w:fldSimple w:instr=" MERGEFIELD middle_name:if \\* MERGEFORMAT ">
          <w:r>
            <w:rPr><w:noProof/></w:rPr>
            <w:t>«middle_name:if»</w:t>
          </w:r>
        </w:fldSimple>
      </w:p>
      <w:p>
        <w:fldSimple w:instr=" MERGEFIELD =middle_name \\* MERGEFORMAT ">
          <w:r>
            <w:rPr><w:noProof/></w:rPr>
            <w:t>«=middle_name»</w:t>
          </w:r>
        </w:fldSimple>
      </w:p>
      <w:p>
        <w:fldSimple w:instr=" MERGEFIELD middle_name:endIf \\* MERGEFORMAT ">
          <w:r>
            <w:rPr><w:noProof/></w:rPr>
            <w:t>«middle_name:endIf»</w:t>
          </w:r>
        </w:fldSimple>
      </w:p>
      <w:r><w:t xml:space="preserve">Hall</w:t></w:r>
    documentxml
    result = process(document, {"middle_name" => "Michael"})
    assert_equal "Anthony Michael Hall", text(result)

    result = process(document, {"middle_name" => nil})
    assert_equal "Anthony Hall", text(result)
  end

  def test_conditional_with_predicate
    document = <<-documentxml
      <w:p>
        <w:fldSimple w:instr=" MERGEFIELD body:if(empty?) \\* MERGEFORMAT ">
          <w:r>
            <w:rPr><w:noProof/></w:rPr>
            <w:t>«body:if(empty?)»</w:t>
          </w:r>
        </w:fldSimple>
      </w:p>
      <w:p>
        <w:t>some content</w:t>
      </w:p>
      <w:p>
        <w:fldSimple w:instr=" MERGEFIELD body:endIf \\* MERGEFORMAT ">
          <w:r>
            <w:rPr><w:noProof/></w:rPr>
            <w:t>«body:endIf»</w:t>
          </w:r>
        </w:fldSimple>
      </w:p>
    documentxml
    result = process(document, {"body" => ""})
    assert_equal "some content", text(result)

    result = process(document, {"body" => "not empty"})
    assert_equal "", text(result)
  end

  private
  def process(document, context)
    @processor.process(wrap(document), context).to_xml
  end
end
