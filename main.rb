require_relative 'lib/server'
require_relative 'lib/file_inspector'
require_relative 'lib/app'
require_relative 'lib/renderer'
require_relative 'lib/renderers/html'
require_relative 'lib/renderers/markdown'
require_relative 'lib/renderers/raw'
require_relative 'lib/renderers/controller'

app = App.new

FileInspector.new do
    elapse 0.1
    track "./public"
    app.include self, file: :request
end

Renderer.new do
    use HTMLRenderer.new, :html
    use MarkdownRenderer.new, :md
    use RawRenderer.new, :css, :js, :txt
    router ControllerRenderer.new, :rb
    app.include self, render: :render
end

Server.new do
    setup ip: 'localhost'
    app.include self
end

app.run