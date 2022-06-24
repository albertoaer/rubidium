require 'erb'
require_relative 'raw'
require_relative '../response'

class ERBRenderer < RawRenderer
    def render(request)
        template = ERB.new yield(:file, request.path)
        Response.ok template.result(request.get_binding), 'Content-Type' => 'text/html'
    end
end