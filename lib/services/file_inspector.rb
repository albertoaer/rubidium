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

class FileInspector < Service
    policy :restart
    policy :inspect

    attr_reader :target, :records, :route_ext, :no_route_ext, :tree

    def initialize(&block)
        @target = []
        @elapse_time = nil
        @records = Concurrent::Map.new #Files recorded in memory
        @treenode = Struct.new(:path, :auth, :childs) do
            def directory?
                childs.class == Hash
            end
        end
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
        treecontent = {}
        @tree = @treenode.new(nil, :all, treecontent) #Mapped routes with real files
        opened_dirs = []
        @target.each { |t| opened_dirs << [t, treecontent] }
        while opened_dirs.size > 0
            orig = opened_dirs.pop
            get_elements(orig[0]).each do |f, rpath|
                next if f == '.' or f == '..' # Exclude ., ..
                vessel, name, data = if File.directory? rpath
                    childs = {}
                    opened_dirs << [rpath, childs]
                    [orig[1], f, @treenode.new(rpath, :all, childs)]
                else
                    name = v_name f
                    ext = v_ext(f)
                    if name.nil?
                        [orig[1], ext, @treenode.new(rpath, :all, nil)]
                    elsif orig[1].key? name
                        [orig[1][name], ext, @treenode.new(rpath, :all, nil)]
                    else
                        [orig[1], name, @treenode.new(rpath, :all, {ext => @treenode.new(rpath, :all, nil)})]
                    end
                end
                raise "Collision detected for tree name '#{name}' on: #{rpath}" if vessel.key? name
                vessel[name] = data
            end
        end
    end

    ## Get the elements on a folder and the real path, also maps virtual routes as real files in presence of '.virtuals.json'
    # virtual-routes.json example:
    # {
    #    "virtual name (.ext?)": "real name (.ext?)"
    #    ...
    #}
    def get_elements(folder)
        virtuals = File.join(folder, '.virtuals.json')
        if File.file? virtuals
            JSON.load_file(virtuals).map { |k,v| [k, File.join(folder, v)] }
        else
            Dir.entries(folder).map { |f| [f, File.join(folder, f)] }
        end
    end

    ## Solves a given route based on the mapped file tree
    def solve_route(route)
        path = route.split('/').filter { |p| p.length > 0 }

        #Parse route as path
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

        #Match all path parts
        path.each do |part|
            if current.childs.key? part
                current = current.childs[part]
            elsif current.childs.key? '$'
                current = current.childs['$']
                params << part
            else
                raise HTTPError.new 404, "No file found on the tree: #{route}"
            end
        end

        #Solve routed extensions
        if current.directory?
            # Unexpected behave when multiple routed extensions are childs of the same name
            current = current.childs.find { |file| @route_ext.include? file[0] }&.[](1)
            #File not found for null child
            raise HTTPError.new 404, "No file found on the tree: #{route}" if current.nil?
            #If a folder or nil is returned, raise and HTTP error
            raise HTTPError.new 403, "Trying to access internal folder" if current.directory?
        end
        return current.path, v_ext(current.path), params # path, extension, params
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
    
    private :map_tree, :get_elements, :v_divide, :v_name, :v_ext

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

    private :close, :inspect

    def call
        while true
            sleep @elapse_time unless @elapse_time.nil?
            @records.each_key { |filename| inspect(filename, false) }
        end
    end
end