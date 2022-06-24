##
# It can be raised at any step in the rendering process avoiding the service to crash
# A middleware can use it to render a response, by default it will create an error http response
class HTTPError < StandardError
    attr_reader :code, :message, :concept

    def initialize(code, message, concept="")
        raise ArgumentError.new "Invalid error code" if code < 400 || code > 599
        @code = code
        @message = message
        @concept = concept
        super("[Error #{code}]: #{message}")
    end
end