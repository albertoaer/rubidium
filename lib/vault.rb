require 'yaml'
require 'json'

## Utilities for data structures manipulation
module Utils
    def self.symbolize(data)
        mod = -> (k) { k.is_a?(String) ? k.to_sym : k }
        if data.class == Hash
            data.transform_keys &mod
        elsif data.class == Array
            data.map &mod
        else
            data
        end
    end
end


## The Vault provides a standard behave through configuration files
module Vault
    EXTENSIONS = ['.yml', '.yaml', '.json']
    
    def self.get_yaml(file)
        YAML.load_file(file)
    end

    def self.get_json(file)
        JSON.load_file(file)
    end

    CONVERSION = {'.yml' => method(:get_yaml), '.yaml' => method(:get_yaml), '.json' => method(:get_json)}
    
    @@data = {}

    def self.load(name, data)
        raise "Already loaded into the Vault: #{name}" if @@data.key? name
        @@data[name] = data
    end

    def self.update(name, data)
        raise "Not loaded into the Vault: #{name}" unless @@data.key? name
        @@data[name] = data
    end

    ## The from methods allow merging multiple sources in order to mix or replace multiple configurations
    # The first elements are least priority and will be overwritten by the last ones in case of same key
    def self.from(*names)
        res = {}
        names.map { |name| @@data[name] }.each { |v| res.merge! v unless v.nil? }
        res
    end

    def self.each(&block)
        @@data.each &block
    end
end

## Vault configuration files shared accross the application
class SharedPrefs
    @@shared = ['sharedprefs', 'sharedprefs.local']

    def self.allow(name)
        @@shared << name
    end

    def get_pref(name)
        s = Vault.from(*@@shared)
        s[name] unless s.nil?
    end
end

if File.directory? 'vault'
    Dir.foreach 'vault' do |item|
        name = File.join('vault', item)
        ext = File.extname(item)
        next unless Vault::EXTENSIONS.include? ext and File.file? name
        Vault.load File.basename(name, '.*'), Vault::CONVERSION[ext].call(name)
    end
    rules = Vault.from('vault')
    Vault.each do |name, content|
        rules.each do |rule, val|
            case rule.to_s #Always to_s in order to avoid mistmatch with symbolized rule
            when 'symbolize_str'
                content = Utils.symbolize(content) if val
            else
                raise "Unknown Vault rule: #{rule.to_s}"
            end
        end
        SharedPrefs.allow(name) if File.extname(name) == '.shared'
        Vault.update(name, content)
    end
end