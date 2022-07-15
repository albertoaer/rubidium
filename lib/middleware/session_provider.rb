require 'concurrent'
require 'securerandom'
require_relative 'middleware'

class SessionStorage
    def initialize
        @active_sessions = Concurrent::Map.new
        @content_struct = Struct.new('SessionContent', :data, :auth)
    end

    def create
        id = SecureRandom.uuid
        content = @content_struct.new nil, :all
        @active_sessions[id] = content
        [id, content]
    end

    def clean_id(id)
        return id if @active_sessions.key? id
        #Returns nil by default
    end

    def [](id)
        @active_sessions[id]
    end

    def delete(id)
        @active_sessions.delete(id)
    end
end

class Session
    attr_reader :id
    
    def initialize(id, req, storage)
        @id = id
        @content = storage[@id]
        @storage = storage
        @services = req.services
    end

    def data
        raise 'No active session' if @id.nil?
        return @content.data
    end

    def data=(value)
        raise 'No active session' if @id.nil?
        @content.data = value
    end

    def auth
        raise 'No active session' if @id.nil?
        return @content.auth
    end

    def auth=(value)
        raise 'No active session' if @id.nil?
        raise 'Invalid permission level' unless @services.call :is_permission?, value
        @content.auth = value
    end

    def new
        close
        @id, @content = @storage.create
    end

    def close
        #Wont care if there is no active session since reusability and error prevention
        @storage.delete @id
        @id = nil
        @content = nil
    end
end

class SessionProvider
    include Middleware

    attr_reader :name, :storage

    def initialize(name)
        @name = name.to_s #the name, for example: id, sId, session, etc...
        @storage = SessionStorage.new
    end

    def before(req)
        id = @storage.clean_id req.headers.list_kv_val('Cookie', @name, ';', '=')
        session = Session.new id, req, @storage
        req.define_singleton_method(:session) { session }
    end

    def after(req, res)
        res.headers.include 'Set-Cookie', "#{@name}=#{req.session.id}" unless req.session.id.nil?
    end
end