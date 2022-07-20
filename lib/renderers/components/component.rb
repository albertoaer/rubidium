class Component
    @@dyn_id = 0

    def initialize(id)
        @id = id
        @view_holder = [] #Array with 0 elements
        view
        update
        `setInterval(() => #{update}, #{self.class.interval_time})` if self.class.respond_to? :interval_time
    end

    def view
        @view_holder = Element.find("##{@id}") if @view_holder.length == 0 or @view_holder.parent.length == 0
        @view_holder
    end

    def self.use(name, comtype)
        unless self.respond_to? :components
            arr = []
            self.define_singleton_method(:components) { arr }
        end
        com = comtype.create
        self.components << com
        define_method(name) { com }
    end

    def self.create
        id = "opal_dyn_com_#{@@dyn_id}"
        com = self.new id
        @@dyn_id += 1
        com
    end

    def self.check_each(time)
        self.define_singleton_method(:interval_time) { time }
    end

    def dynamic?
        @id.start_with? 'opal_dyn_com_'
    end

    def update
        view.html render
        self.class.components.each { |com| com.update } if self.class.respond_to? :components
        after
    end

    def layout
        "<#{self.class} id=\"#{@id}\"></#{self.class}>"
    end

    def render
        raise 'render must be overriden'
    end

    def after
    end
end