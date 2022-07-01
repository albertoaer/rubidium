require_relative './headers/http_headers'

class Response
    attr_accessor :code, :concept, :headers, :body
    
    def initialize(code, concept, body=nil, **headers)
        @code = code
        @concept = concept
        @headers = HTTPHeaders.from_kv headers
        @body = body
    end

    def self.default(**headers)
        Response.new 204, 'No Content', **headers
    end

    def self.ok(body, **headers)
        Response.new 200, 'Ok', body, **headers
    end

    def self.to(location, code=302, **headers)
        headers['Location'] = location
        Response.new code, 'Redirect', **headers
    end

    def write(version)
        raise "Expecting block to write response into" unless block_given?
        yield "#{version} #{@code} #{@concept}\r\n"
        headers.include 'Content-Length', body.nil? ? 0 : body.length
        headers.each { |k,v| yield "#{k.to_s}: #{v.to_s}\r\n" }
        yield "\r\n"
        yield body unless body.nil?
    end
end