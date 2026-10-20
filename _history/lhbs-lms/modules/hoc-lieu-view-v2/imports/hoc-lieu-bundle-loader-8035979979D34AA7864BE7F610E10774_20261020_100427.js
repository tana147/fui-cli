// === BUNDLE LOADER FOR HOC LIEU VIEW V2 ===
;(function() {
  const rawUrl = 'https://raw.githubusercontent.com/ND-Luan/fui-mcp/main/workspaces/lhbs-lms/modules/hoc-lieu-view-v2/hoc-lieu-bundle.js';
  const cdnUrl = 'https://cdn.jsdelivr.net/gh/ND-Luan/fui-mcp@main/workspaces/lhbs-lms/modules/hoc-lieu-view-v2/hoc-lieu-bundle.js';
  const script = document.createElement('script');
  script.src = cdnUrl;
  script.onerror = function() {
    console.warn('CDN fallback to raw.githubusercontent.com');
    const fallback = document.createElement('script');
    fallback.src = rawUrl;
    document.head.appendChild(fallback);
  };
  document.head.appendChild(script);
})();