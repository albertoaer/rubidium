require_relative '../response'

class RawRenderer
    @@types = {html: "text/html", js: "application/javascript", css: "text/css",
                txt: "text/plain", json: "application/json", png: "image/png",
                jpeg: "image/jpeg", jpg: "image/jpg"}

    def append_types(**types)
        @@types.merge! types
    end

    def render(req)
        obligatory_only(req)
        Response.new 200, 'Ok', yield(:file, req.path), 'Content-Type' => (content_type req.ext)
    end

    def content_type(ext)
        @@types[ext]
    end

    def obligatory_only(req)
        raise HTTPError.new 405, 'Method not allowed' unless req.obligatory_method?
    end
end