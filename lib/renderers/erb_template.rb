require 'erb'
require_relative 'raw'
require_relative '../response'

class ERBRenderer < HTMLRenderer
    def render(req)
        template = ERB.new yield(:file, req.path)
        res = Response.ok template.result(req.get_binding), 'Content-Type' => 'text/html'
        validate_html res.body
        res
    end
end