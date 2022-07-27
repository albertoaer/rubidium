def policy_template(to, name, default)
    n = "@#{name.to_s}".to_sym
    to.define_singleton_method "do_#{name.to_s}".to_sym do
        x = instance_variable_get n
        return default if x.nil?
        x
    end
    to.define_singleton_method "set_#{name.to_s}".to_sym do |v|
        instance_variable_set n, v
    end
end

class Service
    policy_template(self, :inspect, false)
    policy_template(self, :restart, false)
    
    def initialize(&block)
        instance_exec &block if block_given?
    end

    ##
    # Grant the service a function to call primitives from other services
    def set_services(&services)
        @services = services
    end

    ##
    # Allow the service tell which default primitives exports
    def exports
    end

    ##
    # Called to run the service main loop
    def call
    end
end