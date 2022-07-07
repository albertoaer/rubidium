require 'nokogiri'
require_relative 'raw'
require_relative '../http_error'

class HTMLRenderer < RawRenderer
    def render(req)
        obligatory_only(req)
        res = super req
        validate_html res.body
        res
    end

    def validate_html(html)
        doc = Nokogiri::HTML html
        raise HTTPError.new 500, doc.errors.map { |x| x.to_s }.join(', '), 'HTML Error' unless doc.errors.empty?
    end
end