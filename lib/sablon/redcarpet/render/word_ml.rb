module Sablon
  module Redcarpet
    module Render
      class WordML < ::Redcarpet::Render::Base
        PARAGRAPH_PATTERN = <<-XML.gsub("\n", "")
<w:p>
<w:pPr>
<w:pStyle w:val="%s" />
</w:pPr>
%s
</w:p>
XML

        def linebreak
          "<w:r><w:br/></w:r>"
        end

        def header(title, level)
          heading_style = "Heading#{level}"
          PARAGRAPH_PATTERN % [heading_style, title]
        end

        def paragraph(text)
          PARAGRAPH_PATTERN % ["Paragraph", text]
        end

        def normal_text(text)
          @raw_text = text
          return '' if text.nil? || text == '' || text == "\n"
          "<w:r><w:t xml:space=\"preserve\">#{text}</w:t></w:r>"
        end

        def emphasis(text)
          "<w:r><w:rPr><w:i /></w:rPr><w:t xml:space=\"preserve\">#{@raw_text}</w:t></w:r>"
        end

        def double_emphasis(text)
          "<w:r><w:rPr><w:b /></w:rPr><w:t xml:space=\"preserve\">#{@raw_text}</w:t></w:r>"
        end

        def list(content, list_type)
          content
        end

        LIST_STYLE_MAPPING = {
          ordered: "ListNumber",
          unordered: "ListBullet"
        }

        def list_item(content, list_type)
          list_style = LIST_STYLE_MAPPING[list_type]
          PARAGRAPH_PATTERN % [list_style, content]
        end
      end
    end
  end
end
