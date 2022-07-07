require 'redcarpet'
require_relative 'raw'
require_relative '../response'

class MarkdownRenderer < RawRenderer
    def initialize
        @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
    end

    def render(req)
        obligatory_only(req)
        Response.ok @markdown.render(yield :file, req.path), 'Content-Type' => 'text/html'
    end
end