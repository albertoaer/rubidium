require_relative 'raw'
require_relative '../HTTPError'

def controlled_execution(file, request)
    x = binding
    x.eval file
    return x.method(request.method.downcase).call(request)
end

class ControllerRenderer < RawRenderer
    def solve_response(response)
        return response if response.first == :redirect
        ["Content-Type: #{content_type response.first}", response.last]
    end

    def render(request)
        src = case request.ext
        when :rb
            filedata = yield :file, request.route
        when nil
            filedata = yield :file, request.route + '.rb'
        end
        solve_response controlled_execution(filedata, request)
    end
end