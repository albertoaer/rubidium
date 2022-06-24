require 'concurrent'

class App
    def initialize
        @services = Array.new
        @primitives = Hash.new
        @primitives[:launch] = method(:launch)
        @primitives[:spawn] = -> (&block) { launch(block) }
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
        puts runnable.class.policies if runnable.class.respond_to? :policies
        if runnable.class.method_defined? :call
            @pool.post do
                finnished = false
                begin
                    runnable.call { |name, *args, **kwargs, &block| @primitives[name].(*args, **kwargs, &block) }
                rescue StandardError => e
                    puts "Rescued[#{runnable.class.name}]: #{e.inspect}"
                    e.backtrace.each { |x| puts "\t#{x}" } if Service.about runnable, :inspect
                else
                    finnished = true
                end while Service.about runnable, :restart
                if not finnished
                    puts "Aborted[#{runnable.class.name}]"
                end
            end
        end
    end
end