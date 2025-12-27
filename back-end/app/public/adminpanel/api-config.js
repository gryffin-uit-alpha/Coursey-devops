// API Configuration for Admin Panel
// Detects environment and sets API URL accordingly

(function () {
    var hostname = window.location.hostname;

    if (hostname === 'localhost' || hostname === '127.0.0.1') {
        // Local development
        window.API_BASE_URL = 'http://localhost:8080';
    } else {
        // Production - extract base domain and prepend 'api.'
        // e.g., admin.gryffin-uit.site -> api.gryffin-uit.site
        var baseDomain = hostname.replace(/^admin\./, '');
        window.API_BASE_URL = 'https://api.' + baseDomain;
    }

    console.log('[API Config] Using:', window.API_BASE_URL);
})();
