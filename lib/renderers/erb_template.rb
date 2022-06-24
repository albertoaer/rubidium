require 'erb'
require_relative 'raw'

class ERBRenderer < RawRenderer
    def render(request)
        template = ERB.new yield(:file, request.path)
        ["Content-Type: text/html", template.result(request.get_binding)]
    end
end