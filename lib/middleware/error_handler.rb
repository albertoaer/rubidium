require_relative 'middleware'

class ErrorHandler
    include Middleware
    attr_reader :codes, :default_route
    
    def initialize(default_route, *codes)
        raise "Must be at least one error code atached" if codes.empty?
        codes.each do |c|
            "Invalid error code" if c < 400 || c > 599
        end
        @codes = codes
        @default_route = default_route
    end

    def after(req, res)
        if @codes.include? res.code
            nres = req.fetch(@default_route)
            if nres.code < 400 and nres.code > 299
                nres
            else
                res.headers = nres.headers
                res.body = nres.body
                res
            end
        end
    end
end