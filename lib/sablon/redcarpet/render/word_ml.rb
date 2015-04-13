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
          return '' if text.nil? || text == ''
          "<w:r><w:t xml:space=\"preserve\">#{text}</w:t></w:r>"
        end

        def emphasis(text)
          "<w:r><w:rPr><w:i /></w:rPr><w:t xml:space=\"preserve\">#{@raw_text}</w:t></w:r>"
        end

        def double_emphasis(text)
          "<w:r><w:rPr><w:b /></w:rPr><w:t xml:space=\"preserve\">#{@raw_text}</w:t></w:r>"
        end
      end
    end
  end
end
