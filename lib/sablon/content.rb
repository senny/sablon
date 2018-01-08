module Sablon
  module Content
    class << self
      def wrap(value)
        case value
        when Sablon::Content
          value
        else
          if type = type_wrapping(value)
            type.new(value)
          else
            raise ArgumentError, "Could not find Sablon content type to wrap #{value.inspect}"
          end
        end
      end

      def make(type_id, *args)
        if types.key?(type_id)
          types[type_id].new(*args)
        else
          raise ArgumentError, "Could not find Sablon content type with id '#{type_id}'"
        end
      end

      def register(content_type)
        types[content_type.id] = content_type
      end

      def remove(content_type_or_id)
        types.delete_if {|k,v| k == content_type_or_id || v == content_type_or_id }
      end

      private
      def type_wrapping(value)
        types.values.reverse.detect { |type| type.wraps?(value) }
      end

      def types
        @types ||= {}
      end
    end

    # Handles simple text replacement of fields in the template
    class String < Struct.new(:string)
      include Sablon::Content
      def self.id; :string end
      def self.wraps?(value)
        value.respond_to?(:to_s)
      end

      def initialize(value)
        super value.to_s
      end

      def append_to(paragraph, display_node, env)
        string.scan(/[^\n]+|\n/).reverse.each do |part|
          if part == "\n"
            display_node.add_next_sibling Nokogiri::XML::Node.new "w:br", display_node.document
          else
            text_part = display_node.dup
            text_part.content = part
            display_node.add_next_sibling text_part
          end
        end
      end
    end

    # handles direct addition of WordML to the document template
    class WordML < Struct.new(:xml)
      include Sablon::Content
      def self.id; :word_ml end
      def self.wraps?(value) false end

      def initialize(value)
        super Nokogiri::XML.fragment(value)
      end

      def append_to(paragraph, display_node, env)
        # if all nodes are inline then add them to the existing paragraph
        # otherwise replace the paragraph with the new content.
        if all_inline?
          pr_tag = display_node.parent.at_xpath('./w:rPr')
          add_siblings_to(display_node.parent, pr_tag)
          display_node.parent.remove
        else
          add_siblings_to(paragraph)
          paragraph.remove
        end
      end

      # This allows proper equality checks with other WordML content objects.
      # Due to the fact the `xml` attribute is a live Nokogiri object
      # the default `==` comparison returns false unless it is the exact
      # same object being compared. This method instead checks if the XML
      # being added to the document is the same when the `other` object is
      # an instance of the WordML content class.
      def ==(other)
        if other.class == self.class
          xml.to_s == other.xml.to_s
        else
          super
        end
      end

      private

      # Returns `true` if all of the xml nodes to be inserted are
      def all_inline?
        (xml.children.map(&:node_name) - inline_tags).empty?
      end

      # Array of tags allowed to be a child of the w:p XML tag as defined
      # by the Open XML specification
      def inline_tags
        %w[w:bdo w:bookmarkEnd w:bookmarkStart w:commentRangeEnd
           w:commentRangeStart w:customXml
           w:customXmlDelRangeEnd w:customXmlDelRangeStart
           w:customXmlInsRangeEnd w:customXmlInsRangeStart
           w:customXmlMoveFromRangeEnd w:customXmlMoveFromRangeStart
           w:customXmlMoveToRangeEnd w:customXmlMoveToRangeStart
           w:del w:dir w:fldSimple w:hyperlink w:ins w:moveFrom
           w:moveFromRangeEnd w:moveFromRangeStart w:moveTo
           w:moveToRangeEnd w:moveToRangeStart m:oMath m:oMathPara
           w:pPr w:proofErr w:r w:sdt w:smartTag]
      end

      # Adds the XML to be inserted in the document as siblings to the
      # node passed in. Run properties are merged here because of namespace
      # issues when working with a document fragment
      def add_siblings_to(node, rpr_tag = nil)
        xml.children.reverse.each do |child|
          node.add_next_sibling child
          # merge properties
          next unless rpr_tag
          merge_rpr_tags(child, rpr_tag.children)
        end
      end

      # Merges the provided properties into the run proprties of the
      # node passed in. Properties are only added if they are not already
      # defined on the node itself.
      def merge_rpr_tags(node, props)
        # first assert that all child runs (w:r tags) have a w:rPr tag
        node.xpath('.//w:r').each do |child|
          child.prepend_child '<w:rPr></w:rPr>' unless child.at_xpath('./w:rPr')
        end
        #
        # merge run props, only adding them if they aren't already defined
        node.xpath('.//w:rPr').each do |pr_tag|
          existing = pr_tag.children.map(&:node_name)
          props.map { |pr| pr_tag << pr unless existing.include? pr.node_name }
        end
      end
    end

    # Handles conversion of HTML -> WordML and addition into template
    class HTML < Struct.new(:html_content)
      include Sablon::Content
      def self.id; :html end
      def self.wraps?(value) false end

      def initialize(value)
        super value
      end

      def append_to(paragraph, display_node, env)
        converter = HTMLConverter.new
        word_ml = WordML.new(converter.process(html_content, env))
        word_ml.append_to(paragraph, display_node, env)
      end
    end

    register Sablon::Content::String
    register Sablon::Content::WordML
    register Sablon::Content::HTML
  end
end
