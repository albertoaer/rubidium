class Request
    attr_reader :lines, :method, :version, :attributes, :route, :query, :ext

    def initialize(input, &block)
        @raw = input
        @lines = input.split("\r\n")
        @method, route, @version = @lines[0].split(' ')
        @route, query = route.split('?')
        @query = query&.split(/[\;,&]/)&.map { |v| v.split('=') }&.to_h
        @attributes = @lines[1..-1].map { |field| field.split(': ') if field.length() > 0 }
        @ext = (File.extname @route)[1..-1]
        @ext = @ext.to_sym unless @ext.nil?
        @services = block
    end

    def service(*args, **kwargs, &block)
        @services.call *args, **kwargs, &block
    end

    def fetch(file)
        r = Request.new("GET #{file} #{@version}\r\n\r\n", &@services)
        service :render, r
    end
end