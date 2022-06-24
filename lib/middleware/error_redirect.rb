require_relative 'middleware'
require_relative 'error_handler'

class ErrorRedirect < ErrorHandler
    def after(req, res)
        if @codes.include? res.code
            Response.to @default_route
        end
    end
end