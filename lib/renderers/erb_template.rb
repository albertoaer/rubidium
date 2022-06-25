require 'erb'
require_relative 'raw'
require_relative '../response'

class ERBRenderer < RawRenderer
    def render(req)
        template = ERB.new yield(:file, req.path)
        Response.ok template.result(req.get_binding), 'Content-Type' => 'text/html'
    end
end