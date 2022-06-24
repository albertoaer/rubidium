require_relative '../response'

class RawRenderer
    def render(request)
        Response.new 200, 'Ok', yield(:file, request.path), 'Content-Type' => (content_type request.ext)
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