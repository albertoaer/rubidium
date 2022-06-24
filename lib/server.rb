require 'socket'
require_relative 'policy'
require_relative 'service'
require_relative 'request'

class Server < Service
    include Policy::Restart

    attr_reader :config

    def setup(**config)
        @config = config
        @config[:ip] = @config[:ip] || Socket.ip_address_list.find_all { |a| a.ipv4? && !a.ipv4_loopback? }[-1].ip_address
        @config[:port] = @config[:port] || 80
    end

    def call(&services)
        @server.close unless @server.nil?
        puts "Listenning on #{@config[:ip]}:#{@config[:port]}"
        @server = TCPServer.new @config[:ip], @config[:port]

        while client = @server.accept
            petition = Proc.new do
                request_input = client.readpartial(2048)
                request = Request.new(request_input, &services)

                response = yield :render, request
                
                client.print "HTTP/1.1 200\r\n"
                response.each { |data| client.print data }

                client.close
            end
            services.call :launch, petition
        end
    end
end