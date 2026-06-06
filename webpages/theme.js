(function () {
    const STORAGE_KEY = 'nexacloud-theme';
    const prefersDark = () => window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;

    function getSavedTheme() {
        const saved = localStorage.getItem(STORAGE_KEY);
        if (saved === 'dark' || saved === 'light') return saved;
        return prefersDark() ? 'dark' : 'light';
    }

    function applyTheme(theme) {
        const normalized = theme === 'dark' ? 'dark' : 'light';
        document.documentElement.setAttribute('data-theme', normalized);
        document.body && document.body.setAttribute('data-theme', normalized);
        localStorage.setItem(STORAGE_KEY, normalized);
        document.querySelectorAll('[data-theme-toggle]').forEach(btn => {
            btn.textContent = normalized === 'dark' ? '☀️ Claro' : '🌙 Oscuro';
            btn.setAttribute('aria-label', normalized === 'dark' ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro');
            btn.setAttribute('title', normalized === 'dark' ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro');
        });
    }

    window.toggleTheme = function () {
        const current = document.documentElement.getAttribute('data-theme') || getSavedTheme();
        applyTheme(current === 'dark' ? 'light' : 'dark');
    };

    window.applySavedTheme = function () {
        applyTheme(getSavedTheme());
    };

    applyTheme(getSavedTheme());
    document.addEventListener('DOMContentLoaded', window.applySavedTheme);
})();
