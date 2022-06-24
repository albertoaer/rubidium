require 'socket'
require_relative 'policy'
require_relative 'service'

class Server < Service
    include Policy::Restart

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
                request = client.readpartial(2048)
                method, route, version = request.split("\r\n")[0].split(' ')
                #TODO: Create a request from the client readed data
                pairs = request.split("\r\n")[1..-1].map { |field| field.split(': ') if field.length() > 0 }

                data, type = yield :render, route
                
                client.print "HTTP/1.1 200\r\n"
                client.print "Content-Type: #{type}\r\n"
                client.print "\r\n"
                client.print data

                client.close
            end
            yield :launch, petition
        end
    end
end