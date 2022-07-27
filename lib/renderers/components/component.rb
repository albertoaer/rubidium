class Component
    @@dyn_id = 0

    class << self
        attr_reader :components
    end

    def initialize(id)
        @id = id
        @view_holder = [] #Array with 0 elements
        view
        update
        `setInterval(() => #{update}, #{self.class.interval_time})` if self.class.respond_to? :interval_time
    end

    ##
    # Gets the component view
    def view
        @view_holder = Element.find("##{@id}") if @view_holder.length == 0 or @view_holder.parent.length == 0
        @view_holder
    end

    ##
    # Uses another component inside
    def self.use(name, comtype)
        com = comtype.create
        @components = [] if @components.nil?
        @components << com
        define_method(name) { com }
    end

    ##
    # Creates a new instance of the component
    def self.create
        id = "opal_dyn_com_#{@@dyn_id}"
        com = self.new id
        @@dyn_id += 1
        com
    end

    ##
    # Checks a component every given time
    def self.check_each(time)
        self.define_singleton_method(:interval_time) { time }
    end

    ##
    # Tells if the component was generated dynamically
    def dynamic?
        @id.start_with? 'opal_dyn_com_'
    end

    ##
    # Updates the component and children data whenever is called 
    def update
        view.html render
        self.class.components.each { |com| com.update } unless self.class.components.nil?
        after
    end

    ##
    # Outter html component representation
    def layout
        "<#{self.class} id=\"#{@id}\"></#{self.class}>"
    end

    ##
    # Called before children components are rendered
    def render
        raise 'render must be overriden'
    end

    ##
    # Called after children components are rendered
    def after
    end
end