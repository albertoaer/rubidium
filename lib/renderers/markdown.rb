require 'redcarpet'
require_relative 'raw'

class MarkdownRenderer
    def initialize
        @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true);
    end

    def render(file)
        return @markdown.render(yield :file, file), "text/html"
    end
end