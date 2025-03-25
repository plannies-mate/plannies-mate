// Flash message handling
const FlashMessage = {
    set: function(type, message) {
        document.cookie = `flash_message=${encodeURIComponent(JSON.stringify({type, message}))}; path=/`;
    },
    get: function() {
        const match = document.cookie.match(/flash_message=([^;]+)/);
        if (!match) return null;

        // Clear the cookie immediately
        document.cookie = "flash_message=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT";

        try {
            return JSON.parse(decodeURIComponent(match[1]));
        } catch(e) {
            return null;
        }
    },
    display: function() {
        const flash = this.get();
        if (!flash) return;

        const container = document.getElementById('flash-container');
        if (!container) return;

        const div = document.createElement('div');
        div.className = `flash flash-${flash.type}`;
        div.textContent = flash.message;

        // Add close button
        const closeBtn = document.createElement('button');
        closeBtn.innerHTML = '&times;';
        closeBtn.className = 'flash-close';
        closeBtn.onclick = function() { div.remove(); };
        div.appendChild(closeBtn);

        container.appendChild(div);

        // Auto-remove after 5 seconds
        setTimeout(() => div.remove(), 5000);
    }
};

// Call on page load
document.addEventListener('DOMContentLoaded', function() {
    FlashMessage.display();
});
