require_relative 'attribute_parser'

class HTTPAttributes
    include AttributeParser

    attr_reader :data

    ##
    # Initialize the class with a hash of arrays
    def initialize(data)
        @data = data
    end

    ##
    # Creates a HTTPAttributes object converting a hash to a hash of arrays
    def self.from_kv(data)
        HTTPAttributes.new data.transform_values { |v| v.class == Array ? v : [v] }
    end
    
    ##
    # Creates a HTTPAttributes object from an array of raw text lines
    def self.from_raw(raw_input)
        data = {}
        raw_input.each do |field|
            next if field.strip.empty?
            i = field.index(':')
            att = i.nil? ? field : field[0..i-1]
            item = i.nil? ? '' : field[i+1..-1]
            data.key?(att) ? (data[att] << item) : (data[att] = [item])
        end
        HTTPAttributes.new data
    end

    ##
    # Iterates through all the fields
    def each
        @data.each { |att,items| items.each { |item| yield att, item } unless items.empty? }
    end

    ##
    # Updates a field that is expected to have a single value
    def set(att, val)
        @data[att] = [val]
    end

    ##
    # Includes a value to a field that may have many
    def include(att, val)
        @data.key?(att) ? (@data[att] << val) : set(att, val)
    end

    ##
    # Gets the value of a field that is expected to have a single value 
    def get(att)
        @data[att]&.first
    end

    ##
    # Gets all the values of a field that may have many
    def get_all(att)
        @data[att]
    end
end