module Sablon
  module Processor
    # Adds supported content types to the docx file
    class ContentType
      TYPES = {
        png: 'image/png',
        jpg: 'image/jpeg',
        jpeg: 'image/jpeg',
        gif: 'image/gif',
        bmp: 'image/bmp'
      }.freeze

      def self.process(doc)
        TYPES.each do |extension, content_type|
          next if extensions(doc).include?(extension.to_s)
          node = Nokogiri::XML::Node.new('Default', doc)
          node['Extension'] = extension
          node['ContentType'] = content_type
          doc.root << node
        end

        doc
      end

      def self.extensions(doc)
        doc.root.children.map { |child| child['Extension'] }.compact.uniq
      end
    end
  end
end
