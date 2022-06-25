require_relative '../response'

class RawRenderer
    def render(req)
        Response.new 200, 'Ok', yield(:file, req.path), 'Content-Type' => (content_type req.ext)
    end

    def content_type(ext)
        case ext
        when :html
            "text/html"
        when :js
            "text/javascript"
        when :css
            "text/css"
        when :txt
            "text/plain"
        when :json
            "application/json"
        end
    end
end