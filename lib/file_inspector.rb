require_relative 'service'
require_relative 'HTTPError'

class FileRecord
    attr_reader :data

    ##
    # Initializes a file record, the file must exist at the moment of creation
    def initialize(filename)
        @filename = filename
        @time = File.mtime(filename)
        @data = File.read(filename)
        @followers = 1
    end

    ##
    # Checks if the file has been changed recently so it must be loaded again into memory
    def update
        previous = @time
        if previous != (@time = File.mtime(@filename))
            @data = File.read(@filename)
        end
    end

    def inc() @followers += 1 end

    def dec() @followers -= 1 end

    def alive() @followers > 0 end
end

class FileInspector < Service
    policy :restart
    policy :inspect

    attr_reader :target, :records

    def initialize(&block)
        @target = nil
        @elapse_time = nil
        @records = {}
        @mutex = Mutex.new
        super(&block)
    end

    def elapse(elapse_time) @elapse_time = elapse_time end

    def track(target) 
        raise ArgumentError.new 'Invalid directory to inspect' unless File.directory? target
        @target = target
    end

    def request(file, revision=true)
        raise "Inspecting no folder" if target.nil?
        path = File.realdirpath File.join(@target, file)
        updated = nil
        @mutex.synchronize { updated = inspect(path, !revision) }
        return updated
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

    def call
        while true
            sleep @elapse_time unless @elapse_time.nil?
            @mutex.synchronize do
                @records.each_key { |filename| inspect(filename, false) }
            end
        end
    end
end