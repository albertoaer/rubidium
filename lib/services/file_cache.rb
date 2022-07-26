require 'concurrent'
require 'json'
require_relative 'service'
require_relative '../http_error'

class FileRecord
    attr_reader :data

    ##
    # Initializes a file record, the file must exist at the moment of creation
    def initialize(filename)
        @filename = filename
        @time = File.mtime(filename)
        @data = File.read(filename, mode: 'rb')
        @followers = 1
    end

    ##
    # Checks if the file has been changed recently so it must be loaded again into memory
    def update
        previous = @time
        if previous != (@time = File.mtime(@filename))
            @data = File.read(@filename, mode: 'rb')
        end
    end

    def inc() @followers += 1 end

    def dec() @followers -= 1 end

    def alive() @followers > 0 end
end

class FileCache < Service
    policy :restart
    policy :inspect

    attr_reader :target, :records, :route_ext, :no_route_ext, :tree

    def initialize(&block)
        @records = Concurrent::Map.new #Files recorded in memory
        super(&block)
    end

    ## File methods

    def request(file, revision=true)
        inspect(file, !revision)
    end

    def close(filename)
        record = @records[filename]
        if record.nil?
            record.dec
            @records.delete(filename) unless record.alive
        end
    end

    def inspect(filename, new_follower)
        record = @records[filename]
        notexists = record.nil?
        begin
            if notexists
                record = FileRecord.new filename
                @records[filename] = record
            else
                record.update
            end
            record.data
        rescue Errno::ENOENT
            @records.delete(filename) unless notexists
            raise HTTPError.new 404, 'File not found'
        end
    end

    private :close, :inspect

    def exports
        { file: :request }
    end
end