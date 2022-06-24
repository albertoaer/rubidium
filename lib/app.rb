require 'concurrent'

class App
    def initialize
        @services = Array.new
        @primitives = Hash.new
        @primitives[:launch] = method(:launch)
    end

    def include(service, **primitives)
        @services.push(service)
        primitives&.each { |key, val| @primitives[key] = service.method(val) }
    end

    def run(threads=5)
        @pool = Concurrent::FixedThreadPool.new threads
        @services.each { |service| launch service }
        @pool.wait_for_termination
    end

    private

    def launch(runnable)
        if runnable.class.method_defined? :call
            @pool.post do
                finnished = false
                begin
                    runnable.call { |name, *args| @primitives[name].(*args) }
                rescue StandardError => e
                    puts "Rescued[#{runnable.class.name}]: #{e.inspect}"
                else
                    finnished = true
                end while runnable.respond_to?(:restart?) && runnable.restart?
                if not finnished
                    puts "Aborted[#{runnable.class.name}]"
                end
            end
        end
    end
end