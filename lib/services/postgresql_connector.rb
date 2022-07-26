require 'pg'
require 'concurrent'
require_relative 'sql_connector'

class PostgreSQLConnector < SQLConnector
    def initialize(**config, &block)
        @config = config
        @conn = nil
        super(&block)
    end

    def handle_query(querystr, params)
        @conn.exec_params(querystr, params)
    end

    def start_connector
        @conn = PG.connect **@config
    end
end