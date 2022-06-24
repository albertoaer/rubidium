require 'concurrent'

class App
    def initialize
        @services = Array.new
        @primitives = Hash.new
        @primitives[:launch] = method(:launch)
        @primitives[:spawn] = lambda { |&block| launch(block) }
        @fn_services = lambda { |name, *args, **kwargs, &block| @primitives[name].(*args, **kwargs, &block) }
    end

    ## The service wil be launched when the app starts
    def serve(service, **primitives)
        @services.push(service)
        provide service, **primitives
    end

    ## An utility only provides primitives to the services
    def provide(utility, **primitives)
        utility.set_services &@fn_services if utility.respond_to?(:set_services)
        primitives.each { |key, val| @primitives[key] = utility.method(val) }
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
                    runnable.call
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