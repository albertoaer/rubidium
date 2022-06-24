class RawRenderer
    def render(request)     
        ["Content-Type: #{content_type request.ext}", yield(:file, request.path)]
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