# manages adding relationships to the appropriate word/_rels/*.rels file
module Sablon
  module Processor
    class Relationships
      BASE_URL = 'http://schemas.openxmlformats.org'.freeze
      YEAR = '2006'.freeze
      PICTURE_NS_URI = "#{BASE_URL}/drawingml/#{YEAR}/picture".freeze
      MAIN_NS_URI = "#{BASE_URL}/drawingml/#{YEAR}/main".freeze
      RELATIONSHIPS_NS_URI = "#{BASE_URL}/package/#{YEAR}/relationships".freeze
      IMAGE_TYPE = "#{BASE_URL}/officeDocument/#{YEAR}/relationships/image".freeze

      def self.rels_filename(entry_name)
        rels_file = "#{File.basename(entry_name)}.rels"
        File.join(File.dirname(entry_name), '_rels', rels_file)
      end

      def initialize
        @new_rels = {}
        @rids = {}
      end

      def initialize_rids(zip_path)
        Zip::File.open(zip_path) do |archive|
          archive.each do |main_doc|
            rels_file = Relationships.rels_filename(main_doc.name)
            entry = archive.find_entry(rels_file)
            if entry
              content = Nokogiri::XML(entry.get_input_stream.read)
              @rids[main_doc.name] = initial_file_rid(content)
            else
              @rids[main_doc.name] = 0
            end
          end
        end
      end

      # registers a new relationship for the main file and returns the Id
      def register_relationship(entry_name, attr_hash)
        @rids[entry_name] += 1
        attr_hash['Id'] = "rId#{@rids[entry_name]}"
        #
        @new_rels[entry_name] = [] unless @new_rels[entry_name]
        @new_rels[entry_name] << attr_hash
        #
        attr_hash['Id']
      end

      # outputs all of the new rIds to each respective relationships file
      # TODO: Add logic to create a brand new rels file for an entry if needed
      def output_new_rids(zip_path, zip_out)
        Zip::File.open(zip_path) do |archive|
          @new_rels.each do |main_doc, rels|
            # determine which rels file to open and read it
            rels_file = Relationships.rels_filename(main_doc)
            entry = archive.get_entry(rels_file)
            content = Nokogiri::XML(entry.get_input_stream.read)

            # process the rels and write out new content
            zip_out.put_next_entry(entry.name)
            content = process(content, rels).to_xml(indent: 0, save_with: 0)
            zip_out.write(content)
          end
        end
      end

      private

      def process(xml_node, rels)
        relationships = xml_node.at_xpath('r:Relationships', r: RELATIONSHIPS_NS_URI)
        #
        rels.each do |attr_hash|
          node_attr = attr_hash.map { |k, v| format('%s="%s"', k, v) }.join(' ')
          relationships.add_child("<Relationship #{node_attr} />")
        end
        #
        xml_node
      end

      def initial_file_rid(xml_node)
        xml_node.xpath('r:Relationships/r:Relationship', 'r' => RELATIONSHIPS_NS_URI).inject(0) do |max ,n|
          id = n.attributes['Id'].to_s[3..-1].to_i
          [id, max].max
        end
      end
    end
  end
end
