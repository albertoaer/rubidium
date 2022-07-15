require_relative 'app'
require_relative 'vault'

##
# Deploy testing application with:
# - runtime services exposure
# - instant shutdown on task termination
# - direct access to app methods
def fast_app(&block)
    app = App.new
    Thread.new do
        app.instance_exec &block
        app.shutdown
    end
    app.run
end

##
# Abstracts the app providing process
# @return [lambda] the service request function
def service_provider(&block)
    app = App.new
    def executor
        binding
    end
    exc = executor
    exc.define_singleton_method :provide do |utility, **primitives|
        app.provide(utility, **primitives)
    end
    exc.instance_exec &block if block_given?
    return app.fn_services
end