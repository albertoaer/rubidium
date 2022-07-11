require 'socket'
require_relative 'service'
require_relative '../request'
require_relative '../http_error'
require_relative '../middleware/middleware'

class Server < Service
    policy :restart
    policy :inspect

    attr_reader :config

    def setup(**config)
        @config = config
        @config[:ip] = @config[:ip] || Socket.ip_address_list.find_all { |a| a.ipv4? && !a.ipv4_loopback? }[-1].ip_address
        @config[:port] = @config[:port] || 80
        @middleware_before = []
        @middleware_after = []
    end

    def use(middleware, mode=:both)
        raise "Wrong mode: #{mode}" unless [:before, :after, :both].include? mode
        raise "Expecting a middleware object" unless middleware.class.include? Middleware
        @middleware_before.append middleware.method(:before) if mode != :after
        @middleware_after.unshift middleware.method(:after) if mode != :before
    end

    def before(&block) @middleware_before.append block end
    
    def after(&block) @middleware_after.unshift block end

    def call
        @server.close unless @server.nil?
        puts "Listenning on #{@config[:ip]}:#{@config[:port]}"
        @server = TCPServer.new @config[:ip], @config[:port]

        loop do
            client = @server.accept
            petition = Proc.new do
                keep_alive = true
                while keep_alive
                    request_input = client.readpartial 2048
                    request = Request.new request_input, &@services
                    keep_alive = request.headers.get('Connection')&.strip&.downcase == 'keep-alive'
                    response = get_response request
                    response.headers.include 'Connection', 'keep-alive' if keep_alive
                    response.write 'HTTP/1.1', request.bodiless_response?, &client.method(:print)
                end
                client.close
            end
            @services.call :launch, petition
        end
    end

    private

    def render(request)
        begin
            @services.call :render, request
        rescue HTTPError => e
            puts e.inspect
            e.as_response
        end
    end

    def get_response(request)
        @middleware_before.each do |func|
            ans = func.call request
            request = ans if ans.class == Request
            return ans if ans.class == Response
        end
        response = render request
        @middleware_after.each do |func|
            ans = func.call request, response
            return ans if ans.class == Response
        end
        response
    end
end