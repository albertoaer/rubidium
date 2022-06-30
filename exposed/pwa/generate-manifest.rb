require 'json'
require 'pathname'

def get req
    def iconsz img
        File.read(img, mode: 'rb')[0x10..0x18].unpack('NN').join('x')
    end
    manifest = req.service(:pref, :manifest).clone
    manifest["icons"] = Dir["#{__dir__}/icons/**/*.png"].map { |f| { "src" => Pathname.new(f).relative_path_from(__dir__), "sizes" => iconsz(f) } }
    [:json, JSON.generate(manifest)]
end