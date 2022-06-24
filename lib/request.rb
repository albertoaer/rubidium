class Request
    attr_reader :lines, :method, :version, :attributes, :route, :ext

    def initialize(input, &block)
        @lines = input.split("\r\n")
        @method, @route, @version = @lines[0].split(' ')
        @attributes = @lines[1..-1].map { |field| field.split(': ') if field.length() > 0 }
        @ext = (File.extname @route)[1..-1]
        @ext = @ext.to_sym unless @ext.nil?
        @services = block
    end

    def service(*args, **kwargs, &block)
        @services.call *args, **kwargs, &block
    end
end