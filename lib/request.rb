class Request
    attr_reader :lines, :method, :version, :attributes, :route, :query, :ext, :path, :params, :resolved

    def initialize(input, &block)
        @raw = input
        @lines = input.split("\r\n")
        @method, route, @version = @lines[0].split(' ')
        @route, query = route.split('?')
        @query = query&.split(/[\;,&]/)&.map { |v| get_query_pair(v) }&.to_h
        @attributes = @lines[1..-1].map { |field| field.split(': ') if field.length > 0 }
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

    private
    
    def get_query_pair(query_val)
        i = query_val.index('=')
        return [query_val, ''] if i.nil?
        [query_val[0..i-1], query_val[i+1..-1]]
    end
end