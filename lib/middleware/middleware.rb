##
# Middleware conforms the layers that will navigate through the request and response
# Each middleware wraps the lower one, the 'before' method is executed, then the next middleware and at the end the 'after' method
module Middleware
    ##
    # Is invoked between the client request and the controller rendering
    # Might return either a new request or a response to the client
    def before(req)
    end

    ##
    # Is invoked between the controller rendering and the response to the client
    # Might return a response directly to the client
    def after(req, res)
    end
end