require 'component'

# Use it this way: <pwaloader></pwaloader>
class Pwaloader < Component
    def update
        view.html <<-PAYLOAD
<script>
if ('serviceWorker' in navigator)
    window.addEventListener('load', () => {
        navigator.serviceWorker.register('/service-worker.js');
    });
<#{47.chr}script>
PAYLOAD
    end
end