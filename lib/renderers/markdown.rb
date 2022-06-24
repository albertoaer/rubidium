require 'redcarpet'
require_relative 'raw'

class MarkdownRenderer < RawRenderer
    def initialize
        @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    end

    def render(request)
        ["Content-Type: text/html", @markdown.render(yield :file, request.path)]
    end
end