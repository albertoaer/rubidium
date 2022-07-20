require 'nokogiri'
require 'set'
require_relative 'raw'
require_relative '../http_error'
require_relative 'components/component_manager.rb'

class HTMLRenderer < RawRenderer
    @@component_manager = ComponentManager.new './lib/renderers/components'

    def render(req)
        obligatory_only(req)
        res = super req
        process_html res
    end

    def process_html(res)
        doc = validated_html res.body
        @@component_manager.insert_components(doc)
        res.body = doc.serialize
        res
    end

    def validated_html(html)
        doc = Nokogiri::HTML5.parse html
        raise HTTPError.new 500, doc.errors.map { |x| x.to_s }.join(', '), 'HTML Error' unless doc.errors.empty?
        doc
    end
end