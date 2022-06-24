require 'pg'
require 'json'
require_relative 'raw'

class SqlRenderer < RawRenderer
    def initialize(**config)
        @conn = PG.connect **config
    end

    def render(request)
        src = yield :file, request.path
        result = @conn.exec_params(src, request.params)
        json = get_json(result)
        ["Content-Type: application/json", json]
    end

    private

    def get_json(result)
        JSON.generate result.map { |row| row }
    end
end