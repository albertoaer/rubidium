require 'concurrent'
require_relative 'service'
require_relative 'http_error'

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

    attr_reader :target, :records, :route_ext, :no_route_ext

    def initialize(&block)
        @target = []
        @elapse_time = nil
        @records = Concurrent::Map.new #Files recorded in memory
        @tree = {} #Mapped routes with real files
        @route_ext = {} #Extensions allowed to be accessed by route
        @no_route_ext = {} #Extensions allowed to direct access
        super(&block)
        map_tree
    end

    ## Configuration methods

    def elapse(elapse_time) @elapse_time = elapse_time end

    def track(target) 
        raise ArgumentError.new "Invalid directory to inspect: #{target}" unless File.directory? target
        @target << target
    end

    ## Routing methods

    def map_tree
        @tree = {} #Mapped routes with real files
        opened_dirs = []
        @target.each { |t| opened_dirs << [t, @tree] }
        while opened_dirs.size > 0
            orig = opened_dirs.pop
            Dir.entries(orig[0]).each do |f|
                next if f == '.' or f == '..' # Exclude ., ..
                rpath = File.join orig[0], f
                vessel, name, data = if File.directory? rpath
                    childs = {}
                    opened_dirs << [rpath, childs]
                    [orig[1], f, childs]
                else
                    name = v_name f
                    ext = v_ext(f)
                    if name.nil?
                        [orig[1], ext, rpath]
                    elsif orig[1].key? name
                        [orig[1][name], ext, rpath]
                    else
                        [orig[1], name, {ext => rpath}]
                    end
                end
                raise "Collision detected for tree name '#{name}' on: #{rpath}" if vessel.key? name
                vessel[name] = data
            end
        end
    end

    def solve_route(route)
        path = route.split('/').filter { |p| p.length > 0 }

        if path.length > 0
            name, ext = v_divide path.pop
            path << name unless name.nil?
            unless ext.nil?
                unless no_route_ext.include? ext
                    raise HTTPError.new 403, "Trying to access not allowed route: #{ext}"
                end
                path << ext
            end
        end

        current = @tree
        params = []
        path.each do |part|
            if current.key? part
                current = current[part]
            elsif current.key? '$'
                current = current['$']
                params << part
            else
                raise HTTPError.new 404, "No file found on the tree: #{route}"
            end
        end
        if current.class != String
            # Unexpected behave for multiple route extensions in the same folder
            current = current.find { |file| @route_ext.include? file[0] }&.[](1)
            #If a folder or nil is returned, raise and HTTP error
            raise HTTPError.new 403, "Trying to access internal folder" if current.class != String
        end
        return current, v_ext(current), params # path, extension, params
    end

    ## Returns virtual name and extension
    def v_divide(current)
        [v_name(current), v_ext(current)]
    end

    ## Virtual name without extension, a hidden file's name would be empty String
    def v_name(current)
        name = File.basename('_' + current, '.*')[1..-1]
        name.empty? ? nil : name
    end

    ## Virtual extension, even hidden files are treat as extensions
    def v_ext(current)
        # Concatenate with _ for getting as extension hidden files
        ext = File.extname('_' + File.basename(current))[1..-1]
        ext.nil? ? nil : ext.to_sym
    end
    
    ## File methods

    def request(file, revision=true)
        raise "Inspecting no folder" if target.nil?
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

    def call
        while true
            sleep @elapse_time unless @elapse_time.nil?
            @records.each_key { |filename| inspect(filename, false) }
        end
    end
end