require 'concurrent'
require 'securerandom'
require_relative 'middleware'

class SessionProvider
    include Middleware

    def initialize(name)
        @name = name.to_s #the name, for example: id, sId, session, etc...
        @active_sessions = Concurrent::Map.new
    end

    def before(req)
        id = req.attributes.list_kv_val('Cookie', @name, ';', '=')
        id = nil unless @active_sessions.key? id
        active_sessions = @active_sessions
        req.define_singleton_method(:session_id) { id }
        req.define_singleton_method(:session) { active_sessions[id] if active_sessions.key? id }
        req.define_singleton_method(:write_session) { |credentials| active_sessions[id] = credentials if active_sessions.key? id }
        req.define_singleton_method(:new_session) do |credentials|
            active_sessions.delete(id) if active_sessions.key? id
            id = SecureRandom.uuid
            active_sessions[id] = credentials
        end
        req.define_singleton_method(:close_session) do
            active_sessions.delete(id) if active_sessions.key? id
            id = nil
        end
    end

    def after(req, res)
        res.attributes.include 'Set-Cookie', "#{@name}=#{req.session_id}" unless req.session_id.nil?
    end
end