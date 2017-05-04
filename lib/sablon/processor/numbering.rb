module Sablon
  module Processor
    class Numbering
      LIST_DEFINITION = <<-XML.gsub(/^\s+/, '').tr("\n", '')
        <w:num w:numId="%s">
          <w:abstractNumId w:val="%s" />
        </w:num>
      XML

      def self.process(doc, env)
        processor = new(doc)
        processor.manipulate env
        doc
      end

      def initialize(doc)
        @doc = doc
      end

      def manipulate(env)
        env.numbering.definitions.each do |definition|
          abstract_num_ref = find_definition(definition.style)
          abstract_num_copy = abstract_num_ref.dup
          abstract_num_copy['w:abstractNumId'] = definition.numid
          abstract_num_copy.xpath('./w:nsid').each(&:remove)
          container.prepend_child abstract_num_copy
          container.add_child(LIST_DEFINITION % [definition.numid, abstract_num_copy['w:abstractNumId']])
        end
        @doc
      end

      private
      def container
        @container ||= @doc.xpath('//w:numbering').first
      end

      def find_definition(style)
        abstract_num = @doc.xpath("//w:abstractNum[descendant-or-self::*[w:pStyle[@w:val='#{style}']]]").first
        if abstract_num
          abstract_num
        else
          raise ArgumentError, "Could not find w:abstractNum definition for style: #{style.inspect}"
        end
      end
    end
  end
end
