module Sablon
  module Processor
    # manages adding relationships to the appropriate word/_rels/*.rels file
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

      def initialize_rids(zip_contents)
        zip_contents.keys.each do |entry_name|
          rels_file = Relationships.rels_filename(entry_name)
          if zip_contents[rels_file]
            content = Nokogiri::XML(zip_contents[rels_file])
            @rids[entry_name] = initial_file_rid(content)
          else
            @rids[entry_name] = 0
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
      def output_new_rids(zip_contents)
        @new_rels.each do |main_doc, rels|
          # determine which rels file to open and read it
          rels_file = Relationships.rels_filename(main_doc)
          xml_node = Nokogiri::XML(zip_contents[rels_file])

          # process the rels and write out new content
          process(xml_node, rels)
          zip_contents[rels_file] = xml_node.to_xml(indent: 0, save_with: 0)
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
