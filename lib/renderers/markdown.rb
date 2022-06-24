require 'redcarpet'
require_relative 'raw'

class MarkdownRenderer < RawRenderer
    def initialize
        @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true);
    end

    def render(request)
        ["Content-Type: #{content_type :ext}", @markdown.render(yield :file, request.route)]
    end
end