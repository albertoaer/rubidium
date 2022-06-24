require_relative 'HTTPError'
require_relative 'service'

class Renderer < Service    
    def initialize(&block)
        @renderers = {}
        @routing_renderer = nil
        super(&block)
    end

    def use(renderer, *extensions)
        extensions.each do |ext|
            if @renderers.key? ext
                raise "Extension already in use: .#{ext.to_s}"
            else
                @renderers[ext] = renderer
            end
        end
    end

    def router(renderer, *extensions)
        @routing_renderer = renderer
        use(renderer, *extensions)
    end

    def render(request)
        renderer = get_renderer_for(request.ext)
        unless renderer.nil?
            renderer.render(request, &@services)
        else
            raise HTTPError.new 404, "No render found for extension: #{request.ext}"
        end
    end

    def call(&services) @services = services end

    private

    def get_renderer_for(ext)
        return @routing_renderer if ext.nil?
        return @renderers[ext]
    end
end