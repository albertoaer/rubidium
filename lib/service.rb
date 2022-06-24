class Service
    def initialize(&block)
        instance_exec &block if block_given?
    end

    def call
    end
end