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

    def render(file)
        ext = (File.extname file)[1..-1]
        renderer = get_renderer_for(ext)
        unless renderer.nil?
            renderer.render(file) { |*args| @request.call(*args) }
        else
            puts "No render found for extension: #{ext}"
        end
    end

    def call(&request) @request = request end

    private

    def get_renderer_for(ext)
        return @routing_renderer if ext.nil?
        return @renderers[ext.to_sym]
    end
end