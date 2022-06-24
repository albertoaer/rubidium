require_relative 'lib/server'
require_relative 'lib/file_inspector'
require_relative 'lib/app'
require_relative 'lib/renderer'
require_relative 'lib/renderers/html'
require_relative 'lib/renderers/markdown'
require_relative 'lib/renderers/raw'
require_relative 'lib/renderers/controller'
require_relative 'lib/renderers/erb_template'
require_relative 'lib/renderers/sql'
require_relative 'lib/vault'

app = App.new

FileInspector.new do
    elapse 0.1
    track "./public"
    @route_ext = [ :rb, :erb, :sql ]
    @no_route_ext = [ :html, :js, :css, :md ]
    app.include self, file: :request, solve_route: :solve_route
end

Renderer.new do
    use HTMLRenderer.new, :html
    use MarkdownRenderer.new, :md
    use RawRenderer.new, :css, :js, :txt
    use ERBRenderer.new, :erb
    use ControllerRenderer.new, :rb
    use SqlRenderer.new(**Vault.from('db', 'db.local')), :sql
    app.include self, render: :render
end

Server.new do
    setup **Vault.from('server', 'server.local') #Load config from server and local server
    app.include self
end

app.run