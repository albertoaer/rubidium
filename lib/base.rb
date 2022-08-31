require_relative 'services/server'
require_relative 'services/file_cache'
require_relative 'services/router'
require_relative 'app'
require_relative 'services/renderer'
require_relative 'renderers/html'
require_relative 'renderers/markdown'
require_relative 'renderers/raw'
require_relative 'renderers/controller'
require_relative 'renderers/erb_template'
require_relative 'renderers/sql'
require_relative 'vault'
require_relative 'middleware/error_redirect'
require_relative 'middleware/session_provider'
require_relative 'middleware/response_cache'
require_relative 'services/authentication'
require_relative 'services/postgresql_connector'

##
# BaseApp is a class that implements all the basic services and utilities ready to start working
# All BaseApp components also loads the configuration from the Vault so it's easies to configure
# Any component can be manipulate or replaced
class BaseApp < App
    attr_accessor :file_cache, :router, :renderer, :connector, :auth, :prefs, :server

    def initialize
        super
        @file_cache = FileCache.new
        @router = Router.new do
            track './public'
            track './exposed/pwa' if Vault.select('manifest.shared')[:pwa]
            @route_ext = [ :rb, :erb, :sql ]
            @no_route_ext = [ :html, :js, :css, :md, :json, :png ]
        end
        @renderer = Renderer.new do
            use HTMLRenderer.new, :html
            use MarkdownRenderer.new, :md
            use RawRenderer.new, :css, :js, :txt, :json, :png
            use ERBRenderer.new, :erb
            use ControllerRenderer.new, :rb
            use SqlRenderer.new, :sql
        end
        @connector = PostgreSQLConnector.new(**Vault.select('db', 'db.local'))
        @auth = Authentication.new(:internal, :all)
        @prefs = SharedPrefs.new
        @server = Server.new do
            setup **Vault.from('server', 'server.local') #Load config from server and local server
            use SessionProvider.new :sesion
            use ResponseCache.new :routing
            use ErrorRedirect.new('/not_found.md', 404), :after
        end
    end

    def run(**config)
        [[:file_cache, :provide], [:router, :serve], [:renderer, :provide], [:connector, :serve],
            [:auth, :provide], [:prefs, :provide], [:server, :serve]].each do |service, action|
            com = method(service).call()
            if com
                method(action).call(com)
            end
        end
        super **(Vault.from('app').merge(config))
    end
end