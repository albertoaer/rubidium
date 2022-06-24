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
                request_input = client.readpartial(2048)
                response = get_response(request_input)
                write_response(response, &client.method(:print))

                client.close
            end
            @services.call :launch, petition
        end
    end

    private

    def get_response(request_input)
        begin
            request = Request.new(request_input, &@services)
            res = @services.call :render, request
            if res.first == :redirect
                ["HTTP/1.1 302 Redirect", "Location: #{res.last}", ""]
            else
                res.unshift 'HTTP/1.1 200 OK'
            end
        rescue HTTPError => e
            ["HTTP/1.1 #{e.code} #{e.concept}", ""]
        end
    end

    def write_response(response)
        response.each_with_index do |v, i|
            if i == response.length - 1
                yield "\r\n"
                yield v    
            else
                yield v
                yield "\r\n"
            end
        end
    end
end