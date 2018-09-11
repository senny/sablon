# At this time, Sablon doesn't support to keep original ratio of image.
# We develop these classes for extending this functionality.
module Sablon
  module Content
    class ImageOriginalRatio < Struct.new(:name, :data, :properties)
      # keep this attribute in case of Image (not ImageOriginalRatio).
      attr_accessor :local_rid
      attr_reader :rid_by_file

      MEASURES = { pixel: 'px', centimeter: 'cm', inch: 'in'}

      def initialize(source, attributes = {})
        attributes = Hash[attributes.map { |k, v| [k.to_s, v] }]
        if source.respond_to?(:read)
          name, img_data = process_readable(source, attributes)
        else
          name = File.basename(source)
          img_data = IO.binread(source)
        end
        super(name, img_data)
        @attributes = attributes
        @rid_by_file = {}
      end

      def self.id; :image_free_size end
      def self.wraps?(value) false end

      def inspect
        "#<Image #{name}:#{@rid_by_file}>"
      end

      def append_to(paragraph, display_node, env) end

      def width
        if @attributes["properties"]
          width_with_unit_array = @attributes["properties"][:width].split(/(\d+)/)
          unconverted_width = width_with_unit_array[1].to_i
          unit = width_with_unit_array[2]
          convert_to_emu(unit, unconverted_width)
        end
      end

      def height
        if @attributes["properties"]
          height_with_unit_array = @attributes["properties"][:height].split(/(\d+)/)
          unconverted_height = height_with_unit_array[1].to_i
          unit = height_with_unit_array[2]
          convert_to_emu(unit, unconverted_height)
        end
      end

      private

      def process_readable(source, attributes)
        if attributes['filename']
          name = attributes['filename']
        elsif source.respond_to?(:filename)
          name = source.filename
        else
          begin
            name = File.basename(source)
          rescue TypeError
            raise ArgumentError, "Error: Could not determine filename from source, try: `Sablon.content(readable_obj, filename: '...')`"
          end
        end
        #
        [File.basename(name), source.read]
      end

      # Convert centimeters or inches to Word specific emu format
      def convert_to_emu(unit, value)
        case unit
        when MEASURES[:pixel]
          value * 9525
        when MEASURES[:centimeter]
          value  * 360000
        when MEASURES[:inch]
          value * 914400
        else
          raise "Not support this format yet"
        end
      end
    end
    register Sablon::Content::ImageOriginalRatio
  end

  module Processor
    class Document
      class ImageBlock < ParagraphBlock
        def replace(image)
          nodes = [start_node] + body + [end_node]
          if image
            nodes.each do |node|
              pic_prop = node.at_xpath('.//pic:cNvPr', pic: 'http://schemas.openxmlformats.org/drawingml/2006/picture')
              pic_prop.attributes['name'].value = image.name if pic_prop
              blip = node.at_xpath('.//a:blip', a: 'http://schemas.openxmlformats.org/drawingml/2006/main')
              blip.attributes['embed'].value = image.local_rid if blip
              replace_with_sizes(node, image)
            end
          end

          start_field.remove
          end_field.remove
        end

        private

        def replace_with_sizes(node, image)
          drawing_size = node.at_xpath('.//wp:extent')
          if image.respond_to?(:width) && image.respond_to?(:height)
            drawing_size.attributes['cx'].value = image.width.to_s if drawing_size
            drawing_size.attributes['cy'].value = image.height.to_s if drawing_size
            pic_size = node.at_xpath('.//a:xfrm//a:ext', a: 'http://schemas.openxmlformats.org/drawingml/2006/main')
            pic_size.attributes['cx'].value = image.width.to_s if pic_size
            pic_size.attributes['cy'].value = image.height.to_s if pic_size
          end
        end
      end
    end
  end
end