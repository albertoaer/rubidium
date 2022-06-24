def controlled_execution(file, req)
    x = binding
    x.eval file
    return x.method(:render).call(req)
end

class ControllerRenderer
    def render(file, request, &services)
        ext = File.extname file
        case ext
        when '.rb'
            filedata = services.call(:file, file)
            return controlled_execution(filedata, request), 'text/html'
        end
    end
end