require 'pg'
require 'concurrent'
require_relative 'service'

class SQLConnector < Service
    set_inspect true

    def initialize(&block)
        @connected = Concurrent::Semaphore.new(0)
        super(&block)
    end

    def query(querystr, params)
        @connected.acquire
        @connected.release
        handle_query(querystr, params)
    end

    def handle_query
        raise 'Should be overriden'
    end

    def call
        start_connector
        @connected.release
    end

    def start_connector
        raise 'Should be overriden'
    end

    def exports
        { sql_query: :query }
    end
end