class RawRenderer
    def render(file)
        ext = File.extname file
        return yield(:file, file), ext_repr(ext)
    end

    private

    def ext_repr(ext)
        case ext
        when ".html"
            "text/html"
        when ".js"
            "text/javascript"
        when ".css"
            "text/css"
        when ".txt"
            "text/plain"
        end
    end
end