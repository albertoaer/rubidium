class Service
    @@default_policies = { restart: false, inspect: false }
    class << self
        def policies
            unless instance_variable_defined? :@policies
                @policies = Hash.new
            end
            @policies
        end
    end

    def initialize(&block)
        instance_exec &block if block_given?
    end

    def self.policy(name, action=true)
        self.policies[name] = action
    end

    def call
    end

    def self.about(service, action)
        if service.class.respond_to? :policies and not service.class.policies.nil? and service.class.policies.key? action
            service.class.policies[action]
        else
            @@default_policies[action]
        end
    end
end