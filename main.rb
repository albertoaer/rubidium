require_relative 'lib/services/server'
require_relative 'lib/services/file_inspector'
require_relative 'lib/app'
require_relative 'lib/services/renderer'
require_relative 'lib/renderers/html'
require_relative 'lib/renderers/markdown'
require_relative 'lib/renderers/raw'
require_relative 'lib/renderers/controller'
require_relative 'lib/renderers/erb_template'
require_relative 'lib/renderers/sql'
require_relative 'lib/vault'
require_relative 'lib/middleware/error_redirect'
require_relative 'lib/middleware/session_provider'
require_relative 'lib/middleware/response_cache'
require_relative 'lib/services/authentication'

app = App.new

FileInspector.new do
    elapse 0.1
    track "./public"
    track "./exposed/pwa" if Vault.select('manifest.shared')[:pwa]
    @route_ext = [ :rb, :erb, :sql ]
    @no_route_ext = [ :html, :js, :css, :md, :json, :png ]
    app.serve self
end

Renderer.new do
    use HTMLRenderer.new, :html
    use MarkdownRenderer.new, :md
    use RawRenderer.new, :css, :js, :txt, :json, :png
    use ERBRenderer.new, :erb
    use ControllerRenderer.new, :rb
    use SqlRenderer.new(**Vault.select('db', 'db.local')), :sql
    app.provide self
end

app.provide Authentication.new(:internal, :all)

app.provide SharedPrefs.new

Server.new do
    setup **Vault.from('server', 'server.local') #Load config from server and local server
    use SessionProvider.new :sesion
    use ResponseCache.new :routing
    use ErrorRedirect.new('/todo.md', 404), :after
    app.serve self
end

app.run **Vault.from('app')