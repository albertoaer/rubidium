require 'socket'
require_relative 'service'
require_relative 'request'
require_relative 'HTTPError'

class Server < Service
    policy :restart
    policy :inspect

    attr_reader :config

    def setup(**config)
        @config = config
        @config[:ip] = @config[:ip] || Socket.ip_address_list.find_all { |a| a.ipv4? && !a.ipv4_loopback? }[-1].ip_address
        @config[:port] = @config[:port] || 80
    end

    def call
        @server.close unless @server.nil?
        puts "Listenning on #{@config[:ip]}:#{@config[:port]}"
        @server = TCPServer.new @config[:ip], @config[:port]

        while client = @server.accept
            petition = Proc.new do
                request_input = client.readpartial 2048
                response = get_response request_input
                response.write 'HTTP/1.1', &client.method(:print)
                client.close
            end
            @services.call :launch, petition
        end
    end

    private

    def get_response(request_input)
        begin
            request = Request.new(request_input, &@services)
            @services.call :render, request
        rescue HTTPError => e
            e.as_response
        end
    end
end