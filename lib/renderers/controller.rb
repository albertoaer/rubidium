require_relative 'raw'
require_relative '../HTTPError'
require_relative '../response'

def controlled_execution(file, request)
    x = binding
    x.eval file
    return x.method(request.method.downcase).call(request)
end

class ControllerRenderer < RawRenderer
    def solve_response(res)
        return res if res.class == Response
        return Response.to res.last if res.first == :redirect
        Response.ok res.last, 'Content-Type' => content_type(res.first)
    end

    def render(request)
        src = yield :file, request.path
        solve_response controlled_execution(src, request)
    end
end