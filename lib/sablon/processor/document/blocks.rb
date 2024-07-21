module Sablon
  module Processor
    class Document
      class Block
        attr_accessor :start_field, :end_field

        def self.enclosed_by(start_field, end_field)
          @blocks ||= [ImageBlock, RowBlock, ParagraphBlock, InlineParagraphBlock]
          block_class = @blocks.detect { |klass| klass.encloses?(start_field, end_field) }
          block_class.new start_field, end_field
        end

        def self.encloses?(start_field, end_field)
          parent(start_field) && parent(end_field)
        end

        def self.parent(node)
          node.ancestors(parent_selector).first
        end

        def self.parent_selector
          './/w:p'
        end

        def initialize(start_field, end_field)
          @start_field = start_field
          @end_field = end_field

          # update reference counts for control fields
          @start_field.block_reference_count += 1
          @end_field.block_reference_count += 1
        end

        def process(env)
          replaced_node = Nokogiri::XML::Node.new("tmp", start_node.document)
          replaced_node.children = Nokogiri::XML::NodeSet.new(start_node.document, body.map(&:dup))
          Processor::Document.process replaced_node, env
          replaced_node.children
        end

        def replace(content)
          content.each { |n| start_node.add_next_sibling n }
          remove_control_elements
        end

        def remove_control_elements
          body.each(&:remove)
          # we only want to remove the start and end nodes if they belong
          # to a single block.
          start_field.remove_parent(self.class.parent_selector)
          end_field.remove_parent(self.class.parent_selector)
        end

        def body
          return @body if defined?(@body)
          @body = []
          node = start_node
          while (node = node.next_element) && node != end_node
            @body << node
          end
          @body
        end

        def start_node
          @start_node ||= self.class.parent(start_field)
        end

        def end_node
          @end_node ||= self.class.parent(end_field)
        end
      end

      class RowBlock < Block
        def self.parent_selector
          './/w:tr'
        end

        def self.encloses?(start_field, end_field)
          super && parent(start_field) != parent(end_field)
        end
      end

      class ParagraphBlock < Block
        def self.encloses?(start_field, end_field)
          super && parent(start_field) != parent(end_field)
        end
      end

      class ImageBlock < Block
        def self.encloses?(start_field, end_field)
          start_field.expression.start_with?('@')
        end

        def replace(image)
          # we need to include the start and end nodes in case the image is
          # inline with the merge fields
          nodes = [start_node] + body + [end_node]
          #
          if image
            nodes.each do |node|
              pic_prop = node.at_xpath('.//pic:cNvPr', pic: 'http://schemas.openxmlformats.org/drawingml/2006/picture')
              pic_prop.attributes['name'].value = image.name if pic_prop
              blip = if File.extname(image.name) == '.svg'
                node.at_xpath('.//asvg:svgBlip', asvg: 'http://schemas.microsoft.com/office/drawing/2016/SVG/main')
              else
                node.at_xpath('.//a:blip', a: 'http://schemas.openxmlformats.org/drawingml/2006/main')
              end
              blip.attributes['embed'].value = image.local_rid if blip
              drawing_size = node.at_xpath('.//wp:extent')

              # if image properties are defined, the size of the placeholder
              # image should be replaced with the actual values
              if image.width && image.height
                drawing_size.attributes['cx'].value = image.width.to_s if drawing_size
                drawing_size.attributes['cy'].value = image.height.to_s if drawing_size
                pic_size = node.at_xpath('.//a:xfrm//a:ext', a: 'http://schemas.openxmlformats.org/drawingml/2006/main')
                pic_size.attributes['cx'].value = image.width.to_s if pic_size
                pic_size.attributes['cy'].value = image.height.to_s if pic_size
              end
            end
          end
          #
          start_field.remove
          end_field.remove
        end
      end

      class InlineParagraphBlock < Block
        def self.encloses?(start_field, end_field)
          super && parent(start_field) == parent(end_field)
        end

        def process(env)
          # Create a mock document structure so xpath queries will work
          # correctly on block level content (i.e. searching for the first
          # ancestor paragraph)
          doc_node = Nokogiri::XML::Node.new('document', start_node.document)
          doc_node.namespace = start_node.parent.namespace
          p_node = Nokogiri::XML::Node.new('p', doc_node.document)
          p_node.namespace = start_node.parent.namespace
          p_node.children = Nokogiri::XML::NodeSet.new(p_node.document,
                                                       body.map(&:dup))
          doc_node.children = Nokogiri::XML::NodeSet.new(p_node.document,
                                                         [p_node])
          Processor::Document.process doc_node, env

          if p_node.parent.nil?
            replace_parent_node(doc_node.children)
            []
          else
            p_node.children
          end
        end

        def remove_control_elements
          body.each(&:remove)
          start_field.remove
          end_field.remove
        end

        def start_node
          @start_node ||= start_field.end_node
        end

        def end_node
          @end_node ||= end_field.start_node
        end

        private

        # A block level insertion has occurred which must replace the
        # parent paragraph of the start node.
        def replace_parent_node(content)
          node = start_node.ancestors('.//w:p').first
          content.each { |n| node.add_next_sibling n }
          node.remove
        end
      end
    end
  end
end
