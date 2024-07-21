# -*- coding: utf-8 -*-
require "test_helper"
require "support/document_xml_helper"
require "support/xml_snippets"

class ProcessorDocumentTest < Sablon::TestCase
  include DocumentXMLHelper
  include XMLSnippets

  TestHandler = Struct.new(:handles, :statement) do
    def handles?(*)
      handles
    end

    def build_statement(*)
      statement
    end
  end

  def setup
    super
    @processor = Sablon::Processor::Document
    @processor.instance_variable_set(:@default_field_handler, nil)
  end

  def teardown
    super
    @processor.instance_variable_set(:@default_field_handler, nil)
  end

  def test_register_field_handler
    test_handlers = {}
    handler = TestHandler.new(nil, nil)
    #
    @processor.stub(:field_handlers, test_handlers) do
      @processor.register_field_handler 'test', handler
      #
      assert @processor.field_handlers.keys.include?(:test), 'handler was not added to handlers hash'
      assert_equal handler, @processor.field_handlers[:test]
      #
      # try and re-register a handler
      handler2 = 'test'
      e = assert_raises(ArgumentError, 'Should not have been able to overwrite a handler using this method') do
        @processor.register_field_handler 'test', handler2
      end
      #
      assert_equal "Handler named: 'test' already exists. Use `replace_field_handler` instead.", e.message
      assert_equal handler, @processor.field_handlers[:test], 'pre-existing handler should not have been changed'
    end
  end

  def test_register_default_field_handler
    handler = TestHandler.new(nil, nil)
    @processor.register_field_handler :default, handler
    #
    assert !@processor.field_handlers.keys.include?(:default), 'default handler should not get added to the handlers hash'
    assert_equal handler, @processor.default_field_handler
    #
    # try and re-register a handler
    handler2 = 'test'
    e = assert_raises(ArgumentError, 'Should not have been able to overwrite a handler using this method') do
      @processor.register_field_handler 'default', handler2
    end
    #
    assert_equal "Handler named: 'default' already exists. Use `replace_field_handler` instead.", e.message
    assert_equal handler, @processor.default_field_handler, 'pre-existing default handler should not have been changed'
  end

  def test_remove_field_handler
    handler = TestHandler.new(nil, nil)
    test_handlers = { test: handler }
    #
    @processor.stub(:field_handlers, test_handlers) do
      removed = @processor.remove_field_handler 'test'
      #
      assert !@processor.field_handlers.keys.include?(:test), 'handler was not removed from handlers hash'
      assert_equal handler, removed, 'handler should have been returned after removal'
      #
      # try and remove a non-existent handler
      removed = @processor.remove_field_handler '_i_do_not_exist_'
      assert_nil removed, 'Removing a non-existent handler should just return nil'
    end
  end

  def test_remove_default_field_handler
    handler = TestHandler.new(nil, nil)
    @processor.instance_variable_set(:@default_field_handler, handler)
    #
    removed = @processor.remove_field_handler :default
    assert_equal handler, removed, 'default handler should have been returned after removal'
    #
    # try and remove the default handler again
    removed = @processor.remove_field_handler :default
    assert_nil removed, 'Removing a non-existent default handler should just return nil'
  end


  def test_replace_field_handler
    handler = TestHandler.new(nil, nil)
    handler2 = TestHandler.new(false, nil)
    test_handlers = { test: handler }
    #
    @processor.stub(:field_handlers, test_handlers) do
      assert @processor.field_handlers.keys.include?(:test), 'the test key has to already exist for this test to be meaningful'
      @processor.replace_field_handler :test, handler2
      #
      assert @processor.field_handlers.keys.include?(:test), 'The test key remains in the hash'
      assert_equal handler2, @processor.field_handlers[:test], 'The handler was not replaced'
    end
  end

  def test_replace_default_field_handler
    handler = TestHandler.new(nil, nil)
    handler2 = TestHandler.new(false, nil)
    @processor.instance_variable_set(:@default_field_handler, handler)
    #
    @processor.replace_field_handler 'default', handler2
    assert_equal handler2, @processor.default_field_handler, 'The default handler was not replaced'
  end


  def test_simple_field_replacement
    result = process(snippet("simple_field"), {"first_name" => "Jack"})

    assert_equal "Hello! My Name is Jack , nice to meet you.", text(result)
    assert_xml_equal <<-document, result
    <w:p>
      <w:r><w:t xml:space="preserve">Hello! My Name is </w:t></w:r>
        <w:r w:rsidR="004B49F0">
          <w:rPr><w:noProof/></w:rPr>
          <w:t>Jack</w:t>
        </w:r>
      <w:r w:rsidR="00BE47B1"><w:t xml:space="preserve">, nice to meet you.</w:t></w:r>
    </w:p>
    document
  end

  def test_simple_field_replacement_with_nil
    result = process(snippet("simple_field"), {"first_name" => nil})

    assert_equal "Hello! My Name is , nice to meet you.", text(result)
    assert_xml_equal <<-document, result
    <w:p>
      <w:r><w:t xml:space="preserve">Hello! My Name is </w:t></w:r>
      <w:r w:rsidR="00BE47B1"><w:t xml:space="preserve">, nice to meet you.</w:t></w:r>
    </w:p>
    document
  end

  def test_simple_field_with_styling_replacement
    result = process(snippet("simple_field_with_styling"), {"system_name" => "Sablon 1 million"})

    assert_equal "Generated by Sablon 1 million", text(result)
    assert_xml_equal <<-document, result
    <w:p>
      <w:r><w:t xml:space="preserve">Generated by </w:t></w:r>
        <w:r w:rsidR="002D39A9">
          <w:rPr>
            <w:rFonts w:hint="eastAsia"/>
            <w:noProof/>
          </w:rPr>
          <w:t>Sablon 1 million</w:t>
        </w:r>
    </w:p>
    document
  end

  def test_context_can_contain_string_and_symbol_keys
    context = {"first_name" => "Jack", last_name: "Davis"}
    result = process(snippet("simple_fields"), context)
    assert_equal "Jack Davis", text(result)
  end

  def test_complex_field_replacement
    result = process(snippet("complex_field"), {"last_name" => "Zane"})

    assert_equal "Hello! My Name is Zane , nice to meet you.", text(result)
    assert_xml_equal <<-document, result
    <w:p>
      <w:r><w:t xml:space="preserve">Hello! My Name is </w:t></w:r>
      <w:r w:rsidR="004B49F0">
        <w:rPr><w:b/><w:noProof/></w:rPr>
        <w:t>Zane</w:t>
      </w:r>
      <w:r w:rsidR="00BE47B1"><w:t xml:space="preserve">, nice to meet you.</w:t></w:r>
    </w:p>
    document
  end

  def test_complex_field_replacement_with_split_field
    result = process(snippet("edited_complex_field"), {"first_name" => "Daniel"})

    assert_equal "Hello! My Name is Daniel , nice to meet you.", text(result)
    assert_xml_equal <<-document, result
    <w:p>
      <w:r><w:t xml:space="preserve">Hello! My Name is </w:t></w:r>
      <w:r w:rsidR="00441382">
        <w:rPr><w:noProof/></w:rPr>
        <w:t>Daniel</w:t>
      </w:r>
      <w:r w:rsidR="00BE47B1"><w:t xml:space="preserve">, nice to meet you.</w:t></w:r>
    </w:p>
    document
  end

  def test_paragraph_block_replacement
    result = process(snippet("paragraph_loop"), {"technologies" => ["Ruby", "Rails"]})

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
    result = process(snippet("paragraph_loop_within_table_cell"), {"technologies" => ["Puppet", "Chef"]})

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

  def test_paragraph_block_within_empty_table_cell_and_blank_replacement
    result = process(snippet("paragraph_loop_within_table_cell"), {"technologies" => []})

    assert_equal "", text(result)
    assert_xml_equal <<-document, result
    <w:tbl>
      <w:tblGrid>
        <w:gridCol w:w="2202"/>
      </w:tblGrid>
      <w:tr w:rsidR="00757DAD">
        <w:tc>
          <w:p></w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
    document
  end

  def test_adds_blank_paragraph_to_empty_table_cells
    result = process(snippet("corrupt_table"), {})
    assert_xml_equal <<-document, result
