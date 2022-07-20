require 'opal'
require 'opal/jquery'

class ComponentManager
    def initialize(*paths)
        @paths = paths
        @components = {}
        @paths.each do |path|
            Dir.glob(File.join(path, '*')) do |p|
                if File.file?(p) and !!File.basename(p).match(/^[a-z]+\_component\.rb$/)
                    @components[File.basename(p).sub(/\_component\.rb$/, '')] = p
                end
            end
        end
    end
    
    def generate_js(*components)
        builder = Opal::Builder.new
        builder.append_paths *@paths
        builder.build 'opal-jquery'
        components.each { |com| builder.build @components[com] }
        builder.to_s
    end

    def insert_components(doc)
        used_components = Set.new
        com_order = []
        idcount = 0
        @components.each_key do |com_name|
            doc.search(com_name).each do |tag|
                tag['id'] = id_by_idx idcount
                com_order << com_name
                idcount += 1
                used_components.add com_name
            end
        end
        if used_components.length > 0
            head = doc.search('head')[0]
            head << '<script src="https://code.jquery.com/jquery-3.6.0.min.js" integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4=" crossorigin="anonymous"></script>'
            head << '<script src="https://cdn.opalrb.com/opal/current/opal.js"></script>'
            body = doc.search('body')[0]
            body << "<script>\n#{generate_js(*used_components.to_a)}\n</script>"
            constructed = "Opal.queue(function(Opal) {\nvar $nesting = [], $$ = Opal.$r($nesting), nil = Opal.nil;\nOpal.add_stubs('new');\n"
            (0..(idcount-1)).each do |k|
                constructed += "$$('#{com_order[k].capitalize}').$new('#{id_by_idx k}');\n" 
            end
            constructed += "})\n"
            body << "<script>#{constructed}</script>"
        end
    end

    def id_by_idx(idx)
        "opal_com_#{idx}"
    end
end