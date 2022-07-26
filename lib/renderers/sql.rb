require 'json'
require_relative 'raw'
require_relative '../response'

class SqlRenderer < RawRenderer
    def render(req)
        obligatory_only(req)
        src = yield :file, req.path
        result = yield :sql_query, src, req.params
        json = get_json(result)
        Response.ok json, 'Content-Type' => 'application/json'
    end

    private

    def get_json(result)
        JSON.generate result.map { |row| row }
    end
end