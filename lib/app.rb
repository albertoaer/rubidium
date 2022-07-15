require 'concurrent'

class App
    attr_reader :services, :primitives, :fn_services

    def initialize
        @services = Array.new
        @primitives = Hash.new
        @primitives[:launch] = method(:launch)
        @primitives[:spawn] = lambda { |&block| launch(block) }
        @fn_services = lambda { |name, *args, **kwargs, &block|
            raise "#{name} not in #{@primitives.keys}" unless @primitives.key? name
            @primitives[name].(*args, **kwargs, &block)
        }
        @pool = nil #Pool will be setted up when the app got run
    end

    ## The service wil be launched when the app starts
    def serve(service, **primitives)
        @services.push(service)
        provide service, **primitives
        launch service unless @pool.nil?
    end

    ## An utility only provides primitives to the services
    def provide(utility, **primitives)
        utility.set_services &@fn_services if utility.respond_to?(:set_services)
        primitives.each { |key, val| @primitives[key] = utility.method(val) }
    end

    def run(**config)
        @pool = Concurrent::ThreadPoolExecutor.new **config
        @services.each { |service| launch service }
        @pool.wait_for_termination
        @pool = nil
    end

    def shutdown
        raise 'No pool running' if @pool.nil?
        @pool.shutdown
        @pool = nil
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