<w:tbl>
  <w:tblGrid>
    <w:gridCol w:w="2202"/>
  </w:tblGrid>
  <w:tr w:rsidR="00757DAD">
    <w:tc>
      <w:p>
        Hans
      </w:p>
    </w:tc>

    <w:tc>
      <w:tcPr>
        <w:tcW w:w="5635" w:type="dxa"/>
      </w:tcPr>
      <w:p></w:p>
    </w:tc>
  </w:tr>

  <w:tr w:rsidR="00757DAD">
    <w:tc>
      <w:tcPr>
        <w:tcW w:w="2202" w:type="dxa"/>
      </w:tcPr>
      <w:p>
        <w:r>
          <w:rPr><w:noProof/></w:rPr>
          <w:t>1.</w:t>
        </w:r>
      </w:p>
    </w:tc>

    <w:tc>
      <w:p>
        </w:p><w:p>
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
    result = process(snippet("table_row_loop"), {"items" => [item.new("1.", "Milk", "***"), item.new("2.", "Sugar", "**")]})

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

  def test_loop_over_collection_convertable_to_an_enumerable
    style_collection = Class.new do
      def to_ary
        ["CSS", "SCSS", "LESS"]
      end
    end

    result = process(snippet("paragraph_loop"), {"technologies" => style_collection.new})
    assert_equal "CSS SCSS LESS", text(result)
  end

  def test_loop_over_collection_not_convertable_to_an_enumerable_raises_error
    not_a_collection = Class.new {}

    assert_raises Sablon::ContextError do
      process(snippet("paragraph_loop"), {"technologies" => not_a_collection.new})
    end
  end

  def test_loop_with_missing_variable_raises_error
    e = assert_raises Sablon::ContextError do
      process(snippet("paragraph_loop"), {})
    end
    assert_equal "The expression «technologies» should evaluate to an enumerable but was: nil", e.message
  end

  def test_loop_with_missing_end_raises_error
    e = assert_raises Sablon::TemplateError do
      process(snippet("loop_without_ending"), {})
    end
    assert_equal "Could not find end field for «technologies:each(technology)». Was looking for «technologies:endEach»", e.message
  end

  def test_loop_incrementing_unique_ids
    context = {
      fruits: %w[Apple Blueberry Cranberry Date].map { |i| { name: i } },
      cars: %w[Silverado Serria Ram Tundra].map { |i| { name: i } }
    }
    #
    xml = Nokogiri::XML(process(snippet('loop_with_unique_ids'), context))
    #
    # all unique ids should get incremented to stay unique
    ids = xml.xpath("//*[local-name() = 'docPr']").map { |n| n.attr('id') }
    assert_equal %w[1 2 3 4], ids
    #
    ids = xml.xpath("//*[local-name() = 'cNvPr']").map { |n| n.attr('id') }
    assert_equal %w[1 2 3 4], ids
  end

  def test_conditional_with_missing_end_raises_error
    e = assert_raises Sablon::TemplateError do
      process(snippet("conditional_without_ending"), {})
    end
    assert_equal "Could not find end field for «middle_name:if». Was looking for «middle_name:endIf»", e.message
  end

  def test_multi_row_table_loop
    item = Struct.new(:index, :label, :body)
    context = {"foods" => [item.new("1.", "Milk", "Milk is a white liquid."),
                           item.new("2.", "Sugar", "Sugar is the generalized name for carbohydrates.")]}
    result = process(snippet("table_multi_row_loop"), context)

    assert_equal "1. Milk Milk is a white liquid. 2. Sugar Sugar is the generalized name for carbohydrates.", text(result)
  end

  def test_conditional
    result = process(snippet("conditional"), {"middle_name" => "Michael"})
    assert_equal "Anthony Michael Hall", text(result)

    result = process(snippet("conditional"), {"middle_name" => nil})
    assert_equal "Anthony Hall", text(result)
  end

  def test_simple_field_conditional_inline
    result = process(snippet("conditional_inline"), {"middle_name" => true})
    assert_equal "Anthony Michael Hall", text(result)
  end

  def test_complex_field_conditional_inline
    with_false = process(snippet("complex_field_inline_conditional"), {"boolean" => false})
    assert_equal "ParagraphBefore Before After ParagraphAfter", text(with_false)

    with_true = process(snippet("complex_field_inline_conditional"), {"boolean" => true})
    assert_equal "ParagraphBefore Before Content After ParagraphAfter", text(with_true)
  end

  def test_ignore_complex_field_spanning_multiple_paragraphs
    result = process(snippet("test_ignore_complex_field_spanning_multiple_paragraphs"),
                     {"current_time" => '14:53'})

    assert_equal "AUTOTEXT Header:Date \\* MERGEFORMAT Day Month Year 14:53", text(result)
    assert_xml_equal <<-document, result
    <w:p w14:paraId="2A8BFD66" w14:textId="77777777" w:rsidR="006F0A69" w:rsidRDefault="00E40CBA" w:rsidP="00670731">
      <w:r>
        <w:fldChar w:fldCharType="begin"/>
      </w:r>
      <w:r>
        <w:instrText xml:space="preserve"> AUTOTEXT  Header:Date  \\* MERGEFORMAT </w:instrText>
      </w:r>
      <w:r>
        <w:fldChar w:fldCharType="separate"/>
      </w:r>
      <w:r w:rsidR="006F0A69" w:rsidRPr="009A09E3">
        <w:t>Day Month Year</w:t>
      </w:r>
    </w:p>

    <w:p w14:paraId="71B65E52" w14:textId="613138CB" w:rsidR="001D1AF8" w:rsidRDefault="00E40CBA" w:rsidP="006C34C3">
      <w:pPr>
        <w:pStyle w:val="Address"/>
      </w:pPr>
      <w:r>
        <w:fldChar w:fldCharType="end"/>
      </w:r>
      <w:bookmarkEnd w:id="0"/>
    </w:p>

    <w:p w14:paraId="7C3EB778" w14:textId="78AB4714" w:rsidR="001D1AF8" w:rsidRPr="000C6261" w:rsidRDefault="00A35B65" w:rsidP="001D1AF8">
        <w:r>
          <w:rPr>
            <w:noProof/>
          </w:rPr>
          <w:t>14:53</w:t>
        </w:r>
    </w:p>
    document
  end

  def test_conditional_with_predicate
    result = process(snippet("conditional_with_predicate"), {"body" => ""})
    assert_equal "some content", text(result)

    result = process(snippet("conditional_with_predicate"), {"body" => "not empty"})
    assert_equal "", text(result)
  end

  def test_conditional_with_elsif_else_clauses
    result = process(snippet("conditional_with_elsif_else_clauses"), {'object' => OpenStruct.new(method_a: true, method_b: true)})
    assert_xml_equal <<-document, result
      <w:p>
        <w:t>Method A was true</w:t>
      </w:p>
    document

    result = process(snippet("conditional_with_elsif_else_clauses"), {'object' => OpenStruct.new(method_a: false, method_b: true)})
    assert_xml_equal <<-document, result
      <w:p>
        <w:t>Method B was true</w:t>
      </w:p>
    document

    result = process(snippet("conditional_with_elsif_else_clauses"), {'object' => OpenStruct.new(method_a: false, method_b: false)})
    assert_xml_equal <<-document, result
      <w:p>
        <w:t>Method A and B were false</w:t>
      </w:p>
    document
  end

  def test_inline_conditional_with_elsif_else_clauses
    result = process(snippet("conditional_inline_with_elsif_else_clauses"), {'object' => OpenStruct.new(method_a: true, method_b: true)})
    assert_xml_equal <<-document, result
      <w:p>
        <w:r><w:t>Before</w:t></w:r>
        <w:r><w:t xml:space="preserve"> </w:t></w:r>
        <w:r>
          <w:t>Method A was true</w:t>
        </w:r>
        <w:r>
          <w:t>After</w:t>
        </w:r>
      </w:p>
    document

    result = process(snippet("conditional_inline_with_elsif_else_clauses"), {'object' => OpenStruct.new(method_a: false, method_b: true)})
    assert_xml_equal <<-document, result
    <w:p>
      <w:r><w:t>Before</w:t></w:r>
      <w:r><w:t xml:space="preserve"> </w:t></w:r>
      <w:r>
        <w:t>Method B was true</w:t>
      </w:r>
      <w:r>
        <w:t>After</w:t>
      </w:r>
    </w:p>
    document

    result = process(snippet("conditional_inline_with_elsif_else_clauses"), {'object' => OpenStruct.new(method_a: false, method_b: false)})
    assert_xml_equal <<-document, result
    <w:p>
      <w:r><w:t>Before</w:t></w:r>
      <w:r><w:t xml:space="preserve"> </w:t></w:r>
      <w:r>
        <w:t>Method A and B were false</w:t>
      </w:r>
      <w:r>
        <w:t>After</w:t>
      </w:r>
    </w:p>
    document
  end

  def test_comment
    result = process(snippet("comment"), {})
    assert_equal "Before After", text(result)
  end

  def test_comment_block_and_comment_as_key
    result = process(snippet("comment_block_and_comment_as_key"), {comment: 'Contents of comment key'})

    assert_xml_equal <<-document, result
    <w:r><w:t xml:space="preserve">Before </w:t></w:r>
    <w:r><w:t xml:space="preserve">After </w:t></w:r>
    <w:p>
      <w:r w:rsidR="004B49F0">
        <w:rPr><w:noProof/></w:rPr>
        <w:t>Contents of comment key</w:t>
      </w:r>
    </w:p>
    document
  end

  def test_image_replacement
    base_path = Pathname.new(File.expand_path("../../", __FILE__))
    image = Sablon.content(:image, base_path + "fixtures/images/r2d2.jpg")
    result = process(snippet("image"), { "item" => { "image" => image } })

    assert_xml_equal <<-document, result
      <w:p>
      </w:p>
      <w:p>
      <w:r>
      <w:rPr>
        <w:noProof/>
      </w:rPr>
      <w:drawing>
        <wp:inline distT="0" distB="0" distL="0" distR="0">
          <wp:extent cx="1875155" cy="1249045"/>
          <wp:effectExtent l="0" t="0" r="0" b="0"/>
          <wp:docPr id="2" name="Picture 2"/>
          <wp:cNvGraphicFramePr>
            <a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/>
          </wp:cNvGraphicFramePr>
          <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
            <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
                <pic:nvPicPr>
                  <pic:cNvPr id="2" name="r2d2.jpg"/>
                  <pic:cNvPicPr/>
                </pic:nvPicPr>
                <pic:blipFill>
                  <a:blip r:embed="rId1235\">
                    <a:extLst>
                      <a:ext uri="{28A0092B-C50C-407E-A947-70E740481C1C}">
                        <a14:useLocalDpi xmlns:a14="http://schemas.microsoft.com/office/drawing/2010/main" val="0"/>
                      </a:ext>
                    </a:extLst>
                  </a:blip>
                  <a:stretch>
                    <a:fillRect/>
                  </a:stretch>
                </pic:blipFill>
                <pic:spPr>
                  <a:xfrm>
                    <a:off x="0" y="0"/>
                    <a:ext cx="1875155" cy="1249045"/>
                  </a:xfrm>
                  <a:prstGeom prst="rect">
                    <a:avLst/>
                  </a:prstGeom>
                </pic:spPr>
              </pic:pic>
            </a:graphicData>
          </a:graphic>
        </wp:inline>
      </w:drawing>
      </w:r>
      </w:p>
      <w:p>
      </w:p>
    document
  end

  private

  def process(document, context)
    env = Sablon::Environment.new(MockTemplate.new, context)
    env.document.current_entry = 'word/document.xml'
    @processor.process(wrap(document), env).to_xml
  end
end
