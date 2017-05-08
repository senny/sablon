module Sablon::Processor::ContentType
  TYPES = {
    png: 'image/png',
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    gif: 'image/gif',
    bmp: 'image/bmp'
  }

  def self.process(doc, properties, out)
    TYPES.each do |extension, content_type|
      unless extensions(doc).include?(extension.to_s)
        node = Nokogiri::XML::Node.new('Default', doc)
        node['Extension'] = extension
        node['ContentType'] = content_type
        doc.root << node
      end
    end

    doc
  end

  private

  def self.extensions(doc)
    doc.root.children.map{ |child| child['Extension'] }.compact.uniq
  end
end
