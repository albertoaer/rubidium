class Response
    attr_accessor :code, :concept, :attributes, :body
    
    def initialize(code, concept, body=nil, **attributes)
        @code = code
        @concept = concept
        @attributes = attributes
        @body = body
    end

    def self.ok(body, **attributes)
        Response.new 200, 'Ok', body, **attributes
    end

    def self.to(location, code=302, **attributes)
        attributes['Location'] = location
        Response.new 302, 'Redirect', **attributes
    end

    def [](att)
        @attributes[att]
    end

    def []=(att, val)
        @attributes[att] = val
    end

    def write(version)
        raise "Expecting block to write response into" unless block_given?
        yield "#{version} #{@code} #{@concept}\r\n"
        attributes.each { |k,v| yield "#{k.to_s}: #{v.to_s}\r\n" }
        yield "\r\n"
        yield body unless body.nil?
    end
end