require_relative 'header_parser'

class HTTPHeaders
    include HeaderParser

    attr_reader :data

    ##
    # Initialize the class with a hash of arrays
    def initialize(data)
        @data = data
    end

    ##
    # Creates a HTTPHeaders object converting a hash to a hash of arrays
    def self.from_kv(data)
        HTTPHeaders.new data.transform_values { |v| v.class == Array ? v : [v] }
    end
    
    ##
    # Creates a HTTPHeaders object from an array of raw text lines
    def self.from_raw(raw_input)
        data = {}
        raw_input.each do |raw_header|
            next if raw_header.strip.empty?
            i = raw_header.index(':')
            field = i.nil? ? raw_header : raw_header[0..i-1]
            item = i.nil? ? '' : raw_header[i+1..-1]
            data.key?(field) ? (data[field] << item) : (data[field] = [item])
        end
        HTTPHeaders.new data
    end

    ##
    # Iterates through all the fields
    def each
        @data.each { |field,items| items.each { |item| yield field, item } unless items.empty? }
    end

    ##
    # Updates a field that is expected to have a single value
    def set(field, val)
        @data[field] = [val]
    end

    ##
    # Includes a value to a field that may have many
    def include(field, val)
        @data.key?(field) ? (@data[field] << val) : set(field, val)
    end

    ##
    # Gets the value of a field that is expected to have a single value 
    def get(field)
        @data[field]&.first
    end

    ##
    # Gets all the values of a field that may have many
    def get_all(field)
        @data[field]
    end
end