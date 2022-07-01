require 'set'
require 'digest'
require_relative 'middleware'

##
# This middleware allows requests indicate to save their response for future requests
# Can be many 'response cache' layers each of them with a key formed with a set of the request attributes, that always include the route
class ResponseCache
    include Middleware
    @@layers = {}

    def initialize(layer_name, *key_att)
        @layer_name = layer_name
        @key_att = key_att.to_set
        @key_att.add(:route)

        raise "Layer name '#{@layer_name}' already in use" if @@layers.key? @layer_name
        @@layers[@layer_name] = self

        @responses = {} #Associate a sha-1 key to a response
        @expected = Set.new #Set of sha-1 keys of awaited responses
    end

    def before(req)
        k = get_key(req)
        return @responses[k] if @responses.key? k
        unless req.respond_to? :save_response
            expect = Proc.new do |layer, obj|
                raise "Invalid layer" unless @@layers.key? layer
                key = @@layers[layer].get_key(obj)
                @@layers[layer].expect key
            end
            req.define_singleton_method(:save_response) do |layer|
                expect.call layer, self
            end
        end
    end

    def after(req, res)
        k = get_key(req)
        unless @expected.delete?(k).nil?
            @responses[k] = res
        end
    end

    def expect(key)
        @expected.add key
    end

    def get_key(obj)
        collect = ""
        @key_att.each do |v|
            collect += obj.method(v).call.to_s
        end
        Digest::SHA1.hexdigest collect
    end
end