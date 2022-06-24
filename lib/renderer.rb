require_relative 'httperror'
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

    def render(request)
        request.resolve! unless request.resolved #Prevent resolve twice if it's already done
        renderer = get_renderer_for(request.ext)
        unless renderer.nil?
            renderer.render(request, &@services)
        else
            raise HTTPError.new 404, "No render found for extension: #{request.ext}"
        end
    end

    private

    def get_renderer_for(ext)
        return @renderers[ext]
    end
end