require_relative './headers/http_headers'

class Request
    attr_reader :lines, :req_method, :version, :headers, :route, :query, :ext, :path, :params, :services, :resolved

    def initialize(input, &block)
        @raw = input
        @lines = input.split("\r\n")
        @req_method, route, @version = @lines[0].split(' ')
        @route, query = route.split('?')
        @query = query&.split(/[\;,&]/)&.map { |v| get_query_pair(v) }&.to_h
        @query = {} if @query.nil?
        @headers = HTTPHeaders.from_raw @lines[1..-1]
        @services = block
        @resolved = false
    end

    ##
    # Resolve a request is the only operation that can cause an exception, so it's handled separately
    def resolve!
        @path, @ext, @params = @services.call :solve_route, @route
        @resolved = true
    end

    def service(*args, **kwargs, &block)
        @services.call *args, **kwargs, &block
    end

    def fetch(file)
        r = Request.new("GET #{file} #{@version}\r\n\r\n", &@services)
        service :render, r
    end

    def get_binding
        binding
    end
    
    def obligatory_method?
        req_method == 'GET' or req_method == 'HEAD' 
    end

    def bodiless_response?
        req_method == 'HEAD'
    end

    private
    
    def get_query_pair(query_val)
        i = query_val.index('=')
        return [query_val, ''] if i.nil?
        [query_val[0..i-1], query_val[i+1..-1]]
    end
end