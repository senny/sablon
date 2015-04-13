module Sablon
  module Redcarpet
    module Render
      class WordML < ::Redcarpet::Render::Base
        def linebreak
          "</w:p><w:p>"
        end

        def header(title, level)
          style = "Heading#{level}"

          "<w:p><w:pPr><w:pStyle w:val=\"#{style}\"/></w:pPr>#{title}</w:p>"
        end

        def paragraph(text)
          "<w:p>#{text}</w:p>"
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

        LIST_PATTERN = <<-XML.gsub("\n", "")
<w:p>
<w:pPr>
<w:pStyle w:val="%s" />
</w:pPr>
%s
</w:p>
XML
        LIST_STYLE_MAPPING = {
          ordered: "ListNumber",
          unordered: "ListBullet"
        }

        def list_item(content, list_type)
          list_style = LIST_STYLE_MAPPING[list_type]
          LIST_PATTERN % [list_style, content]
        end
      end
    end
  end
end
