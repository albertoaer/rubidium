require_relative 'raw'

def controlled_execution(file, request)
    x = binding
    x.eval file
    return x.method(request.method.downcase).call(request)
end

class ControllerRenderer < RawRenderer
    def solve_response(response)
        ["Content-Type: #{content_type response[0]}\r\n",
        "\r\n",
        response[1]]
    end

    def render(request)
        src = case request.ext
        when :rb
            filedata = yield :file, request.route
        when nil
            filedata = yield :file, File.join(request.route, 'index.rb')
        end
        solve_response controlled_execution(filedata, request)
    end
end